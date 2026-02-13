import SwiftUI

/// A Liquid Glass styled button.
public struct GlassButton: View {
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    public init(_ title: String,
                systemImage: String? = nil,
                action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(AppTheme.bodyFont)
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, AppTheme.padding * 0.5)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}
