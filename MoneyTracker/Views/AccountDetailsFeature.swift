//
//  AccountDetails.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 17/07/24.
//

import SwiftUI
import Charts
import ComposableArchitecture

enum LoadingState: Equatable {
  case idle
  case loading
  case error(String)
}

@Reducer
struct AccountDetailsFeature {
  @ObservableState
  struct State {
    let account: Account
    var movements: AccountMovementsFeature.State
    
    @Presents var destination: Destination.State?
    
    init(
      account: Account,
      movements: AccountMovementsFeature.State
    ) {
      self.account = account
      self.movements = movements
    }
  }
  
  @Reducer
  enum Destination {
    case adjustBalance(AdjustBalanceFormFeature)
    case importMovements(ImportMovements)
  }
  
  enum Action: BindableAction {
    case onTask
    case adjustBalanceTapped
    case importMovementsTapped
    
    case movements(AccountMovementsFeature.Action)
    case destination(PresentationAction<Destination.Action>)

    case binding(BindingAction<State>)
  }
  
  @Dependency(\.accountsRepository) var repository
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    
    Scope(state: \.movements, action: \.movements) {
      AccountMovementsFeature()
    }
    
    Reduce { state, action in
      switch action {
      case .onTask:Label("Menu", systemImage: "list.dash")
        return .none
        
      case .binding:
        return .none
        
      case .movements:
        return .none
        
      case .destination(.presented(.adjustBalance(.balanceSaved))):
        state.destination = nil
        return .send(.movements(.loadData))
        
      case .destination:
        return .none
        
      case .adjustBalanceTapped:
        state.destination = .adjustBalance(
          AdjustBalanceFormFeature.State(
            account: state.account,
            date: Date.now,
            description: "",
            note: "",
            balance: state.account.balance.value
          )
        )
        return .none
        
      case .importMovementsTapped:
        state.destination = .importMovements(
          ImportMovements.State(
            account: state.account
          )
        )
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

private struct HistoryTabView: View {
  @Bindable var store: StoreOf<AccountDetailsFeature>
  
  var body: some View {
    SimpleList {
      ListSection {
        Button {
          store.send(.adjustBalanceTapped)
        } label: {
          ActionRow(text: "Adjust balance")
        }
        
        Button {
          store.send(.importMovementsTapped)
        } label: {
          ActionRow(text: "Import movements")
        }
        
        Divider()
        
//        NavigationLink(
//          state: AccountsFeature.Path.State.stats(
//            AccountStatsFeature.State(
//              accountId: store.account.id
//            )
//          )
//        ) {
//          ActionRow(text: "Statistics")
//        }
        
        Divider()
        
        NavigationLink(
          state: AccountsFeature.Path.State.movements(
            AccountMovementsFeature.State(
              account: store.account
            )
          )
        ) {
          ActionRow(text: "Movements")
        }
      } header: {
        HStack {
          Label("Quick actions", systemImage: "wand.and.rays")
          
          Spacer()
        }
        .padding(.bottom, 10)
      }
      
      AccountsMovementsWidgetView(
        store: store.scope(
          state: \.movements,
          action: \.movements
        )
      )
    }
  }
}

private struct ActionRow: View {
  let text: String
  
  var body: some View {
    HStack {
      Text(text)
        .foregroundStyle(.primary)
      
      Spacer()
      
      Image(systemName: "chevron.forward")
        .foregroundStyle(.secondary)
        .padding(.trailing, 10)
    }
    .padding(.vertical, 10)
  }
}

//private struct StatsTabView: View {
//  let store: StoreOf<AccountDetailsFeature>
//  
//  private var chartBackground: Gradient {
//    return Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.0)])
//  }
//  
//  var body: some View {
//    ScrollView {
//      VStack {
//        ForEach(store.stats, id: \.periodText) { stat in
//          
//          VStack(spacing: 10) {
//            HStack(spacing: 0) {
//              Text(stat.periodText)
//              Spacer()
//              CurrencyValueText(currencyValue: stat.balance)
//            }
//            .padding(.horizontal, 10)
//            
//            ForEach(stat.movementsByCategories, id: \.category.id) { row in
//              VStack(spacing: 0) {
//                HStack(alignment: .top, spacing: 0) {
//                  VStack(alignment: .leading) {
//                    Text(row.category.name)
//                    Text("\(row.count) transactions")
//                      .foregroundStyle(.secondary)
//                  }
//                  
//                  Spacer()
//                  CurrencyValueText(currencyValue: row.currencyValue)
//                }
//              }
//              .padding(.horizontal, 20)
//            }
//          }
//          .padding(.top, 20)
//        }
//      }
//    }
//  }
//}

//private struct MovementsDailyView: View {
//  private let movements: [AccountMovement]
//  
//  init(
//    movements: [AccountMovement],
//    showCategoriesAction: @escaping (AccountMovement) -> Void
//  ) {
//    self.movements = movements.sorted(by: { $0.balance.value > $1.balance.value })
//    self.showCategoriesAction = showCategoriesAction
//  }
//  
//  var body: some View {
//    VStack(spacing: 10) {
//      ForEach(movements, id: \.id) { movement in
//        MovementItemView(
//          movement: movement
//        )
//      }
//    }
//    .padding(10)
//  }
//}

//private struct MovementItemView: View {
//  let movement: AccountMovement
//  let showCategoriesAction: (AccountMovement) -> Void
//  
//  var body: some View {
//    HStack(alignment: .center, spacing: 10) {
//      Button {
//        showCategoriesAction(movement)
//      } label: {
//        movement.category.map { CategoryIcon($0) }
//        ?? CategoryIcon.noCategory()
//      }
//      
//      Text(movement.description)
//        .lineLimit(2)
//      
//      Spacer()
//      
//      VStack(alignment: .trailing) {
//        CurrencyValueText(currencyValue: movement.amount)
//          .fontWeight(.medium)
//      }
//    }
//    .frame(height: 64)
//  }
//}

struct AccountDetailView2: View {
  @Bindable var store: StoreOf<AccountDetailsFeature>
  
  var body: some View {
    HistoryTabView(store: store)
    
//    TabView {
//      HistoryTabView(store: store)
//        .tabItem { Label("History", systemImage: "chart.line.uptrend.xyaxis") }
//
//      StatsTabView(store: store)
//        .tabItem { Label("Stats", systemImage: "chart.pie.fill") }
//    }
    .inlineTitle(store.account.name)
    .task {
      await store.send(.onTask).finish()
    }
    .sheet(
      item: $store.scope(
        state: \.destination?.adjustBalance,
        action: \.destination.adjustBalance
      )
    ) { store in
      NavigationStack {
        AdjustBalanceForm(store: store)
      }
      .presentationDetents([.medium])
    }
    .navigationDestination(
      item: $store.scope(
        state: \.destination?.importMovements,
        action: \.destination.importMovements
      )
    ) { store in
//      NavigationStack {
      ImportMovementsView(store: store)
        .navigationTitle("Import")
//      }
//      .presentationDetents([.medium])
    }
//    .sheet(
//      item: $store.scope(state: \.adjustBalance, action: \.adjustBalance)
//    ) { store in
//    }
  }
}
