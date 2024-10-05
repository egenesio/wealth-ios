//
//  Account.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 27/06/24.
//

import Foundation

struct Account: Decodable, Identifiable {
  let id: UUID
  let group: AccountGroup
  let currency: Currency
  let symbol: String?
  let name: String
  let description: String?
  let balance: CurrencyValue
  
  var flag: String {
    switch currency {
    case .usd: "💵"
    case .eur: "🇪🇺"
    case .gbp: "="
    case .chf: "🇨🇭"
    }
  }
}

extension Account {
  struct Body: Encodable {
    let groupId: AccountGroup.ID
    let currency: Currency
    let symbol: String?
    let name: String
    let description: String?
  }
}

struct AccountResponse: Decodable {
  var data: [Account]
}

extension Collection where Element == Account {
  func ordered() -> [Element] {
    sorted {
      if $0.group.order == $1.group.order {
        $0.balance.value > $1.balance.value
      } else {
        $0.group.order < $1.group.order
      }
    }
  }
}
