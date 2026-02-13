import SwiftUI

/// The root navigation view of the app.
/// Routes between the game catalog and individual game screens.
public struct AppRouter: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            Text("Offline Games")
                .font(AppTheme.titleFont)
                .navigationTitle("Games")
        }
    }
}
