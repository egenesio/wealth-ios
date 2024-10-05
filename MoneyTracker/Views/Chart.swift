////
////  Chart.swift
////  MoneyTracker
////
////  Created by Emilio Genesio on 17/08/24.
////
//
//import SwiftUI
//import Charts
//
//// Struct for Meta Data
//struct MetaData: Codable {
//  let information: String
//  let symbol: String
//  let lastRefreshed: String
//  let outputSize: String
//  let timeZone: String
//  
//  enum CodingKeys: String, CodingKey {
//    case information = "1. Information"
//    case symbol = "2. Symbol"
//    case lastRefreshed = "3. Last Refreshed"
//    case outputSize = "4. Output Size"
//    case timeZone = "5. Time Zone"
//  }
//}
//
//// Struct for Daily Data
//struct DailyData: Codable {
//  let open: String
//  let high: String
//  let low: String
//  let close: String
//  let volume: String
//  
//  enum CodingKeys: String, CodingKey {
//    case open = "1. open"
//    case high = "2. high"
//    case low = "3. low"
//    case close = "4. close"
//    case volume = "5. volume"
//  }
//}
//
//// Struct for the main JSON response
//struct StockResponse: Codable {
//  let metaData: MetaData
//  let timeSeriesDaily: [String: DailyData]
//  
//  enum CodingKeys: String, CodingKey {
//    case metaData = "Meta Data"
//    case timeSeriesDaily = "Time Series (Daily)"
//  }
//}
//
//struct ChartData {
//  let dates: Array<[Date: DailyData].Element>
//  
//  init(timeSeriesDaily: [String: DailyData]) {
//    var dateDict = [Date: DailyData]()
//    
//    let formatter = DateFormatter()
//    formatter.dateFormat = "yyyy-MM-dd"
//    
//    for (dateString, dailyData) in timeSeriesDaily {
//      if let date = formatter.date(from: dateString) {
//        dateDict[date] = dailyData
//      } else {
//        print("Failed to parse date: \(dateString)")
//      }
//    }
//    self.dates = dateDict.sorted(by: { $0.key > $1.key })
//  }
//}
//
//func readData() -> StockResponse {
//  func loadStockHistory(from filename: String) -> StockResponse? {
//    guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
//      print("Failed to locate \(filename) in bundle.")
//      return nil
//    }
//    
//    do {
//      let data = try Data(contentsOf: url)
//      let stockHistory = try JSONDecoder().decode(StockResponse.self, from: data)
//      print("===", stockHistory.timeSeriesDaily.count)
//      return stockHistory
//    } catch {
//      print("Failed to decode \(filename) from bundle: \(error.localizedDescription)")
//      return nil
//    }
//  }
//  
//  // Usage
//  guard let stockHistory = loadStockHistory(from: "history_vt")
//  else {
//    fatalError("")
//  }
//  
//  return stockHistory
//}
//
//struct StockHistoryChartView: View {
//  let chartData: ChartData
//  @State private var selectedDate: Date? = nil
//  @State private var selectedValue: Double? = nil
//  
//  var body: some View {
//    VStack {
//      Chart {
//        ForEach(chartData.dates, id: \.0) { date, dailyData in
//          LineMark(
//            x: .value("Date", date),
//            y: .value("Close Price", Double(dailyData.close) ?? 0.0)
//          )
//          .interpolationMethod(.catmullRom)
//          .lineStyle(StrokeStyle(lineWidth: 2))
//          .foregroundStyle(.blue)
//          
//          AreaMark(
//            x: .value("Date", date),
//            y: .value("Close Price", Double(dailyData.close) ?? 0.0)
//          )
//          .foregroundStyle(.linearGradient(colors: [.blue.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
//        }
//        
//        if let selectedDate = selectedDate, let selectedValue = selectedValue {
//          RuleMark(x: .value("Selected Date", selectedDate))
//            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
//            .foregroundStyle(.red)
//          
//          PointMark(
//            x: .value("Selected Date", selectedDate),
//            y: .value("Selected Value", selectedValue)
//          )
//          .symbolSize(100)
//          .foregroundStyle(.red)
//        }
//      }
//      .chartXAxis {
//        AxisMarks(values: .stride(by: .week)) { value in
//          AxisGridLine()
//          AxisValueLabel(format: .dateTime.month(.abbreviated))
//        }
//      }
//      .chartYAxis {
//        AxisMarks { value in
//          AxisGridLine()
//          AxisValueLabel()
//        }
//      }
////      .chartOverlay { proxy in
////        GeometryReader { geo in
////          Rectangle().fill(Color.clear).contentShape(Rectangle())
////            .gesture(
////              DragGesture()
////                .onChanged { value in
////                  let location = value.location
////                  if let date: Date = proxy.value(atX: location.x),
////                     let (dataDate, dataValue) = nearestDataPoint(to: date, in: chartData.dates) {
////                    selectedDate = dataDate
////                    selectedValue = dataValue
////                  }
////                }
////                .onEnded { _ in
////                  // Keep the selected date and value after drag ends
////                }
////            )
////        }
////      }
//      .padding()
//      
//      if let selectedDate = selectedDate, let selectedValue = selectedValue {
//        VStack(alignment: .leading) {
//          Text("Selected Date: \(formattedDate(selectedDate))")
//            .font(.headline)
//          Text("Close Price: \(String(format: "%.2f", selectedValue))")
//            .font(.subheadline)
//        }
//        .padding()
//        .background(Color.white.opacity(0.8))
//        .cornerRadius(8)
//        .shadow(radius: 5)
//        .padding(.top)
//      }
//    }
//    .navigationTitle(chartData.dates.first?.1.symbol ?? "Stock Data")
//    .padding()
//  }
//  
//  func nearestDataPoint(to date: Date, in series: [(Date, DailyData)]) -> (Date, Double)? {
//    if let nearestDate = series.map({ $0.0 }).min(by: { abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date)) }),
//       let closeValue = Double(series.first(where: { $0.0 == nearestDate })?.1.close ?? "") {
//      return (nearestDate, closeValue)
//    }
//    return nil
//  }
//  
//  func formattedDate(_ date: Date) -> String {
//    let formatter = DateFormatter()
//    formatter.dateStyle = .medium
//    return formatter.string(from: date)
//  }
//}
//
//#Preview {
//  StockHistoryChartView(chartData: .init(timeSeriesDaily: readData().timeSeriesDaily))
//}
//
