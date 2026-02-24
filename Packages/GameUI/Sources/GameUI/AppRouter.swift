import GameCatalog
import SwiftUI

/// The root navigation view of the app.
/// Routes between the game catalog and individual game screens.
public struct AppRouter: View {
  private struct CatalogEntry: Identifiable {
    let definition: any GameDefinition

    var id: String { definition.metadata.id }
    var metadata: GameMetadata { definition.metadata }
  }

  private let registry: GameRegistry

  @AppStorage("settings.languagePreference")
  private var languagePreference: String = AppLanguage.system.rawValue

  @State private var games: [CatalogEntry] = []

  public init(registry: GameRegistry) {
    self.registry = registry
  }

  public var body: some View {
    NavigationStack {
      Group {
        if games.isEmpty {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            LazyVGrid(
              columns: [
                GridItem(.adaptive(minimum: 300, maximum: .infinity), spacing: AppTheme.padding)
              ], spacing: AppTheme.padding
            ) {
              ForEach(games) { entry in
                NavigationLink(value: entry.id) {
                  catalogRow(for: entry)
                }
                .buttonStyle(CatalogCardStyle())
                .accessibilityIdentifier("catalog.row.\(entry.id)")
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
              }
            }
            .padding(AppTheme.padding)
          }
          .background(AppTheme.catalogBackground.ignoresSafeArea())
        }
      }
      .navigationTitle(Text("navigation.games.title", bundle: .module))
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Menu {
            languageButton(.system, labelKey: "language.option.system")
            languageButton(.en, labelKey: "language.option.english")
            languageButton(.zhHans, labelKey: "language.option.zhHans")
          } label: {
            Label {
              Text("language.menu.title", bundle: .module)
            } icon: {
              Image(systemName: "globe")
            }
          }
          .accessibilityIdentifier("language.menu")
        }
      }
      .navigationDestination(for: String.self) { id in
        if let entry = games.first(where: { $0.id == id }) {
          entry.definition.makeRootView()
            .navigationTitle(Text(LocalizedStringKey(entry.metadata.displayName), bundle: .module))
        } else {
          GameLocalizedText("catalog.gameUnavailable")
            .font(AppTheme.bodyFont)
            .padding()
        }
      }
    }
    .task {
      await loadGamesIfNeeded()
    }
  }

  @ViewBuilder
  private func catalogRow(for entry: CatalogEntry) -> some View {
    GlassCard {
      HStack(spacing: AppTheme.padding) {
        Image(systemName: entry.metadata.iconName)
          .font(.title)
          .foregroundStyle(entry.metadata.accentColor)
          .frame(width: 48, height: 48)
          .background(entry.metadata.accentColor.opacity(0.15))
          .clipShape(Circle())

        VStack(alignment: .leading, spacing: 6) {
          Text(LocalizedStringKey(entry.metadata.displayName), bundle: .module)
            .font(AppTheme.subtitleFont)
            .foregroundStyle(.primary)
          Text(LocalizedStringKey(entry.metadata.description), bundle: .module)
            .font(AppTheme.captionFont)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
    }
  }

  @ViewBuilder
  private func languageButton(_ language: AppLanguage, labelKey: LocalizedStringKey) -> some View {
    Button {
      languagePreference = language.rawValue
    } label: {
      HStack {
        Text(labelKey, bundle: .module)
        if selectedLanguage == language {
          Image(systemName: "checkmark")
        }
      }
    }
  }

  private var selectedLanguage: AppLanguage {
    AppLanguage(rawValue: languagePreference) ?? .system
  }

  private func loadGamesIfNeeded() async {
    guard games.isEmpty else { return }
    let definitions = await registry.allGames()
    await MainActor.run {
      games = definitions.map(CatalogEntry.init(definition:))
    }
  }
}

private struct CatalogCardStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
      .animation(AppTheme.springAnimation, value: configuration.isPressed)
  }
}
