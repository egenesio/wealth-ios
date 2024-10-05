//
//  CurrencyValueText.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 27/06/24.
//

import SwiftUI

struct CurrencyValueText: View {
  let currencyValue: CurrencyValue
  
  var body: some View {
    Text(currencyValue.value, format: .currency(code: currencyValue.currency.rawValue))
  }
}
