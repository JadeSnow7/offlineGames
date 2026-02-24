import CoreEngine
import GameCatalog
import GameUI
import SwiftUI

/// Catalog registration for Snake.
public struct SnakeDefinition: GameDefinition {
  public init() {}

  public var metadata: GameMetadata {
    GameMetadata(
      id: "snake",
      displayName: "game.snake.name",
      description: "game.snake.description",
      iconName: "arrow.trianglehead.2.clockwise.rotate.90",
      accentColor: .green,
      category: .classic
    )
  }

  @MainActor
  public func makeRootView() -> AnyView {
    AnyView(SnakeRootView())
  }
}

private struct SnakeRootView: View {
  var body: some View {
    GameSessionView(
      titleKey: "game.snake.name",
      gameID: "snake",
      initialState: SnakeState(),
      reducer: snakeReducer,
      controls: SessionControlActions(
        start: .start,
        pause: .pause,
        resume: .resume,
        reset: .reset
      ),
      tick: TickConfiguration(tickRate: 7) { _ in .tick }
    ) { state, send in
      SnakeBoardView(state: state, send: send)
    }
  }
}

private struct SnakeBoardView: View {
  let state: SnakeState
  let send: (SnakeAction) -> Void

  private var occupied: Set<GridPosition> {
    Set(state.segments)
  }

  private var head: GridPosition? {
    state.segments.first
  }

  var body: some View {
    VStack(spacing: AppTheme.padding) {
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: state.gridWidth),
        spacing: 2
      ) {
        ForEach(0..<(state.gridHeight * state.gridWidth), id: \.self) { index in
          let y = index / state.gridWidth
          let x = index % state.gridWidth
          RoundedRectangle(cornerRadius: 2)
            .fill(colorFor(x: x, y: y))
            .frame(height: 12)
        }
      }
      .padding(8)
      .background(Color.black.opacity(0.12))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .accessibilityIdentifier("snake.board")

      controlPad
    }
  }

  private var controlPad: some View {
    VStack(spacing: 8) {
      Button {
        send(.changeDirection(.up))
      } label: {
        Label {
          GameLocalizedText("game.snake.controls.up")
        } icon: {
          Image(systemName: "arrow.up")
        }
      }
      .buttonStyle(.bordered)

      HStack(spacing: 8) {
        Button {
          send(.changeDirection(.left))
        } label: {
          Label {
            GameLocalizedText("game.snake.controls.left")
          } icon: {
            Image(systemName: "arrow.left")
          }
        }
        .buttonStyle(.bordered)

        Button {
          send(.changeDirection(.down))
        } label: {
          Label {
            GameLocalizedText("game.snake.controls.down")
          } icon: {
            Image(systemName: "arrow.down")
          }
        }
        .buttonStyle(.bordered)

        Button {
          send(.changeDirection(.right))
        } label: {
          Label {
            GameLocalizedText("game.snake.controls.right")
          } icon: {
            Image(systemName: "arrow.right")
          }
        }
        .buttonStyle(.bordered)
      }
    }
  }

  private func colorFor(x: Int, y: Int) -> Color {
    let position = GridPosition(x: x, y: y)
    if position == head {
      return .green
    }
    if occupied.contains(position) {
      return .green.opacity(0.7)
    }
    if state.food == position {
      return .red
    }
    return .gray.opacity(0.2)
  }
}
