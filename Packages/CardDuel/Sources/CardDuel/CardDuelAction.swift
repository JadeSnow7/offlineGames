/// Actions handled by the Card Duel CCG reducer.
public enum CardDuelAction: Sendable {
  // Session lifecycle
  case start
  case pause
  case resume
  case reset

  // Player actions (playerMain phase only)
  /// Play a card from hand. For spells that need a target, `target` must be non-nil.
  case playCard(handIndex: Int, target: Target?)
  /// Order a board minion to attack a target (enemy hero or any minion).
  case minionAttack(attackerID: Int, target: Target)

  // AI phases (internal, triggered by endTurn)
  case aiPlayPhase
  case aiAttackPhase

  // Turn management
  case endTurn
  case startPlayerTurn
}
