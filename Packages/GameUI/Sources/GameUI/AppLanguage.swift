import Foundation

/// Supported app language preferences.
public enum AppLanguage: String, CaseIterable, Sendable {
    case system = "system"
    case en = "en"
    case zhHans = "zh-Hans"

    /// Resolve the effective locale used by SwiftUI.
    /// `system` maps Chinese systems to `zh-Hans`, English systems to `en`,
    /// and all other languages to `en`.
    public var resolvedLocale: Locale {
        switch self {
        case .en:
            return Locale(identifier: AppLanguage.en.rawValue)
        case .zhHans:
            return Locale(identifier: AppLanguage.zhHans.rawValue)
        case .system:
            let systemID = Locale.autoupdatingCurrent.identifier.lowercased()
            if systemID.hasPrefix("zh") {
                return Locale(identifier: AppLanguage.zhHans.rawValue)
            }
            if systemID.hasPrefix("en") {
                return Locale(identifier: AppLanguage.en.rawValue)
            }
            return Locale(identifier: AppLanguage.en.rawValue)
        }
    }
}
