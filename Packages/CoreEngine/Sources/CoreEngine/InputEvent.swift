import Foundation

/// Unified input events consumed by game reducers.
public enum InputEvent: Sendable, Equatable {
    /// Touch/tap began at a normalized position (0..1, 0..1).
    case touchBegan(x: Float, y: Float)

    /// Touch/tap moved to a normalized position.
    case touchMoved(x: Float, y: Float)

    /// Touch/tap ended at a normalized position.
    case touchEnded(x: Float, y: Float)

    /// Swipe gesture in a cardinal direction.
    case swipe(Direction)

    /// Hardware keyboard key press (for iPad/external keyboard).
    case keyDown(KeyCode)

    /// Hardware keyboard key release.
    case keyUp(KeyCode)
}

/// Cardinal directions for swipe gestures and game movement.
public enum Direction: Sendable, Equatable {
    case up, down, left, right
}

/// Key codes for hardware keyboard support.
public enum KeyCode: String, Sendable, Equatable {
    case arrowUp, arrowDown, arrowLeft, arrowRight
    case space, enter, escape
    case w, a, s, d
}
