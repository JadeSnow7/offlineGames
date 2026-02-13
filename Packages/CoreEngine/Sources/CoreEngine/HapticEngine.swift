#if canImport(UIKit)
import UIKit

/// Actor that manages haptic feedback.
public actor HapticEngine {
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    public init() {}

    /// Trigger a light impact haptic.
    public func lightImpact() {
        impactLight.impactOccurred()
    }

    /// Trigger a medium impact haptic.
    public func mediumImpact() {
        impactMedium.impactOccurred()
    }

    /// Trigger a heavy impact haptic.
    public func heavyImpact() {
        impactHeavy.impactOccurred()
    }

    /// Trigger a success notification haptic.
    public func success() {
        notification.notificationOccurred(.success)
    }

    /// Trigger a warning notification haptic.
    public func warning() {
        notification.notificationOccurred(.warning)
    }

    /// Trigger an error notification haptic.
    public func error() {
        notification.notificationOccurred(.error)
    }
}
#else
/// Stub HapticEngine for platforms without UIKit.
public actor HapticEngine {
    public init() {}
    public func lightImpact() {}
    public func mediumImpact() {}
    public func heavyImpact() {}
    public func success() {}
    public func warning() {}
    public func error() {}
}
#endif
