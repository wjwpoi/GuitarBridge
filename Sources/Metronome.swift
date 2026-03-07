import Foundation
import AVFoundation

@MainActor
class Metronome: ObservableObject {
    @Published var bpm: Double = 80 {
        didSet {
            UserDefaults.standard.set(bpm, forKey: "metronomeBPM")
            if isPlaying {
                restart()
            }
        }
    }
    
    @Published var beatsPerMeasure: Int = 4 {
        didSet {
            UserDefaults.standard.set(beatsPerMeasure, forKey: "metronomeBeats")
            currentBeat = 0
        }
    }
    
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    
    private var timer: Timer?
    private var audioEngine: AVAudioEngine?
    private var clickPlayer: AVAudioPlayerNode?
    private var accentPlayer: AVAudioPlayerNode?
    
    // Audio buffers
    private var clickBuffer: AVAudioPCMBuffer?
    private var accentBuffer: AVAudioPCMBuffer?
    
    init() {
        bpm = UserDefaults.standard.object(forKey: "metronomeBPM") as? Double ?? 80
        beatsPerMeasure = UserDefaults.standard.object(forKey: "metronomeBeats") as? Int ?? 4
        setupAudio()
        loadClickSounds()
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        clickPlayer = AVAudioPlayerNode()
        accentPlayer = AVAudioPlayerNode()
        
        guard let engine = audioEngine,
              let click = clickPlayer,
              let accent = accentPlayer else { return }
        
        engine.attach(click)
        engine.attach(accent)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(click, to: engine.mainMixerNode, format: format)
        engine.connect(accent, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
        } catch {
            // Silent fail
        }
    }
    
    private func loadClickSounds() {
        // Generate click sounds programmatically
        let sampleRate: Double = 44100
        let duration: Double = 0.05
        
        // Normal click (high tick)
        let clickFrames = AVAudioFrameCount(sampleRate * duration)
        clickBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!, frameCapacity: clickFrames)
        clickBuffer?.frameLength = clickFrames
        
        if let data = clickBuffer?.floatChannelData?[0] {
            for i in 0..<Int(clickFrames) {
                let t = Double(i) / sampleRate
                let envelope = exp(-t * 50)  // Quick decay
                data[i] = Float(sin(2 * Double.pi * 1000 * t) * envelope * 0.5)
            }
        }
        
        // Accent click (lower, stronger)
        let accentFrames = AVAudioFrameCount(sampleRate * duration)
        accentBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!, frameCapacity: accentFrames)
        accentBuffer?.frameLength = accentFrames
        
        if let data = accentBuffer?.floatChannelData?[0] {
            for i in 0..<Int(accentFrames) {
                let t = Double(i) / sampleRate
                let envelope = exp(-t * 30)  // Slower decay
                data[i] = Float(sin(2 * Double.pi * 800 * t) * envelope * 0.8)
            }
        }
    }
    
    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }
    
    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        currentBeat = 0
        
        let interval = 60.0 / bpm
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    func stop() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        currentBeat = 0
    }
    
    private func restart() {
        stop()
        start()
    }
    
    private func tick() {
        guard isPlaying else { return }
        
        // Play click sound
        if currentBeat == 0 {
            // Accent on first beat
            if let buffer = accentBuffer {
                accentPlayer?.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                accentPlayer?.play()
            }
        } else {
            if let buffer = clickBuffer {
                clickPlayer?.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                clickPlayer?.play()
            }
        }
        
        currentBeat = (currentBeat + 1) % beatsPerMeasure
    }
    
    // Tap tempo function
    private var tapTimes: [Date] = []
    
    func tap() {
        let now = Date()
        tapTimes.append(now)
        
        // Keep only last 4 taps
        if tapTimes.count > 4 {
            tapTimes.removeFirst()
        }
        
        // Calculate average interval
        guard tapTimes.count >= 2 else { return }
        
        var totalInterval: TimeInterval = 0
        for i in 1..<tapTimes.count {
            totalInterval += tapTimes[i].timeIntervalSince(tapTimes[i-1])
        }
        
        let averageInterval = totalInterval / Double(tapTimes.count - 1)
        let newBPM = 60.0 / averageInterval
        
        // Clamp to valid range
        bpm = min(max(newBPM, 40), 240)
    }
}
