import AVFoundation
import Foundation
import SwiftUI
import AudioToolbox

#if DEBUG
private let debugEnabled = true
#else
private let debugEnabled = false
#endif

private func log(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}

// MARK: - Tone Mode Definition
enum GuitarToneMode: String, CaseIterable {
    case clean = "clean"
    case distortion = "distortion"
    case telecaster = "telecaster"
    case nylon = "nylon"
    
    var program: UInt8 {
        switch self {
        case .clean: return 0      // Acoustic Grand Piano
        case .distortion: return 30 // Overdriven Guitar
        case .telecaster: return 24 // Acoustic Guitar (nylon)
        case .nylon: return 24      // Acoustic Guitar (nylon)
        }
    }
    
    static func from(_ string: String) -> GuitarToneMode {
        return GuitarToneMode(rawValue: string.lowercased()) ?? .clean
    }
}

@MainActor
class AudioEngine: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    
    // MARK: - Multi-Tone Samplers with Crossfade Support
    private var toneSamplers: [GuitarToneMode: AVAudioUnitSampler] = [:]
    private var toneMixers: [GuitarToneMode: AVAudioMixerNode] = [:]
    private var activeTone: GuitarToneMode = .clean
    
    // MARK: - Crossfade Configuration
    @Published var crossfadeDuration: Double = 0.15 { // Default 150ms
        didSet {
            UserDefaults.standard.set(crossfadeDuration, forKey: "crossfadeDuration")
        }
    }
    
    // Swift 6 Concurrency: Use Actor for thread-safe crossfade state
    private actor CrossfadeActor {
        private var isCrossfading = false
        private var currentTask: Task<Void, Never>? = nil
        
        var crossfading: Bool { isCrossfading }
        
        func startCrossfade() -> Bool {
            guard !isCrossfading else { return false }
            isCrossfading = true
            return true
        }
        
        func endCrossfade() {
            isCrossfading = false
        }
        
        func cancel() {
            currentTask?.cancel()
            currentTask = nil
            isCrossfading = false
        }
        
        func setTask(_ task: Task<Void, Never>?) {
            currentTask = task
        }
    }
    
    private let crossfadeActor = CrossfadeActor()
    
    @Published var isPlaying = false
    @Published var isReady = false
    @Published var currentMode = "clean"
    @Published var lastError: String?
    @Published var volume: Float = 0.8 {
        didSet {
            audioEngine.mainMixerNode.outputVolume = volume
            UserDefaults.standard.set(volume, forKey: "audioVolume")
        }
    }
    
    private var currentVelocity: UInt8 = 80
    private var sampleBuffers: [String: AVAudioPCMBuffer] = [:]
    private var sampleNames: [String] = []
    
    private let sampleDirectory = "@RJPASIN 1SHOT KIT"
    
    init() {
        setupAudioSession()
        loadGuitarSamples()
        setupMultiToneAudioEngine()
        
        // Load saved preferences
        volume = UserDefaults.standard.object(forKey: "audioVolume") as? Float ?? 0.8
        crossfadeDuration = UserDefaults.standard.object(forKey: "crossfadeDuration") as? Double ?? 0.15
        audioEngine.mainMixerNode.outputVolume = volume
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            log("[AudioEngine] Audio session ready")
        } catch {
            log("[AudioEngine] Session error: \(error)")
            lastError = error.localizedDescription
        }
    }
    
    private func loadGuitarSamples() {
        guard let resourcesURL = Bundle.main.resourceURL else {
            log("[AudioEngine] Could not get resource URL")
            loadSamplesFromBundle()
            return
        }
        
        let sampleDirURL = resourcesURL.appendingPathComponent(sampleDirectory)
        
        do {
            let fileManager = FileManager.default
            
            // 方法1: 从 sampleDirectory 子目录加载
            if fileManager.fileExists(atPath: sampleDirURL.path) {
                let subdirs = try fileManager.contentsOfDirectory(atPath: sampleDirURL.path)
                
                for subdir in subdirs {
                    let subdirPath = sampleDirURL.appendingPathComponent(subdir)
                    var isDirectory: ObjCBool = false
                    
                    if fileManager.fileExists(atPath: subdirPath.path, isDirectory: &isDirectory), isDirectory.boolValue {
                        let files = try fileManager.contentsOfDirectory(atPath: subdirPath.path)
                        
                        for file in files where file.lowercased().hasSuffix(".wav") {
                            let filePath = subdirPath.appendingPathComponent(file)
                            loadWavFile(url: filePath, name: "\(subdir)/\(file)")
                        }
                    }
                }
                
                if !sampleBuffers.isEmpty {
                    log("[AudioEngine] Loaded \(sampleBuffers.count) guitar samples from subdirectories")
                    return
                }
            }
            
            // 方法2: 从根目录扫描 (平铺结构)
            let rootFiles = try fileManager.contentsOfDirectory(at: resourcesURL, includingPropertiesForKeys: nil)
            for file in rootFiles where file.pathExtension.lowercased() == "wav" {
                loadWavFile(url: file, name: file.lastPathComponent)
            }
            
            log("[AudioEngine] Loaded \(sampleBuffers.count) guitar samples from root")
        } catch {
            log("[AudioEngine] Error loading samples: \(error)")
            loadSamplesFromBundle()
        }
    }
    
    private func loadSamplesFromBundle() {
        guard let resourcesURL = Bundle.main.resourceURL else { return }
        
        // 采样文件可能被平铺在根目录，也可能在子目录中
        // 先尝试从 sampleDirectory 子目录加载
        let sampleDirURL = resourcesURL.appendingPathComponent(sampleDirectory)
        
        var loaded = false
        
        // 方法1: 从子目录加载 (原结构)
        if FileManager.default.fileExists(atPath: sampleDirURL.path) {
            if let enumerator = FileManager.default.enumerator(at: sampleDirURL, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "wav" {
                        let relativePath = fileURL.path.replacingOccurrences(of: sampleDirURL.path + "/", with: "")
                        loadWavFile(url: fileURL, name: relativePath)
                    }
                }
            }
            if !sampleBuffers.isEmpty {
                loaded = true
                log("[AudioEngine] Loaded \(sampleBuffers.count) samples from subdirectories")
            }
        }
        
        // 方法2: 如果子目录没加载到，从根目录扫描 (平铺结构)
        if !loaded {
            if let enumerator = FileManager.default.enumerator(at: resourcesURL, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "wav" {
                        // 跳过已经在子目录中加载的
                        if !fileURL.path.contains("/") {
                            loadWavFile(url: fileURL, name: fileURL.lastPathComponent)
                        }
                    }
                }
            }
            log("[AudioEngine] Bundle scan loaded \(sampleBuffers.count) samples from root")
        }
    }
    
    private func loadWavFile(url: URL, name: String) {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(audioFile.length)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                log("[AudioEngine] Could not create buffer for: \(name)")
                return
            }
            
            try audioFile.read(into: buffer)
            sampleBuffers[name] = buffer
            sampleNames.append(name)
            
        } catch {
            log("[AudioEngine] Error loading \(name): \(error)")
        }
    }
    
    // MARK: - Setup Multi-Tone Audio Engine with Crossfade Support
    private func setupMultiToneAudioEngine() {
        // Setup player node for samples
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        
        // Create sampler and mixer for each tone mode
        for toneMode in GuitarToneMode.allCases {
            let sampler = AVAudioUnitSampler()
            let mixer = AVAudioMixerNode()
            
            audioEngine.attach(sampler)
            audioEngine.attach(mixer)
            
            // Connect sampler -> tone mixer -> main mixer
            audioEngine.connect(sampler, to: mixer, format: nil)
            audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: nil)
            
            // Store references
            toneSamplers[toneMode] = sampler
            toneMixers[toneMode] = mixer
            
            // Initialize: only active tone has full volume
            mixer.outputVolume = (toneMode == activeTone) ? 1.0 : 0.0
            
            // Load DLS instrument for this sampler (only on real device)
            #if !targetEnvironment(simulator)
            loadDLSForSampler(sampler, toneMode: toneMode)
            #endif
            
            log("[AudioEngine] Created sampler & mixer for: \(toneMode.rawValue)")
        }
        
        // Start engine
        do {
            try audioEngine.start()
            isReady = true
            log("[AudioEngine] Multi-tone engine ready with \(sampleBuffers.count) samples")
        } catch {
            log("[AudioEngine] Setup error: \(error)")
            lastError = error.localizedDescription
            try? audioEngine.start()
            isReady = true
        }
    }
    
    private func loadDLSForSampler(_ sampler: AVAudioUnitSampler, toneMode: GuitarToneMode) {
        let dlsPaths = [
            "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls",
            "/System/Library/Components/CoreAudio.component/Contents/Resources/gm.dls"
        ]
        
        for dlsPath in dlsPaths {
            let url = URL(fileURLWithPath: dlsPath)
            if FileManager.default.fileExists(atPath: dlsPath) {
                do {
                    try sampler.loadInstrument(at: url)
                    // Set program for this tone mode
                    sampler.sendProgramChange(toneMode.program, bankMSB: 0, bankLSB: 0, onChannel: 0)
                    log("[AudioEngine] Loaded DLS for \(toneMode.rawValue): program \(toneMode.program)")
                    return
                } catch {
                    log("[AudioEngine] Failed to load DLS for \(toneMode.rawValue): \(error)")
                }
            }
        }
        
        // Fallback: try default soundbank
        loadDefaultSoundBankForSampler(sampler, toneMode: toneMode)
    }
    
    private func loadDefaultSoundBankForSampler(_ sampler: AVAudioUnitSampler, toneMode: GuitarToneMode) {
        guard let bankURL = Bundle.main.url(forResource: "Piano", withExtension: "sf2") ??
              Bundle.main.url(forResource: "GMGS", withExtension: "dls") else {
            log("[AudioEngine] No default sound bank found")
            return
        }
        
        do {
            try sampler.loadSoundBankInstrument(
                at: bankURL,
                program: toneMode.program,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
            log("[AudioEngine] Loaded sound bank for \(toneMode.rawValue)")
        } catch {
            log("[AudioEngine] Failed to load sound bank: \(error)")
        }
    }
    
    // MARK: - Crossfade Tone Switching (Swift 6 Concurrency Safe)
    func setToneMode(_ modeString: String) {
        let newTone = GuitarToneMode.from(modeString)
        
        guard newTone != activeTone else { return }
        
        // Check and set crossfade state atomically via actor
        Task {
            let canProceed = await crossfadeActor.startCrossfade()
            guard canProceed else { return }
            
            let oldTone = activeTone
            
            await MainActor.run {
                self.activeTone = newTone
                self.currentMode = modeString
                log("[AudioEngine] Crossfade: \(oldTone.rawValue) -> \(newTone.rawValue), duration: \(crossfadeDuration)s")
            }
            
            // Perform crossfade with gain ramping to prevent clicks/pops
            await performCrossfade(from: oldTone, to: newTone)
        }
    }
    
    private func performCrossfade(from oldTone: GuitarToneMode, to newTone: GuitarToneMode) async {
        guard let oldMixer = toneMixers[oldTone],
              let newMixer = toneMixers[newTone] else {
            await crossfadeActor.endCrossfade()
            return
        }
        
        let steps = 30 // Higher resolution for smoother ramping
        let stepDuration = crossfadeDuration / Double(steps)
        
        // Use sine curve for smoother exponential-like fade (prevents clicks)
        for i in 1...steps {
            // Calculate fade using sine curve for natural sound
            let progress = Float(i) / Float(steps)
            let fadeOut = cos(progress * .pi / 2) // 1.0 -> 0.0
            let fadeIn = sin(progress * .pi / 2)   // 0.0 -> 1.0
            
            await MainActor.run {
                oldMixer.outputVolume = fadeOut
                newMixer.outputVolume = fadeIn
            }
            
            // Stop notes on old sampler at the very start to prevent hanging
            if i == 1 {
                stopAllNotesOnSampler(oldTone)
            }
            
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
        
        // Ensure final volumes are exact
        await MainActor.run {
            oldMixer.outputVolume = 0.0
            newMixer.outputVolume = 1.0
        }
        
        await crossfadeActor.endCrossfade()
        log("[AudioEngine] Crossfade complete: now using \(newTone.rawValue)")
    }
    
    private func stopAllNotesOnSampler(_ toneMode: GuitarToneMode) {
        guard let sampler = toneSamplers[toneMode] else { return }
        // Stop all notes on all channels (0-15)
        for channel in 0...15 {
            for note in 0...127 {
                sampler.stopNote(UInt8(note), onChannel: UInt8(channel))
            }
        }
    }
    
    // Cancel any ongoing crossfade (useful when user rapidly switches tones)
    func cancelCrossfade() {
        Task {
            await crossfadeActor.cancel()
        }
    }
    
    func play(midiNote: Int) {
        guard midiNote >= 20 && midiNote <= 127 else { return }

        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                log("[AudioEngine] Failed to start engine: \(error)")
                return
            }
        }

        // 优先尝试使用吉他采样
        playGuitarSample(midiNote: midiNote)
    }
    
    // MARK: - 使用当前激活的 Sampler 播放 MIDI
    private func playMIDIWithSampler(midiNote: Int) {
        // 确保音频引擎正在运行
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                log("[AudioEngine] Failed to start: \(error)")
                return
            }
        }
        
        // 使用当前激活的 sampler 播放 MIDI
        guard let sampler = toneSamplers[activeTone] else {
            log("[AudioEngine] No sampler for active tone: \(activeTone)")
            return
        }
        
        sampler.startNote(UInt8(midiNote), withVelocity: currentVelocity, onChannel: 0)
        
        // 1秒后自动停止音符（模拟音符释放）
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            sampler.stopNote(UInt8(midiNote), onChannel: 0)
        }
    }
    
    private func playGuitarSample(midiNote: Int) {
        log("[AudioEngine] playGuitarSample called for midiNote: \(midiNote), sampleBuffers count: \(sampleBuffers.count)")
        
        guard !sampleBuffers.isEmpty else {
            // Fallback to sampler if no samples
            log("[AudioEngine] No samples, falling back to MIDI sampler")
            if let sampler = toneSamplers[activeTone] {
                sampler.startNote(UInt8(midiNote), withVelocity: currentVelocity, onChannel: 0)
            }
            return
        }
        
        let noteRange = midiNote - 24
        let sampleIndex = noteRange % sampleNames.count
        let sampleName = sampleNames[sampleIndex]
        
        guard let buffer = sampleBuffers[sampleName] else {
            // Fallback to MIDI sampler if sample not found
            log("[AudioEngine] Sample not found: \(sampleName), falling back to MIDI")
            if let sampler = toneSamplers[activeTone] {
                sampler.startNote(UInt8(midiNote), withVelocity: currentVelocity, onChannel: 0)
            }
            return
        }
        
        log("[AudioEngine] Playing sample: \(sampleName) for MIDI note: \(midiNote)")
        
        // 确保音频引擎已启动
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
                log("[AudioEngine] Audio engine started successfully")
            } catch {
                log("[AudioEngine] Failed to start engine: \(error)")
                return
            }
        }
        
        playerNode.volume = volume  // 应用音量
        log("[AudioEngine] Playing sample: \(sampleName), volume: \(volume)")
        
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        
        if !playerNode.isPlaying {
            playerNode.play()
            log("[AudioEngine] Player node started playing")
        }
        
        isPlaying = true
        
        // 采样播放完成后自动停止
        Task {
            let duration = Double(buffer.frameLength) / buffer.format.sampleRate
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            playerNode.stop()
            isPlaying = false
        }
    }
    
    func setVelocity(_ v: UInt8) { currentVelocity = v }
}
