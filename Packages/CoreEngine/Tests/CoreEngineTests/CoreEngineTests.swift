import Foundation
import Testing
@testable import CoreEngine

@Test func coreEngineModuleLoads() async throws {
    // Verify module imports successfully
}

@Test func highScoreStoreRecordsTopScore() async {
    let gameID = HighScoreKey.session(gameID: "snake.\(UUID().uuidString)")
    let store = HighScoreStore(gameID: gameID)
    await store.record(score: 120)
    await store.record(score: 240)

    let top = await store.topScores(limit: 1)
    #expect(top.first?.score == 240)
}

@Test func settingsStorePersistsFlags() async {
    let settings = SettingsStore()
    let originalSound = await settings.soundEnabled
    let originalHaptics = await settings.hapticsEnabled

    await settings.setSoundEnabled(false)
    await settings.setHapticsEnabled(false)

    let soundEnabled = await settings.soundEnabled
    let hapticsEnabled = await settings.hapticsEnabled

    #expect(!soundEnabled)
    #expect(!hapticsEnabled)

    await settings.setSoundEnabled(originalSound)
    await settings.setHapticsEnabled(originalHaptics)
}
