//
//  MoneyTrackerApp.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 04/02/24.
//

import SwiftUI
import ComposableArchitecture

@main
struct MoneyTrackerApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationStack {
//        AccountsView(
//          store: Store(initialState: AccountsFeature.State(accounts: [:])) {
//            AccountsFeature()
//          }
//        )
        RootView(
          store: Store(
            initialState: RootFeature.State(
              accounts: .init(accounts: [:]),
              settings: .init(path: .init()),
              stats: .init(data: [])
            )
          ) {
            RootFeature()
          }
        )
      }
    }
  }
}
