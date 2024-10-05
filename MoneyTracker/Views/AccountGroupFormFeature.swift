//
//  AccountGroupFormFeature.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 10/08/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AccountGroupFormFeature {
  @ObservableState
  struct State {
    enum LoadingState {
      case idle
      case saving
      case deleting
    }
    
    let group: AccountGroup?
   
    var loadingState: LoadingState
    var name: String
    var description: String
    
    @Presents var alert: AlertState<Action.Alert>? = nil
    
    init(group: AccountGroup? = nil) {
      self.group = group
      self.loadingState = .idle
      self.name = group?.name ?? ""
      self.description = group?.description ?? ""
    }
  }
  
  enum Action: BindableAction {
    case alert(PresentationAction<Alert>)
    
    case saveTapped
    case deleteTapped(AccountGroup.ID)
    case finished
    
    case binding(BindingAction<State>)
    
    case error(Error)
    
    @CasePathable
    enum Alert {
      case incrementButtonTapped
    }
  }
  
  @Dependency(\.accountGroupsRepository) var repository
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce {state, action in
      switch action {
      case .alert:
        return .none
        
      case .saveTapped:
        state.loadingState = .saving
        return .run { [state] send in
          let body = AccountGroup.Body(
            name: state.name,
            description: state.description.emptyAsNil,
            order: 0
          )
          do {
            if let group = state.group {
              _ = try await repository.updateGroup(group.id, body)
            } else {
              _ = try await repository.createGroup(body)
            }
            await send(.finished)
          } catch {
            await send(.error(error))
          }
        }
      
      case let .deleteTapped(id):
        state.loadingState = .deleting
        return .run { send in
          do {
            _  = try await repository.deleteGroup(id)
            await send(.finished)
          } catch {
            await send(.error(error))
          }
        }
        
      case let .error(error):
        state.loadingState = .idle
        state.alert = AlertState { TextState(error.message) }
        return .none
        
      case .finished:
        state.loadingState = .idle
        return .none
      
      case .binding(_):
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

struct AccountGroupForm: View {
  @Bindable var store: StoreOf<AccountGroupFormFeature>
  
  var body: some View {
    SimpleList {
      ListSection {
        TextField(
          "Name",
          text: $store.name
        )
        
        TextField(
          "Description",
          text: $store.description
        )
      }
      .sectionSpacing(20)
      
      ListSection {
        if store.loadingState == .saving {
          ProgressView()
        } else {
          Button {
            store.send(.saveTapped)
          } label: {
            Text("Save")
          }
        }
      }
      
      if let group = store.group {
        ListSection {
          if store.loadingState == .deleting {
            ProgressView()
          } else {
            Button {
              store.send(.deleteTapped(group.id))
            } label: {
              Text("Delete")
                .foregroundStyle(Color.red)
            }
          }
        }
      }
    }
    .navigationTitle(store.group?.name ?? "New group")
    .toolbarTitleDisplayMode(.inline)
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}
