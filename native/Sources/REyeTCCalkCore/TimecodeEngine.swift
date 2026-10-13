import Foundation

public enum TimecodeError: Error, Equatable, Sendable {
    case malformed
    case invalidHour
    case invalidMinute
    case invalidSecond
    case invalidFrame
    case invalidDropFrameAddress
}

public enum FrameRate: String, CaseIterable, Sendable {
    case fps23_976NDF = "23.976 NDF"
    case fps24NDF = "24 NDF"
    case fps25NDF = "25 NDF"
    case fps29_97NDF = "29.97 NDF"
    case fps29_97DF = "29.97 DF"
    case fps30NDF = "30 NDF"
    case fps50NDF = "50 NDF"
    case fps59_94NDF = "59.94 NDF"
    case fps59_94DF = "59.94 DF"
    case fps60NDF = "60 NDF"

    public var nominalFPS: Int {
        switch self {
        case .fps23_976NDF, .fps24NDF: 24
        case .fps25NDF: 25
        case .fps29_97NDF, .fps29_97DF, .fps30NDF: 30
        case .fps50NDF: 50
        case .fps59_94NDF, .fps59_94DF, .fps60NDF: 60
        }
    }

    public var dropFramesPerMinute: Int {
        switch self {
        case .fps29_97DF: 2
        case .fps59_94DF: 4
        default: 0
        }
    }

    public var isDropFrame: Bool { dropFramesPerMinute > 0 }

    public var framesPer24Hours: Int64 {
        if isDropFrame {
            let framesPer10Minutes = Int64(nominalFPS * 60 * 10 - dropFramesPerMinute * 9)
            return framesPer10Minutes * 6 * 24
        }
        return Int64(nominalFPS * 60 * 60 * 24)
    }
}

public struct Timecode: Equatable, Sendable {
    public var hours: Int
    public var minutes: Int
    public var seconds: Int
    public var frames: Int

    public init(hours: Int, minutes: Int, seconds: Int, frames: Int) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.frames = frames
    }

    public var stringValue: String {
        String(format: "%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
    }
}

public enum TimecodeEngine {
    public static func parseAddress(_ text: String, rate: FrameRate) throws -> Timecode {
        let tc = try parseComponents(text)
        guard (0...23).contains(tc.hours) else { throw TimecodeError.invalidHour }
        try validateCommon(tc, rate: rate)
        if rate.isDropFrame && isDroppedAddress(tc, rate: rate) {
            throw TimecodeError.invalidDropFrameAddress
        }
        return tc
    }

    public static func parseDuration(_ text: String, rate: FrameRate) throws -> Timecode {
        let tc = try parseComponents(text)
        guard tc.hours >= 0 else { throw TimecodeError.invalidHour }
        try validateCommon(tc, rate: rate)
        return tc
    }

    private static func parseComponents(_ text: String) throws -> Timecode {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 4,
              let h = Int(parts[0]),
              let m = Int(parts[1]),
              let s = Int(parts[2]),
              let f = Int(parts[3]) else {
            throw TimecodeError.malformed
        }
        return Timecode(hours: h, minutes: m, seconds: s, frames: f)
    }

    private static func validateCommon(_ tc: Timecode, rate: FrameRate) throws {
        guard (0...59).contains(tc.minutes) else { throw TimecodeError.invalidMinute }
        guard (0...59).contains(tc.seconds) else { throw TimecodeError.invalidSecond }
        guard (0..<rate.nominalFPS).contains(tc.frames) else { throw TimecodeError.invalidFrame }
    }

    private static func isDroppedAddress(_ tc: Timecode, rate: FrameRate) -> Bool {
        guard rate.isDropFrame else { return false }
        return tc.seconds == 0
            && tc.minutes % 10 != 0
            && tc.frames < rate.dropFramesPerMinute
    }

    public static func addressToFrames(_ tc: Timecode, rate: FrameRate) throws -> Int64 {
        try validateAddressStruct(tc, rate: rate)
        let nominal = Int64(rate.nominalFPS)
        let totalNominalFrames = Int64(tc.hours * 3600 + tc.minutes * 60 + tc.seconds) * nominal + Int64(tc.frames)

        guard rate.isDropFrame else { return totalNominalFrames }

        let totalMinutes = tc.hours * 60 + tc.minutes
        let droppedMinutes = totalMinutes - totalMinutes / 10
        let droppedFrames = Int64(rate.dropFramesPerMinute * droppedMinutes)
        return totalNominalFrames - droppedFrames
    }

    public static func framesToAddress(_ frameCount: Int64, rate: FrameRate) -> Timecode {
        let wrapped = positiveModulo(frameCount, rate.framesPer24Hours)

        if !rate.isDropFrame {
            return nominalFramesToTimecode(wrapped, nominalFPS: rate.nominalFPS)
        }

        let fps = Int64(rate.nominalFPS)
        let drop = Int64(rate.dropFramesPerMinute)
        let framesPer10Minutes = fps * 60 * 10 - drop * 9
        let framesPerMinuteDropped = fps * 60 - drop

        let tenMinuteBlocks = wrapped / framesPer10Minutes
        let remainder = wrapped % framesPer10Minutes

        var nominalFrameNumber = wrapped + drop * 9 * tenMinuteBlocks

        if remainder >= fps * 60 {
            let afterFirstMinute = remainder - fps * 60
            let completedDroppedMinutes = afterFirstMinute / framesPerMinuteDropped
            nominalFrameNumber += drop * (completedDroppedMinutes + 1)
        }

        return nominalFramesToTimecode(nominalFrameNumber, nominalFPS: rate.nominalFPS)
    }

    public static func durationToFrames(_ duration: Timecode, rate: FrameRate) throws -> Int64 {
        try validateDurationStruct(duration, rate: rate)
        let seconds = Int64(duration.hours * 3600 + duration.minutes * 60 + duration.seconds)
        return seconds * Int64(rate.nominalFPS) + Int64(duration.frames)
    }

    public static func framesToDuration(_ frameCount: Int64, rate: FrameRate) -> Timecode {
        let nonNegative = max(0, frameCount)
        return nominalFramesToTimecode(nonNegative, nominalFPS: rate.nominalFPS, wrapHours: false)
    }

    public static func duration(from start: Timecode, to end: Timecode, rate: FrameRate) throws -> Timecode {
        let startFrames = try addressToFrames(start, rate: rate)
        let endFrames = try addressToFrames(end, rate: rate)
        var delta = endFrames - startFrames
        if delta < 0 { delta += rate.framesPer24Hours }
        return framesToDuration(delta, rate: rate)
    }

    public static func add(_ lhs: Timecode, _ rhs: Timecode, rate: FrameRate) throws -> Timecode {
        let a = try addressToFrames(lhs, rate: rate)
        let b = try addressToFrames(rhs, rate: rate)
        return framesToAddress(a + b, rate: rate)
    }

    public static func subtract(_ lhs: Timecode, _ rhs: Timecode, rate: FrameRate) throws -> Timecode {
        let a = try addressToFrames(lhs, rate: rate)
        let b = try addressToFrames(rhs, rate: rate)
        return framesToAddress(a - b, rate: rate)
    }

    public static func totalDuration(_ durations: [Timecode], rate: FrameRate) throws -> Timecode {
        let total = try durations.reduce(Int64(0)) { partial, duration in
            partial + (try durationToFrames(duration, rate: rate))
        }
        return framesToDuration(total, rate: rate)
    }

    public static func totalTC(cuts: [(start: Timecode, end: Timecode)], rate: FrameRate) throws -> Timecode {
        var total: Int64 = 0
        for cut in cuts {
            let start = try addressToFrames(cut.start, rate: rate)
            let end = try addressToFrames(cut.end, rate: rate)
            var delta = end - start
            if delta < 0 { delta += rate.framesPer24Hours }
            total += delta
        }
        return framesToDuration(total, rate: rate)
    }

    private static func validateAddressStruct(_ tc: Timecode, rate: FrameRate) throws {
        guard (0...23).contains(tc.hours) else { throw TimecodeError.invalidHour }
        try validateCommon(tc, rate: rate)
        if rate.isDropFrame && isDroppedAddress(tc, rate: rate) {
            throw TimecodeError.invalidDropFrameAddress
        }
    }

    private static func validateDurationStruct(_ tc: Timecode, rate: FrameRate) throws {
        guard tc.hours >= 0 else { throw TimecodeError.invalidHour }
        try validateCommon(tc, rate: rate)
    }

    private static func nominalFramesToTimecode(_ frameCount: Int64, nominalFPS: Int, wrapHours: Bool = true) -> Timecode {
        let fps = Int64(nominalFPS)
        let framesPerHour = fps * 3600
        let framesPerMinute = fps * 60

        var remaining = frameCount
        var hours = Int(remaining / framesPerHour)
        remaining %= framesPerHour
        if wrapHours { hours %= 24 }

        let minutes = Int(remaining / framesPerMinute)
        remaining %= framesPerMinute
        let seconds = Int(remaining / fps)
        let frames = Int(remaining % fps)

        return Timecode(hours: hours, minutes: minutes, seconds: seconds, frames: frames)
    }

    private static func positiveModulo(_ value: Int64, _ modulus: Int64) -> Int64 {
        let r = value % modulus
        return r >= 0 ? r : r + modulus
    }
}
