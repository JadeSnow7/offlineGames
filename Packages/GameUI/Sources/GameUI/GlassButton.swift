import SwiftUI

/// A Liquid Glass styled button.
public struct GlassButton: View {
  private let titleKey: LocalizedStringKey
  private let systemImage: String?
  private let action: () -> Void

  public init(
    _ title: String,
    systemImage: String? = nil,
    action: @escaping () -> Void
  ) {
    self.titleKey = LocalizedStringKey(title)
    self.systemImage = systemImage
    self.action = action
  }

  public init(
    localizedKey: LocalizedStringKey,
    systemImage: String? = nil,
    action: @escaping () -> Void
  ) {
    self.titleKey = localizedKey
    self.systemImage = systemImage
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack {
        if let systemImage {
          Image(systemName: systemImage)
        }
        Text(titleKey, bundle: .module)
          .font(AppTheme.bodyFont)
      }
      .padding(.horizontal, AppTheme.padding)
      .padding(.vertical, AppTheme.padding * 0.5)
      .background(.ultraThinMaterial)
      .overlay(
        Capsule()
          .strokeBorder(AppTheme.glassHighlight, lineWidth: 1)
      )
      .clipShape(Capsule())
      .shadow(color: AppTheme.ambientShadow, radius: 5, x: 0, y: 2)
      .shadow(color: AppTheme.directionalShadow, radius: 10, x: 0, y: 6)
    }
    .buttonStyle(GlassButtonStyle())
  }
}

private struct GlassButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
      .animation(AppTheme.springAnimation, value: configuration.isPressed)
  }
}
