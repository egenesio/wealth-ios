//
//  PickerFeature.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 10/08/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct PickerFeature<Item> where Item: Decodable, Item: Identifiable {
  @ObservableState
  struct State {
    var isLoading: Bool
    let showAllItem: Bool
    let allowMultiple: Bool
    var items: IdentifiedArrayOf<Item>
    var selected: IdentifiedArrayOf<Item>
    
    var metadata: Page<Item>.Metadata?
    
    var hasMorePages: Bool {
      guard let metadata else { return false }
      
      return metadata.page < metadata.pageCount
    }
    
    init(
      isLoading: Bool = false,
      showAllItem: Bool = false,
      allowMultiple: Bool = false,
      items: IdentifiedArrayOf<Item> = [],
      selected: IdentifiedArrayOf<Item> = []
    ) {
      self.isLoading = isLoading
      self.showAllItem = showAllItem
      self.allowMultiple = allowMultiple
      self.items = .init(uniqueElements: items)
      self.selected = .init(uniqueElements: selected)
    }
    
    mutating func clear() {
      items = []
      selected = []
      metadata = nil
    }
  }
  
  enum Action {
    case onTask
    case onPageEnd
    
    case loadingData
    
    case dataLoaded([Item])
    case pageLoaded(Page<Item>)
    
    case allSelected
    case itemSelected(Item)
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        return .none
        
      case .onPageEnd:
        print("===", "onPageEnd inner")
        return .none
        
//      case let .loadData(block):
//        state.isLoading = true
//        return .run { send in
//          let items = try await block()
//          await send(.dataLoaded(items))
//        }
//        
//      case let .loadPage(clear, block):
//        print("===", "loadPage ", clear)
//        if clear {
//          state.items = []
//          state.selected = []
//          state.metadata = nil
//        }
//        state.isLoading = true
//        return .run { [state] send in
//          let page = if let currentPage = state.metadata?.page {
//            currentPage + 1
//          } else {
//            1
//          }
//          print("===", "loadPage ", "run ", page)
//          let items = try await block(page)
//          await send(.pageLoaded(items))
//        }
        
      case .loadingData:
        state.isLoading = false
        return .none
        
      case let .dataLoaded(items):
        state.isLoading = false
        state.items = .init(uniqueElements: items)
        return .none
        
      case let .pageLoaded(page):
        print("===", "pageLoaded ", page.metadata)
        state.isLoading = false
        state.items.append(contentsOf: page.items)
        state.metadata = page.metadata
        return .none
        
      case .allSelected:
        state.selected.removeAll()
        return .none
      
      case let .itemSelected(item):
        if !state.allowMultiple {
          state.selected.removeAll()
        }
        state.selected.append(item)
        return .none
      }
    }
  }
}

struct PickerView<SelectAllLabel: View, Label: View, Item>: View where Item: Decodable, Item: Identifiable  {
  let store: StoreOf<PickerFeature<Item>>
  let selectAllLabel: () -> SelectAllLabel
  let label: (Item) -> Label
  
  init(
    store: StoreOf<PickerFeature<Item>>,
    selectAllLabel: @escaping () -> SelectAllLabel = { EmptyView() },
    label: @escaping (Item) -> Label
  ) {
    self.store = store
    self.selectAllLabel = selectAllLabel
    self.label = label
  }
  
  var body: some View {
    LazyList {
      if store.isLoading {
        ListSection {
          ProgressView()
        }
      }
      
      if !store.items.isEmpty {
        ListSection {
          if store.showAllItem {
            Button {
              store.send(.allSelected)
            } label: {
              ZStack(alignment: .trailing) {
                selectAllLabel()
                
                if store.selected.isEmpty {
                  Image(systemName: "checkmark.circle.fill")
                }
              }
              .padding(.vertical, 10)
            }
          }
          
          ForEach(store.items) { item in
            Button {
              store.send(.itemSelected(item))
            } label: {
              HStack(spacing: 10) {
                label(item)
                
                if store.selected.contains(item){
                  Image(systemName: "checkmark.circle.fill")
                }
              }
              .padding(.vertical, 10)
            }
          }
        }
        
        if store.hasMorePages {
          HStack(spacing: 20) {
            ProgressView()
            Text("Loading your history")
          }
          .padding(.vertical, 50)
          .task {
            await store.send(.onPageEnd).finish()
          }
        }
      }
    }
    .task { await store.send(.onTask).finish() }
  }
}
