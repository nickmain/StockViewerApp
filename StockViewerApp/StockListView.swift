// Copyright (c) 2024 Foo Bar Corporation

import SwiftUI
import Stocks

struct StockListView: View {
    @EnvironmentObject private var stockService: StockService
    @State private var showAddStocks = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Add Stock") {
                    stockService.searchText = ""
                    showAddStocks = true
                }
                .padding(.horizontal)
            }
            
            List {
                ForEach(stockService.currentStocks) { stock in
                    StockNameAndTickerView(stock: stock)
                }
                .onDelete {
                    if let firstIndex = $0.first {
                        stockService.removeCurrentStock(at: firstIndex)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddStocks) {
            AddStocksView(showAddStocks: $showAddStocks)
        }
    }
}

struct AddStocksView: View {
    @EnvironmentObject private var stockService: StockService
    @Binding var showAddStocks: Bool
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Close") {
                    showAddStocks = false
                }
                .padding(.horizontal)
                .padding(.top)
            }
            
            NavigationStack {
                List {
                    if stockService.searchResults.isEmpty && !stockService.searchText.isEmpty {
                        VStack {
                            Spacer()
                            Text("No Results")
                            Spacer()
                        }
                    } else {
                        ForEach(stockService.searchResults) { stock in
                            StockNameAndTickerView(stock: stock)
                                .onTapGesture {
                                    stockService.addCurrentStock(stock)
                                }
                        }
                    }
                }
                .navigationTitle("Find Stocks")
                .searchable(text: $stockService.searchText)
            }
             
            Spacer()
            
            Text(rateLimitMessage)
                .font(.caption)
                .foregroundStyle(.red)
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


struct StockNameAndTickerView: View {
    @ObservedObject var stock: Stock
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.id).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                Text(stock.name).font(.caption)
            }
        }
        .padding(.horizontal)
    }
}
