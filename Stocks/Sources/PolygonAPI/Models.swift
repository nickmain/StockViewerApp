// Copyright (c) 2024 Foo Bar Corporation

import Foundation

/// Namespace for the response models
public enum PolygonAPIResponse {

    public struct TickerSearch: Codable, Equatable {

        public struct Item: Codable, Equatable {
            public let active: Bool?
            public let cik: String?
            public let composite_figi: String?
            public let currency_name: String?
            public let last_updated_utc: String?
            public let locale: String?
            public let market: String?
            public let name: String
            public let primary_exchange: String?
            public let share_class_figi: String?
            public let ticker: String
            public let type: String?
            
            public init(active: Bool, cik: String?, composite_figi: String?, currency_name: String?, last_updated_utc: String?, locale: String?, market: String, name: String, primary_exchange: String, share_class_figi: String, ticker: String, type: String) {
                self.active = active
                self.cik = cik
                self.composite_figi = composite_figi
                self.currency_name = currency_name
                self.last_updated_utc = last_updated_utc
                self.locale = locale
                self.market = market
                self.name = name
                self.primary_exchange = primary_exchange
                self.share_class_figi = share_class_figi
                self.ticker = ticker
                self.type = type
            }
        }

        public let count: Int?
        public let next_url: String?
        public let request_id: String
        public let status: String
        public let results: [Item]
        
        public init(count: Int, next_url: String?, request_id: String, status: String, results: [Item]) {
            self.count = count
            self.next_url = next_url
            self.request_id = request_id
            self.status = status
            self.results = results
        }
    }
    
    public struct Aggregates: Codable, Equatable {
     
        public struct Item: Codable, Equatable {
            public let c: Double?
            public let h: Double?
            public let l: Double?
            public let n: Int?
            public let o: Double?
            public let t: Int
            public let v: Int?
            public let vw: Double?
            
            public init(c: Double?, h: Double?, l: Double?, n: Int?, o: Double?, t: Int, v: Int?, vw: Double?) {
                self.c = c
                self.h = h
                self.l = l
                self.n = n
                self.o = o
                self.t = t
                self.v = v
                self.vw = vw
            }
        }
        
        public let results: [Item]?
        
        public let adjusted: Bool?
        public let next_url: String?
        public let queryCount: Int?
        public let request_id: String?
        public let resultsCount: Int
        public let status: String?
        public let ticker: String
        
        public init(results: [Item]?, adjusted: Bool?, next_url: String?, queryCount: Int?, request_id: String?, resultsCount: Int, status: String?, ticker: String) {
            self.results = results
            self.adjusted = adjusted
            self.next_url = next_url
            self.queryCount = queryCount
            self.request_id = request_id
            self.resultsCount = resultsCount
            self.status = status
            self.ticker = ticker
        }
    }
    
    public struct PreviousClose: Codable, Equatable {
     
        public struct Item: Codable, Equatable {
            public let T: String?
            public let c: Double?
            public let h: Double?
            public let l: Double?
            public let o: Double?
            public let t: Int
            public let v: Int?
            public let vw: Double?
            
            public init(T: String?, c: Double?, h: Double?, l: Double?, o: Double?, t: Int, v: Int?, vw: Double?) {
                self.T = T
                self.c = c
                self.h = h
                self.l = l
                self.o = o
                self.t = t
                self.v = v
                self.vw = vw
            }
        }
        
        public let results: [Item]?
        
        public let adjusted: Bool?
        public let queryCount: Int?
        public let request_id: String?
        public let resultsCount: Int
        public let status: String?
        public let ticker: String
        
        public init(results: [Item]?, adjusted: Bool?, queryCount: Int?, request_id: String?, resultsCount: Int, status: String?, ticker: String) {
            self.results = results
            self.adjusted = adjusted
            self.queryCount = queryCount
            self.request_id = request_id
            self.resultsCount = resultsCount
            self.status = status
            self.ticker = ticker
        }
    }
}
