import SwiftUI

struct ContentView: View {
    @StateObject private var audio = AudioEngineController()
    @State private var patternText = """
    kick: x---x---x---x---
    snare: ----x-------x---
    hat: x-x-x-x-x-x-x-x-
    note: 0 4 7 9
    """

    var body: some View {
        VStack(spacing: 16) {
            Text("Playable Text Instrument")
                .font(.title2.bold())

            TextEditor(text: $patternText)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .frame(minHeight: 260)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.secondary, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text("Tempo: \(Int(audio.bpm)) BPM")
                    .font(.subheadline)
                Slider(value: $audio.bpm, in: 60...180, step: 1)
            }

            HStack(spacing: 12) {
                Button("Play") {
                    audio.play(patternText: patternText)
                }
                .buttonStyle(.borderedProminent)

                Button("Stop") {
                    audio.stop()
                }
                .buttonStyle(.bordered)
            }

            Text("x = hit, - = silence, each char = 16th note")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
