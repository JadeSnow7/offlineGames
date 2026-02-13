import AVFoundation

/// Actor that manages audio playback for sound effects.
public actor AudioEngine {
    private var players: [String: AVAudioPlayer] = [:]

    public init() {}

    /// Play a sound effect by name (from bundle resource).
    public func playSound(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else {
            return
        }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.play()
        players[name] = player
    }

    /// Stop all currently playing sounds.
    public func stopAll() {
        for player in players.values { player.stop() }
        players.removeAll()
    }
}
