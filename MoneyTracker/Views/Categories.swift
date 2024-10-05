//
//  CategoriesView.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 25/06/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct CategoriesFeature {
  @ObservableState
  struct State {
    var categories: IdentifiedArrayOf<Category>
  }
  
  enum Action {
    case onTask
    case categoriesLoaded(IdentifiedArrayOf<Category>)
    case categoryMoved(from: IndexSet, to: Int)
  }
  
  @Dependency(\.categoriesRepository) var categoriesRepository
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        return .run { send in
          let categories = try await categoriesRepository.fetchCategories()
          await send(.categoriesLoaded(.init(uniqueElements: categories)))
        }
        
      case let .categoriesLoaded(categories):
        state.categories = categories
        
        return .none
        
      case let .categoryMoved(from, to):
        print("===", from, to)
        state.categories.move(fromOffsets: from, toOffset: to)
        return .none
      }
    }
  }
}

struct NoChevronNavigationLink<State>: View {
  var state: State
  var label: () -> AnyView
  
  var body: some View {
    ZStack {
      label()
      
      NavigationLink(
        state: state
      ) {
        EmptyView()
      }.opacity(0)
    }
  }
}
  
struct CategoriesView: View {
  let store: StoreOf<CategoriesFeature>
  
  var body: some View {
    List {
      Section {
        ForEach(store.categories) { category in
          NavigationLink(
            state: SettingsFeature.Path.State.categoryDetails(CategoryForm.State(
              category: category
            ))
          ) {
            CategoryItemView(category)
          }

//          NoChevronNavigationLink(
//            state: SettingsFeature.Path.State.categoryDetails(.init())
//          ) {
//            AnyView(
//              Text("Add **\(category.name)** category")
//                .frame(maxWidth: .infinity, alignment: .leading)
//            )
//          }
          .padding(.leading, 10)
        }
        
        NavigationLink(
          state: SettingsFeature.Path.State.categoryDetails(CategoryForm.State())
        ) {
          Text("Create category")
        }
      }
      .listRowSeparator(.hidden)
    }
    .inlineTitle("Categories")
    .toolbar {
      #if canImport(iOS)
        EditButton()
      #endif
    }
    .task {
      await store.send(.onTask).finish()
    }
  }
}

struct CategoryItemView: View {
  private let category: Category
  
  init(_ category: Category) {
    self.category = category
  }
  
  var body: some View {
    HStack(spacing: 10) {
      CategoryIcon(category)
      
      VStack(spacing: 0) {
        Text(category.name)
        
        if category.isDefault {
          Text("Default")
            .font(.caption)
            .padding(4)
            .background {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundColor)
            }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct CategoryIcon: View {
  private let icon: String
  private let backgroundColor: Color
  private let size: CGFloat
  
  init(
    icon: String,
    backgroundColor: Color,
    size: CGFloat = 48
  ) {
    self.icon = icon
    self.backgroundColor = backgroundColor
    self.size = size
  }
  
  init(_ category: Category, size: CGFloat = 48) {
    self.icon = category.icon
    self.backgroundColor = Color(hex: category.backgroundColor)
    self.size = size
  }
  
  var body: some View {
    Text(icon)
      .font(.system(size: size / 2))
      .frame(width: size, height: size)
      .background(
        Circle()
          .frame(width: size, height: size)
          .foregroundStyle(backgroundColor)
      )
      .clipped()
  }
}
