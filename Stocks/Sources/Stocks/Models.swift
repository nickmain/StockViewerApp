// Copyright (c) 2024 Foo Bar Corporation

import Foundation
import Combine
import PolygonAPI

/// An observable model of a single stock ticker item.
///
/// Assumes that ticker is a unique id for stocks.
///
public class Stock: ObservableObject, Identifiable, Hashable {
    
    public typealias Ticker = String
    
    /// The stock ticker
    public let id: Ticker
    
    /// The stock name (assumes that names may change)
    @Published public var name: String
    
    /// The last known closing price
    @Published public var closingPrice: Double?
    
    /// The change between the last two closing prices
    @Published public var closingChange: Double?
    
    /// The last available aggregate
    @Published public var lastAggregate: AggregateWindow?
   
    /// The currently known aggregates
    @Published public var aggregates: [AggregateWindow] = [] {
        didSet { updatePrices() }
    }
    
    public init(ticker: Ticker, name: String) {
        self.id = ticker
        self.name = name
    }
    
    // Update prices based on the known aggregates
    private func updatePrices() {
        let aggs = Array(aggregates.sorted().reversed())
        lastAggregate = aggs.first
        closingPrice = aggs.first?.closingPrice
        
        if aggs.count > 1 {
            if let lastClosePrice = closingPrice,
               let prevClosePrice = aggs[1].closingPrice {
                closingChange = lastClosePrice - prevClosePrice
            } else {
                closingChange = nil
            }
        } else {
            closingChange = nil
        }
    }
    
    public static func == (lhs: Stock, rhs: Stock) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Stock {
    
    public struct AggregateWindow: Comparable, Identifiable {
        
        public var id: String { startDay }
        
        public let startDay: String  // YYYY-MM-DD
        public let openingPrice: Double?
        public let closingPrice: Double?
        public let highPrice: Double?
        public let lowPrice: Double?
        public let volume: Int?
        public let averagePrice: Double?
        public let transactionCount: Int?

        /// Comparable based on start day
        public static func < (lhs: Stock.AggregateWindow, rhs: Stock.AggregateWindow) -> Bool {
            lhs.startDay < rhs.startDay
        }
    }
}

extension Stock.AggregateWindow {
    static func from(_ polyModel: PolygonAPIResponse.Aggregates.Item) -> Self {
        .init(startDay: polyModel.t.dayString,
              openingPrice: polyModel.o,
              closingPrice: polyModel.c,
              highPrice: polyModel.h,
              lowPrice: polyModel.l,
              volume: polyModel.v,
              averagePrice: polyModel.vw,
              transactionCount: polyModel.n)
    }
}

extension Int {
    // Convert unix timestamp to YYYY-MMM-DD string
    var dayString: String {
        let time = Double(self)/1000
        let day = Date(timeIntervalSince1970: time)
        return PolygonAPI.dayDateFormatter.string(from: day)
    }
}
