/// Minion keyword abilities.
public enum Keyword: String, Sendable, Equatable, CaseIterable {
  case taunt  // Enemies must attack this minion first
  case rush  // Can attack minions (not hero) on the summon turn
  case charge  // Can attack anything on the summon turn
  case divineShield  // Absorbs the first damage instance, then is removed

  /// Static localization key — avoids SwiftUI turning interpolated LocalizedStringKey
  /// into format-string keys like "keyword.%@" instead of "keyword.charge".
  public var titleKey: String {
    switch self {
    case .taunt: return "keyword.taunt"
    case .rush: return "keyword.rush"
    case .charge: return "keyword.charge"
    case .divineShield: return "keyword.divineShield"
    }
  }
}

/// The resolved effect of a spell card.
public enum SpellEffect: Sendable, Equatable {
  case damageTarget(Int)  // Deals N to a Target
  case healTarget(Int)  // Restores N health to a Target
  case aoeEnemyMinions(Int)  // Deals N to all enemy minions (no target needed)
  case drawCards(Int)  // Draws N cards (no target needed)
  case buffMinion(attack: Int, health: Int)  // +N/+N to a friendly minion
}

/// Identifies who or what a card effect is directed at.
public enum Target: Sendable, Equatable {
  case enemyHero
  case friendlyHero
  case minion(id: Int)  // Reducer validates whether the minion belongs to the legal target pool
}
