// Copyright (c) 2024 David N Main

import SwiftUI
import Charts
import Stocks
import Combine

struct ContentView: View {
    @EnvironmentObject private var stockService: StockService
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(value: "StockList") {
                    HStack {
                        Spacer()
                        Text("List of Stocks")
                    }
                    .padding(.horizontal)
                }
                
                List {
                    ForEach(stockService.currentStocks) { stock in
                        NavigationLink(value: stock) {
                            StockOverviewView(stock: stock)
                        }
                    }
                }
                .refreshable {
                    stockService.fetchCurrentAggregates()
                }
                            
                Text(rateLimitMessage)
                    .font(.caption)
                    .foregroundStyle(.red)

            }
            .navigationDestination(for: Stock.self) {
                StockDetailView(stock: $0)
            }
            .navigationDestination(for: String.self) { _ in
                StockListView()
            }
        }
        .onAppear {
            stockService.fetchCurrentAggregates()
        }
    }
    
    private var rateLimitMessage: String {
        if let time = stockService.limitTimeLeft {
            "Rate limited for \(Int(time)) secs"
        } else {
            ""
        }
    }
}

struct StockDetailView: View {
    @ObservedObject var stock: Stock
    
    var body: some View {
        VStack {
            Text(stock.name)
            Divider()
            Spacer()
            Text("Closing Prices")
            Chart {
                ForEach(stock.aggregates) { item in
                    LineMark(
                        x: .value("Month", item.startDay),
                        y: .value("Temp", item.closingPrice ?? 0.0)
                    )
                }
            }
            .frame(height: 300)
            Spacer()
        }
    }
}

struct StockOverviewView: View {
    @ObservedObject var stock: Stock
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.id).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                Text(stock.name).font(.caption)
            }
            Spacer()
            VStack(alignment: .leading) {
                Spacer()
                HStack {
                    Text("Closing:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatPrice(stock.closingPrice))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                Spacer()
                HStack {
                    Text("Change:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatPrice(stock.closingChange))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                Spacer()
            }
        }
        .padding()
    }
    
    private func formatPrice(_ value: Double?) -> String {
        guard let value else { return "---" }
        if value >= 0 {
            return String(format: "$%.2f", value)
        } else {
            return String(format: "-$%.2f", abs(value))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(StockService(polygonAPI: PolygonAPIMock(), rateLimiter: .init()))
}
