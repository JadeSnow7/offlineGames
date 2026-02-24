import CoreEngine
import Foundation
import SwiftUI

/// Localized text helper that always resolves from the GameUI resource bundle.
public struct GameLocalizedText: View {
  private let key: LocalizedStringKey

  public init(_ key: String) {
    self.key = LocalizedStringKey(key)
  }

  public var body: some View {
    Text(key, bundle: .module)
  }
}

/// Standardized container for all game sessions.
///
/// It owns the store lifecycle, score header, pause/resume/reset controls,
/// and a common game-over experience.
public struct GameSessionView<SessionState: GameState, Action: Sendable, Content: View>: View {
  private let titleKey: String
  private let controls: SessionControlActions<Action>
  private let tick: TickConfiguration<Action>?
  private let content: (SessionState, @escaping (Action) -> Void) -> Content

  @Environment(\.dismiss) private var dismiss

  @State private var store: StateStore<SessionState, Action>
  @State private var highScoreStore: HighScoreStore
  @State private var sessionState: SessionState
  @State private var highScore: Int = 0
  @State private var tickTask: Task<Void, Never>?
  @State private var hasInitialized = false
  @State private var didRecordCurrentGameOver = false

  @AppStorage("settings.sound") private var soundEnabled: Bool = true
  @AppStorage("settings.haptics") private var hapticsEnabled: Bool = true

  public init(
    titleKey: String,
    gameID: String,
    initialState: SessionState,
    reducer: @escaping Reduce<SessionState, Action>,
    controls: SessionControlActions<Action>,
    tick: TickConfiguration<Action>? = nil,
    @ViewBuilder content: @escaping (SessionState, @escaping (Action) -> Void) -> Content
  ) {
    self.titleKey = titleKey
    self.controls = controls
    self.tick = tick
    self.content = content

    _store = State(initialValue: StateStore(initialState: initialState, reducer: reducer))
    _highScoreStore = State(
      initialValue: HighScoreStore(gameID: HighScoreKey.session(gameID: gameID)))
    _sessionState = State(initialValue: initialState)
  }

  public var body: some View {
    VStack(spacing: AppTheme.padding) {
      header
      content(sessionState, dispatch)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("game.session.content")
    }
    .padding(AppTheme.padding)
    .navigationBarBackButtonHidden(true)
    .task {
      guard !hasInitialized else { return }
      hasInitialized = true
      await send(controls.start)
      await loadHighScore()
      startTickLoopIfNeeded()
    }
    .onDisappear {
      tickTask?.cancel()
      tickTask = nil
    }
    .overlay {
      if sessionState.isGameOver {
        gameOverOverlay
      }
    }
  }

  private var header: some View {
    GlassCard {
      HStack(alignment: .top, spacing: AppTheme.padding) {
        VStack(alignment: .leading, spacing: 6) {
          GameLocalizedText(titleKey)
            .font(.headline)
          HStack(spacing: 6) {
            GameLocalizedText("session.score")
            Text("\(sessionState.score)")
              .font(AppTheme.scoreFont)
          }
          .accessibilityLabel(Text("session.score", bundle: .module))
          HStack(spacing: 6) {
            GameLocalizedText("session.best")
            Text("\(highScore)")
              .font(AppTheme.scoreFont)
          }
          .accessibilityLabel(Text("session.best", bundle: .module))
        }

        Spacer(minLength: AppTheme.padding)

        HStack(spacing: 10) {
          Button {
            toggleRunningState()
          } label: {
            Image(systemName: sessionState.isRunning ? "pause.fill" : "play.fill")
          }
          .accessibilityLabel(
            sessionState.isRunning
              ? Text("session.pause", bundle: .module)
              : Text("session.resume", bundle: .module)
          )

          Button {
            restart()
          } label: {
            Image(systemName: "arrow.clockwise")
          }
          .accessibilityLabel(Text("session.restart", bundle: .module))

          Menu {
            Button {
              soundEnabled.toggle()
            } label: {
              HStack {
                GameLocalizedText("session.settings.sound")
                Spacer()
                if soundEnabled {
                  Image(systemName: "checkmark")
                }
              }
            }

            Button {
              hapticsEnabled.toggle()
            } label: {
              HStack {
                GameLocalizedText("session.settings.haptics")
                Spacer()
                if hapticsEnabled {
                  Image(systemName: "checkmark")
                }
              }
            }
          } label: {
            Image(systemName: "switch.2")
          }
          .accessibilityLabel(Text("session.settings.title", bundle: .module))

          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle.fill")
          }
          .accessibilityLabel(Text("session.exit", bundle: .module))
        }
        .buttonStyle(.borderless)
        .font(.title3.weight(.semibold))
      }
    }
  }

  private var gameOverOverlay: some View {
    ZStack {
      Color.black.opacity(0.35)
        .ignoresSafeArea()

      GlassCard {
        VStack(spacing: AppTheme.padding) {
          GameLocalizedText("session.gameOver.title")
            .font(.title3.bold())

          HStack(spacing: 6) {
            GameLocalizedText("session.gameOver.score")
            Text("\(sessionState.score)")
              .font(AppTheme.scoreFont)
          }

          HStack(spacing: 6) {
            GameLocalizedText("session.gameOver.best")
            Text("\(highScore)")
              .font(AppTheme.scoreFont)
          }

          HStack(spacing: AppTheme.padding) {
            GlassButton("session.gameOver.playAgain", systemImage: "gobackward") {
              restart()
            }

            GlassButton("session.gameOver.backToGames", systemImage: "list.bullet") {
              dismiss()
            }
          }
        }
        .padding(.vertical, AppTheme.padding)
      }
      .frame(maxWidth: 360)
      .padding(.horizontal, AppTheme.padding)
    }
  }

  private func restart() {
    Task {
      await send(controls.reset)
      await send(controls.start)
    }
  }

  private func toggleRunningState() {
    if sessionState.isRunning {
      dispatch(controls.pause)
      return
    }

    if sessionState.isGameOver {
      restart()
      return
    }

    dispatch(controls.resume)
  }

  private func startTickLoopIfNeeded() {
    guard let tick else { return }
    guard tickTask == nil else { return }

    tickTask = Task {
      let interval = max(1.0 / tick.tickRate, 0.01)
      var lastTime = CFAbsoluteTimeGetCurrent()

      while !Task.isCancelled {
        let now = CFAbsoluteTimeGetCurrent()
        let delta = max(0, now - lastTime)
        lastTime = now

        await send(tick.makeAction(delta))
        try? await Task.sleep(for: .seconds(interval))
      }
    }
  }

  private func dispatch(_ action: Action) {
    Task {
      await send(action)
    }
  }

  private func send(_ action: Action) async {
    let newState = await store.send(action)
    await MainActor.run {
      let wasGameOver = sessionState.isGameOver
      sessionState = newState

      if newState.isGameOver && !wasGameOver && !didRecordCurrentGameOver {
        didRecordCurrentGameOver = true
        Task {
          await recordHighScore(score: newState.score)
        }
      }

      if !newState.isGameOver {
        didRecordCurrentGameOver = false
      }
    }
  }

  private func loadHighScore() async {
    let topScore = await highScoreStore.topScores(limit: 1).first?.score ?? 0
    await MainActor.run {
      highScore = topScore
    }
  }

  private func recordHighScore(score: Int) async {
    _ = await highScoreStore.record(score: score)
    await loadHighScore()
  }
}
