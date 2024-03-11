// Copyright (c) 2024 Foo Bar Corporation

import Foundation
import Combine

/// The requests that can be made of the Polygon API
public protocol PolygonAPIRequests {

    /// Search for active stock tickers with a symbol or company name containing the query.
    ///
    /// Return up to 100 results.
    func searchStocks(for query: String) throws -> AnyPublisher<PolygonAPIResponse.TickerSearch, PolygonAPI.Error>

    /// Get the aggregates for a ticker, for the previous dayCount days.
    /// The result count may be less due to weekends and non-trading days.
    /// See [https://polygon.io/docs/stocks/get_v2_aggs_ticker__stocksticker__prev](Polygon Docs)
    func getAggregates(for ticker: String, dayCount: Int) throws -> AnyPublisher<PolygonAPIResponse.Aggregates, PolygonAPI.Error>
    
    /// Get the previous day's open, high, low, and close for the specified stock ticker.
    ///
    /// See [https://polygon.io/docs/stocks/get_v2_aggs_ticker__stocksticker__range__multiplier___timespan___from___to](Polygon Docs)
    func getPreviousDay(for ticker: String) throws -> AnyPublisher<PolygonAPIResponse.PreviousClose, PolygonAPI.Error>
    
}
