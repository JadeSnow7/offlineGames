import Foundation

/// Deterministic RNG for reproducible deck generation and tests.
public struct SeededRNG: Sendable, Equatable {
    private static let fallbackSeed: UInt64 = 0xA5A5_A5A5_5A5A_5A5A

    public private(set) var state: UInt64

    public init(seed: UInt64) {
        self.state = seed == 0 ? Self.fallbackSeed : seed
    }

    /// Produces a pseudo-random UInt64 using xorshift64*.
    public mutating func nextUInt64() -> UInt64 {
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2_685_821_657_736_338_717
    }

    public mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        let value = nextUInt64() % span
        return Int(value) + range.lowerBound
    }

    public mutating func nextDouble() -> Double {
        let raw = nextUInt64() >> 11
        return Double(raw) / Double(1 << 53)
    }

    public static func systemSeed() -> UInt64 {
        let time = UInt64(Date().timeIntervalSinceReferenceDate * 1_000_000)
        let pid = UInt64(ProcessInfo.processInfo.processIdentifier)
        return time ^ (pid << 16) ^ 0x9E37_79B9_7F4A_7C15
    }
}
