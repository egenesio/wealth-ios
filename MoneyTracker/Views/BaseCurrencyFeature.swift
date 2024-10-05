//
//  BaseCurrencyFeature.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 03/08/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct BaseCurrencyFeature {
  @ObservableState
  struct State {
    enum LoadingState: Equatable {
      case idle
      case data
      case selection(CurrencyData.ID)
    }
    
    var loading: LoadingState = .idle
    var currencies: IdentifiedArrayOf<CurrencyData> = []
  }
  
  enum Action {
    case onTask
    case currenciesLoaded(IdentifiedArrayOf<CurrencyData>)
    
    case currencySelected(Currency)
  }
  
  @Dependency(\.currenciesRepository) var currenciesRepository
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        state.loading = .data
        return .run { send in
          let currencies = try await currenciesRepository.fetchCurrencies()
          await send(.currenciesLoaded(.init(uniqueElements: currencies)))
        }
      
      case let .currenciesLoaded(currencies):
        state.loading = .idle
        state.currencies = currencies
        return .none
        
      case let .currencySelected(currency):
        state.loading = .selection(currency.rawValue)
        return .run { send in
          let currencies = try await currenciesRepository.selectBaseCurrency(currency)
          await send(.currenciesLoaded(.init(uniqueElements: currencies)))
        }
      }
    }
  }
}

struct BaseCurrencyView: View {
  let store: StoreOf<BaseCurrencyFeature>
  
  var body: some View {
    if store.loading == .data {
      ProgressView()
    }
    
    List {
      if !store.currencies.isEmpty {
        Section {
          ForEach(store.currencies) { currency in
            Button {
              store.send(.currencySelected(currency.currency))
            } label: {
              HStack(spacing: .zero) {
                Text(currency.currency.rawValue)
                
                Spacer()
                
                if case let .selection(id) = store.loading, id == currency.id {
                  ProgressView()
                    .transition(.scale.animation(.spring))
                  
                } else if currency.isSelected {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.primary)
                    .transition(.opacity.combined(with: .scale).animation(.spring))
                }
              }
            }
            .disabled(store.loading != .idle)
          }
        } footer: {
          Text("Select currency to be used as base when doing calculations between different accounts.")
        }
      }
    }
    .inlineTitle("Base currency")
    .task {
      await store.send(.onTask).finish()
    }
  }
}
