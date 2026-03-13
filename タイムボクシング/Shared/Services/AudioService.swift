import AVFoundation

final class AudioService {
    static let shared = AudioService()

    private var audioPlayer: AVAudioPlayer?

    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }

    private init() {
        configureAudioSession()
    }

    func playTaskMusic() {
        play(resource: "task", fileExtension: "m4a")
    }

    func playBreakMusic() {
        play(resource: "rest", fileExtension: "m4a")
    }

    func pause() {
        audioPlayer?.pause()
    }

    func resume() {
        audioPlayer?.play()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
    }

    private func play(resource: String, fileExtension: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else { return }
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {}
    }
}
