//
//  CategoriesPickerView.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 27/06/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct CategoriesPickerFeature {
  @ObservableState
  struct State {
    let movement: AccountMovement
    var categories: [Category] = []
  }
  
  enum Action {
    case onTask
    case categoriesLoaded([Category])
    case categorySelected(Category)
  }
  
  @Dependency(\.categoriesRepository) var repository
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        return .run { send in
          let categories = try await repository.fetchCategories()
          await send(.categoriesLoaded(categories))
        }
        
      case let .categoriesLoaded(categories):
        state.categories = categories
        return .none
        
      case .categorySelected:
        return .run { _ in
          await dismiss()
        }
      }
    }
  }
}

struct CategoriesPickerView: View {
  let store: StoreOf<CategoriesPickerFeature>
  
  var body: some View {
    ScrollView {
      VStack(spacing: 10) {
        ForEach(store.categories, id: \.id) { category in
          CategoryItemView(category)
            .onTapGesture {
              store.send(.categorySelected(category))
            }
        }
      }
      .padding(.horizontal, 10)
      .task { await store.send(.onTask).finish() }
    }
  }
}

//#Preview {
//  CategoriesPickerView(
//    viewModel: .init(),
//    onSelected: { _ in }
//  )
//}

