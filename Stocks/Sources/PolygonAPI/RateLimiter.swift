// Copyright (c) 2024 Foo Bar Corporation

import Foundation
import Combine

/// Request rate limiter that attempts to model the Polygon limiter to avoid
/// retrying too soon or too often when the limit is reached.
///
/// This implementation assumes that failed requests still count towards the limit,
/// which is probably not correct
///
@MainActor
public class RateLimiter: ObservableObject {
    
    // Seconds to subtract from limit window to account for the fact that
    // we are modeling request timestamps based on send time not server-receive/processing
    // time.
    private static let fuzzFactor = -2.0
    
    /// Requests are closures
    public typealias APIRequest = () -> Void
    
    /// If not nil, the time left in seconds until the current rate limit expires
    @Published public private(set) var limitTimeLeft: TimeInterval? = nil
    
    private let rateLimitCallCount: Int
    private let rateLimitPeriodSecs: TimeInterval
    
    private var requestQueue: [APIRequest] = [] // requests yet to be dispatched
    
    // The last rateLimitCallCount requests that count towards the limit.
    // Newest at the end.
    private var previousRequestTimes: [TimeInterval] = []
    
    // The countdown timer
    private var timer: Timer?
    
    /// Do not limit requests
    public init() {
        rateLimitCallCount = 0
        rateLimitPeriodSecs = 0
    }
    
    /// Use the given endpoint configuration
    public init(config: PolygonConfiguration) {
        rateLimitCallCount = config.rateLimitCallCount
        rateLimitPeriodSecs = config.rateLimitPeriodSecs + Self.fuzzFactor
    }
    
    /// Enqueue a request and dispatch as many waiting requests as possible
    public func enqueue(request: @escaping APIRequest) {
        requestQueue.append(request)
        dispatchFromQueue()
    }
    
    /// Dispatch the next request(s) on the queue until limiting is predicted
    private func dispatchFromQueue() {
        while timer == nil, !requestQueue.isEmpty {
            if let timeUntilLimitExpires = timeUntilLimitExpires() {
                // our model predicts that requests have been limited with the given time remaining
                // Start a timer to check for limit expiry
                startTimer()
                
            } else {
                // model predicts no current limit - send a request
                let request = requestQueue.removeFirst()
                dispatch(request: request)
            }
        }
    }
    
    // Invoke a request closure and add a timestamp
    private func dispatch(request: APIRequest) {
        addRequestTimestamp()
        request()
    }
    
    // Start the timer for the limit countdown
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            let this = self // avoid Swift 6 warning
            DispatchQueue.main.async {
                this?.timerTick()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Called every second when there is a rate limit countdown
    private func timerTick() {
        if let timeLeft = timeUntilLimitExpires(), timeLeft > 0, !requestQueue.isEmpty {
            self.limitTimeLeft = timeLeft
        } else {
            stopTimer()
            self.limitTimeLeft = nil
            
            // start request dispatching again
            dispatchFromQueue()
        }
    }
    
    // Add a request timestamp to the record
    private func addRequestTimestamp() {
        previousRequestTimes.append(Date().timeIntervalSince1970)
    }
    
    /// The time between now the oldest previous request and now, nil if limit is not active
    private func timeUntilLimitExpires() -> TimeInterval? {
        guard rateLimitPeriodSecs > 0 else { return nil }
        
        let now = Date().timeIntervalSince1970
        cullPreviousRequests(now: now)
        if previousRequestTimes.count < rateLimitCallCount {
            return nil
        }
        
        return if let oldest = previousRequestTimes.first {
            rateLimitPeriodSecs - (now - oldest)
        } else {
            nil
        }
    }
    
    // Remove previous requests that are older than the rateLimitPeriodSecs
    private func cullPreviousRequests(now: TimeInterval) {
        let periodStart = now - rateLimitPeriodSecs
        previousRequestTimes.removeAll(where: { $0 < periodStart })
    }
}
