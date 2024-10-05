//
//  AccountDetailsView.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 23/06/24.
//

import SwiftUI
import Charts

@MainActor
class AccountsDetailsViewModel: ObservableObject {
  @Published var account: Account?
  @Published var history: HistoryQueryData?
  @Published var historyPeriod: HistoryPeriod = .year
  
  @Published var groupedMovements: [Date: [AccountMovement]] = [:]
  @Published var stats: [StatsResult] = []
  
  var isWeekSelected: Bool {
    get {
      historyPeriod == .week
    }
    set {
      if newValue {
        historyPeriod = .week
        onHistoryPeriodChanged()
      }
    }
  }
  var isMonthSelected: Bool {
    get {
      historyPeriod == .month
    }
    set {
      if newValue {
        historyPeriod = .month
        onHistoryPeriodChanged()
      }
    }
  }
  var isYearSelected: Bool {
    get {
      historyPeriod == .year
    }
    set {
      if newValue {
        historyPeriod = .year
        onHistoryPeriodChanged()
      }
    }
  }
  
  private let repository = AccountsRepository()
  private let accountId: String
  private var movementsPage = 0
  private var movements: Set<AccountMovement> = []
  
  init(accountId: String) {
    self.accountId = accountId
  }
  
  func refresh() async {
    await fetchDetails()
  }
  
  private func onHistoryPeriodChanged() {
    Task { @MainActor in
      await fetchDetails()
    }
  }
  
  private func fetchDetails() async {
    do {
      let accountDetails = try await repository.fetchAccountDetails(
        accountId: accountId,
        period: historyPeriod,
        page: movementsPage
      )
      self.account = accountDetails.account
      self.history = accountDetails.history
      self.movementsPage = accountDetails.movements.metadata.page
      self.updateMovements(accountDetails.movements.items)
      
      self.stats = try await repository.fetchAccountStats(accountId: accountId)
      
    } catch {
      print(error)
    }
  }
  
  func loadMoreMovements() async { // listEnded
    Task { @MainActor in
      self.movementsPage += 1
      await fetchDetails()
    }
  }
  
  func updateMovement(_ movement: AccountMovement, category: Category) {
    Task { @MainActor in
      do {
        let resultMovement = try await repository.updateMovementCategory(movement: movement, category: category)
        self.updateMovements([resultMovement])
      } catch {
        print(error)
      }
    }
  }
  
  private func updateMovements(_ movements: [AccountMovement]) {
    for movement in movements {
      self.movements.update(with: movement)
    }
    
    self.groupedMovements = Dictionary(grouping: self.movements) { movement in
      Calendar.current.startOfDay(for: movement.date)
    }
  }
}

struct AccountDetailView: View {
  @ObservedObject var viewModel: AccountsDetailsViewModel
  
  private var chartBackground: Gradient {
    return Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.0)])
  }
  
  private var historyTab: some View {
    Group {
      if let history = viewModel.history {
        ScrollView(showsIndicators: false) {
          LazyVStack(spacing: .zero) {
            
            VStack {
              CurrencyValueText(currencyValue: history.balance)
              switch history.growth.type {
              case .percentage:
                Text("\(history.growth.value)%")
              case .amount:
                Text("+") // TODO: Text(history.balance, format: .currency(code: account.currency.rawValue))
              }
            }
            
            HistoryView(history: history)
            
            HStack(spacing: 20) {
              Toggle(isOn: $viewModel.isWeekSelected) {
                Text("Week")
              }
              .toggleStyle(.button)
              Toggle(isOn: $viewModel.isMonthSelected) {
                Text("Month")
              }
              .toggleStyle(.button)
              
              Toggle(isOn: $viewModel.isYearSelected) {
                Text("Year")
              }
              .toggleStyle(.button)
            }
            .padding(.top, 10)
            
            ForEach(viewModel.groupedMovements.keys.sorted(by: >), id: \.self) { date in
              Section {
                AccountMovementsDailyView(
                  movements: viewModel.groupedMovements[date] ?? [],
                  onUpdateCategory: { movement, category in
                    viewModel.updateMovement(movement, category: category)
                  }
                )
              } header: {
                Text(DateFormatter.forString.string(from: date))
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal, 10)
                  .foregroundStyle(.secondary)
                  .font(.footnote)
                  .padding(.top, 20)
              }
            }
            .padding(.horizontal, 10)
            
            Text("Loading")
              .task {
                await viewModel.loadMoreMovements()
              }
          }
        }
      } else {
        Text("Empty")
      }
    }
  }
  
  private var statsTab: some View {
    ScrollView {
      VStack {
        ForEach(viewModel.stats, id: \.periodText) { stat in
          
          VStack(spacing: 10) {
            HStack(spacing: 0) {
              Text(stat.periodText)
              Spacer()
              CurrencyValueText(currencyValue: stat.balance)
            }
            .padding(.horizontal, 10)
            
            ForEach(stat.movementsByCategories, id: \.category.id) { row in
              
              VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                  VStack(alignment: .leading) {
                    Text(row.category.name)
                    Text("\(row.count) transactions")
                      .foregroundStyle(.secondary)
                  }
                  
                  Spacer()
                  CurrencyValueText(currencyValue: row.currencyValue)
                }
              }
              .padding(.horizontal, 20)
            }
          }
          .padding(.top, 20)
          
          
        }
      }
    }
  }
  
  var body: some View {
    TabView {
      statsTab
        .tabItem { Label("Stats", systemImage: "chart.pie.fill") }

      historyTab
        .tabItem { Label("History", systemImage: "chart.line.uptrend.xyaxis") }
    }
    .inlineTitle(viewModel.account?.name ?? "Loading")
    .task {
      await viewModel.refresh()
    }
  }
}

struct HistoryView: View {
  let history: HistoryQueryData
  
  @State private var chartSelection: String?

  private var areaBackground: Gradient {
    return Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.1)])
  }
  
  var body: some View {
    Chart(history.items.reversed(), id: \.dateRaw) { data in
      LineMark(
        x: .value("Date", data.dateRaw),
        y: .value("Amount", data.balance.value)
      )
      .interpolationMethod(.catmullRom)
      
      AreaMark(
        x: .value("Date", data.dateRaw),
        y: .value("Amount", data.balance.value)
      )
      .interpolationMethod(.catmullRom)
      .foregroundStyle(areaBackground)
      
      if let chartSelection {
        RuleMark(x: .value("Date", chartSelection))
          .foregroundStyle(.gray.opacity(0.5))
          .annotation(
            position: .leading,
            overflowResolution: .init(x: .fit, y: .disabled)
          ) {
            ZStack {
//              textFor(chartSelection)
              Text("Selection: \(chartSelection)")
            }
            .padding()
            .background {
              RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(Color.accentColor.opacity(0.2))
            }
          }
      }
    }
    .chartYScale(domain: history.min.value * 0.90 ... history.max.value * 1.1)
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartXSelection(value: $chartSelection)
    .frame(height: 300)
    .clipped()
  }
}

struct AccountMovementsDailyView: View {
  private let movements: [AccountMovement]
  private let onUpdateCategory: (AccountMovement, Category) -> Void
  
  init(
    movements: [AccountMovement],
    onUpdateCategory: @escaping (AccountMovement, Category) -> Void
  ) {
    self.movements = movements.sorted(by: { $0.balance.value > $1.balance.value })
    self.onUpdateCategory = onUpdateCategory
  }
  
  @State private var categoriesPickerFor: AccountMovement? = nil
  
  var body: some View {
    VStack(spacing: 10) {
      ForEach(movements, id: \.id) { movement in
        AccountMovementItemView(
          movement: movement,
          showCategoriesPicker: {
            print("===showCategoriesPicker")
            categoriesPickerFor = $0
          }
        )
      }
    }
    .padding(10)
//    .sheet(item: $categoriesPickerFor) { movement in
//      CategoriesPickerView(
//        viewModel: .init(),
//        onSelected: {
//          onUpdateCategory(movement, $0)
//          categoriesPickerFor = nil
//        }
//      )
//    }
  }
}

struct AccountMovementItemView: View {
  let movement: AccountMovement
  let showCategoriesPicker: (AccountMovement) -> Void
  
  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      Button {
        showCategoriesPicker(movement)
      } label: {
        CategoryIcon(movement.category)
      }
      
      Text(movement.description)
        .lineLimit(2)
      
      Spacer()
      
      VStack(alignment: .trailing) {
        CurrencyValueText(currencyValue: movement.amount)
          .fontWeight(.medium)
      }
    }
    .frame(height: 64)
  }
}


