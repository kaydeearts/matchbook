import Testing
@testable import MatchingEngine

@Suite struct OrderBookTests {
    let book = OrderBook()

    @Test func limitRestsWhenNoCross() throws {
        // A limit buy with no matching ask → no trade, and it rests as the best bid.
        let (initOrder, trades) = book.submit(side: .buy, type: .limit(price: 10), quantity: 100)

        // no cross → no trade, and nothing lands on the ask side
        #expect(trades.isEmpty)
        #expect(book.getAsks().isEmpty)

        // it rests as the sole bid level, at the submitted price / quantity
        let bids = book.getBids()
        #expect(bids.count == 1)
        let level = try #require(bids.first)
        #expect(level.price == initOrder.type.limitPrice)
        #expect(level.orders.count == 1)
        let order = try #require(level.orders.first)
        #expect(order.id == initOrder.id)
        #expect(order.side == .buy)
        #expect(order.quantity == initOrder.quantity)
    }
    
    @Test func marketDoesNotRestWhenNoCross() throws {
        // A market buy with no matching ask -> no trade, but it does not rest.
        let initQuantity = 100
        let (_, trades) = book.submit(side: .buy, type: .market, quantity: initQuantity)
        
        // no cross -> no trade, and nothing lands on ask side nor on bids side.
        #expect(trades.isEmpty)
        #expect(book.getAsks().isEmpty)
        #expect(book.getBids().isEmpty)
    }
    
    @Test func fifoRespected() throws {
        // If there are multiple matching resting orders within a PriceLevel, first in will get processed
        let samePrice = 35
        let sameQuantity = 20
        let (orderOne, _) = book.submit(side: .sell, type: .limit(price: samePrice), quantity: sameQuantity)
        let (orderTwo, _) = book.submit(side: .sell, type: .limit(price: samePrice), quantity: sameQuantity)
        
        #expect(orderOne.id != orderTwo.id)
        var asks = book.getAsks()
        #expect(asks.count == 1)
        #expect(asks[0].orders.count == 2)
        #expect(asks[0].orders[0].id == orderOne.id)
        #expect(asks[0].orders[1].id == orderTwo.id)
        
        let (_, trades) = book.submit(side: .buy, type: .market, quantity: sameQuantity)
        #expect(trades.count == 1)
        #expect(trades[0].makerId == orderOne.id)
        asks = book.getAsks()
        #expect(asks.count == 1)
        #expect(asks[0].orders.count == 1)
        #expect(asks[0].orders[0].id == orderTwo.id)
        
    }
    
    @Test func limitOrderPartialProcess() throws {
        // A limit order that partially matches order on opposite book and rests the remaining toFulfill
        let (restOrder, _) = book.submit(side: .buy, type: .limit(price: 5), quantity: 7)
        let (matchOrder, trades) = book.submit(side: .sell, type: .limit(price: 4), quantity: 25)
        
        #expect(trades.count == 1)
        #expect(trades[0].quantity == restOrder.quantity)
        #expect(trades[0].price == restOrder.type.limitPrice)
        
        let asks = book.getAsks()
        #expect(asks.count == 1)
        #expect(asks[0].price == matchOrder.type.limitPrice)
        #expect(asks[0].orders[0].quantity == matchOrder.quantity - trades[0].quantity)
        
    }
    
    @Test func limitOrderSweeps() throws {
        // A limit order that matches multiple orders on opposite book
        let (firstOrder, _) = book.submit(side: .buy, type: .limit(price: 10), quantity: 50)
        let (secondOrder, _) = book.submit(side: .buy, type: .limit(price: 9), quantity: 20)
        let (matchOrder,trades) = book.submit(side: .sell, type: .limit(price: 9), quantity: 60)
        
        #expect(trades.count == 2)
        #expect(trades[0].makerId == firstOrder.id)
        #expect(trades[0].takerId == matchOrder.id)
        #expect(trades[0].quantity == firstOrder.quantity)
        #expect(trades[0].price == firstOrder.type.limitPrice)
        let toFulfill = matchOrder.quantity - firstOrder.quantity
        
        #expect(trades[1].makerId == secondOrder.id)
        #expect(trades[1].takerId == matchOrder.id)
        #expect(trades[1].quantity == toFulfill)
        #expect(trades[1].price == secondOrder.type.limitPrice)
        
        let bids = book.getBids()
        #expect(bids.count == 1)
        #expect(bids[0].price == secondOrder.type.limitPrice)
        #expect(bids[0].orders.count == 1)
        #expect(bids[0].orders[0].quantity == secondOrder.quantity - toFulfill)
    }
    
    @Test func marketOrderPartialSweep() throws {
        // A market order that matches multiple orders on opposite book but has leftover to fulfill
        let (firstOrder, _) = book.submit(side: .sell, type: .limit(price: 11), quantity: 50)
        let (secondOrder, _) = book.submit(side: .sell, type: .limit(price: 10), quantity: 20)
        let (matchOrder,trades) = book.submit(side: .buy, type: .market, quantity: 100)
        
        #expect(trades.count == 2)
        #expect(trades[0].makerId == secondOrder.id) // best price first
        #expect(trades[0].takerId == matchOrder.id)
        #expect(trades[0].quantity == secondOrder.quantity)
        #expect(trades[0].price == secondOrder.type.limitPrice)
        let toFulfill = matchOrder.quantity - secondOrder.quantity
        
        #expect(trades[1].makerId == firstOrder.id) // second-best price
        #expect(trades[1].takerId == matchOrder.id)
        #expect(trades[1].quantity == min(toFulfill, firstOrder.quantity))
        #expect(trades[1].price == firstOrder.type.limitPrice)
        
        #expect(book.getBids().count == 0) // all resting orders were processed
        #expect(book.getAsks().count == 0) // remaining toFulfill will not rest due to type market
        
    }
}
