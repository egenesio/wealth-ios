//
//  AccountFormFeature.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 10/08/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AccountFormFeature {
  @ObservableState
  struct State {
    enum LoadingState {
      case idle
      case saving
      case deleting
    }
    
    var loadingState: LoadingState = .idle
    var group: AccountGroup?
    var currency: Currency = .chf
    
    var symbol = ""
    var name = ""
    var description = ""
    
    var saveButtonEnabled: Bool {
      group != nil && !name.isEmpty
    }
    
    var path: StackState<Path.State> = .init()
  }
  
  enum Action: BindableAction {
    case path(StackActionOf<Path>)
    case binding(BindingAction<State>)
    
    case saveTapped
    case finished
  }
  
  @Reducer
  enum Path {
    case groupPicker(AccountGroupPickerFeature)
    case currencyPicker(PickerFeature<Currency>)
  }
  
  @Dependency(\.accountsRepository) var repository
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce {
      state,
      action in
      switch action {
      case let .path(.element(id: id, action: .groupPicker(.picker(.itemSelected(group))))):
        state.group = group
        state.path.pop(from: id)
        return .none
        
      case let .path(.element(id: id, action: .currencyPicker(.itemSelected(currency)))):
        state.currency = currency
        state.path.pop(from: id)
        return .none
        
      case .path:
        return .none
        
      case .binding(_):
        return .none
        
      case .saveTapped:
        state.loadingState = .saving
        return .run { [state] send in
          do {
            guard let groupId = state.group?.id else {
              return
            }
            
            let saved = try await repository.createAccount(
              .init(
                groupId: groupId,
                currency: state.currency,
                symbol: state.symbol.emptyAsNil,
                name: state.name,
                description: state.description.emptyAsNil
              )
            )
            
            await send(.finished)
          } catch {
            await send(.finished)
          }
        }
        
      case .finished:
        state.loadingState = .idle
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

struct AccountFormView: View {
  @Bindable var store: StoreOf<AccountFormFeature>
  
  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      SimpleList {
        ListSection {
          NavigationLink(
            state: AccountFormFeature.Path.State.groupPicker(
              .init(
                groups: [],
                selected: store.group
              )
            )
          ) {
            HStack {
              if let group = store.group {
                Text(group.name)
              } else {
                Text("Group")
              }
              Spacer()
            }
          }
        }
        
        ListSection {
          NavigationLink(
            state: AccountFormFeature.Path.State.currencyPicker(
              .init(
                items: .init(uniqueElements: Currency.allCases),
                selected: [store.currency]
              )
            )
          ) {
            HStack {
              Text(store.currency.rawValue)
              Spacer()
            }
          }
          
          TextField(
            "Symbol",
            text: $store.symbol
          )
        }
        
        ListSection {
          TextField(
            "Name",
            text: $store.name
          )
          
          TextField(
            "Description",
            text: $store.description
          )
        }
        
        ListSection {
          if store.loadingState == .saving {
            ProgressView()
          } else {
            Button {
              store.send(.saveTapped)
            } label: {
              Text("Save")
            }
          }
        }
        .disabled(!store.saveButtonEnabled)
      }
      .navigationTitle("Create account")
      .toolbarTitleDisplayMode(.inline)
      
    } destination: { store in
      switch store.case {
      case let .groupPicker(store):
        AccountGroupPickerView(store: store)
          .navigationTitle("Group")
        
      case let .currencyPicker(store):
        PickerView(store: store) { currency in
          Text(currency.rawValue)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Currency")
      }
    }
  }
}
