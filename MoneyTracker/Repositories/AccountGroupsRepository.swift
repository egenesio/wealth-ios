//
//  AccountGroupsRepository.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 10/08/24.
//

import Dependencies

struct AccountGroupsRepository {
  var fetchGroups: @Sendable () async throws -> [AccountGroup]
  
  var createGroup: @Sendable (AccountGroup.Body) async throws -> AccountGroup
  var updateGroup: @Sendable (AccountGroup.ID, AccountGroup.Body) async throws -> AccountGroup
  var deleteGroup: @Sendable (AccountGroup.ID) async throws -> Bool
}

extension AccountGroupsRepository: DependencyKey {
  static let liveValue: Self = {
    let network: Network = .init()
    
    return .init(
      fetchGroups: {
        try await network.dataRequest(.get("account-groups"))
      },
      createGroup: { body in
        try await network.dataRequest(.post("account-groups", body: body))
      },
      updateGroup: { id, body in
        try await network.dataRequest(.put("account-groups/\(id)", body: body))
      },
      deleteGroup: { id in
        try await network.dataRequest(.delete("account-groups/\(id)"))
      }
    )
  }()
}

extension DependencyValues {
  var accountGroupsRepository: AccountGroupsRepository {
    get { self[AccountGroupsRepository.self] }
    set { self[AccountGroupsRepository.self] = newValue }
  }
}
