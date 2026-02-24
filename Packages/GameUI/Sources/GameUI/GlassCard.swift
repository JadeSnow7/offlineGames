import SwiftUI

/// A Liquid Glass card container with frosted glass appearance.
/// Uses iOS 26 glassEffect modifier when available.
public struct GlassCard<Content: View>: View {
  private let content: Content

  public init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  public var body: some View {
    content
      .padding(AppTheme.padding)
      .background(.ultraThinMaterial)
      .overlay(
        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
          .strokeBorder(AppTheme.glassHighlight, lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
      .shadow(color: AppTheme.ambientShadow, radius: 10, x: 0, y: 4)
      .shadow(color: AppTheme.directionalShadow, radius: 20, x: 0, y: 15)
  }
}
