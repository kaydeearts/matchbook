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
    
    func processOrder(newOrder: Order) {
        var bestPriceLevel: PriceLevel?
        let isBuy = newOrder.side == .buy
        var toFulfill = newOrder.quantity
        
        while toFulfill != 0 {
            switch newOrder.type {
            case .market:
                bestPriceLevel = matchPriceLevel(forSide: newOrder.side, nil)
            case .limit(let price):
                bestPriceLevel = matchPriceLevel(forSide: newOrder.side, price)
                if bestPriceLevel == nil {
                    switch newOrder.side {
                    case .buy:  insertLimitOrder(price, newOrder, into: &bids)
                    case .sell: insertLimitOrder(price, newOrder, into: &asks)
                    }
                }
            }
            
            if let bestPriceLevel, let firstOrder = bestPriceLevel.orders.first {
                let fulfilled = processTrade(newOrder, firstOrder, bestPriceLevel.price, quantity: toFulfill)
                toFulfill = toFulfill - fulfilled
            }
        }
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

    
    func processTrade(_ newOrder: Order, _ firstOrder: Order, _ price: Int, quantity: Int) -> Int {
        // first determine how much is fulfillable in this order, then pass into quantity
//        let trade = Trade(takerId: newOrder.id, makerId: firstOrder.id, price: price, quantity: quantity)
        
    }
    
    func matchPriceLevel(forSide: Side, _ requestedPrice: Int?) -> PriceLevel? {
        let best: PriceLevel?
        switch forSide {
        case .buy: best = asks.first // buy orders are given lowest asks
        case .sell: best = bids.last  // sell orders are given highest buys
        }
        
        guard let best else { return nil }
        guard let requestedPrice else { return best } // check if there's price to compare to (aka limit order)
        let crosses = (forSide == .buy) ? best.price <= requestedPrice
                                     : best.price >= requestedPrice
        return crosses ? best : nil
    }

}
