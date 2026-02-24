import SwiftUI
import Foundation
import CoreEngine
import GameUI
import GameCatalog

/// Catalog registration for Reaction Tap.
public struct ReactionTapDefinition: GameDefinition {
    public init() {}

    public var metadata: GameMetadata {
        GameMetadata(
            id: "reaction-tap",
            displayName: "game.reactionTap.name",
            description: "game.reactionTap.description",
            iconName: "hand.tap.fill",
            accentColor: .teal,
            category: .reflex
        )
    }

    @MainActor
    public func makeRootView() -> AnyView {
        AnyView(ReactionTapRootView())
    }
}

private struct ReactionTapRootView: View {
    var body: some View {
        GameSessionView(
            titleKey: "game.reactionTap.name",
            gameID: "reaction-tap",
            initialState: ReactionTapState(),
            reducer: reactionTapReducer,
            controls: SessionControlActions(
                start: .start,
                pause: .pause,
                resume: .resume,
                reset: .reset
            )
        ) { state, send in
            ReactionTapBoardView(state: state, send: send)
        }
    }
}

private struct ReactionTapBoardView: View {
    let state: ReactionTapState
    let send: (ReactionTapAction) -> Void

    @State private var stimulusTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: AppTheme.padding) {
            HStack {
                GameLocalizedText("game.reactionTap.round")
                Text("\(state.currentRound)/\(state.totalRounds)")
                    .font(AppTheme.scoreFont)
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(phaseColor)
                .frame(height: 240)
                .overlay {
                    VStack(spacing: 8) {
                        GameLocalizedText(phaseTextKey)
                            .multilineTextAlignment(.center)
                            .font(.headline)

                        if case let .result(reactionTime) = state.phase {
                            Text(String(format: "%.3fs", reactionTime))
                                .font(AppTheme.scoreFont)
                        }
                    }
                    .padding()
                }
                .accessibilityIdentifier("reactionTap.panel")
                .onTapGesture {
                    handlePrimaryTap()
                }

            Button {
                handlePrimaryTap()
            } label: {
                Label {
                    GameLocalizedText(primaryButtonKey)
                } icon: {
                    Image(systemName: primaryButtonIcon)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onChange(of: state.phase) { _, newPhase in
            scheduleStimulusIfNeeded(for: newPhase)
        }
        .onDisappear {
            stimulusTask?.cancel()
            stimulusTask = nil
        }
    }

    private var phaseColor: Color {
        switch state.phase {
        case .waiting, .ready:
            return .orange.opacity(0.45)
        case .stimulus:
            return .green.opacity(0.65)
        case .tooEarly:
            return .red.opacity(0.65)
        case .result:
            return .blue.opacity(0.55)
        case .finished:
            return .purple.opacity(0.55)
        }
    }

    private var phaseTextKey: String {
        switch state.phase {
        case .waiting:
            return "game.reactionTap.phase.waiting"
        case .ready:
            return "game.reactionTap.phase.ready"
        case .stimulus:
            return "game.reactionTap.phase.stimulus"
        case .tooEarly:
            return "game.reactionTap.phase.tooEarly"
        case .result:
            return "game.reactionTap.phase.result"
        case .finished:
            return "game.reactionTap.phase.finished"
        }
    }

    private var primaryButtonKey: String {
        switch state.phase {
        case .waiting:
            return "game.reactionTap.controls.start"
        case .ready, .stimulus:
            return "game.reactionTap.controls.tap"
        case .tooEarly, .result:
            return "game.reactionTap.controls.next"
        case .finished:
            return "game.reactionTap.controls.restart"
        }
    }

    private var primaryButtonIcon: String {
        switch state.phase {
        case .waiting:
            return "play.fill"
        case .ready, .stimulus:
            return "hand.tap"
        case .tooEarly, .result:
            return "arrow.right"
        case .finished:
            return "gobackward"
        }
    }

    private func handlePrimaryTap() {
        switch state.phase {
        case .waiting:
            send(.start)
        case .ready, .stimulus:
            send(.tap(at: .now))
        case .tooEarly, .result:
            send(.nextRound)
        case .finished:
            send(.start)
        }
    }

    private func scheduleStimulusIfNeeded(for phase: ReactionTapState.Phase) {
        stimulusTask?.cancel()
        stimulusTask = nil

        guard phase == .ready, state.isRunning else { return }

        let delay = Double.random(in: 1.0...2.7)
        stimulusTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            send(.showStimulus)
        }
    }
}
