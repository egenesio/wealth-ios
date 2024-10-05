//
//  AccountDetails.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 27/06/24.
//

import Foundation

struct AccountDetails: Decodable {
  let account: Account
  let history: HistoryQueryData
  let movements: MovementsQueryData
}

struct HistoryQueryData: Equatable, Decodable {
  struct Growth: Equatable, Decodable {
    enum ValueType: String, Decodable {
      case percentage
      case amount
    }
    
    let value: Decimal
    let type: ValueType
  }

  let items: [BalanceAtDate]
  let min: CurrencyValue
  let max: CurrencyValue
  let balance: CurrencyValue
  let growth: Growth
  let period: HistoryPeriod
}

struct MovementsQueryData: Equatable, Decodable {
  struct Metadata: Equatable, Decodable {
    let page: Int
    let per: Int
    let total: Int
    let pageCount: Int
  }
  
  let items: [AccountMovement]
  let metadata: Metadata
}
