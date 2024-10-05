//
//  AdjustBalanceForm.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 04/08/24.
//

import SwiftUI
import ComposableArchitecture

extension String {
  var emptyAsNil: String? {
    if self == "" {
      nil
    } else {
      self
    }
  }
}

@Reducer
struct AdjustBalanceFormFeature {
  @ObservableState
  struct State {
    let account: Account
    
    var isLoading = false
    
    var date: Date
    var description: String
    var note: String
    var balance: Decimal
  }
  
  enum Action: BindableAction {
    case saveTapped
    case balanceSaved
    
    case binding(BindingAction<State>)
  }
  
  @Dependency(\.accountsRepository) var accountsRepository
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .saveTapped:
        state.isLoading = true
        return .run { [state] send in
          _ = try await accountsRepository.adjustBalance(
            state.account.id,
            state.date,
            state.description.emptyAsNil,
            state.note.emptyAsNil,
            state.balance
          )
          
          await send(.balanceSaved)
        }
      
      case .balanceSaved:
        state.isLoading = false
        return .none
        
      case .binding(_):
        return .none
      }
    }
  }
}

struct AdjustBalanceForm: View {
  @Bindable var store: StoreOf<AdjustBalanceFormFeature>
  
  var body: some View {
    List {
      Section {
        DatePicker(
          "Date",
          selection: $store.date,
          displayedComponents: .date
        )
        
        TextField(
          "Description",
          text: $store.description
        )
        
        TextField(
          "Note",
          text: $store.note
        )
        
        TextField(
          "Balance",
          value: $store.balance,
          format: .currency(code: store.account.currency.rawValue)
        )
      } header: {
        HStack {
          Text(store.account.name)
          Spacer()
          CurrencyValueText(currencyValue: store.account.balance)
        }
      }
      
      Section {
        if store.isLoading {
          ProgressView()
        } else {
          Button {
            store.send(.saveTapped)
          } label: {
            Text("Save")
          }
        }
      }
    }
    .inlineTitle("Adjust Balance")
  }
}

#Preview {
  Text("")
    .sheet(
      isPresented: .constant(true)
    ) {
      NavigationStack {
        AdjustBalanceForm(
          store: Store(
            initialState: AdjustBalanceFormFeature.State(
              account: Account(
                id: .init(),
                group: .init(
                  id: .init(),
                  name: "Group",
                  description: nil,
                  order: 1
                ),
                currency: .chf,
                symbol: nil,
                name: "Test Account",
                description: nil,
                balance: .init(value: 100, currency: .chf)
              ),
              date: .now,
              description: "",
              note: "",
              balance: 0
            )
          ) {
            AdjustBalanceFormFeature()
          }
        )
      }
      .presentationDetents([.medium])
    }
}
