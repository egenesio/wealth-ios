//
//  AccountStats.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 22/07/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AccountStatsFeature {
  @ObservableState
  struct State {
    let accountId: Account.ID
    var stats: IdentifiedArrayOf<StatsResult> = []
  }
  
  enum Action {
    case onTask
    case dataLoaded([StatsResult])
  }
  
  @Dependency(\.accountsRepository) var repository
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        return .run { [state] send in
          let stats = try await repository.fetchAccountStats(state.accountId.uuidString)
          await send(.dataLoaded(stats))
        }
        
      case let .dataLoaded(results):
        state.stats = .init(uniqueElements: results)
        return .none
      }
    }
  }
  
}

struct AccountStatsView: View {
  let store: StoreOf<AccountStatsFeature>
  
  var body: some View {
    List {
      ForEach(store.stats, id: \.periodText) { stat in
        
        Section {
          ForEach(stat.movementsByCategories, id: \.category.id) { row in
            VStack(spacing: 0) {
              HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading) {
                  Text(row.category.name)
                  Text("\(row.count) transactions")
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                CurrencyValueText(currencyValue: row.currencyValue)
              }
            }
          }
        } header: {
          HStack(spacing: 0) {
            Text(stat.periodText)
            Spacer()
            CurrencyValueText(currencyValue: stat.balance)
          }
          .padding(.horizontal, 10)
        }
      }
    }
    .task { await store.send(.onTask).finish() }
  }
}
