//
//  CategoryDetailsView.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 27/06/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct CategoryForm {
  @ObservableState
  struct State {
    enum LoadingState: Equatable {
      static func == (lhs: CategoryForm.State.LoadingState, rhs: CategoryForm.State.LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): true
        case (.loading, .loading): true
        case (.error, .error): true
        default: false
        }
      }
      
      case idle
      case loading
      case error(Error)
    }
    
    let categoryId: Category.ID?
    var body: CategoryBody
    var loadingState: LoadingState = .idle
    var backgroundColor: Color {
      get { Color(hex: body.backgroundColor) }
      set { body.backgroundColor = newValue.hex ?? "" }
    }
    
    init(
      category: Category
    ) {
      self.body = .init(
        name: category.name,
        icon: category.icon,
        backgroundColor: category.backgroundColor
      )
      self.categoryId = category.id
    }
    
    init() {
      self.body = .init(
        name: "",
        icon: "😎",
        backgroundColor: "#FF0000FF"
      )
      self.categoryId = nil
    }
  }
  
  enum Action: BindableAction {
    case saveTapped
    case saveSuccess
    case saveError(Error)
    case binding(BindingAction<State>)
  }
  
  @Dependency(\.categoriesRepository) var repository
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .saveTapped:
        state.loadingState = .loading
        return .run { [state] send in
          let _ = if let id = state.categoryId {
            try await repository.updateCategory(id, state.body)
          } else {
            try await repository.createCategory(state.body)
          }
          await send(.saveSuccess)
        } catch: { error, send in
          await send(.saveError(error))
        }
        
      case .saveSuccess:
        state.loadingState = .idle
        return .run { _ in
          await dismiss()
        }
        
      case let .saveError(error):
        state.loadingState = .error(error)
        return .none
        
      case .binding(_):
        return .none
      }
    }
  }
}

struct CategoryFormView: View {
  @Bindable var store: StoreOf<CategoryForm>
  
  private let iconSize: CGFloat = 100
  
  var body: some View {
    Form {
      Section {
        TextField(text: $store.body.name) {
          Text("Name")
        }
        TextField(text: $store.body.icon) {
          Text("Icon")
        }
        
        ColorPicker(selection: $store.backgroundColor) {
          TextField("Background color", text: $store.body.backgroundColor)
        }
        
        HStack {
          Spacer()
          CategoryIcon(
            icon: store.body.icon,
            backgroundColor: store.backgroundColor,
            size: 64
          )
          Spacer()
        }
      }
      
      Section {
        if store.loadingState == .loading {
          ProgressView()
        } else {
          Button("Save") {
            store.send(.saveTapped)
          }
        }
      }
      
      if case let .error(error) = store.loadingState {
        Section {
          Text(error.localizedDescription)
            .foregroundStyle(Color.red)
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    CategoryFormView(
      store: Store(initialState: CategoryForm.State()) {
        CategoryForm()
      }
    )
  }
}
