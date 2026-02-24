import CoreEngine
import GameCatalog
import GameUI
import SwiftUI

/// Catalog registration for Minesweeper.
public struct MinesweeperDefinition: GameDefinition {
  public init() {}

  public var metadata: GameMetadata {
    GameMetadata(
      id: "minesweeper",
      displayName: "game.minesweeper.name",
      description: "game.minesweeper.description",
      iconName: "flag.pattern.checkered",
      accentColor: .red,
      category: .puzzle
    )
  }

  @MainActor
  public func makeRootView() -> AnyView {
    AnyView(MinesweeperRootView())
  }
}

private struct MinesweeperRootView: View {
  var body: some View {
    GameSessionView(
      titleKey: "game.minesweeper.name",
      gameID: "minesweeper",
      initialState: MinesweeperState(),
      reducer: minesweeperReducer,
      controls: SessionControlActions(
        start: .start,
        pause: .pause,
        resume: .resume,
        reset: .reset
      )
    ) { state, send in
      MinesweeperBoardView(state: state, send: send)
    }
  }
}

private struct MinesweeperBoardView: View {
  let state: MinesweeperState
  let send: (MinesweeperAction) -> Void

  @State private var flagMode = false

  var body: some View {
    VStack(spacing: AppTheme.padding) {
      HStack {
        Button {
          flagMode.toggle()
        } label: {
          Label {
            GameLocalizedText(
              flagMode
                ? "game.minesweeper.controls.revealMode" : "game.minesweeper.controls.flagMode")
          } icon: {
            Image(systemName: flagMode ? "hand.tap" : "flag.fill")
          }
        }
        .buttonStyle(.bordered)

        Spacer()

        HStack(spacing: 6) {
          GameLocalizedText("game.minesweeper.flags")
          Text("\(state.flagCount)")
            .font(AppTheme.scoreFont)
        }
      }

      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: state.cols),
        spacing: 3
      ) {
        ForEach(0..<(state.rows * state.cols), id: \.self) { index in
          let row = index / state.cols
          let col = index % state.cols
          Button {
            if flagMode {
              send(.toggleFlag(row: row, col: col))
            } else {
              send(.reveal(row: row, col: col))
            }
          } label: {
            cellView(state.cells[row][col])
          }
          .buttonStyle(.plain)
          .accessibilityLabel(accessibilityLabel(for: state.cells[row][col]))
        }
      }
      .padding(8)
      .background(Color.black.opacity(0.12))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .accessibilityIdentifier("minesweeper.board")
    }
  }

  @ViewBuilder
  private func cellView(_ cell: Cell) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 4)
        .fill(cell.isRevealed ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15))
        .frame(height: 30)

      if cell.isFlagged {
        Image(systemName: "flag.fill")
          .foregroundStyle(.orange)
      } else if cell.isRevealed && cell.isMine {
        Image(systemName: "burst.fill")
          .foregroundStyle(.red)
      } else if cell.isRevealed && cell.adjacentMines > 0 {
        Text("\(cell.adjacentMines)")
          .font(.subheadline.bold())
          .foregroundStyle(.blue)
      }
    }
  }

  private func accessibilityLabel(for cell: Cell) -> Text {
    if cell.isFlagged {
      return Text("game.minesweeper.cell.flagged", bundle: .gameUI)
    }
    if !cell.isRevealed {
      return Text("game.minesweeper.cell.hidden", bundle: .gameUI)
    }
    if cell.isMine {
      return Text("game.minesweeper.cell.mine", bundle: .gameUI)
    }
    if cell.adjacentMines > 0 {
      return Text("\(cell.adjacentMines)")
    }
    return Text("game.minesweeper.cell.empty", bundle: .gameUI)
  }
}
