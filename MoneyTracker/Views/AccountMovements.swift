//
//  AccountMovements.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 19/07/24.
//

import SwiftUI
import ComposableArchitecture

// TODO: move 
extension Array where Element == AccountMovement {
  func isNewDate(_ movement: Element) -> Bool {
    guard
      let index = firstIndex(of: movement),
      index > 0
    else {
      return true
    }
    
    let lastMovement = self[self.index(before: index)]
    
    return Calendar.current.compare(
      movement.date,
      to: lastMovement.date,
      toGranularity: .day
    ) == .orderedAscending
  }
}

@Reducer
struct AccountMovementsFeature {
  @ObservableState
  struct State {
    let account: Account
    let limit: Int?
    
    var loadingState: LoadingState
    var items: IdentifiedArrayOf<AccountMovementItemFeature.State>
    var hasMoreData: Bool = false
    var currentPage: Int
    var totalRecords: Int
    
    init(
      account: Account,
      limit: Int? = nil,
      loadingState: LoadingState = .idle,
      items: IdentifiedArrayOf<AccountMovementItemFeature.State> = [],
      hasMoreData: Bool = false,
      currentPage: Int = 0,
      totalRecords: Int = 0
    ) {
      self.account = account
      self.limit = limit
      self.loadingState = loadingState
      self.items = items
      self.hasMoreData = hasMoreData
      self.currentPage = currentPage
      self.totalRecords = totalRecords
    }
    
    init(
      account: Account,
      page: Page<AccountMovement>
    ) {
      self.account = account
      self.limit = nil
      self.loadingState = .idle
      self.items = Self.itemsFrom(page.items)
      self.hasMoreData = false
      self.currentPage = page.metadata.page
      self.totalRecords = page.metadata.total
    }
    
    static func itemsFrom(
      _ items: [AccountMovement]
    ) -> IdentifiedArrayOf<AccountMovementItemFeature.State> {
      IdentifiedArray(
        uniqueElements: items.map { movement in
          let dateLabel: String? = if items.isNewDate(movement) {
            DateFormatter.forString.string(from: movement.date)
          } else {
            nil
          }
          
          return AccountMovementItemFeature.State(
            movement: movement,
            dateLabel: dateLabel
          )
        }
      )
    }
  }
  
  enum Action {
    case onTask
    case loadData
    case bottomViewAppeared
    
    case dataLoaded(Page<AccountMovement>)
    case items(IdentifiedActionOf<AccountMovementItemFeature>)
  }
  
  @Dependency(\.movementsRepository) var repository
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        if state.items.isEmpty {
          state.loadingState = .loading
          return .send(.loadData)
        } else {
          return .none
        }
      
      case let .dataLoaded(data):
        state.items.append(contentsOf: State.itemsFrom(data.items))
        state.loadingState = .idle
        state.currentPage = data.metadata.page
        state.totalRecords = data.metadata.total
        state.hasMoreData = data.metadata.page <= data.metadata.pageCount
        
        return .none
        
      case .bottomViewAppeared:
        state.currentPage += 1
        return .send(.loadData)
        
      case .loadData:
        return .run { [state] send in
          let page = try await repository.fetchMovementsByAccount(
            state.account.id,
            state.currentPage
          )
          
          await send(.dataLoaded(page))
        }
        
      case .items:
        return .none
      }
    }
    .forEach(\.items, action: \.items) {
      AccountMovementItemFeature()
    }
  }
}

struct AccountsMovementsScreenView: View {
  let store: StoreOf<AccountMovementsFeature>
  
  var body: some View {
    ScrollView(showsIndicators: false) {
      AccountsMovementsView(store: store)
    }
  }
}

struct AccountsMovementsWidgetView: View {
  let store: StoreOf<AccountMovementsFeature>
  
  var body: some View {
    ListSection {
      if store.loadingState == .loading {
        ProgressView()
          .transition(.scale.animation(.spring))
        
      } else if store.items.isEmpty {
        Text("No records")
        
      } else if let limit = store.limit {
        ForEach(store.scope(state: \.items, action: \.items).prefix(limit)) { itemStore in
          NavigationLink(
            state: AccountsFeature.Path.State.movementDetails(
              MovementDetailFeature.State(
                account: store.account,
                movement: itemStore.state.movement
              )
            )
          ) {
            MovementItemView2(store: itemStore)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
    } header: {
      HStack {
        Label("History", systemImage: "list.bullet")
        
        Spacer()
      
        NavigationLink(
          state: AccountsFeature.Path.State.movements(
            AccountMovementsFeature.State(
              account: store.account,
              items: store.items,
              hasMoreData: store.hasMoreData,
              currentPage: store.currentPage
            )
          )
        ) {
          Image(systemName: "arrow.up.left.and.arrow.down.right.square")
        }
      }
    } footer: {
      if !store.items.isEmpty {
        Text("\(store.totalRecords) Records")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .trailing)
          .padding([.top], 10)        
      }
    }
    .sectionMinHeight(100)
    .task {
      await store.send(.onTask).finish()
    }
  }
}

private struct AccountsMovementsView: View {
  let store: StoreOf<AccountMovementsFeature>
  
  var body: some View {
    Group {
      switch store.loadingState {
      case .idle:
        LazyVStack {
          ForEach(store.scope(state: \.items, action: \.items)) { itemStore in
            NavigationLink(
              state: AccountsFeature.Path.State.movementDetails(
                MovementDetailFeature.State(
                  account: store.account,
                  movement: itemStore.state.movement
                )
              )
            ) {
              MovementItemView2(store: itemStore)
            }
            .buttonStyle(PlainButtonStyle())
          }
          .padding(.horizontal, 10)

          if store.hasMoreData {
            HStack(spacing: 20) {
              ProgressView()
              Text("Loading your history")
            }
            .padding(.vertical, 50)
            .task {
              await store.send(.bottomViewAppeared).finish()
            }
          }
        }
        
      case .loading:
        ProgressView()
          .frame(height: 200)
        
      case let .error(error):
        Text("Error: \(error)")
      }
    }
    .task {
      await store.send(.onTask).finish()
    }
  }
}

//#Preview {
//  NavigationStack {
//    ScrollView {
//      AccountsMovementsWidgetView(
//        store: Store(
//          initialState: AccountMovementsFeature.State(
//            accountId: "7ec0a028-2812-11ef-93ba-0242ac130002"
//          )
//        ) {
//          AccountMovementsFeature()
//        }
//      )
//    }
//  }
//}
//
