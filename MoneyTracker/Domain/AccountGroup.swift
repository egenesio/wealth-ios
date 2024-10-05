//
//  AccountGroup.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 10/08/24.
//

import Foundation

struct AccountGroup: Decodable, Identifiable, Sendable, Hashable {
  let id: UUID
  let name: String
  let description: String?
  let order: Int
}

extension AccountGroup {
  struct Body: Encodable {
    let name: String
    let description: String?
    let order: Int
  }
}

extension Collection where Element == AccountGroup {
  func ordered() -> [Element] {
    sorted(by: { $0.order < $1.order })
  }
}
