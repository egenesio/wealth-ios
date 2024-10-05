//
//  CurrenciesRepository.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 03/08/24.
//

import Dependencies

struct CurrenciesRepository {
  var fetchCurrencies: @Sendable () async throws -> [CurrencyData]
  
  var selectBaseCurrency: @Sendable (Currency) async throws -> [CurrencyData]
}

extension CurrenciesRepository: DependencyKey {
  static var liveValue: CurrenciesRepository = {
    .init(
      fetchCurrencies: {
        try await Task.sleep(for: .seconds(1))
        return [
          .init(currency: .usd, isSelected: false),
          .init(currency: .eur, isSelected: false),
          .init(currency: .gbp, isSelected: false),
          .init(currency: .chf, isSelected: true),
        ]
      },
      
      selectBaseCurrency: { currency in
        try await Task.sleep(for: .seconds(1))
        
        return [
          .init(currency: .usd, isSelected: currency == .usd),
          .init(currency: .eur, isSelected: currency == .eur),
          .init(currency: .gbp, isSelected: currency == .gbp),
          .init(currency: .chf, isSelected: currency == .chf),
        ]
      }
    )
  }()
}

extension DependencyValues {
  var currenciesRepository: CurrenciesRepository {
    get { self[CurrenciesRepository.self] }
    set { self[CurrenciesRepository.self] = newValue }
  }
}
