import CoreEngine
import GameCatalog
import GameUI
import SwiftUI

/// Catalog registration for Block Puzzle.
public struct BlockPuzzleDefinition: GameDefinition {
  public init() {}

  public var metadata: GameMetadata {
    GameMetadata(
      id: "block-puzzle",
      displayName: "game.blockPuzzle.name",
      description: "game.blockPuzzle.description",
      iconName: "square.grid.3x2.fill",
      accentColor: .orange,
      category: .puzzle
    )
  }

  @MainActor
  public func makeRootView() -> AnyView {
    AnyView(BlockPuzzleRootView())
  }
}

private struct BlockPuzzleRootView: View {
  var body: some View {
    GameSessionView(
      titleKey: "game.blockPuzzle.name",
      gameID: "block-puzzle",
      initialState: BlockPuzzleState(),
      reducer: blockPuzzleReducer,
      controls: SessionControlActions(
        start: .start,
        pause: .pause,
        resume: .resume,
        reset: .reset
      ),
      tick: TickConfiguration(tickRate: 3.5) { _ in .tick }
    ) { state, send in
      BlockPuzzleBoardView(state: state, send: send)
    }
  }
}

private struct BlockPuzzleBoardView: View {
  let state: BlockPuzzleState
  let send: (BlockPuzzleAction) -> Void

  var body: some View {
    VStack(spacing: AppTheme.padding) {
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: state.gridWidth),
        spacing: 1
      ) {
        ForEach(0..<(state.gridHeight * state.gridWidth), id: \.self) { index in
          let row = index / state.gridWidth
          let col = index % state.gridWidth
          RoundedRectangle(cornerRadius: 1)
            .fill(colorForCell(row: row, col: col))
            .frame(height: 11)
        }
      }
      .padding(8)
      .background(Color.black.opacity(0.12))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .accessibilityIdentifier("blockPuzzle.board")

      HStack(spacing: 8) {
        controlButton("game.blockPuzzle.controls.left", icon: "arrow.left") {
          send(.moveLeft)
        }

        controlButton("game.blockPuzzle.controls.right", icon: "arrow.right") {
          send(.moveRight)
        }

        controlButton("game.blockPuzzle.controls.rotate", icon: "rotate.right") {
          send(.rotate)
        }
      }

      HStack(spacing: 8) {
        controlButton("game.blockPuzzle.controls.softDrop", icon: "arrow.down") {
          send(.softDrop)
        }

        controlButton("game.blockPuzzle.controls.hardDrop", icon: "arrow.down.to.line") {
          send(.hardDrop)
        }
      }
    }
  }

  @ViewBuilder
  private func controlButton(_ key: String, icon: String, action: @escaping () -> Void) -> some View
  {
    Button(action: action) {
      Label {
        GameLocalizedText(key)
      } icon: {
        Image(systemName: icon)
      }
    }
    .buttonStyle(.bordered)
  }

  private func colorForCell(row: Int, col: Int) -> Color {
    if let piece = state.currentPiece,
      isCell(row: row, col: col, occupiedBy: piece)
    {
      return color(for: piece.colorIndex).opacity(0.95)
    }

    let value = state.grid[row][col]
    if value == 0 {
      return .gray.opacity(0.2)
    }

    return color(for: value)
  }

  private func isCell(row: Int, col: Int, occupiedBy piece: Piece) -> Bool {
    for cell in piece.cells {
      if piece.x + cell.dx == col && piece.y + cell.dy == row {
        return true
      }
    }
    return false
  }

  private func color(for index: Int) -> Color {
    switch index {
    case 1:
      return .cyan
    case 2:
      return .orange
    case 3:
      return .blue
    case 4:
      return .yellow
    case 5:
      return .green
    case 6:
      return .red
    case 7:
      return .purple
    default:
      return .white
    }
  }
}
