//
//  OrderBook.swift
//  matchbook
//
//  Created by Kamilé Demir on 9/20/26.
//

// The order book receives and serves buy and sell orders, which can be limit or market.
// - must quickly find the best ask (lowest sell price), and the best bid (highest buy price)
// - must serve orders FIFO within a price level
// - must allow deletion & cancellation operations
//
// The chosen simplified data structure here is an array with (price, [Order]) tuples.
//
// TODO: try a balanced-BST backend behind the OrderBook protocol & benchmark vs. this sorted array (learning + possible perf win at scale).
// The ideal data structure here would be a balanced binary search tree. Balanced so that search remains optimal at O(logN) regardless of insertion
// order, and BST so that either finding an exact price match or going up/down the tree to find the closest.
// In C++, I would use an std::map, but no such data structure exists in Swift built-in.


class OrderBook {
    var asks: [PriceLevel] = []
    var bids: [PriceLevel] = []
    
    func processOrder(newOrder: Order) -> [Trade]{
        var trades: [Trade] = []
        var bestPriceLevel: PriceLevel?
        var toFulfill = newOrder.quantity
        
        while toFulfill != 0 {
            switch newOrder.type {
            case .market:
                bestPriceLevel = matchPriceLevel(forSide: newOrder.side, nil)
            case .limit(let price):
                bestPriceLevel = matchPriceLevel(forSide: newOrder.side, price)
            }
            
            if let bestPriceLevel, let firstOrder = bestPriceLevel.orders.first {
                let trade = processTrade(newOrder, firstOrder, bestPriceLevel.price, quantity: min(toFulfill, firstOrder.quantity))
                trades.append(trade)
                toFulfill = toFulfill - trade.quantity
            } else {
                break
            }
        }
        
        if toFulfill > 0 {
            switch newOrder.type {
            case .limit(let price):
                var leftoverOrder = newOrder
                leftoverOrder.quantity = toFulfill
                switch newOrder.side {
                case .buy:  insertLimitOrder(price, leftoverOrder, into: &bids)
                case .sell: insertLimitOrder(price, leftoverOrder, into: &asks)
                }
            case .market:
                break
            }
        }
        return trades
    }
    
    func insertLimitOrder(_ orderPrice: Int, _ order: Order, into levels: inout [PriceLevel]) {
        // find first index where orderPrice is less than or equal to it
        if let idx = levels.firstIndex(where: { $0.price >= orderPrice }) {
            if levels[idx].price == orderPrice {
                // price level exists, so place order within it
                levels[idx].orders.append(order)
            } else {
                
                // orderPrice < levels[idx].price, so insert before it
                levels.insert(PriceLevel(price: orderPrice, orders: [order]), at: idx)
            }
        } else {
            // idx is nil, thus orderPrice is highest price. Insert at end of array
            levels.append(PriceLevel(price: orderPrice, orders: [order]))
        }
    }

    func consumeFront(of levels: inout [PriceLevel], at levelIdx: Int, by amount: Int) {
        levels[levelIdx].orders[0].quantity -= amount
        if levels[levelIdx].orders[0].quantity <= 0 { levels[levelIdx].orders.removeFirst()}
        if levels[levelIdx].orders.count == 0 { levels.remove(at: levelIdx) }
    }
    
    func processTrade(_ newOrder: Order, _ firstOrder: Order, _ price: Int, quantity: Int) -> Trade {
        let trade = Trade(takerId: newOrder.id, makerId: firstOrder.id, price: price, quantity: quantity)
        // remove the firstOrder from the proper array
        switch newOrder.side {
        case .buy: consumeFront(of:&asks, at:0, by:quantity)
        case .sell: consumeFront(of:&bids, at:bids.count - 1, by:quantity)
        }
        
        return trade
    }
    
    func matchPriceLevel(forSide: Side, _ requestedPrice: Int?) -> PriceLevel? {
        let best: PriceLevel?
        switch forSide {
        case .buy: best = asks.first // buy orders are given lowest asks
        case .sell: best = bids.last  // sell orders are given highest buys
        }
        
        guard let best else { return nil }              // no opposite book
        guard let requestedPrice else { return best }   // market order
        let crosses = (forSide == .buy) ? best.price <= requestedPrice
                                        : best.price >= requestedPrice
        return crosses ? best : nil                     // limit: only if it crosses
    }

}
