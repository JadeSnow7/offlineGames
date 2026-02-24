import Testing
@testable import GameUI

@Test func gameUIModuleLoads() async throws {
    // Verify module imports successfully
}

@Test func appLanguageExplicitLocaleResolution() {
    #expect(AppLanguage.en.resolvedLocale.identifier.hasPrefix("en"))
    #expect(AppLanguage.zhHans.resolvedLocale.identifier.hasPrefix("zh"))
}
