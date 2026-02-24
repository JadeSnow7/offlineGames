import SwiftUI
import CoreEngine
import GameUI
import GameCatalog

/// Catalog registration for Memory Match.
public struct MemoryMatchDefinition: GameDefinition {
    public init() {}

    public var metadata: GameMetadata {
        GameMetadata(
            id: "memory-match",
            displayName: "game.memoryMatch.name",
            description: "game.memoryMatch.description",
            iconName: "square.on.square",
            accentColor: .purple,
            category: .puzzle
        )
    }

    @MainActor
    public func makeRootView() -> AnyView {
        AnyView(MemoryMatchRootView())
    }
}

private struct MemoryMatchRootView: View {
    var body: some View {
        GameSessionView(
            titleKey: "game.memoryMatch.name",
            gameID: "memory-match",
            initialState: MemoryMatchState(),
            reducer: memoryMatchReducer,
            controls: SessionControlActions(
                start: .start,
                pause: .pause,
                resume: .resume,
                reset: .reset
            )
        ) { state, send in
            MemoryMatchBoardView(state: state, send: send)
        }
    }
}

private struct MemoryMatchBoardView: View {
    let state: MemoryMatchState
    let send: (MemoryMatchAction) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        VStack(spacing: AppTheme.padding) {
            HStack(spacing: 6) {
                GameLocalizedText("game.memoryMatch.moves")
                Text("\(state.moves)")
                    .font(AppTheme.scoreFont)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(state.cards.enumerated()), id: \.element.id) { index, card in
                    Button {
                        send(.flipCard(index: index))
                        Task {
                            try? await Task.sleep(for: .milliseconds(450))
                            send(.checkMatch)
                            send(.hideUnmatched)
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(card.isFaceUp || card.isMatched ? Color.blue.opacity(0.85) : Color.gray.opacity(0.2))
                            .frame(height: 72)
                            .overlay {
                                if card.isFaceUp || card.isMatched {
                                    Text(symbol(for: card.symbolID))
                                        .font(.title2)
                                } else {
                                    Image(systemName: "questionmark")
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(card.isMatched)
                    .accessibilityIdentifier("memory.card.\(card.id)")
                }
            }
        }
    }

    private func symbol(for symbolID: Int) -> String {
        let symbols = ["★", "●", "▲", "■", "◆", "♥", "☀", "☁", "☂", "♫", "✿", "☕"]
        return symbols[symbolID % symbols.count]
    }
}
