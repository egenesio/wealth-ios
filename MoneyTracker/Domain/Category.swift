//
//  Category.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 27/06/24.
//

import Foundation

struct Category: Decodable, Hashable, Identifiable {
  let id: UUID
  let name: String
  let icon: String
  let backgroundColor: String
  let isDefault: Bool
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

struct CategoryBody: Encodable, Equatable {
  var name: String
  var icon: String
  var backgroundColor: String
}
