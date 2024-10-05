//
//  Page.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 11/08/24.
//

import Foundation

struct Page<T: Decodable>: Decodable {
  struct Metadata: Decodable {
    let page: Int
    let per: Int
    let total: Int
    let pageCount: Int
  }
  
  let items: [T]
  let metadata: Metadata
}
