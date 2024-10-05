//
//  StatsFeature.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 26/08/24.
//

import Charts
import SwiftUI
import ComposableArchitecture

@Reducer
struct StatsFeature {
  @ObservableState
  struct State {
    var data: IdentifiedArrayOf<AccountBalanceHistory>
  }
  
  enum Action {
    case onTask
    case dataLoaded([AccountBalanceHistory])
  }
  
  @Dependency(\.accountsRepository) var repository
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        return .run { send in
          let data = try await repository.stats()
          await send(.dataLoaded(data))
        }
        
      case let .dataLoaded(data):
        state.data = .init(uniqueElements: data)
        return .none
      }
    }
  }
}

struct StatsFeatureView: View {
  let store: StoreOf<StatsFeature>
  
  var body: some View {
    VStack {
      Chart {
        ForEach(store.data) { group in
          ForEach(group.balances.dropLast(), id: \.date) { entry in
            LineMark(
              x: .value("Date", entry.date),
              y: .value("Balance", entry.balance.value)
            )
            .interpolationMethod(.catmullRom) // Smooth curve interpolation
//            .lineStyle(StrokeStyle(lineWidth: 2.5))
//            .symbol(Circle())
            .foregroundStyle(by: .value("Group", group.key))
//            .symbolSize(50)
            
//            AreaMark(
//              x: .value("Date", entry.date),
//              y: .value("Balance", entry.balance.value)
//            )
//            .interpolationMethod(.catmullRom)
//            .foregroundStyle(
//              .linearGradient(
//                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
//                startPoint: .top,
//                endPoint: .bottom
//              )
//            )
          }
        }
      }
      .chartXAxis {
        AxisMarks(values: .automatic) { value in
          AxisGridLine()
          AxisValueLabel(format: .dateTime.year().month().day(), centered: true)
        }
      }
      .chartYAxis {
        AxisMarks { value in
          AxisGridLine()
          AxisValueLabel()
        }
      }
      .padding()
      .background(
        LinearGradient(
          gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.1)]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
//      .cornerRadius(16)
//      .shadow(radius: 10)
    }
    .task { await store.send(.onTask).finish() }
  }
}
