import CoreEngine
import GameCatalog
import GameUI
import SwiftUI

/// Catalog registration for Card Duel.
public struct CardDuelDefinition: GameDefinition {
  public init() {}

  public var metadata: GameMetadata {
    GameMetadata(
      id: "card-duel",
      displayName: "game.cardDuel.name",
      description: "game.cardDuel.description",
      iconName: "rectangle.on.rectangle",
      accentColor: .indigo,
      category: .puzzle
    )
  }

  @MainActor
  public func makeRootView() -> AnyView {
    AnyView(CardDuelRootView())
  }
}

private struct CardDuelRootView: View {
  var body: some View {
    GameSessionView(
      titleKey: "game.cardDuel.name",
      gameID: "card-duel",
      initialState: CardDuelState(),
      reducer: cardDuelReducer,
      controls: SessionControlActions(
        start: .start,
        pause: .pause,
        resume: .resume,
        reset: .reset
      )
    ) { state, send in
      CardDuelBoardView(state: state, send: send)
    }
  }
}

// MARK: - Theme

private struct CardDuelTheme {
  static let background = Color(hex: "1E1E2F")
  static let health = Color(hex: "EF5350")
  static let energy = Color(hex: "29B6F6")
  static let action = Color(hex: "66BB6A")
  static let panel = Color.black.opacity(0.30)
  static let cardDark = Color(hex: "2A2A3D")
}

// MARK: - Board View

private struct CardDuelBoardView: View {
  let state: CardDuelState
  let send: (CardDuelAction) -> Void

  /// ID of the player minion the user has tapped to attack with.
  @State private var selectedAttackerID: Int? = nil

  var body: some View {
    ZStack {
      CardDuelTheme.background.ignoresSafeArea()

      VStack(spacing: 0) {
        aiPanel
        aiBoardRow
        centerVS
        playerBoardRow
        bottomPanel
        handArea
        actionBar
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
    }
  }

  // MARK: - AI Panel

  private var aiPanel: some View {
    HeroPanel(
      nameKey: "game.cardDuel.ai",
      hp: state.aiHP,
      maxHP: CardDuelState.maxHP,
      mana: state.aiMana,
      maxMana: state.aiMaxMana,
      isActive: state.turnPhase != .playerMain,
      deckCount: state.aiDeck.count
    )
    .padding(.bottom, 6)
  }

  // MARK: - Boards

  private var aiBoardRow: some View {
    BoardRow(
      minions: state.aiBoard,
      isPlayerSide: false,
      selectedAttackerID: selectedAttackerID,
      canAct: canPlayerAct,
      onTap: { target in
        if let attackerID = selectedAttackerID {
          send(.minionAttack(attackerID: attackerID, target: target))
          selectedAttackerID = nil
        }
      },
      onPlayerSelect: { _ in }
    )
    .frame(height: 100)
  }

  private var playerBoardRow: some View {
    BoardRow(
      minions: state.playerBoard,
      isPlayerSide: true,
      selectedAttackerID: selectedAttackerID,
      canAct: canPlayerAct,
      onTap: { _ in },
      onPlayerSelect: { minionID in
        if canPlayerAct {
          selectedAttackerID = (selectedAttackerID == minionID) ? nil : minionID
        }
      }
    )
    .frame(height: 100)
  }

  private var centerVS: some View {
    HStack {
      // Left: recent log line
      if let log = state.battleLog.last {
        Text("• \(log)")
          .font(.caption2)
          .foregroundStyle(.gray)
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        Spacer()
      }

      // VS badge
      ZStack {
        Circle()
          .fill(Color.orange.gradient)
          .frame(width: 36, height: 36)
          .shadow(color: .orange.opacity(0.5), radius: 8)
        Text("VS")
          .font(.caption.bold())
          .foregroundStyle(.white)
      }

      // Right: turn indicator
      Text("T\(state.turnNumber)")
        .font(.caption2.bold())
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(.vertical, 4)
  }

  // MARK: - Player Panel

  private var bottomPanel: some View {
    HeroPanel(
      nameKey: "game.cardDuel.player",
      hp: state.playerHP,
      maxHP: CardDuelState.maxHP,
      mana: state.playerMana,
      maxMana: state.playerMaxMana,
      isActive: state.turnPhase == .playerMain,
      deckCount: state.playerDeck.count
    )
    .padding(.top, 6)
    .onTapGesture {
      // Tap hero = attack with selected attacker
      if let attackerID = selectedAttackerID {
        send(.minionAttack(attackerID: attackerID, target: .enemyHero))
        selectedAttackerID = nil
      }
    }
  }

  // MARK: - Hand

  private var handArea: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        ForEach(Array(state.playerHand.enumerated()), id: \.element.id) { index, card in
          Button {
            if canPlayerAct {
              // Spells that need no target can be played directly
              let needsTarget = spellNeedsTarget(card)
              if !needsTarget {
                send(.playCard(handIndex: index, target: nil))
              } else {
                // For simplicity: auto-target enemy hero for damaging spells
                let autoTarget: Target =
                  card.spellEffect == .damageTarget(0) ? .enemyHero : .enemyHero
                send(.playCard(handIndex: index, target: autoTarget))
              }
            }
          } label: {
            HandCardView(
              card: card,
              isPlayable: canPlayerAct && state.playerMana >= card.cost
            )
          }
          .buttonStyle(HandCardButtonStyle())
          .disabled(!canPlayerAct)
        }
      }
      .padding(.horizontal, 4)
      .padding(.vertical, 8)
    }
    .frame(height: 140)
  }

  // MARK: - Action Bar

  private var actionBar: some View {
    HStack(spacing: 16) {
      // Surrender (ghost button)
      Button {
        // No action yet; placeholder for future
      } label: {
        Label {
          GameLocalizedText("game.cardDuel.surrender")
            .font(.caption.bold())
        } icon: {
          Image(systemName: "flag.fill")
        }
        .foregroundStyle(.red.opacity(0.7))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.12))
        .clipShape(Capsule())
      }

      Spacer()

      // End Turn
      Button {
        send(.endTurn)
        selectedAttackerID = nil
      } label: {
        GameLocalizedText("game.cardDuel.endTurn")
          .font(.headline.bold())
          .foregroundStyle(.white)
          .padding(.horizontal, 28)
          .padding(.vertical, 12)
          .background(canPlayerAct ? CardDuelTheme.action : Color.gray.opacity(0.3))
          .clipShape(Capsule())
      }
      .disabled(!canPlayerAct)
    }
    .padding(.vertical, 8)
  }

  // MARK: - Helpers

  private var canPlayerAct: Bool {
    state.isRunning && !state.isGameOver && state.turnPhase == .playerMain
  }

  private func spellNeedsTarget(_ card: DuelCard) -> Bool {
    guard let effect = card.spellEffect else { return false }
    switch effect {
    case .damageTarget, .healTarget, .buffMinion: return true
    case .aoeEnemyMinions, .drawCards: return false
    }
  }
}

// MARK: - Sub-views

private struct HeroPanel: View {
  let nameKey: String
  let hp: Int
  let maxHP: Int
  let mana: Int
  let maxMana: Int
  let isActive: Bool
  let deckCount: Int

  var body: some View {
    HStack(spacing: 12) {
      // Avatar circle
      Circle()
        .fill(Color.gray.opacity(0.3))
        .frame(width: 44, height: 44)
        .overlay(Circle().stroke(isActive ? Color.yellow : Color.clear, lineWidth: 2))
        .shadow(color: isActive ? .yellow.opacity(0.4) : .clear, radius: 8)

      VStack(alignment: .leading, spacing: 6) {
        HStack {
          GameLocalizedText(nameKey)
            .font(.headline)
            .foregroundStyle(.white)
          Spacer()
          // Deck count
          Image(systemName: "square.stack.fill")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text("\(deckCount)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }

        // HP bar
        HStack(spacing: 6) {
          Image(systemName: "heart.fill")
            .foregroundStyle(CardDuelTheme.health)
            .font(.caption2)
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              RoundedRectangle(cornerRadius: 5)
                .fill(Color.white.opacity(0.1))
              RoundedRectangle(cornerRadius: 5)
                .fill(CardDuelTheme.health)
                .frame(width: max(0, CGFloat(hp) / CGFloat(maxHP) * geo.size.width))
                .animation(.spring(response: 0.35), value: hp)
              Text("\(hp)/\(maxHP)")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .frame(width: geo.size.width, alignment: .center)
            }
          }
          .frame(height: 13)
        }

        // Mana crystals
        if maxMana > 0 {
          HStack(spacing: 3) {
            ForEach(0..<maxMana, id: \.self) { i in
              Circle()
                .fill(i < mana ? CardDuelTheme.energy : Color.white.opacity(0.2))
                .frame(width: 10, height: 10)
            }
            Spacer()
          }
        }
      }
    }
    .padding(10)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(CardDuelTheme.panel)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    )
  }
}

private struct BoardRow: View {
  let minions: [BoardMinion]
  let isPlayerSide: Bool
  let selectedAttackerID: Int?
  let canAct: Bool
  let onTap: (Target) -> Void
  let onPlayerSelect: (Int) -> Void

  var body: some View {
    HStack(spacing: 6) {
      if minions.isEmpty {
        RoundedRectangle(cornerRadius: 10)
          .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
          .foregroundStyle(Color.white.opacity(0.12))
          .frame(maxWidth: .infinity)
      } else {
        ForEach(minions) { minion in
          if isPlayerSide {
            Button {
              onPlayerSelect(minion.id)
            } label: {
              MinionCardView(
                minion: minion,
                isSelected: selectedAttackerID == minion.id,
                canAct: canAct && minion.canAttack
              )
            }
            .buttonStyle(.plain)
          } else {
            Button {
              onTap(.minion(id: minion.id))
            } label: {
              MinionCardView(
                minion: minion,
                isSelected: false,
                canAct: false
              )
              .overlay(
                selectedAttackerID != nil
                  ? RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.7), lineWidth: 2)
                  : nil
              )
            }
            .buttonStyle(.plain)
          }
        }
        Spacer()
      }
    }
    .padding(.horizontal, 4)
  }
}

private struct MinionCardView: View {
  let minion: BoardMinion
  let isSelected: Bool
  let canAct: Bool

  var body: some View {
    VStack(spacing: 2) {
      // Divine shield indicator
      if minion.hasDivineShield {
        Image(systemName: "shield.fill")
          .font(.caption2)
          .foregroundStyle(.yellow)
      }

      // Keywords badges — use kw.titleKey (static String) so LocalizedStringKey
      // init(_ key: String) is called, not the interpolation overload that produces "keyword.%@".
      ForEach(minion.card.keywords.filter { $0 != .divineShield }, id: \.rawValue) { kw in
        Text(LocalizedStringKey(kw.titleKey), bundle: .gameUI)
          .font(.system(size: 7).bold())
          .foregroundStyle(.white)
          .padding(.horizontal, 4)
          .padding(.vertical, 1)
          .background(keywordColor(kw).opacity(0.8))
          .clipShape(Capsule())
      }

      Spacer(minLength: 2)

      Text(LocalizedStringKey(minion.card.nameKey), bundle: .gameUI)
        .font(.system(size: 9).bold())
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.6)

      // Attack / Health
      HStack(spacing: 0) {
        Text("\(minion.currentAttack)")
          .font(.caption.bold())
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .background(Color.red)
          .clipShape(RoundedRectangle(cornerRadius: 4))

        Text("\(minion.currentHealth)")
          .font(.caption.bold())
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .background(Color.green)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
    }
    .frame(width: 60, height: 88)
    .padding(4)
    .background(CardDuelTheme.cardDark)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(
          isSelected ? Color.cyan : (canAct ? Color.green.opacity(0.6) : Color.white.opacity(0.15)),
          lineWidth: isSelected ? 2.5 : 1.2)
    )
    .opacity(canAct || isSelected ? 1.0 : 0.65)
  }

  private func keywordColor(_ kw: Keyword) -> Color {
    switch kw {
    case .taunt: return .purple
    case .rush: return .orange
    case .charge: return .red
    case .divineShield: return .yellow
    }
  }
}

private struct HandCardView: View {
  let card: DuelCard
  let isPlayable: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      // Cost badge
      HStack {
        ZStack {
          Circle()
            .fill(CardDuelTheme.energy)
            .frame(width: 26, height: 26)
          Text("\(card.cost)")
            .font(.caption.bold())
            .foregroundStyle(.white)
        }
        .offset(x: -4, y: -4)
        Spacer()
      }

      Spacer()

      Text(LocalizedStringKey(card.nameKey), bundle: .gameUI)
        .font(.caption.bold())
        .foregroundStyle(.white)
        .lineLimit(2)
        .minimumScaleFactor(0.7)

      if card.cardType == .minion {
        HStack(spacing: 0) {
          Text("\(card.attack)")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 3))
          Text("\(card.health)")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
      } else if let effect = card.spellEffect {
        Text(spellDescription(effect))
          .font(.system(size: 8))
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      // Keywords — use kw.titleKey (static String) to avoid LocalizedStringKey
      // string-interpolation producing format keys like "keyword.%@".
      HStack(spacing: 2) {
        ForEach(card.keywords, id: \.rawValue) { kw in
          Text(LocalizedStringKey(kw.titleKey), bundle: .gameUI)
            .font(.system(size: 6).bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(Color.purple.opacity(0.7))
            .clipShape(Capsule())
        }
      }
    }
    .padding(8)
    .frame(width: 88, height: 120)
    .background(
      ZStack {
        CardDuelTheme.cardDark
        LinearGradient(
          colors: [cardColor.opacity(0.35), .clear],
          startPoint: .topLeading, endPoint: .bottomTrailing
        )
      }
    )
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(
      RoundedRectangle(cornerRadius: 14).stroke(
        isPlayable ? cardColor.opacity(0.9) : Color.white.opacity(0.15),
        lineWidth: isPlayable ? 1.8 : 1)
    )
    .opacity(isPlayable ? 1.0 : 0.45)
  }

  private var cardColor: Color {
    if card.cardType == .spell { return .purple }
    return .cyan
  }

  private func spellDescription(_ effect: SpellEffect) -> String {
    switch effect {
    case .damageTarget(let n): return "Deal \(n) dmg"
    case .healTarget(let n): return "Heal \(n)"
    case .aoeEnemyMinions(let n): return "AOE \(n)"
    case .drawCards(let n): return "Draw \(n)"
    case .buffMinion(let a, let h): return "+\(a)/+\(h)"
    }
  }
}

private struct HandCardButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 1.06 : 1.0)
      .offset(y: configuration.isPressed ? -10 : 0)
      .shadow(
        color: configuration.isPressed ? .cyan.opacity(0.5) : .black.opacity(0.3),
        radius: configuration.isPressed ? 16 : 8
      )
      .animation(AppTheme.springAnimation, value: configuration.isPressed)
  }
}

// MARK: - Color Hex Helper

extension Color {
  init(hex: String) {
    let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hexString).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hexString.count {
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255,
      opacity: Double(a) / 255)
  }
}
