//
//  AccountGroupsFeature.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 10/08/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AccountGroupsFeature {
  @ObservableState
  struct State {
    var isLoading = false
    var groups: IdentifiedArrayOf<AccountGroup>
  }
  
  enum Action {
    case onTask
    
    case dataLoaded([AccountGroup])
  }
  
  @Dependency(\.accountGroupsRepository) var repository
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        state.isLoading = true
        return .run { send in
          let groups = try await repository.fetchGroups()
          await send(.dataLoaded(groups))
        }
        
      case let .dataLoaded(groups):
        state.groups = .init(uniqueElements: groups.ordered())
        state.isLoading = false
        return .none
      }
    }
  }
}

struct AccountGroupsView: View {
  let store: StoreOf<AccountGroupsFeature>
  
  var body: some View {
    LazyList {
      ListSection {
        ForEach(store.groups) { group in
          NavigationLink(
            state: SettingsFeature.Path.State.accountGroupForm(.init(group: group))
          ) {
            Text(group.name)
          }
        }
      }
      
      ListSection {
        NavigationLink(
          state: SettingsFeature.Path.State.accountGroupForm(.init())
        ) {
          Text("Create new group")
        }
      }
    }
    .task { await store.send(.onTask).finish()}
    .navigationTitle("Account Groups")
  }
}
