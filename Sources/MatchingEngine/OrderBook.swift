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
