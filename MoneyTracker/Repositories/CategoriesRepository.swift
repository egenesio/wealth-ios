//
//  CategoriesRepository.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 25/06/24.
//

import Dependencies

struct CategoriesRepository {
  var fetchCategories: @Sendable () async throws -> [Category]
  
  var createCategory: @Sendable (
    _ body: CategoryBody
  ) async throws -> Category
  
  var updateCategory: @Sendable (
    _ categoryID: Category.ID,
    _ body: CategoryBody
  ) async throws -> Category
}

extension CategoriesRepository: DependencyKey {
  static var liveValue: Self = {
    let network: Network = .init()
    
    return .init(
      fetchCategories: {
        try await network.dataRequest(.get("categories"))
      },
      createCategory: { body in
        try await network.dataRequest(.post("categories", body: body))
      },
      updateCategory: { categoryID, body in
        try await network.dataRequest(.put("categories/\(categoryID)", body: body))
      }
    )
  }()
}

extension DependencyValues {
  var categoriesRepository: CategoriesRepository {
    get { self[CategoriesRepository.self] }
    set { self[CategoriesRepository.self] = newValue }
  }
}
