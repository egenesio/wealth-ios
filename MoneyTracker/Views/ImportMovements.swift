//
//  ImportMovements.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 18/08/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct ImportMovements {
  @ObservableState
  struct State {
    let account: Account
    
    var loadingState: LoadingState = .idle
    var fileType: AccountMovement.ImportFileType = .allCases[0]
    var skipParsingErrors: Bool = false
    var skipExisting: Bool = false
    var removeText: String = ""
    var fileURL: URL?
    
    var presentFilePicker = false
    
    @Presents var destination: Destination.State?
    
    mutating func reset() {
      loadingState = .idle
      skipParsingErrors = false
      skipExisting = false
      removeText = ""
      fileURL = nil
    }
  }
  
  @Reducer
  enum Destination {
    case movements(AccountMovementsFeature)
  }
  
  enum Action: BindableAction {
    case pickFileTapped
    case importTapped

    case onFileCompletion(URL)
    case importSuccess(Page<AccountMovement>)
    case importError(Error)
    case binding(BindingAction<State>)
    
    case destination(PresentationAction<Destination.Action>)
  }
  
  @Dependency(\.movementsRepository) var repository
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .pickFileTapped:
        state.presentFilePicker = true
        return .none
        
      case .importTapped:
        guard let url = state.fileURL else {
          return .none
        }
        
        state.loadingState = .loading
        return .run { [state, url] send in
          let movements = try await repository.importMovements(
            state.account.id,
            .init(
              fileType: state.fileType,
              fileURL: url,
              skipParsingErrors: state.skipParsingErrors,
              skipExisting: state.skipExisting,
              removeText: state.removeText.emptyAsNil
            )
          )
          await send(.importSuccess(movements))
        } catch: { error, send in
          await send(.importError(error))
        }
        
      case let .importSuccess(page):
        state.reset()
        state.destination = .movements(
          AccountMovementsFeature.State(
            account: state.account,
            page: page
          )
        )
        return .none
        
      case let .importError(error):
        state.loadingState = .error(error.message)
        return .none
        
      case let .onFileCompletion(url):
        state.fileURL = url
        return .none
        
      case .binding(_):
        return .none
        
      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

struct ImportMovementsView: View {
  @Bindable var store: StoreOf<ImportMovements>
  
  var body: some View {
    Form {
      Section {
        Picker("File type", selection: $store.fileType) {
          ForEach(AccountMovement.ImportFileType.allCases, id: \.self) {
            Text($0.rawValue)
          }
        }
        Toggle("Skip parsing errors", isOn: $store.skipParsingErrors)
        Toggle("Skip existing", isOn: $store.skipExisting)
        TextField("Remove text", text: $store.removeText)
        Button(store.fileURL?.lastPathComponent ?? "Pick file") {
          store.send(.pickFileTapped)
        }
      }
      
      Section {
        if store.loadingState == .loading {
          ProgressView()
        } else {
          Button("Import") {
            store.send(.importTapped)
          }
        }
      }
      
      if case let .error(message) = store.loadingState {
        Section {
          Text(.init(message))
            .foregroundStyle(Color.red)
        }
      }
    }
    .fileImporter(
      isPresented: $store.presentFilePicker,
      allowedContentTypes: [.commaSeparatedText]
    ) { result in
      switch result {
      case .success(let url):
        store.send(.onFileCompletion(url))
      case .failure(let failure):
        print("===", failure)
      }
    }
    .sheet(
      item: $store.scope(
        state: \.destination?.movements,
        action: \.destination.movements
      )
    ) { store in
      NavigationStack {
        AccountsMovementsScreenView(store: store)
          .navigationTitle("Imported records")
      }
    }
  }
  
  // FIXME: do not remove
  private func read(from url: URL) throws -> String {
    let accessing = url.startAccessingSecurityScopedResource()
    defer {
      if accessing {
        url.stopAccessingSecurityScopedResource()
      }
    }
    return try String(contentsOf: url)
  }
}

//#Preview {
//  NavigationStack {
//    ImportMovementsView(store: Store(initialState: ImportMovements.State()) {
//      ImportMovements()
//    })
//  }
//}
