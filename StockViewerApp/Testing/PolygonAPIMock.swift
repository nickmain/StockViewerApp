// Copyright (c) 2024 Foo Bar Corporation

import Foundation
import PolygonAPI
import Combine

struct PolygonAPIMock: PolygonAPIRequests {
    
    func getAggregates(for ticker: String, dayCount: Int) throws -> AnyPublisher<PolygonAPIResponse.Aggregates, PolygonAPI.Error> {
        
        let secsInDay = 86400
        let day1 = Int(Date().timeIntervalSince1970)
        let day2 = day1 - secsInDay
        
        let aggs: PolygonAPIResponse.Aggregates =
            .init(results: [
                    .init(c: 100.01, h: nil, l: nil, n: nil, o: nil, t: day1, v: nil, vw: nil),
                    .init(c: 105.32, h: nil, l: nil, n: nil, o: nil, t: day2, v: nil, vw: nil)
                  ],
                  adjusted: true, next_url: nil, queryCount: 1, request_id: "asdasdsa", resultsCount: 2, status: "OK", ticker: ticker)
        
        return CurrentValueSubject(aggs).eraseToAnyPublisher()
    }
    
    func getPreviousDay(for ticker: String) throws ->
    AnyPublisher<PolygonAPIResponse.PreviousClose, PolygonAPI.Error> {
        let prevClose: PolygonAPIResponse.PreviousClose = switch ticker {
        case "AAPL": PolygonAPIResponse.PreviousClose(results: [.init(T: ticker, c: 123.45, h: 124.33, l: 100.21, o: 99.87, t: 0, v: 0, vw: 0)], adjusted: true, queryCount: 1, request_id: "sdlkhfsdkfhsd", resultsCount: 1, status: "OK", ticker: ticker)
            case "Z": PolygonAPIResponse.PreviousClose(results: [.init(T: ticker, c: 123.45, h: 124.33, l: 100.21, o: 99.87, t: 0, v: 0, vw: 0)], adjusted: true, queryCount: 1, request_id: "sdlkhfsdkfhsd", resultsCount: 1, status: "OK", ticker: ticker)
            default: PolygonAPIResponse.PreviousClose(results: [.init(T: ticker, c: 123.45, h: 124.33, l: 100.21, o: 99.87, t: 0, v: 0, vw: 0)], adjusted: true, queryCount: 1, request_id: "sdlkhfsdkfhsd", resultsCount: 1, status: "OK", ticker: ticker)
            }
        
        return CurrentValueSubject(prevClose).eraseToAnyPublisher()
    }
    
    func searchStocks(for query: String) throws -> AnyPublisher<PolygonAPIResponse.TickerSearch, PolygonAPI.Error> {
        
        return CurrentValueSubject<PolygonAPIResponse.TickerSearch?, PolygonAPI.Error>(nil)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
