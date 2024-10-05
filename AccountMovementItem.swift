//
//  AccountMovementItem.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 21/07/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AccountMovementItemFeature {
  @ObservableState
  struct State: Identifiable {
    init(
      movement: AccountMovement,
      dateLabel: String? = nil
    ) {
      self.movement = movement
      self.dateLabel = dateLabel
    }
    
    var id: UUID {
      movement.id
    }
    
    var movement: AccountMovement
    var dateLabel: String?
    
    @Presents var categoriesPicker: CategoriesPickerFeature.State? = nil
  }
  
  enum Action {
    case categoryTapped
    case movementUpdated(AccountMovement)
    
    case categoriesPicker(PresentationAction<CategoriesPickerFeature.Action>)
  }
  
  @Dependency(\.movementsRepository) var repository
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .categoryTapped:
        state.categoriesPicker = .init(
          movement: state.movement
        )
        return .none
        
      case let .movementUpdated(movement):
        state.movement = movement
        return .none
        
      case let .categoriesPicker(.presented(.categorySelected(category))):
        return .run { [state] send in
          let movement = try await repository.setCategory(state.movement.id, category.id)
          await send(.movementUpdated(movement))
        }
        
      case .categoriesPicker:
        return .none
      }
    }
    .ifLet(\.$categoriesPicker, action: \.categoriesPicker) {
      CategoriesPickerFeature()
    }
  }
}

struct MovementItemView2: View {
  @Bindable var store: StoreOf<AccountMovementItemFeature>
  
  var body: some View {
    VStack(spacing: 0) {
      if let dateLabel = store.dateLabel {
        Text(dateLabel)
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundStyle(.secondary)
          .font(.footnote)
          .padding([.top], 20)
          .padding([.horizontal], 10)
      }
      
      HStack(alignment: .center, spacing: 10) {
        Button {
          store.send(.categoryTapped)
        } label: {
          CategoryIcon(store.movement.category)
        }
        
        Text(store.movement.description)
          .lineLimit(2)
        
        Spacer()
        
        VStack(alignment: .trailing) {
          CurrencyValueText(currencyValue: store.movement.amount)
            .fontWeight(.medium)
        }
      }
      .frame(height: 64)
      .contextMenu(menuItems: {
        Button {
          store.send(.categoryTapped)
        } label: {
          Text("Edit category")
        }
        Button {
          
        } label: {
          Text("Open details")
        }
      })
    }
    .sheet(
      item: $store.scope(state: \.categoriesPicker, action: \.categoriesPicker)
    ) { store in
      NavigationStack {
        CategoriesPickerView(store: store)
          .navigationTitle("Categories")
      }
    }
  }
}

struct MovementItemViewStatic: View {
  let movement: AccountMovement
  let dateLabel: String?
  
  var body: some View {
    VStack(spacing: 0) {
      if let dateLabel = dateLabel {
        Text(dateLabel)
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundStyle(.secondary)
          .font(.footnote)
          .padding([.top], 20)
          .padding([.horizontal], 10)
      }
      
      HStack(alignment: .center, spacing: 10) {
        CategoryIcon(movement.category)
        
        Text(movement.description)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
        
        Spacer()
        
        VStack(alignment: .trailing) {
          CurrencyValueText(currencyValue: movement.amount)
            .fontWeight(.medium)
        }
      }
      .frame(height: 64)
    }
  }
}

#Preview {
  Text("")
}
