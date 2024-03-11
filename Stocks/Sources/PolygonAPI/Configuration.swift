// Copyright (c) 2024 Foo Bar Corporation

import Foundation

/// Configuration parameters for the Polygon API
public struct PolygonConfiguration {

    /// The base URL for the API endpoint
    public let baseURL: String

    /// The API key
    public let apiKey: String

    /// Number of times to retry
    public let retryCount: Int

    /// The timeout for requests
    public let timeout: TimeInterval?

    /// Rate limit
    public let rateLimitCallCount: Int
    public let rateLimitPeriodSecs: TimeInterval
    
    /// The production endpoint
    public static let production = PolygonConfiguration(
        baseURL: "https://api.polygon.io/",
        apiKey: "vu_gTzbpgsdEgCPrjYGJsQWbs1seO7x7", // hardcoded for now - rethink how this is set up
        retryCount: 1,
        timeout: 30, // seconds
        rateLimitCallCount: 5,
        rateLimitPeriodSecs: 60
    )
}
