import XCTest
@testable import MatchingEngine

// Phase 1 test targets — write these as you build the engine. They're the
// acceptance criteria for the matching core:
//
//   - a limit order that doesn't cross rests on the book
//   - a crossing limit order generates a trade at the RESTING (maker) price
//   - partial fills leave the correct remainder resting
//   - price-time priority: at the same price, the earlier order fills first
//   - a market order sweeps multiple price levels until filled or book-empty
//   - cancel removes a resting order (and it no longer participates in matches)
//   - conservation: total shares and cash are unchanged by a sequence of trades
//
// (You can switch this to the Swift Testing framework — `import Testing` — if
// you'd prefer the modern style; XCTest is here so the package is green today.)

final class MatchingEngineTests: XCTestCase {
    func testPackageBuilds() {
        XCTAssertEqual(MatchingEngine.version, "0.0.1")
    }
    
    func testWorkedExample() {
        let book = OrderBook()
        _ = book.processOrder(newOrder: Order(id: 1, side: .buy,  type: .limit(price: 10), quantity: 100))
        let trades = book.processOrder(newOrder: Order(id: 2, side: .sell, type: .limit(price: 10), quantity: 50))
        print(trades)   // expect: one trade, 50 @ $10, taker 2 / maker 1
        XCTAssertEqual(trades.count, 1)
        let trade = trades[0]
        XCTAssertEqual(trade.takerId, 2)
        XCTAssertEqual(trade.makerId, 1)
        XCTAssertEqual(trade.price, 10)
        XCTAssertEqual(trade.quantity, 50)
    }
}
