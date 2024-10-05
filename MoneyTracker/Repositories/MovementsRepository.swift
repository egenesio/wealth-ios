//
//  AccountGroupsRepository.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 10/08/24.
//

import Foundation
import Dependencies

struct MovementsRepository {
  var fetchMovements: @Sendable (
    _ page: Int
  ) async throws -> Page<AccountMovement>
  
  var fetchMovementsByAccount: @Sendable (
    _ accountID: Account.ID,
    _ page: Int
  ) async throws -> Page<AccountMovement>
  
  var importMovements: @Sendable (
    _ accountID: Account.ID,
    _ body: AccountMovement.ImportBody
  ) async throws -> Page<AccountMovement>
  
  var setCategory: @Sendable (
    _ movementID: AccountMovement.ID,
    _ categoryID: Category.ID
  ) async throws -> AccountMovement
}

extension MovementsRepository: DependencyKey {
  static let liveValue: Self = {
    let network: Network = .init()
    let per = 30
    
    return .init(
      fetchMovements: { page in
        try await network.dataRequest(.get("movements", queryItems: [
          .init(name: "page", value: page.description),
          .init(name: "per", value: per.description),
        ]))
      },
      
      fetchMovementsByAccount: { accountID, page in
        try await network.dataRequest(.get("movements", queryItems: [
          .init(name: "page", value: page.description),
          .init(name: "per", value: per.description),
          .init(name: "accountID", value: accountID.uuidString)
        ]))
      },
      
      importMovements: { accountID, body in
        let boundary = UUID().uuidString
        guard let data = dataFrom(body: body, boundary: boundary) else {
          throw NetworkError.decodingError
        }
        
        return try await network.dataRequest(
          .post(
            "movements/\(accountID)/import",
            encodedBody: (
              contentType: "multipart/form-data; boundary=\(boundary)",
              body: data
            )
          )
        )
      },
      
      setCategory: { movementID, categoryID in
        struct Body: Encodable {
          let categoryID: Category.ID
        }
        
        return try await network.dataRequest(
          .put(
            "movements/\(movementID)/category",
            body: Body(categoryID: categoryID)
          )
        )
      }
    )
  }()
}

private func dataFrom(
  body inputBody: AccountMovement.ImportBody,
  boundary: String
) -> Data? {
  guard let fileData = try? Data(contentsOf: inputBody.fileURL)
  else {
    return nil
  }
  
  var body = Data()
  let fileName = inputBody.fileURL.lastPathComponent
  
  body.append("--\(boundary)\r\n".data(using: .utf8)!)
  body.append("Content-Disposition: form-data; name=\"records[]\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
  body.append("Content-Type: text/csv\r\n\r\n".data(using: .utf8)!)
  body.append(fileData)
  body.append("\r\n".data(using: .utf8)!)
  
  // Adding the fileType part
  body.append("--\(boundary)\r\n".data(using: .utf8)!)
  body.append("Content-Disposition: form-data; name=\"fileType\"\r\n\r\n".data(using: .utf8)!)
  body.append("\(inputBody.fileType)\r\n".data(using: .utf8)!)
  
  // Adding the skipParsingErrors part
  body.append("--\(boundary)\r\n".data(using: .utf8)!)
  body.append("Content-Disposition: form-data; name=\"skipParsingErrors\"\r\n\r\n".data(using: .utf8)!)
  body.append("\(inputBody.skipParsingErrors)\r\n".data(using: .utf8)!)
  
  // Adding the skipExisting part
  body.append("--\(boundary)\r\n".data(using: .utf8)!)
  body.append("Content-Disposition: form-data; name=\"skipExisting\"\r\n\r\n".data(using: .utf8)!)
  body.append("\(inputBody.skipExisting)\r\n".data(using: .utf8)!)
  
  if let removeText = inputBody.removeText {
    // Adding the skipFromDescription part
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"removeText\"\r\n\r\n".data(using: .utf8)!)
    body.append("\(removeText)\r\n".data(using: .utf8)!)
  }
  body.append("--\(boundary)--\r\n".data(using: .utf8)!)
  
  return body
}

extension DependencyValues {
  var movementsRepository: MovementsRepository {
    get { self[MovementsRepository.self] }
    set { self[MovementsRepository.self] = newValue }
  }
}
