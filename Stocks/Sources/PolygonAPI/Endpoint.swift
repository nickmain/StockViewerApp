// Copyright (c) 2024 Foo Bar Corporation

import Foundation
import Combine
import OSLog

/// The Polygon API endpoint common methods and configuration
public struct PolygonAPI {

    public static let logger = Logger(subsystem: "Stocks", category: "PolygonAPI")
    
    private static let rateLimitedHTTPCode = 429

    /// The errors that can arise when making API requests
    public enum Error: Swift.Error {
        /// Error when decoding a response
        case decoding(_ message: String, Swift.Error)

        /// Low level network error
        case network(Swift.Error)

        /// A bad HTTP response
        case response(_ httpCode: Int, _ message: String?)

        /// The request timed out
        case timeout

        /// The API rate limit was exceeded
        case rateLimited
        
        /// Something else happened
        case other(String)
    }

    private let configuration: PolygonConfiguration
    private let urlSession: URLSession
    private let baseURL: URL?

    public static let dayDateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Create an API endpoint for the given configuration
    public init(configuration: PolygonConfiguration, urlSession: URLSession = URLSession.shared) {
        self.configuration = configuration
        self.urlSession = urlSession
        
        guard let baseURL = URL(string: configuration.baseURL) else {
            Self.logger.error("Bad API endpoint: \(configuration.baseURL)")
            self.baseURL = nil
            return
        }

        self.baseURL = baseURL
    }

    // Create a publisher for the given API path and expected return type and perform a GET request
    internal func getRequest<ResultType: Decodable>(path: String, params: [String: String] = [:] , returning parsedType: ResultType.Type) throws -> AnyPublisher<ResultType, PolygonAPI.Error> {

        guard let baseURL = self.baseURL,
              var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        else {
            throw PolygonAPI.Error.other("Bad API endpoint: \(configuration.baseURL)")
        }

        urlComponents.path = path

        if !params.isEmpty {
            var queryParameters = urlComponents.queryItems ?? [URLQueryItem]()
            queryParameters.append(contentsOf: params.map { .init(name: $0.key, value: $0.value) })
            urlComponents.queryItems = queryParameters
        }

        guard let finalURL = urlComponents.url else {
            throw PolygonAPI.Error.other("Could not construct URL for path: \(path)")
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        if let timeout = configuration.timeout {
            urlRequest.timeoutInterval = timeout
        }

        Self.logger.debug("Sending request to \(finalURL.absoluteString)")
        return urlSession.dataTaskPublisher(for: urlRequest)
            .retry(configuration.retryCount)
            .tryMap { (data: Data, response: URLResponse) -> ResultType in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw Error.other("Response was not HTTPURLResponse for \(finalURL.absoluteString)")
                }

                if httpResponse.statusCode == Self.rateLimitedHTTPCode {
                    throw Error.rateLimited
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw Error.response(httpResponse.statusCode, "Unexpected code for \(finalURL.absoluteString)")
                }

                do {
                    return try JSONDecoder().decode(parsedType, from: data)
                } catch {
                    throw Error.decoding("Decoding \(finalURL.absoluteString) as \(ResultType.self)", error)
                }
            }
            .mapError(Self.apiError(for:))
            .eraseToAnyPublisher()
    }

    // Make a PolygonAPI error
    private static func apiError(for error : Swift.Error) -> PolygonAPI.Error {
        switch error {
        case let apiError as PolygonAPI.Error:
            apiError

        case let urlError as URLError:
            switch urlError.code {
            case URLError.Code.timedOut: .timeout
            default: .response(urlError.code.rawValue, urlError.localizedDescription)
            }

        default: .network(error)
        }
    }
}
