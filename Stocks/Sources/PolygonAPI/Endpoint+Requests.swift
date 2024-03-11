// Copyright (c) 2024 Foo Bar Corporation

import Foundation
import Combine

extension PolygonAPI: PolygonAPIRequests {
        
    public func getAggregates(for ticker: String, dayCount: Int) throws -> AnyPublisher<PolygonAPIResponse.Aggregates, Error> {
        
        let today = Date()
        let end = Self.dayDateFormatter.string(from: today)
        
        // no aggs will be returned for today unless the market is closed so don't include it
        // in the day count calculation
        guard let then = Calendar.current.date(byAdding: .day, value: -dayCount, to: today) else {
            throw Error.other("Could not get date for \(dayCount) days ago")
        }
        let start = Self.dayDateFormatter.string(from: then)
        
        return try getRequest(path: "/v2/aggs/ticker/\(ticker)/range/1/day/\(start)/\(end)",
                              params: [
                                  "adjusted": "true",
                                  "sort": "asc",
                                  "limit": "\(dayCount+1)"
                              ],
                              returning: PolygonAPIResponse.Aggregates.self)
    }

    public func getPreviousDay(for ticker: String) throws -> AnyPublisher<PolygonAPIResponse.PreviousClose, Error> {
        try getRequest(path: "/v2/aggs/ticker/\(ticker)/prev",
                       params: [
                           "adjusted": "true"
                       ],
                       returning: PolygonAPIResponse.PreviousClose.self)
    }
    

    public func searchStocks(for query: String) throws -> AnyPublisher<PolygonAPIResponse.TickerSearch, PolygonAPI.Error> {
        try getRequest(path: "/v3/reference/tickers",
                       params: [
                           "market": "stocks",
                           "active": "true",
                           "search": query
                       ],
                       returning: PolygonAPIResponse.TickerSearch.self)
    }
}
