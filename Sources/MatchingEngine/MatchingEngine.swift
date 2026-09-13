// MatchingEngine — the core order book + matching logic lives here.
//
// This is YOUR code to write. See SPEC.md, Phase 1. Suggested order:
//   1. Domain types:  Order, Side (buy/sell), OrderType (limit/market), Trade
//   2. The order book: bids & asks by price level, FIFO within a level
//   3. Matching:       price-time priority, partial fills, market orders, cancel
//   4. Tests:          see Tests/MatchingEngineTests
//
// Then in Phase 2 you'll wrap the book in an actor for concurrency safety.
//
// This placeholder just lets the package build before you start. Replace it.

public enum MatchingEngine {
    /// Placeholder public symbol so the library + executable compile from day one.
    public static let version = "0.0.1"
}
