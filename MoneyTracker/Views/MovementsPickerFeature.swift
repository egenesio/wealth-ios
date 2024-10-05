
//
//  AccountPickerFeature.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 11/08/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct MovementsPickerFeature {
  @ObservableState
  struct State {
    var movementsPicker: PickerFeature<AccountMovement>.State
    @Presents var accountPicker: PickerFeature<Account>.State?
    var selectedAccount: Account?
    
    init(
      movementsPicker: PickerFeature<AccountMovement>.State = .init(),
      accountPicker: PickerFeature<Account>.State? = nil,
      selectedAccount: Account? = nil
    ) {
      self.movementsPicker = movementsPicker
      self.accountPicker = accountPicker
      self.selectedAccount = selectedAccount
    }
  }
  
  enum Action {
    case onTask
    case accountButtonTapped
    
    case loadMovements(page: Int)
    
    case accountPicker(PresentationAction<PickerFeature<Account>.Action>)
    case movementsPicker(PickerFeature<AccountMovement>.Action)
  }
  
  @Dependency(\.accountsRepository) var accountsRepository
  @Dependency(\.movementsRepository) var movementsRepository
  
  var body: some ReducerOf<Self> {
    Scope(state: \.movementsPicker, action: \.movementsPicker) {
      PickerFeature()
    }
    
    Reduce { state, action in
      switch action {
      case .onTask:
        return .send(.loadMovements(page: 1))
        
      case .accountButtonTapped:
        state.accountPicker = .init(
          showAllItem: true,
          selected: state.selectedAccount.map { [$0] } ?? []
        )
        return .none
        
      case let .loadMovements(page):
        return .run { [state] send in
          let page = if let accountId = state.selectedAccount?.id {
            try await movementsRepository.fetchMovementsByAccount(accountId, page)
          } else {
            try await movementsRepository.fetchMovements(page)
          }
          await send(.movementsPicker(.pageLoaded(page)))
        }
        
      case .accountPicker(.presented(.onTask)):
        return .run { send in
          let accounts = try await accountsRepository.fetchAccounts()
          await send(.accountPicker(.presented(.dataLoaded(accounts))))
        }
        
      case let .accountPicker(.presented(.itemSelected(account))):
        state.selectedAccount = account
        state.accountPicker = nil
        state.movementsPicker.clear()
        return .send(.loadMovements(page: 1))
        
      case .accountPicker(.presented(.allSelected)):
        state.selectedAccount = nil
        state.accountPicker = nil
        state.movementsPicker.clear()
        return .send(.loadMovements(page: 1))
        
      case .accountPicker:
        return .none
      
      case .movementsPicker(.onPageEnd):
        guard let page = state.movementsPicker.metadata?.page else {
          return .none
        }
        return .send(.loadMovements(page: page + 1))
      
      case .movementsPicker:
        return .none
      }
    }
    .ifLet(\.$accountPicker, action: \.accountPicker) {
      PickerFeature<Account>()
    }
    }
}

struct MovementsPickerView: View {
  @Bindable var store: StoreOf<MovementsPickerFeature>
  
  var body: some View {
    LazyList {
      ListSection {
        Button {
          store.send(.accountButtonTapped)
        } label: {
          Text(store.selectedAccount?.name ?? "All accounts")
            .maxWidth()
        }
      }
      
      PickerView(
        store: store.scope(
          state: \.movementsPicker,
          action: \.movementsPicker
        )
      ) { movement in
        MovementItemViewStatic(movement: movement, dateLabel: nil)
      }
    }
    .inlineTitle("History")
    .task { await store.send(.onTask).finish() }
    .sheet(
      item: $store.scope(state: \.accountPicker, action: \.accountPicker)
    ) { store in
      NavigationStack {
        AccountsPickerView(store: store)
          .inlineTitle("Accounts")
      }
    }
  }
}

struct AccountsPickerView: View {
  let store: StoreOf<PickerFeature<Account>>
  
  var body: some View {
    PickerView(
      store: store,
      selectAllLabel: {
        Text("All accounts")
          .maxWidth()
      },
      label: { account in
        VStack {
          Text(account.name)
            .maxWidth()
          
          Text(account.group.name)
            .maxWidth()
            .foregroundStyle(.secondary)
        }
      }
    )
  }
}

extension View {
  func maxWidth(alignment: Alignment = .leading) -> some View {
    frame(maxWidth: .infinity, alignment: alignment)
  }
}
