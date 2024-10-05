////
////  AccountDetails.swift
////  MoneyTracker
////
////  Created by Emilio Genesio on 17/07/24.
////
//
//import SwiftUI
//import Charts
//import ComposableArchitecture
//
//enum LoadingState: Equatable {
//  case idle
//  case loading
//  case error(String)
//}
//
//@Reducer
//struct AccountDetailsFeature {
//  @ObservableState
//  struct State {
//    @ObservableState
//    struct Movements {
//      var all: Set<AccountMovement> = []
//      var grouped: [Date: [AccountMovement]] = [:]
//      var page: Int = 0
//      var loadingState: LoadingState = .idle
//    }
//    
//    @ObservableState
//    struct History: Equatable {
//      var queryData: HistoryQueryData? = nil
//      var period: HistoryPeriod = .year
//      
//      var isWeekSelected: Bool {
//        get { period == .week }
//        set {
//          if newValue {
//            period = .week
//          }
//        }
//      }
//      var isMonthSelected: Bool {
//        get { period == .month }
//        set {
//          if newValue {
//            period = .month
//          }
//        }
//      }
//      var isYearSelected: Bool {
//        get { period == .year }
//        set {
//          if newValue {
//            period = .year
//          }
//        }
//      }
//    }
//    
//    var account: Account? = nil
//    var stats: [StatsResult] = []
//    var movements: Movements = .init()
//    var history: History = .init()
//    
//    let accountId: Account.ID
//    
//    var movementsState: AccountMovementsFeature.State
//    
//    @Presents var adjustBalance: AdjustBalanceFormFeature.State? = nil
//  }
//  
//  enum Action: BindableAction {
//    case onTask
//    case loadDetails
//    
//    case detailsLoaded(AccountDetails, [StatsResult])
//    case movementsLoaded([AccountMovement])
//    case listScrollEnded
//    
//    case binding(BindingAction<State>)
//    
//    case movements(AccountMovementsFeature.Action)
//    case adjustBalance(PresentationAction<AdjustBalanceFormFeature.Action>)
//    
//    case adjustBalanceTapped
//  }
//  
//  @Dependency(\.accountsRepository) var repository
//  
//  var body: some ReducerOf<Self> {
//    BindingReducer()
//    
//    Scope(state: \.movementsState, action: \.movements) {
//      AccountMovementsFeature()
//    }
//    
//    Reduce {
//      state,
//      action in
//      switch action {
//      case .onTask:
//        return .send(.loadDetails)
//        
//      case .loadDetails:
//        return .run { [state] send in
//          let accountDetails = try await repository.fetchAccountDetails(
//            state.accountId,
//            state.history.period,
//            state.movements.page
//          )
//          let stats = try await repository.fetchAccountStats(state.accountId)
//          await send(.detailsLoaded(accountDetails, stats))
//        }
//        
//      case let .detailsLoaded(accountDetails, stats):
//        state.account = accountDetails.account
//        state.history.queryData = accountDetails.history
//        state.movements.page = accountDetails.movements.metadata.page
//        state.stats = stats
//        
//        return .send(.movementsLoaded(accountDetails.movements.items))
//        
//      case let .movementsLoaded(movements):
//        for movement in movements {
//          state.movements.all.update(with: movement)
//        }
//        
//        state.movements.grouped = Dictionary(grouping: state.movements.all) { movement in
//          Calendar.current.startOfDay(for: movement.date)
//        }
//        return .none
//        
//      case .listScrollEnded:
//        state.movements.page += 1
//        return .send(.loadDetails)
//        
//      case .binding(\.history):
//        return .send(.loadDetails)
//        
//      case .binding:
//        return .none
//        
//      case .movements:
//        return .none
//        
//      case .adjustBalance(\.balanceSaved):
//        state.adjustBalance = nil
//        return .send(.movements(.loadData))
//        
//      case .adjustBalance:
//        return .none
//        
//      case .adjustBalanceTapped:
//        state.adjustBalance = .init(
//          account: state.account!,
//          date: .now,
//          description: "",
//          note: "",
//          balance: state.account!.balance.value
//        )
//        return .none
//      }
//    }
//    .ifLet(\.$adjustBalance, action: \.adjustBalance) {
//      AdjustBalanceFormFeature()
//    }
//  }
//}
//
//private struct HistoryTabView: View {
//  @Bindable var store: StoreOf<AccountDetailsFeature>
//  
//  var body: some View {
//    SimpleList {
//      if let history = store.history.queryData {
//        
//        // TODO: do not remove
//        
//        //            VStack {
//        //              CurrencyValueText(currencyValue: history.balance)
//        //              switch history.growth.type {
//        //              case .percentage:
//        //                Text("\(history.growth.value)%")
//        //              case .amount:
//        //                Text("+") // TODO: Text(history.balance, format: .currency(code: account.currency.rawValue))
//        //              }
//        //            }
//        //
//        //            HistoryView(history: history)
//        //
//        //            HStack(spacing: 20) {
//        //              Toggle(isOn: $store.history.isWeekSelected) {
//        //                Text("Week")
//        //              }
//        //              .toggleStyle(.button)
//        //              Toggle(isOn: $store.history.isMonthSelected) {
//        //                Text("Month")
//        //              }
//        //              .toggleStyle(.button)
//        //
//        //              Toggle(isOn: $store.history.isYearSelected) {
//        //                Text("Year")
//        //              }
//        //              .toggleStyle(.button)
//        //            }
//        //            .padding(.top, 10)
//        
//        ListSection {
//          Button {
//            store.send(.adjustBalanceTapped)
//          } label: {
//            ActionRow(text: "Adjust balance")
//          }
//          
//          Divider()
//          
//          NavigationLink(
//            state: AccountsFeature.Path.State.stats(
//              AccountStatsFeature.State(
//                accountId: store.accountId
//              )
//            )
//          ) {
//            ActionRow(text: "Statistics")
//          }
//          
//          Divider()
//          
//          NavigationLink(
//            state: AccountsFeature.Path.State.movements(
//              AccountMovementsFeature.State(
//                account: store.account!
//              )
//            )
//          ) {
//            ActionRow(text: "Movements")
//          }
//        } header: {
//          HStack {
//            Label("Quick actions", systemImage: "wand.and.rays")
//            
//            Spacer()
//          }
//          .padding(.bottom, 10)
//        }
//        
//        AccountsMovementsWidgetView(
//          store: store.scope(
//            state: \.movementsState,
//            action: \.movements
//          )
//        )
//        
//      } else {
//        ProgressView()
//          .transition(.scale.animation(.spring))
//      }
//    }
//  }
//}
//
//private struct ActionRow: View {
//  let text: String
//  
//  var body: some View {
//    HStack {
//      Text(text)
//        .foregroundStyle(.primary)
//      
//      Spacer()
//      
//      Image(systemName: "chevron.forward")
//        .foregroundStyle(.secondary)
//        .padding(.trailing, 10)
//    }
//    .padding(.vertical, 10)
//  }
//}
//
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
//
////private struct MovementsDailyView: View {
////  private let movements: [AccountMovement]
////  
////  init(
////    movements: [AccountMovement],
////    showCategoriesAction: @escaping (AccountMovement) -> Void
////  ) {
////    self.movements = movements.sorted(by: { $0.balance.value > $1.balance.value })
////    self.showCategoriesAction = showCategoriesAction
////  }
////  
////  var body: some View {
////    VStack(spacing: 10) {
////      ForEach(movements, id: \.id) { movement in
////        MovementItemView(
////          movement: movement
////        )
////      }
////    }
////    .padding(10)
////  }
////}
//
////private struct MovementItemView: View {
////  let movement: AccountMovement
////  let showCategoriesAction: (AccountMovement) -> Void
////  
////  var body: some View {
////    HStack(alignment: .center, spacing: 10) {
////      Button {
////        showCategoriesAction(movement)
////      } label: {
////        movement.category.map { CategoryIcon($0) }
////        ?? CategoryIcon.noCategory()
////      }
////      
////      Text(movement.description)
////        .lineLimit(2)
////      
////      Spacer()
////      
////      VStack(alignment: .trailing) {
////        CurrencyValueText(currencyValue: movement.amount)
////          .fontWeight(.medium)
////      }
////    }
////    .frame(height: 64)
////  }
////}
//
//struct AccountDetailView2: View {
//  @Bindable var store: StoreOf<AccountDetailsFeature>
//  
//  var body: some View {
//    HistoryTabView(store: store)
//    
////    TabView {
////      HistoryTabView(store: store)
////        .tabItem { Label("History", systemImage: "chart.line.uptrend.xyaxis") }
////
////      StatsTabView(store: store)
////        .tabItem { Label("Stats", systemImage: "chart.pie.fill") }
////    }
//    
//    .navigationTitle(store.account?.name ?? "Loading")
//    .inlineTitle()
//    .task {
//      await store.send(.onTask).finish()
//    }
//    .sheet(
//      item: $store.scope(state: \.adjustBalance, action: \.adjustBalance)
//    ) { store in
//      NavigationStack {
//        AdjustBalanceForm(store: store)
//      }
//      .presentationDetents([.medium])
//    }
//  }
//}
