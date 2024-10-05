//
//  Network.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 27/06/24.
//

import Foundation

enum NetworkError: Error {
  case badURL, requestFailed, decodingError
  case custom(String)
  
  var networkMessage: String? {
    switch self {
    case .badURL:
      ""
    case .requestFailed:
      ""
    case .decodingError:
      ""
    case .custom(let string):
      string
    }
  }
  
  var localizedDescription: String {
    networkMessage ?? "An Error has ocurred"
  }
}

extension Error {
  var message: String {
    if let network = (self as? NetworkError) {
      return network.networkMessage ?? "Error"
    }
    
    return "Error"
  }
}

struct NetworkRequest {
  let path: String
  let method: String
  let queryItems: [URLQueryItem]
  let body: (any Encodable)?
  let encodedBody: (contentType: String, body: Data)?
  
  private init(
    path: String,
    method: String,
    queryItems: [URLQueryItem],
    body: (any Encodable)? = nil,
    encodedBody: (contentType: String, body: Data)? = nil
  ) {
    self.path = path
    self.method = method
    self.queryItems = queryItems
    self.body = body
    self.encodedBody = encodedBody
  }
  
  static func get(_ path: String, queryItems: [URLQueryItem] = []) -> Self {
    .init(path: path, method: "GET", queryItems: queryItems)
  }
  
  static func post(
    _ path: String,
    queryItems: [URLQueryItem] = [],
    body: (any Encodable)? = nil,
    encodedBody: (contentType: String, body: Data)? = nil
  ) -> Self {
    self.init(
      path: path,
      method: "POST",
      queryItems: queryItems,
      body: body,
      encodedBody: encodedBody
    )
  }
  
  static func put(
    _ path: String,
    queryItems: [URLQueryItem] = [],
    body: (any Encodable)? = nil,
    encodedBody: (contentType: String, body: Data)? = nil
  ) -> Self {
    self.init(
      path: path,
      method: "PUT",
      queryItems: queryItems,
      body: body,
      encodedBody: encodedBody
    )
  }
  
  static func delete(
    _ path: String,
    queryItems: [URLQueryItem] = [],
    body: (any Encodable)? = nil,
    encodedBody: (contentType: String, body: Data)? = nil
  ) -> Self {
    self.init(
      path: path,
      method: "DELETE",
      queryItems: queryItems,
      body: body,
      encodedBody: encodedBody
    )
  }
}

struct Network {
  private let baseURL: String
  private let session: URLSession
  private let jsonDecoder: JSONDecoder
  
  static func defaultJsonDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
  
  init(
//    baseURL: String = "http:/proxyman.debug:8080/",
    baseURL: String = "http:/127.0.0.1:8080/",
    session: URLSession = .shared,
    jsonDecoder: JSONDecoder = Self.defaultJsonDecoder()
  ) {
    self.baseURL = baseURL
    self.session = session
    self.jsonDecoder = jsonDecoder
  }
  
  func request<T>(_ request: NetworkRequest) async throws -> T where T: Decodable {
    guard var url = URL(string: baseURL.appending(request.path)) else {
      throw NetworkError.badURL
    }
    
    url.append(queryItems: request.queryItems)
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = request.method
    
    if let body = request.body {
      urlRequest.httpBody = try JSONEncoder().encode(body)
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw NetworkError.requestFailed
    }
    
    return try jsonDecoder.decode(T.self, from: data)
  }
  
  func dataRequest<T>(_ request: NetworkRequest) async throws -> T where T: Decodable {
    guard var url = URL(string: baseURL.appending(request.path)) else {
      throw NetworkError.badURL
    }
    
    if !request.queryItems.isEmpty {
      url.append(queryItems: request.queryItems)
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = request.method
    
    if let (contentType, body) = request.encodedBody {
      urlRequest.httpBody = body
      urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
    } else if let body = request.body {
      urlRequest.httpBody = try JSONEncoder().encode(body)
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    log(request: request, url: url, urlRequest: urlRequest)
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      if let abort = try? jsonDecoder.decode(NetworkAbort.self, from: data) {
        throw NetworkError.custom(abort.reason)
      }
      
      throw NetworkError.requestFailed
    }
    
    let dataResponse = try jsonDecoder.decode(DataResponse<T>.self, from: data)
    return dataResponse.data
  }
  
  private func log(
    request: NetworkRequest,
    url: URL,
    urlRequest: URLRequest
  ) {
    let body: String = urlRequest.httpBody.map { String(data: $0, encoding: .utf8) ?? "" } ?? ""
    
    print("___ \(request.method) \(url.path()) \(url.query() ?? "" ) \(body)")
  }
}

struct DataResponse<Data>: Decodable where Data: Decodable {
  let data: Data
}

struct NetworkAbort: Decodable {
  let error: Bool
  let reason: String
}
