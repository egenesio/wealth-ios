//
//  AccountGroupPickerFeature.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 10/08/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AccountGroupPickerFeature {
  @ObservableState
  struct State {
    var isLoading = false
    var picker: PickerFeature<AccountGroup>.State
    
    init(
      isLoading: Bool = false,
      groups: IdentifiedArrayOf<AccountGroup>,
      selected: AccountGroup? = nil
    ) {
      self.isLoading = isLoading
      
      self.picker = .init(
        items: groups,
        selected: selected.map { [$0] } ?? []
      )
    }
  }
  
  enum Action {
    case onTask
    case dataLoaded([AccountGroup])
    case picker(PickerFeature<AccountGroup>.Action)
  }
  
  @Dependency(\.accountGroupsRepository) var repository
  
  var body: some ReducerOf<Self> {
    Scope(state: \.picker, action: \.picker) {
      PickerFeature()
    }
    
    Reduce { state, action in
      switch action {
      case .onTask:
        state.isLoading = true
        return .run { send in
          let groups = try await repository.fetchGroups()
          await send(.dataLoaded(groups))
        }
        
      case let .dataLoaded(groups):
        state.picker = .init(
          items: .init(uniqueElements: groups.ordered()),
          selected: state.picker.selected
        )
        state.isLoading = false
        return .none
        
      case .picker:
        return .none
      }
    }
  }
}

struct AccountGroupPickerView: View {
  let store: StoreOf<AccountGroupPickerFeature>
  
  var body: some View {
    PickerView(
      store: store.scope(state: \.picker, action: \.picker)
    ) { group in
      Text(group.name)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .task { await store.send(.onTask).finish() }
  }
}
