import Foundation

/// Actor that manages app-wide settings using UserDefaults.
public actor SettingsStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Whether haptic feedback is enabled.
    public var hapticsEnabled: Bool {
        get { defaults.object(forKey: "settings.haptics") as? Bool ?? true }
    }

    /// Set haptic feedback preference.
    public func setHapticsEnabled(_ value: Bool) {
        defaults.set(value, forKey: "settings.haptics")
    }

    /// Whether sound effects are enabled.
    public var soundEnabled: Bool {
        get { defaults.object(forKey: "settings.sound") as? Bool ?? true }
    }

    /// Set sound preference.
    public func setSoundEnabled(_ value: Bool) {
        defaults.set(value, forKey: "settings.sound")
    }

    /// Whether to use reduced motion (accessibility).
    public var reduceMotion: Bool {
        get { defaults.object(forKey: "settings.reduceMotion") as? Bool ?? false }
    }

    /// Set reduced motion preference.
    public func setReduceMotion(_ value: Bool) {
        defaults.set(value, forKey: "settings.reduceMotion")
    }
}
