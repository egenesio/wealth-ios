//
//  Repository.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 12/06/24.
//

import Foundation
import Dependencies

struct AccountsRepository {
  private let network: Network = .init()

  func fetchAccounts() async throws -> [Account] {
    let accountResponse: AccountResponse = try await network.request(.get("accounts"))
    return accountResponse.data
  }
  
  func fetchAccountDetails(
    accountId: String,
    period: HistoryPeriod,
    page: Int
  ) async throws -> AccountDetails {
    try await network.request(.get("accounts/\(accountId)/details", queryItems: [
      .init(name: "page", value: "\(page)"),
      .init(name: "per", value: "30"),
      .init(name: "period", value: period.rawValue),
    ]))
  }
  
  func fetchAccountStats(
    accountId: String
  ) async throws -> [StatsResult] {
    try await network.request(.get("accounts/\(accountId)/stats"))
  }
  
  func updateMovementCategory(
    movement: AccountMovement,
    category: Category
  ) async throws -> AccountMovement {
    struct Body: Encodable {
      let categoryId: String
    }
    
    return try await network.request(
      .put("movements/\(movement.id)/category", body: Body(categoryId: category.id.uuidString))
    )
  }
}

struct AccountsRepo {
  var fetchAccounts: @Sendable () async throws -> [Account]
  
  var fetchAccountDetails: @Sendable (
    _ accountId: String,
    _ period: HistoryPeriod,
    _ page: Int
  ) async throws -> AccountDetails
  
  var fetchAccountStats: @Sendable (
    _ accountId: String
  ) async throws -> [StatsResult]
  
  var updateMovementCategory: @Sendable (
    _ movement: AccountMovement,
    _ category: Category
  ) async throws -> AccountMovement
  
  var adjustBalance: @Sendable (
    _ accountId: Account.ID,
    _ date: Date,
    _ description: String?,
    _ note: String?,
    _ balance: Decimal
  ) async throws -> AccountMovement
  
  var createAccount: @Sendable (
    _ body: Account.Body
  ) async throws -> Account
  
  var stats: @Sendable () async throws -> [AccountBalanceHistory]
}

extension AccountsRepo: DependencyKey {
  static var liveValue: Self = {
    let network: Network = .init()
    
    return .init(
      fetchAccounts: {
        let accountResponse: AccountResponse = try await network.request(.get("accounts"))
        return accountResponse.data.ordered()
      },
      
      fetchAccountDetails: { accountId, period, page in
//        try await Task.sleep(for: .seconds(1))
        
        return try await network.request(.get("accounts/\(accountId)/details", queryItems: [
          .init(name: "page", value: "\(page)"),
          .init(name: "per", value: "30"),
          .init(name: "period", value: period.rawValue),
        ]))
      },
      
      fetchAccountStats: { accountId in
        try await network.request(.get("accounts/\(accountId)/stats"))
      },
      
      updateMovementCategory: { movement, category in
        struct Body: Encodable {
          let categoryId: String
        }
        
        return try await network.request(
          .put("movements/\(movement.id)/category", body: Body(categoryId: category.id.uuidString))
        )
      },
      
      adjustBalance: {
        accountId,
        date,
        description,
        note,
        balance in
        struct Body: Encodable {
          let date: String
          let description: String?
          let note: String?
          let balance: Decimal
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        
        let body = Body(
          date: dateFormatter.string(from: date),
          description: description,
          note: note,
          balance: balance
        )
        
        return try await network.dataRequest(
          .post("movements/\(accountId)/adjust", body: body)
        )
      },
      
      createAccount: { body in
        try await network.dataRequest(.post("accounts", body: body))
      },
      
      stats: {
        try await network.dataRequest(.get("stats"))
      }
    )
  }()
}

extension DependencyValues {
  var accountsRepository: AccountsRepo {
    get { self[AccountsRepo.self] }
    set { self[AccountsRepo.self] = newValue }
  }
}
