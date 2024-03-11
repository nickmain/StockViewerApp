// Copyright (c) 2024 Foo Bar Corporation

import Foundation
import Combine
import PolygonAPI
import OSLog

/// A stock information service.
///
/// This is currently only uses the Polygon.io API
///
@MainActor
public class StockService: ObservableObject {

    private static let persistenceKey = "StockService_stocks"
    private static let userDefaults = UserDefaults.standard
    
    private let polygonAPI: PolygonAPIRequests
    private let rateLimiter: RateLimiter
    private var rateLimiterSub: AnyCancellable? = nil
    
    private var subscriptions = Set<AnyCancellable>()
    
    // All locally known stock items
    internal var stocks: [Stock.Ticker: Stock] = [:]
    
    public static let logger = Logger(subsystem: "Stocks", category: "StockService")
    
    /// The current set of stocks that of interest.
    ///
    /// This list is persisted and reloaded when a StockService instance is created.
    /// Only the ticker and stock name are saved.
    /// Persistence currently uses UserDefaults for storage.
    ///
    @Published public private(set) var currentStocks: [Stock] = []
            
    /// If not nil, the time left in seconds until the current rate limit expires
    @Published public private(set) var limitTimeLeft: TimeInterval? = nil
    
    /// Search text
    @Published public var searchText: String = "" {
        didSet { search() }
    }
    private var currentSearchTerm = ""
    private var searchTimestamp: Int = 0
    
    /// Search results based on the searchText
    @Published public private(set) var searchResults: [Stock] = []
    
    ///
    /// - Parameters:
    ///   - polygonAPI: the Polygon API implementation to use
    ///   - rateLimiter: the rate limiter for the API
    ///
    public init(polygonAPI: PolygonAPIRequests, rateLimiter: RateLimiter) {
        self.polygonAPI = polygonAPI
        self.rateLimiter = rateLimiter
        
        if let defaultStocks = readCurrentStocks() {
            self.currentStocks = defaultStocks
            Self.logger.debug("Read \(defaultStocks.count) stocks from UserDefaults")
        }
        else {
            self.currentStocks = [
                .init(ticker: "AAPL", name: "Tim Cook and friends"),
                .init(ticker: "Z", name: "Zillow"),
                .init(ticker: "A", name: "Agilent Technologies Inc")
            ]
            saveCurrentStocks()
        }
        
        for stock in currentStocks {
            self.stocks[stock.id] = stock
        }
        
        rateLimiterSub = rateLimiter.$limitTimeLeft.sink(receiveValue: { time in
            self.limitTimeLeft = time
        })
    }
    
    /// Perform a stock search, based on the current ``searchText`` and putting results in ``searchResults``
    public func search() {
        // SwiftUI seems to be setting searchText multiple times with the same value
        guard searchText != currentSearchTerm else { return }
        currentSearchTerm = searchText
        
        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if searchTerm.isEmpty {
            searchResults = []
            return
        }
        
        rateLimiter.enqueue { [weak self] in
            guard let self else { return }
            do {
                var sub: AnyCancellable? = nil
                
                Self.logger.debug("Searching for term \(searchTerm)")
                sub = try self.polygonAPI.searchStocks(for: searchTerm)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished: break
                            case .failure(let error): print(error)
                            }
                            if let sub {
                                self.subscriptions.remove(sub)
                            }
                        },
                        receiveValue: { result in
                            Self.logger.debug("Search received \(result.count ?? 0) results")
                            self.searchResults = result.results.map { Stock(ticker: $0.ticker, name: $0.name) }
                        }
                    )

                if let sub {
                    self.subscriptions.insert(sub)
                }
                
            } catch {
                Self.logger.debug("Searching for term \(searchTerm): \(error)")
            }
        }
    }
    
    /// Remove the current stock at the given index
    public func removeCurrentStock(at index: Int) {
        currentStocks.remove(at: index)
        saveCurrentStocks()
    }
    
    /// Fetch the aggregates for the current stocks
    public func fetchCurrentAggregates() {
        for stock in currentStocks {
            stock.aggregates = []
            fetchAggregates(for: stock)
        }
    }
    
    /// Fetch the aggregate for a single stock (hardcoded to 5 days)
    public func fetchAggregates(for stock: Stock) {
        rateLimiter.enqueue { [weak self] in
            guard let self else { return }
            do {
                var sub: AnyCancellable? = nil
                
                Self.logger.debug("Fetching aggregates for ticker \(stock.id)")
                sub = try self.polygonAPI.getAggregates(for: stock.id, dayCount: 5)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished: break
                            case .failure(let error): print(error)
                            }
                            if let sub {
                                self.subscriptions.remove(sub)
                            }
                        },
                        receiveValue: { result in
                            Self.logger.debug("Received \(result.resultsCount) aggregates for ticker \(stock.id)")
                            if let aggs = result.results?.map({ Stock.AggregateWindow.from($0) }) {
                                stock.aggregates = aggs
                            }
                        }
                    )

                if let sub {
                    self.subscriptions.insert(sub)
                }
                
            } catch {
                Self.logger.debug("Fetching aggs for \(stock.id): \(error)")
            }
        }
    }
    
    // Add a stock to the current and known stocks and persist, iff the stock does not exist
    public func addCurrentStock(_ stock: Stock) {
        guard !currentStocks.contains(where: { $0.id == stock.id }) else { return }
        
        stocks[stock.id] = stock
        currentStocks.append(stock)
        saveCurrentStocks()
        
        searchResults.removeAll(where: { $0 == stock })
        fetchAggregates(for: stock)
    }
    
    private func saveCurrentStocks() {
        let stockList = currentStocks.map { "\($0.id)|\($0.name)" }
        Self.userDefaults.setValue(stockList, forKey: Self.persistenceKey)
        Self.logger.debug("Saved \(stockList.count) stocks to UserDefaults")
    }
    
    private func readCurrentStocks() -> [Stock]? {
        guard let stockList = Self.userDefaults.array(forKey: Self.persistenceKey) else { return nil }
        
        return stockList.compactMap {
            guard let element = $0 as? String else { return nil }
            let pair = element.split(separator: "|")
            guard pair.count == 2 else { return nil }
            return Stock(ticker: String(pair[0]), name: String(pair[1]))
        }
    }
}
