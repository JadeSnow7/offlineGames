import SwiftUI

/// Centralized theme for the app. Uses iOS 26 Liquid Glass design language.
public enum AppTheme {
  /// Primary accent color.
  public static let accentColor = Color.blue

  /// Standard corner radius for glass cards.
  public static let cornerRadius: CGFloat = 20

  /// Standard padding.
  public static let padding: CGFloat = 16

  /// Title font.
  public static let titleFont: Font = .largeTitle.bold()

  /// Body font.
  public static let bodyFont: Font = .body

  /// Caption font.
  public static let captionFont: Font = .caption

  /// Score display font (monospaced for alignment).
  public static let scoreFont: Font = .system(.title, design: .monospaced).bold()
  /// Subtitle font.
  public static let subtitleFont: Font = .title3.weight(.medium)

  /// Dynamic catalog background gradient
  public static let catalogBackground = LinearGradient(
    colors: [
      Color(red: 0.1, green: 0.12, blue: 0.25),
      Color(red: 0.05, green: 0.06, blue: 0.1),
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  /// Standard spring animation for interactive elements
  public static let springAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)

  /// Standard hover/press duration
  public static let hoverDuration: Double = 0.15

  /// Multi-layered shadows for Liquid Glass depth
  public static let ambientShadow = Color.black.opacity(0.15)
  public static let directionalShadow = Color.black.opacity(0.3)

  /// Glass material highlights
  public static let glassHighlight = LinearGradient(
    colors: [.white.opacity(0.4), .clear, .clear, .white.opacity(0.1)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
}
