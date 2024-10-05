//
//  ContentView.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 04/02/24.
//

import SwiftUI
import Charts
import ComposableArchitecture

@Reducer
struct AccountsFeature {
  @ObservableState
  struct State {
    var accounts: [AccountGroup: [Account]]
    @Presents var settings: SettingsFeature.State?
    @Presents var accountForm: AccountFormFeature.State?
    
    var path: StackState<Path.State> = .init()
    
    var sortedGroups: [AccountGroup] {
      accounts.keys.ordered()
    }
  }
  
  enum Action {
    case onTask
    case accountsLoaded([Account])
    case addAccountTapped
    case accountForm(PresentationAction<AccountFormFeature.Action>)
    
    // settings
    case settingsTapped
    case settings(PresentationAction<SettingsFeature.Action>)
    case closeSettingsTapped
    
    case path(StackActionOf<Path>)
  }
  
  @Reducer
  enum Path {
    case details(AccountDetailsFeature)
    case movements(AccountMovementsFeature)
    case stats(AccountStatsFeature)
    case movementDetails(MovementDetailFeature)
    case movementsPicker(MovementsPickerFeature)
  }
  
  @Dependency(\.accountsRepository) var accountsRepository
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        return .run { send in
          let accounts = try await accountsRepository.fetchAccounts()
          
          await send(.accountsLoaded(accounts))
        }
        
      case let .accountsLoaded(accounts):
        state.accounts = Dictionary(grouping: accounts, by: \.group)
        return .none
        
      case .addAccountTapped:
        state.accountForm = .init()
        return .none
        
      case .accountForm(.presented(.finished)):
        state.accountForm = nil
        return .send(.onTask)
        
      case .accountForm:
        return .none
        
      case .settingsTapped:
        state.settings = .init(path: .init())
        return .none
        
      case .settings, .path:
        return .none
        
      case .closeSettingsTapped:
        state.settings = nil
        return .none
      }
    }
    .ifLet(\.$settings, action: \.settings) {
      SettingsFeature()
    }
    .ifLet(\.$accountForm, action: \.accountForm) {
      AccountFormFeature()
    }
    .forEach(\.path, action: \.path)
  }
}

struct AccountsView: View {
  @Bindable var store: StoreOf<AccountsFeature>
  
  var body: some View {
    NavigationStack(
      path: $store.scope(
        state: \.path,
        action: \.path
      )
    ) {
      AccountsListView(store: store)
    } destination: { store in
      switch store.case {
      case let .details(store):
        AccountDetailView2(store: store)
        
      case let .movements(store):
        AccountsMovementsScreenView(store: store)
          .navigationTitle("History")
        
      case let .stats(store):
        AccountStatsView(store: store)
        
      case let .movementDetails(store):
        MovementDetailView(store: store)
        
      case let .movementsPicker(store):
        MovementsPickerView(store: store)
      }
    }
  }
  
//  func stateFrom(_ account: Account) -> AccountsFeature.Path.State {
//    AccountsFeature.Path.State.details(
//      AccountDetailsFeature.State(
//        accountId: account.id,
//        movementsState: .init(
//          account: account,
//          limit: 3
//        )
//      )
//    )
//  }
  
  struct AccountsListView: View {
    @Bindable var store: StoreOf<AccountsFeature>
    
    var body: some View {
      List {
        Section {
          Button {
            store.send(.addAccountTapped)
          } label: {
            Text("Add account")
          }
        }
        
        Section {
          NavigationLink(
            state: AccountsFeature.Path.State.movementsPicker(.init())
          ) {
            Text("Movements picker")
          }
        }
        
        ForEach(store.sortedGroups) { group in
          if let accounts = store.accounts[group] {
            Section {
              ForEach(accounts, id: \.id) { account in
                NavigationLink(
                  state: AccountsFeature.Path.State.details(
                    AccountDetailsFeature.State(
                      account: account,
                      movements: .init(
                        account: account,
                        limit: 3
                      )
                    )
                  )
                ) {
                  AccountItemView(account: account)
                }
              }
            } header: {
              Text("\(group.name)")
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
        }
      }
      .navigationTitle("Accounts")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            store.send(.settingsTapped)
          } label: {
            Image(systemName: "gear")
          }
        }
      }
      .task {
        await store.send(.onTask).finish()
      }
      .sheet(
        item: $store.scope(state: \.settings, action: \.settings)
      ) { store in
        NavigationStack {
          SettingsView(store: store)
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button {
                  self.store.send(.closeSettingsTapped)
                } label: {
                  Image(systemName: "xmark")
                }
              }
            }
        }
      }
      .sheet(item: $store.scope(state: \.accountForm, action: \.accountForm)) { store in
        AccountFormView(store: store)
      }
    }
  }
  
  struct AccountItemView: View {
    let account: Account
    
    var body: some View {
      HStack(spacing: 0) {
        Text(account.flag)
        
        Text(account.name)
          .padding(.leading)
        
        Spacer()
        
        CurrencyValueText(currencyValue: account.balance)
      }
    }
  }
}

#Preview {
  NavigationStack {
    AccountsView(
      store: Store(
        initialState: AccountsFeature.State(
          accounts: [:]//,
//          settings: .init(path: .init())
        )
      ) {
        AccountsFeature()
          ._printChanges()
      }
    )
  }
}


//struct OldAccountsView: View {
//  @StateObject var viewModel: AccountsViewModel
//  
//  var body: some View {
//    NavigationStack {
//      List {
//        ForEach(AccountType.allCases, id: \.self) { accountType in
//          if let accounts = viewModel.accounts[accountType] {
//            Section {
//              ForEach(accounts, id: \.id) { account in
//                NavigationLink {
//                  AccountDetailView(viewModel: .init(accountId: account.id))
//                } label: {
//                  AccountItemView(account: account)
//                }
//              }
//            } header: {
//              Text("\(accountType.rawValue)")
//                .frame(maxWidth: .infinity, alignment: .leading)
//            }
//          }
//        }
//      }
//      .navigationTitle("Accounts")
//      .toolbar {
//        ToolbarItem(placement: .topBarTrailing) {
//          Button {
//            viewModel.showSettings = true
//          } label: {
//            Image(systemName: "gear")
//          }
//        }
//      }
//      .sheet(isPresented: $viewModel.showSettings) {
//        CategoriesView(viewModel: .init())
//      }
//      .task {
//        await viewModel.refresh()
//      }
//    }
//  }
//  
//  struct AccountItemView: View {
//    let account: Account
//    
//    var body: some View {
//      HStack(spacing: 0) {
//        Text(account.flag)
//        
//        Text(account.name)
//          .padding(.leading)
//        
//        Spacer()
//        
//        CurrencyValueText(currencyValue: account.balance)
//      }
//    }
//  }
//}
