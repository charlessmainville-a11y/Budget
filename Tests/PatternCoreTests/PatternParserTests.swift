import XCTest
@testable import PatternCore

final class PatternParserTests: XCTestCase {
    func testParsesDrumAndMelodyLines() {
        let text = """
        kick: x---x---x---x---
        snare: ----x-------x---
        hat: x-x-x-x-x-x-x-x-
        note: 0 4 7 9
        """

        let parsed = PatternParser.parse(text)

        XCTAssertEqual(parsed.drums[.kick]?.count, 16)
        XCTAssertEqual(parsed.drums[.snare]?[4], true)
        XCTAssertEqual(parsed.drums[.hat]?[1], false)
        XCTAssertEqual(parsed.melodySteps, [0, 4, 7, 9])
        XCTAssertEqual(parsed.maxStepCount, 16)
    }

    func testIgnoresUnknownLinesAndCharacters() {
        let text = """
        foo: abc
        kick: x-?-x
        note: 0 a 2
        """

        let parsed = PatternParser.parse(text)

        XCTAssertEqual(parsed.drums[.kick], [true, false, false, true])
        XCTAssertEqual(parsed.melodySteps, [0, 2])
    }

    func testScaleMapping() {
        XCTAssertEqual(ScaleMapper.midiNote(for: 0), 60)
        XCTAssertEqual(ScaleMapper.midiNote(for: 4), 67)
        XCTAssertEqual(ScaleMapper.midiNote(for: 7), 72)
    }
}
