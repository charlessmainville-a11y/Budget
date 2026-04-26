import Foundation

public enum DrumInstrument: String, CaseIterable {
    case kick
    case snare
    case hat
}

public struct PatternDefinition: Equatable {
    public var drums: [DrumInstrument: [Bool]]
    public var melodySteps: [Int]
    public var maxStepCount: Int

    public init(drums: [DrumInstrument: [Bool]], melodySteps: [Int], maxStepCount: Int) {
        self.drums = drums
        self.melodySteps = melodySteps
        self.maxStepCount = max(1, maxStepCount)
    }
}

public enum PatternParser {
    public static func parse(_ text: String) -> PatternDefinition {
        var drums: [DrumInstrument: [Bool]] = [:]
        var melody: [Int] = []

        for rawLine in text.split(whereSeparator: \ .isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)

            if key == "note" {
                melody = value
                    .split(whereSeparator: \ .isWhitespace)
                    .compactMap { Int($0) }
                continue
            }

            guard let instrument = DrumInstrument(rawValue: key) else { continue }
            let pattern = value.compactMap { char -> Bool? in
                switch char {
                case "x", "X": return true
                case "-": return false
                default: return nil
                }
            }
            if !pattern.isEmpty {
                drums[instrument] = pattern
            }
        }

        let longestDrumLine = drums.values.map(\.count).max() ?? 0
        let maxStepCount = max(longestDrumLine, melody.count, 16)
        return PatternDefinition(drums: drums, melodySteps: melody, maxStepCount: maxStepCount)
    }
}

public enum ScaleMapper {
    private static let majorSemitoneOffsets = [0, 2, 4, 5, 7, 9, 11]

    /// Converts a scale degree number into a MIDI note.
    /// 0 starts at C4 (MIDI 60), 1 = D4, etc.
    public static func midiNote(for degree: Int, root: Int = 60) -> UInt8 {
        let octave = Int(floor(Double(degree) / Double(majorSemitoneOffsets.count)))
        let index = ((degree % majorSemitoneOffsets.count) + majorSemitoneOffsets.count) % majorSemitoneOffsets.count
        let semitone = majorSemitoneOffsets[index] + (octave * 12)
        let note = min(max(root + semitone, 0), 127)
        return UInt8(note)
    }
}
