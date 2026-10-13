import XCTest
@testable import REyeTCCalkCore

final class TimecodeEngineTests: XCTestCase {
    func testDefaultProductRateListContainsAllSupportedRates() {
        XCTAssertEqual(FrameRate.allCases.count, 10)
        XCTAssertEqual(FrameRate.fps30NDF.rawValue, "30 NDF")
    }

    func testBasicNDFRoundTrips() throws {
        let cases: [(FrameRate, String, Int64)] = [
            (.fps23_976NDF, "00:01:00:00", 1440),
            (.fps24NDF, "00:01:00:00", 1440),
            (.fps25NDF, "00:01:00:00", 1500),
            (.fps29_97NDF, "00:01:00:00", 1800),
            (.fps30NDF, "00:01:00:00", 1800),
            (.fps50NDF, "00:01:00:00", 3000),
            (.fps59_94NDF, "00:01:00:00", 3600),
            (.fps60NDF, "00:01:00:00", 3600)
        ]

        for (rate, text, expected) in cases {
            let tc = try TimecodeEngine.parseAddress(text, rate: rate)
            XCTAssertEqual(try TimecodeEngine.addressToFrames(tc, rate: rate), expected, "rate: \(rate.rawValue)")
            XCTAssertEqual(TimecodeEngine.framesToAddress(expected, rate: rate).stringValue, text, "rate: \(rate.rawValue)")
        }
    }

    func test2997DFMinuteBoundary() throws {
        let before = try TimecodeEngine.parseAddress("00:00:59:29", rate: .fps29_97DF)
        let next = TimecodeEngine.framesToAddress(try TimecodeEngine.addressToFrames(before, rate: .fps29_97DF) + 1, rate: .fps29_97DF)
        XCTAssertEqual(next.stringValue, "00:01:00:02")
    }

    func test2997DFTenMinuteBoundary() throws {
        let before = try TimecodeEngine.parseAddress("00:09:59:29", rate: .fps29_97DF)
        let next = TimecodeEngine.framesToAddress(try TimecodeEngine.addressToFrames(before, rate: .fps29_97DF) + 1, rate: .fps29_97DF)
        XCTAssertEqual(next.stringValue, "00:10:00:00")
        XCTAssertEqual(try TimecodeEngine.addressToFrames(try TimecodeEngine.parseAddress("00:10:00:00", rate: .fps29_97DF), rate: .fps29_97DF), 17_982)
    }

    func test5994DFMinuteBoundary() throws {
        let before = try TimecodeEngine.parseAddress("00:00:59:59", rate: .fps59_94DF)
        let next = TimecodeEngine.framesToAddress(try TimecodeEngine.addressToFrames(before, rate: .fps59_94DF) + 1, rate: .fps59_94DF)
        XCTAssertEqual(next.stringValue, "00:01:00:04")
    }

    func test5994DFTenMinuteBoundary() throws {
        let before = try TimecodeEngine.parseAddress("00:09:59:59", rate: .fps59_94DF)
        let next = TimecodeEngine.framesToAddress(try TimecodeEngine.addressToFrames(before, rate: .fps59_94DF) + 1, rate: .fps59_94DF)
        XCTAssertEqual(next.stringValue, "00:10:00:00")
        XCTAssertEqual(try TimecodeEngine.addressToFrames(try TimecodeEngine.parseAddress("00:10:00:00", rate: .fps59_94DF), rate: .fps59_94DF), 35_964)
    }

    func testDroppedAddressesAreRejected() {
        XCTAssertThrowsError(try TimecodeEngine.parseAddress("00:01:00:00", rate: .fps29_97DF))
        XCTAssertThrowsError(try TimecodeEngine.parseAddress("00:01:00:01", rate: .fps29_97DF))
        XCTAssertNoThrow(try TimecodeEngine.parseAddress("00:01:00:02", rate: .fps29_97DF))

        for ff in 0...3 {
            XCTAssertThrowsError(try TimecodeEngine.parseAddress(String(format: "00:01:00:%02d", ff), rate: .fps59_94DF))
        }
        XCTAssertNoThrow(try TimecodeEngine.parseAddress("00:01:00:04", rate: .fps59_94DF))
        XCTAssertNoThrow(try TimecodeEngine.parseAddress("00:10:00:00", rate: .fps59_94DF))
    }

    func testNormalTCRejects24Hours() {
        XCTAssertThrowsError(try TimecodeEngine.parseAddress("24:00:00:00", rate: .fps30NDF))
    }

    func test24HourWrapNDF() throws {
        let last = try TimecodeEngine.parseAddress("23:59:59:29", rate: .fps30NDF)
        let next = TimecodeEngine.framesToAddress(try TimecodeEngine.addressToFrames(last, rate: .fps30NDF) + 1, rate: .fps30NDF)
        XCTAssertEqual(next.stringValue, "00:00:00:00")
    }

    func test24HourWrapDF() throws {
        let last = try TimecodeEngine.parseAddress("23:59:59:29", rate: .fps29_97DF)
        let next = TimecodeEngine.framesToAddress(try TimecodeEngine.addressToFrames(last, rate: .fps29_97DF) + 1, rate: .fps29_97DF)
        XCTAssertEqual(next.stringValue, "00:00:00:00")
    }

    func testDurationCrossesMidnight() throws {
        let start = try TimecodeEngine.parseAddress("23:59:50:00", rate: .fps30NDF)
        let end = try TimecodeEngine.parseAddress("00:00:10:00", rate: .fps30NDF)
        XCTAssertEqual(try TimecodeEngine.duration(from: start, to: end, rate: .fps30NDF).stringValue, "00:00:20:00")
    }

    func testAddSubtractWrapAt24Hours() throws {
        let a = try TimecodeEngine.parseAddress("23:59:50:00", rate: .fps30NDF)
        let b = try TimecodeEngine.parseAddress("00:00:20:00", rate: .fps30NDF)
        XCTAssertEqual(try TimecodeEngine.add(a, b, rate: .fps30NDF).stringValue, "00:00:10:00")

        let c = try TimecodeEngine.parseAddress("00:00:10:00", rate: .fps30NDF)
        XCTAssertEqual(try TimecodeEngine.subtract(c, b, rate: .fps30NDF).stringValue, "23:59:50:00")
    }

    func testDurationDFDoesNotRejectDroppedAddressNumbers() throws {
        let duration = try TimecodeEngine.parseDuration("00:01:00:00", rate: .fps29_97DF)
        XCTAssertEqual(try TimecodeEngine.durationToFrames(duration, rate: .fps29_97DF), 1800)
    }

    func testTotalDurationCanExceed24Hours() throws {
        let d1 = try TimecodeEngine.parseDuration("23:00:00:00", rate: .fps30NDF)
        let d2 = try TimecodeEngine.parseDuration("02:00:00:00", rate: .fps30NDF)
        XCTAssertEqual(try TimecodeEngine.totalDuration([d1, d2], rate: .fps30NDF).stringValue, "25:00:00:00")
    }

    func testTotalTCCanExceed24Hours() throws {
        let start = try TimecodeEngine.parseAddress("00:00:00:00", rate: .fps30NDF)
        let end = try TimecodeEngine.parseAddress("12:00:00:00", rate: .fps30NDF)
        let cuts = [(start: start, end: end), (start: start, end: end), (start: start, end: end)]
        XCTAssertEqual(try TimecodeEngine.totalTC(cuts: cuts, rate: .fps30NDF).stringValue, "36:00:00:00")
    }

    func testFrameRoundTripsAcrossRates() throws {
        let samples: [Int64] = [0, 1, 23, 24, 59, 1_000, 17_982, 35_964, 100_000]
        for rate in FrameRate.allCases {
            for frame in samples {
                let wrapped = ((frame % rate.framesPer24Hours) + rate.framesPer24Hours) % rate.framesPer24Hours
                let tc = TimecodeEngine.framesToAddress(frame, rate: rate)
                XCTAssertEqual(try TimecodeEngine.addressToFrames(tc, rate: rate), wrapped, "rate=\(rate.rawValue), frame=\(frame), tc=\(tc.stringValue)")
            }
        }
    }
}
