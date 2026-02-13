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
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}
