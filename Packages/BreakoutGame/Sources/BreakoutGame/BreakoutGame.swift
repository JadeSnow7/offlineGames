import SwiftUI
import CoreEngine
import GameUI
import GameCatalog

/// Catalog registration for Breakout.
public struct BreakoutDefinition: GameDefinition {
    public init() {}

    public var metadata: GameMetadata {
        GameMetadata(
            id: "breakout",
            displayName: "game.breakout.name",
            description: "game.breakout.description",
            iconName: "circle.grid.cross",
            accentColor: .mint,
            category: .action
        )
    }

    @MainActor
    public func makeRootView() -> AnyView {
        AnyView(BreakoutRootView())
    }
}

private struct BreakoutRootView: View {
    var body: some View {
        GameSessionView(
            titleKey: "game.breakout.name",
            gameID: "breakout",
            initialState: BreakoutState(),
            reducer: breakoutReducer,
            controls: SessionControlActions(
                start: .start,
                pause: .pause,
                resume: .resume,
                reset: .reset
            ),
            tick: TickConfiguration(tickRate: 60) { dt in
                .tick(deltaTime: dt)
            }
        ) { state, send in
            BreakoutBoardView(state: state, send: send)
        }
    }
}

private struct BreakoutBoardView: View {
    let state: BreakoutState
    let send: (BreakoutAction) -> Void

    private let brickCols: Int = 8
    private let brickGap: CGFloat = 0.008
    private let brickTop: CGFloat = 0.08
    private let brickHeight: CGFloat = 0.05
    private let paddleWidth: CGFloat = 0.22
    private let paddleHeight: CGFloat = 0.03
    private let paddleY: CGFloat = 0.92
    private let ballRadius: CGFloat = 0.015

    var body: some View {
        VStack(spacing: AppTheme.padding) {
            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.16))

                    ForEach(state.bricks) { brick in
                        brickView(brick, in: proxy.size)
                    }

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                        .frame(width: proxy.size.width * paddleWidth,
                               height: proxy.size.height * paddleHeight)
                        .position(
                            x: CGFloat(state.paddleX) * proxy.size.width,
                            y: paddleY * proxy.size.height
                        )

                    Circle()
                        .fill(Color.white)
                        .frame(width: proxy.size.width * ballRadius * 2,
                               height: proxy.size.width * ballRadius * 2)
                        .position(
                            x: CGFloat(state.ball.x) * proxy.size.width,
                            y: CGFloat(state.ball.y) * proxy.size.height
                        )
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let normalizedX = max(0, min(1, value.location.x / proxy.size.width))
                            send(.movePaddle(x: Float(normalizedX)))
                        }
                )
            }
            .aspectRatio(1, contentMode: .fit)
            .accessibilityIdentifier("breakout.board")

            HStack(spacing: AppTheme.padding) {
                HStack(spacing: 6) {
                    GameLocalizedText("game.breakout.lives")
                    Text("\(state.lives)")
                        .font(AppTheme.scoreFont)
                }

                Spacer()

                Button {
                    send(.launch)
                } label: {
                    Label {
                        GameLocalizedText("game.breakout.controls.launch")
                    } icon: {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.isBallLaunched || state.isGameOver)
            }
        }
    }

    @ViewBuilder
    private func brickView(_ brick: Brick, in size: CGSize) -> some View {
        let width = (1 - brickGap * CGFloat(brickCols + 1)) / CGFloat(brickCols)
        let x = brickGap + CGFloat(brick.col) * (width + brickGap)
        let y = brickTop + CGFloat(brick.row) * (brickHeight + brickGap)

        RoundedRectangle(cornerRadius: 4)
            .fill(Color.orange)
            .frame(width: size.width * width, height: size.height * brickHeight)
            .position(
                x: (x + width / 2) * size.width,
                y: (y + brickHeight / 2) * size.height
            )
    }
}
