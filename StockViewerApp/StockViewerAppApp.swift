// Copyright (c) 2024 David N Main

import SwiftUI
import Stocks
import PolygonAPI

@main
struct StockViewerAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(StockService(polygonAPI: PolygonAPI.init(configuration: .production),
                                                rateLimiter: .init(config: .production)))
        }
    }
}
