//
//  Domain.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 27/06/24.
//

import Foundation

struct CurrencyValue: Equatable, Decodable {
  let value: Decimal
  let currency: Currency
}

struct CurrencyData: Identifiable {
  var id: String {
    currency.rawValue
  }
  
  let currency: Currency
  let isSelected: Bool
}

enum Currency: String, Codable, Identifiable, CaseIterable {
  case usd = "USD"
  case eur = "EUR"
  case gbp = "GBP"
  case chf = "CHF"
  
  var id: String {
    rawValue
  }
}

enum HistoryPeriod: String, Equatable, Codable {
  case week
  case month
  case year
}

struct MovementsByCategories: Equatable, Decodable {
  let category: Category
  let currencyValue: CurrencyValue
  let count: Int
  let children: [MovementsByCategories]
}

struct StatsResult: Equatable, Decodable {
  let periodText: String
  let balance: CurrencyValue
  let count: Int
  let movementsByCategories: [MovementsByCategories]
}

extension StatsResult: Identifiable {
  var id: String {
    periodText
  }
}

struct BalanceAtDate: Equatable, Decodable {
  private let date: Date
  let dateRaw: String
  let balance: CurrencyValue
  
  private enum CodingKeys: String, CodingKey {
    case date, balance
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let dateString = try container.decode(String.self, forKey: .date)
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "YYYY-MM-dd"
    if let date = dateFormatter.date(from: dateString) {
      self.date = date
    } else {
      throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Date string does not match format expected by formatter.")
    }
    
    self.dateRaw = dateString
    self.balance = try container.decode(CurrencyValue.self, forKey: .balance)
  }
}

struct AccountBalanceHistory: Decodable, Identifiable {
  struct Item: Decodable {
    let date: Date
    let original: CurrencyValue?
    let balance: CurrencyValue
  }
  let key: String
  let balances: [Item]
  
  var id: String { key }
}

extension DateFormatter {
  static let iso8601Full: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
  
  static let full: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
  
  static let forString: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM yyyy"
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}
