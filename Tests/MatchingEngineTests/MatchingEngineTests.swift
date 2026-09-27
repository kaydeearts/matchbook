import Testing
@testable import MatchingEngine

// Phase 1 test targets — acceptance criteria for the matching core:
//
//   - a limit order that doesn't cross rests on the book
//   - a crossing limit order generates a trade at the RESTING (maker) price
//   - partial fills leave the correct remainder resting
//   - price-time priority: at the same price, the earlier order fills first
//   - a market order sweeps multiple price levels until filled or book-empty
//   - cancel removes a resting order (and it no longer participates in matches)
//   - conservation: total shares and cash are unchanged by a sequence of trades

@Suite struct MatchingEngineTests {

    @Test func packageBuilds() {
        #expect(MatchingEngine.version == "0.0.1")
    }

    @Test func workedExample() throws {
        let book = OrderBook()
        
        let initPrice = 10
        let initQuantity = 100
        let (initOrder, trade) = book.submit(side: .buy,  type: .limit(price: initPrice), quantity: initQuantity)
        #expect(trade.count == 0)
        #expect(book.getBids().count == 1)
        #expect(book.getBids()[0].price == initPrice)
        #expect(book.getBids()[0].orders.count == 1)
        #expect(book.getBids()[0].orders[0].side == .buy)
        #expect(book.getBids()[0].orders[0].quantity == initQuantity)
        
        // one trade, 50 @ $10, taker 2 (incoming sell) / maker 1 (resting buy)
        let secondQuantity = 50
        let (secondOrder, trade2) = book.submit(side: .sell, type: .limit(price: initPrice), quantity: secondQuantity)
        
        #expect(trade2.count == 1)
        #expect(trade2[0].makerId == initOrder.id)
        #expect(trade2[0].takerId == secondOrder.id)
        #expect(trade2[0].price == initPrice)
        #expect(trade2[0].quantity == initQuantity - secondQuantity)
        
        #expect(book.getBids().count == 1)
        #expect(book.getBids()[0].orders.count == 1)
        #expect(book.getBids()[0].orders[0].quantity == initQuantity - secondQuantity)
    }
}
