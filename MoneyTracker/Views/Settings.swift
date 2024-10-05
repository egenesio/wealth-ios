//
//  Settings.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 16/07/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct SettingsFeature {
  @ObservableState
  struct State {
    var path: StackState<Path.State>
  }
  
  enum Action {
    case path(StackActionOf<Path>)
  }
  
  @Reducer
  enum Path {
    case accountGroups(AccountGroupsFeature)
    case accountGroupForm(AccountGroupFormFeature)
    
    case categories(CategoriesFeature)
    case categoryDetails(CategoryForm)
    case baseCurrency(BaseCurrencyFeature)
  }
  
  enum Settings: String, CaseIterable {
    case accountGroups = "Account Groups"
    case categories = "Categories"
    case baseCurrency = "Base currency"
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {

      case let .path(.element(id: id, action: .accountGroupForm(.finished))):
        state.path.pop(from: id)
        return .none
        
      default:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>
  
  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      List {
        NavigationLink(
          state: SettingsFeature.Path.State.accountGroups(.init(groups: []))
        ) {
          Text("Account Groups")
        }
        
        NavigationLink(
          state: SettingsFeature.Path.State.categories(.init(categories: []))
        ) {
          Text("Categories")
        }
        
        NavigationLink(
          state: SettingsFeature.Path.State.baseCurrency(.init())
        ) {
          Text("Base Currency")
        }
      }
      .navigationTitle("Settings")
      .toolbarTitleDisplayMode(.inline)
      
    } destination: { store in
      switch store.case {
      case let .accountGroups(store):
        AccountGroupsView(store: store)
          .toolbarTitleDisplayMode(.inline)
        
      case let .accountGroupForm(store):
        AccountGroupForm(store: store)
          .toolbarTitleDisplayMode(.inline)
        
      case let .categories(store):
        CategoriesView(store: store)
          .toolbarTitleDisplayMode(.inline)
        
      case let .categoryDetails(store):
        CategoryFormView(store: store)
          .toolbarTitleDisplayMode(.inline)
        
      case let .baseCurrency(store):
        BaseCurrencyView(store: store)
          .toolbarTitleDisplayMode(.inline)
      }
    }
  }
}
