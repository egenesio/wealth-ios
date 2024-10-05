//
//  AccountMovementDetail.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 05/08/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct MovementDetailFeature {
  enum Tab: CaseIterable, Identifiable, Hashable {
    case details
    case related
    
    var label: String {
      switch self {
      case .details:
        "Details"
      case .related:
        "Related"
      }
    }
    
    var id: String {
      switch self {
      case .details:
        "details"
      case .related:
        "related"
      }
    }
  }

  @ObservableState
  struct State {
    let account: Account
    var movement: AccountMovement
    
    var currentTab: Tab = .details
  }
  
  enum Action: BindableAction {
    case onTask
    case binding(BindingAction<State>)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      return .none
    }
  }
}

struct MovementDetailView: View {
  @Bindable var store: StoreOf<MovementDetailFeature>
  
  struct TabButton: View {
    let store: StoreOf<MovementDetailFeature>
    let tab: MovementDetailFeature.Tab
    var body: some View {
      Button {
        store.send(.binding(.set(\.currentTab, tab)))
      } label: {
        Text(tab.label)
          .padding(10)
          .maxWidth(alignment: .center)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(
                store.currentTab == tab
                ? Color.accentColor.opacity(0.2)
                : Color.clear
              )
          )
      }
    }
  }
  
  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        ForEach(MovementDetailFeature.Tab.allCases) { tab in
          TabButton(store: store, tab: tab)
        }
      }
      .padding(.horizontal, 10)
      .clipped()
      
      TabView(selection: $store.currentTab) {
        SimpleList {
          ListSection {
            CategoryItemView(store.movement.category)
          } header: {
            FieldHeader(text: "Category")
          }
          
          ListSection {
            Text(store.movement.description)
              .frame(maxWidth: .infinity, alignment: .leading)
          } header: {
            FieldHeader(text: "Description")
          }
          
          ListSection {
            HStack {
              Text("Amount")
              Spacer()
              CurrencyValueText(currencyValue: store.movement.amount)
            }
          }
          
          if store.movement.fees.value != 0 {
            ListSection {
              HStack {
                Text("Fees")
                Spacer()
                CurrencyValueText(currencyValue: store.movement.fees)
              }
            }
          }
          
          ListSection {
            HStack {
              Text("Balance after")
              Spacer()
              CurrencyValueText(currencyValue: store.movement.balance)
            }
          }
          
          ListSection {
            HStack {
              Text("Date")
              Spacer()
              Text(DateFormatter.forString.string(from: store.movement.date))
            }
          }
          
          if store.movement.date != store.movement.completionDate {
            ListSection {
              HStack {
                Text("Completion date")
                Spacer()
                Text(DateFormatter.forString.string(from: store.movement.completionDate))
              }
            }
          }
          
          ListSection {
            Text(store.movement.note ?? "No notes")
              .frame(maxWidth: .infinity, alignment: .leading)
          } header: {
            FieldHeader(text: "Notes")
          }
          
          ListSection {
            Text("**Last updated**")
            Text(DateFormatter.full.string(from: store.movement.updatedAt))
            
            Text("**Created**")
              .padding(.top, 10)
            Text(DateFormatter.full.string(from: store.movement.createdAt))
            
            Text("**Import identifier**")
              .padding(.top, 10)
            Text(store.movement.importKey)
          }
          .sectionColor(.clear)
          .sectionAlignment(.leading)
          .foregroundStyle(.secondary)
        }
        .tag(MovementDetailFeature.Tab.details)
        
        SimpleList {
          ListSection {
            Text("Second tab")
          }
        }
        .tag(MovementDetailFeature.Tab.related)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
    }
    .background(Color.backgroundColor)
    .inlineTitle("Record")
  }
}

extension View {
  func inlineTitle(_ title: String) -> some View {
    #if canImport(UIKit)
      navigationBarTitleDisplayMode(.inline)
      .navigationTitle(title)
    #else
      navigationTitle(title)
    #endif
  }
}

private struct FieldHeader: View {
  let text: String
  
  var body: some View {
    HStack {
      Text(text)
        .font(.callout)
        .foregroundStyle(.secondary)
      Spacer()
    }
    .padding([.bottom], 10)
  }
}
//#Preview {
//  NavigationStack {
//    AccountMovementDetailView(
//      store: .init(
//        initialState: AccountMovementDetailFeature.State(
//          account: Account(
//            id: "",
//            group: .init(
//              id: .init(),
//              name: "Group",
//              description: nil,
//              order: 1
//            ),
//            currency: .chf,
//            symbol: nil,
//            name: "Test Account",
//            description: nil,
//            balance: .init(value: 100, currency: .chf)
//          ),
//          movement: .init(
//            id: .init(),
//            accountId: .init(),
//            category: .init(
//              id: "",
//              parentId: "",
//              name: "Subscriptions",
//              icon: "😎",
//              backgroundColor: "#66FE3A2F",
//              tintColor: nil,
//              categories: []
//            ),
//            amount: CurrencyValue(value: 10, currency: .chf),
//            fees: CurrencyValue(value: 0, currency: .chf),
//            balance: CurrencyValue(value: 2231.45, currency: .chf),
//            date: .distantFuture,
//            completionDate: .distantFuture,
//            description: "Description",
//            note: "Note",
//            importKey: "import",
//            createdAt: .distantFuture,
//            updatedAt: .distantFuture
//          )
//        )
//      ) {
//        AccountMovementDetailFeature()
//      }
//    )
//  }
//}
