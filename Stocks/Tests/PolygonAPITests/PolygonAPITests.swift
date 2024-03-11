// Copyright (c) 2024 David N Main

import XCTest
import Combine
import PolygonAPI

final class PolygonAPITests: XCTestCase {

    var cancellable: AnyCancellable?

    // Sanity test - get Apple aggregates
    func testAggregatesSanity() throws {
        let results = try PolygonAPI.init(configuration: .production).getAggregates(for: "AAPL", dayCount: 5)
        
        let expectation = XCTestExpectation()

        cancellable = results
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error)
                    }
                    expectation.fulfill()
                },
                receiveValue: { result in
                    print(result)
                    expectation.fulfill()
                }
            )

        wait(for: [expectation], timeout: 10)
    }
    
    // Sanity test - get Apple last close price
    func testPreviousCloseSanity() throws {
        let results = try PolygonAPI.init(configuration: .production).getPreviousDay(for: "AAPL")
        
        let expectation = XCTestExpectation()

        cancellable = results
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error)
                    }
                    expectation.fulfill()
                },
                receiveValue: { result in
                    print(result.results?.first as Any)
                    expectation.fulfill()
                }
            )

        wait(for: [expectation], timeout: 10)
    }
    
    // Sanity test - finding the AAPL ticker by name
    func testSearchSanity() throws {
        let results = try PolygonAPI.init(configuration: .production).searchStocks(for: "apple")

        let expectation = XCTestExpectation()
        var foundAAPL = false

        cancellable = results
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error)
                    }
                    expectation.fulfill()
                },
                receiveValue: { result in
                    for item in result.results {
                        if item.ticker == "AAPL" {
                            print("Found \(item)")
                            foundAAPL = true
                            break
                        }
                    }
                    expectation.fulfill()
                }
            )

        wait(for: [expectation], timeout: 10)
        if !foundAAPL {
            XCTFail("Did not find AAPL ticker")
        }
    }
}
