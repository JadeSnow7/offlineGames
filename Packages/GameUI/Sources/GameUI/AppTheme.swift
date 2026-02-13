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
}
