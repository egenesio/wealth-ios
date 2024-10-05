//
//  Root.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 18/08/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct RootFeature {
  @ObservableState
  struct State {
    var accounts: AccountsFeature.State
    var settings: SettingsFeature.State
    var stats: StatsFeature.State
  }
  
  enum Action {
    case accounts(AccountsFeature.Action)
    case settings(SettingsFeature.Action)
    case stats(StatsFeature.Action)
  }
  
  var body: some ReducerOf<Self> {
    Scope(state: \.accounts, action: \.accounts) {
      AccountsFeature()
    }
    
    Scope(state: \.stats, action: \.stats) {
      StatsFeature()
    }
    
    Scope(state: \.settings, action: \.settings) {
      SettingsFeature()
    }
    
    Reduce { state, action in
      return .none
    }
  }
}

struct StatsView: View {
  var body: some View {
    Text("Stats")
  }
}

struct RootView: View {
  let store: StoreOf<RootFeature>
  
  var body: some View {
    TabView {
      AccountsView(
        store: store.scope(state: \.accounts, action: \.accounts)
      )
      .tabItem { Label("Accounts", systemImage: "list.bullet.rectangle.fill") }
      
      StatsFeatureView(
        store: store.scope(state: \.stats, action: \.stats)
      )
      .tabItem { Label("Stats", systemImage: "chart.pie.fill") }
      
//      SettingsView(
//        store: store.scope(state: \.settings, action: \.settings)
//      )
//      .tabItem { Label("Settings", systemImage: "gear.circle.fill") }
    }
  }
}
