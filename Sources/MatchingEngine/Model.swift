//
//  Model.swift
//  matchbook
//
//  Created by Kamilé Demir on 9/13/26.
//

import Collections

public enum Side: String {
    case buy, sell
}

public enum OrderType {
    case limit(price: Int)
    case market
    
    var limitPrice: Int? {
        if case .limit(let price) = self { return price }
        return nil
    }
}

public struct Order {
    let id: Int
    let side: Side
    let type: OrderType
    let quantity: Int
}

public struct Trade {
    let takerId: Int
    let makerId: Int
    let price: Int
    let quantity: Int
}

public struct PriceLevel {
    let price: Int
    var orders: Deque<Order>
}
