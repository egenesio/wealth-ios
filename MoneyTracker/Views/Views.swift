//
//  Views.swift
//  MoneyTracker
//
//  Created by Emilio Genesio on 05/08/24.
//

import SwiftUI
import SwiftUIMacros

struct SimpleList<Content: View>: View {
  @ViewBuilder var content: () -> Content
  
  @Environment(\.listColor) var listColor
  
  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(content: content)
        .frame(maxWidth: .infinity)
    }
    .background(listColor)
    .buttonStyle(.plain)
  }
}

struct LazyList<Content: View>: View {
  @ViewBuilder var content: () -> Content
  
  @Environment(\.listColor) var listColor
  
  var body: some View {
    ScrollView(showsIndicators: false) {
      LazyVStack(content: content)
        .frame(maxWidth: .infinity)
    }
    .background(listColor)
    .buttonStyle(.plain)
  }
}

struct ListSection<Content, Header, Footer>: View where Content: View, Header: View, Footer: View {
  @ViewBuilder var content: () -> Content
  @ViewBuilder var header: () -> Header
  @ViewBuilder var footer: () -> Footer
  
  @Environment(\.sectionColor) var sectionColor
  @Environment(\.sectionSpacing) var sectionSpacing
  @Environment(\.sectionAlignment) var sectionAlignment
  @Environment(\.sectionMinHeight) var sectionMinHeight
  
  var alignment: Alignment {
    switch sectionAlignment {
    case .center: .center
    case .leading: .leading
    case .trailing: .trailing
    default: .center
    }
  }
  
  init(
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder header: @escaping () -> Header = { EmptyView() },
    @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
  ) {
    self.content = content
    self.header = header
    self.footer = footer
  }
  
  var body: some View {
    VStack(
      alignment: sectionAlignment,
      spacing: sectionSpacing
    ) {
      header()
      content()
        .frame(minHeight: sectionMinHeight, alignment: alignment)
      footer()
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: alignment)
    .background(sectionColor)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .padding(.horizontal, 10)
  }
}

// MARK: - List
@EnvironmentValues
extension EnvironmentValues {
  var listColor: Color = .backgroundColor
}

extension View {
  func listColor(_ color: Color) -> some View {
    self.environment(\.listColor, color)
  }
}

// MARK: - Section

@EnvironmentValues
extension EnvironmentValues {
  var sectionColor: Color = .white
  var sectionSpacing: CGFloat = .zero
  var sectionAlignment: HorizontalAlignment = .center
  var sectionMinHeight: CGFloat? = nil
}

extension View {
  func sectionColor(_ color: Color) -> some View {
    self.environment(\.sectionColor, color)
  }
  
  func sectionSpacing(_ spacing: CGFloat) -> some View {
    self.environment(\.sectionSpacing, spacing)
  }
  
  func sectionAlignment(_ alignment: HorizontalAlignment) -> some View {
    self.environment(\.sectionAlignment, alignment)
  }
  
  func sectionMinHeight(_ minHeight: CGFloat?) -> some View {
    self.environment(\.sectionMinHeight, minHeight)
  }
}


#Preview {
  VStack {
    ListSection {
      Text("asdf")
      Text("asdf")
    }
    
    ListSection {
      Text("asdf")
      Text("asdf")
    }
    .sectionMinHeight(200)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.gray.opacity(0.2))
}
