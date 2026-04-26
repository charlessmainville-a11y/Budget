import AVFoundation
import Foundation
import PatternCore

@MainActor
final class AudioEngineController: ObservableObject {
    @Published var bpm: Double = 120
    @Published var isPlaying = false

    private let engine = AVAudioEngine()
    private var drumNodes: [DrumInstrument: AVAudioPlayerNode] = [:]
    private var drumBuffers: [DrumInstrument: AVAudioPCMBuffer] = [:]
    private let sampler = AVAudioUnitSampler()

    private var timer: DispatchSourceTimer?
    private var stepIndex = 0
    private var pattern = PatternDefinition(drums: [:], melodySteps: [], maxStepCount: 16)

    init() {
        setupAudioGraph()
        loadSamples()
    }

    private func setupAudioGraph() {
        DrumInstrument.allCases.forEach { instrument in
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: nil)
            drumNodes[instrument] = node
        }

        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        do {
            try engine.start()
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }

    private func loadSamples() {
        drumBuffers[.kick] = loadBuffer(named: "kick")
        drumBuffers[.snare] = loadBuffer(named: "snare")
        drumBuffers[.hat] = loadBuffer(named: "hat")

        // Optional melodic voice. If this fails, drum sequencing still works.
        if let bankURL = Bundle.main.url(forResource: "gs_instruments", withExtension: "dls") {
            try? sampler.loadSoundBankInstrument(at: bankURL, program: 0, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0)
        }
    }

    private func loadBuffer(named name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
              let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
        else {
            print("Missing sample: \(name).wav")
            return nil
        }

        try? file.read(into: buffer)
        return buffer
    }

    func play(patternText: String) {
        stop()
        pattern = PatternParser.parse(patternText)
        stepIndex = 0
        isPlaying = true
        startTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        drumNodes.values.forEach { $0.stop() }
        sampler.stopNote(0, onChannel: 0)
        isPlaying = false
    }

    private func startTimer() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        let interval = 60.0 / bpm / 4.0 // 16th-note duration
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        self.timer = timer
        timer.resume()
    }

    private func tick() {
        for instrument in DrumInstrument.allCases {
            guard let line = pattern.drums[instrument], !line.isEmpty else { continue }
            if line[stepIndex % line.count], let buffer = drumBuffers[instrument], let node = drumNodes[instrument] {
                if !node.isPlaying {
                    node.play()
                }
                node.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
            }
        }

        if !pattern.melodySteps.isEmpty {
            let melodyValue = pattern.melodySteps[stepIndex % pattern.melodySteps.count]
            let midiNote = ScaleMapper.midiNote(for: melodyValue)
            sampler.startNote(midiNote, withVelocity: 100, onChannel: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + (60.0 / bpm / 4.0 * 0.9)) { [weak self] in
                self?.sampler.stopNote(midiNote, onChannel: 0)
            }
        }

        stepIndex = (stepIndex + 1) % max(pattern.maxStepCount, 1)
    }
}
