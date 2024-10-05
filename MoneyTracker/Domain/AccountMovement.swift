//
//  AccountMovement.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 27/06/24.
//

import Foundation

struct AccountMovement: Decodable, Hashable, Identifiable {
  let id: UUID
  let account: Account
  let category: Category
  let amount: CurrencyValue
  let fees: CurrencyValue
  let balance: CurrencyValue
  let date: Date
  let completionDate: Date
  let description: String
  let note: String?
  let importKey: String
  let createdAt: Date
  let updatedAt: Date
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  static func ==(lhs: AccountMovement, rhs: AccountMovement) -> Bool {
    lhs.id == rhs.id
  }
}

extension AccountMovement {
  enum ImportFileType: String, CaseIterable {
    case revolut
    case zkb
  }

  struct ImportBody: Equatable {
    let fileType: ImportFileType
    let fileURL: URL
    let skipParsingErrors: Bool
    let skipExisting: Bool
    let removeText: String?
  }
}
