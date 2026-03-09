import SwiftUI
import AVFoundation

struct MetronomeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var metronome = MetronomeEngine()
    
    @State private var bpm: Double = 120
    @State private var selectedTimeSignature: TimeSignature = .quarter
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // BPM Display
                VStack(spacing: 8) {
                    Text("\(Int(bpm))")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                    
                    Text("BPM")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                
                // BPM Slider
                VStack(spacing: 8) {
                    Slider(value: $bpm, in: 20...300, step: 1)
                        .accentColor(.cyan)
                    
                    HStack {
                        Text("20")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("300")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // Time Signature Picker
                VStack(spacing: 12) {
                    Text("分拍")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        ForEach(TimeSignature.allCases, id: \.self) { sig in
                            Button {
                                selectedTimeSignature = sig
                                metronome.timeSignature = sig
                            } label: {
                                Text(sig.displayName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .frame(width: 70, height: 50)
                                    .background(selectedTimeSignature == sig ? Color.cyan : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTimeSignature == sig ? .white : .primary)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // Beat Indicator
                HStack(spacing: 12) {
                    ForEach(0..<selectedTimeSignature.beats, id: \.self) { beat in
                        Circle()
                            .fill(beat < metronome.currentBeat ? Color.cyan : Color.gray.opacity(0.3))
                            .frame(width: 30, height: 30)
                            .scaleEffect(beat == metronome.currentBeat && metronome.isPlaying ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: metronome.currentBeat)
                    }
                }
                
                // Control Buttons
                HStack(spacing: 32) {
                    Button {
                        metronome.isPlaying.toggle()
                        if metronome.isPlaying {
                            metronome.start(bpm: Int(bpm))
                        } else {
                            metronome.stop()
                        }
                    } label: {
                        Image(systemName: metronome.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.cyan)
                    }
                    
                    Button {
                        metronome.currentBeat = 0
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                    }
                }
                
                // Tap Tempo
                Button {
                    metronome.recordTap()
                } label: {
                    Text("Tap Tempo")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("节拍器")
            .toolbar { ToolbarItem(placement: .principal) { Text("") } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { 
                        metronome.stop()
                        dismiss() 
                    }
                }
            }
            .onChange(of: bpm) { _, newValue in
                if metronome.isPlaying {
                    metronome.updateTempo(Int(newValue))
                }
            }
            .onDisappear {
                metronome.stop()
            }
        }
    }
}

// MARK: - Time Signature
enum TimeSignature: Int, CaseIterable {
    case quarter = 4      // 1/4
    case eighth = 8        // 1/8
    case sixteenth = 16   // 1/16
    
    var displayName: String {
        switch self {
        case .quarter: return "1/4"
        case .eighth: return "1/8"
        case .sixteenth: return "1/16"
        }
    }
    
    var beats: Int {
        return 4 // Display 4 beats for visual
    }
}

// MARK: - Metronome Engine
@MainActor
class MetronomeEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var currentBeat = 0
    @Published var timeSignature: TimeSignature = .quarter
    
    private var timer: Timer?
    private var tapTimes: [Date] = []
    private var audioEngine: AudioEngine
    
    // 支持 dependency injection，传入 nil 则创建独立实例
    init(audioEngine: AudioEngine? = nil) {
        self.audioEngine = audioEngine ?? AudioEngine()
    }
    
    func start(bpm: Int) {
        stop()
        currentBeat = 0
        
        let interval = 60.0 / Double(bpm)
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        
        // Play first beat immediately
        tick()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        currentBeat = 0
    }
    
    func updateTempo(_ bpm: Int) {
        if isPlaying {
            start(bpm: bpm)
        }
    }
    
    private func tick() {
        playClick(beat: currentBeat)
        
        let beatsPerMeasure: Int
        switch timeSignature {
        case .quarter: beatsPerMeasure = 4
        case .eighth: beatsPerMeasure = 8
        case .sixteenth: beatsPerMeasure = 16
        }
        
        currentBeat = (currentBeat + 1) % beatsPerMeasure
    }
    
    private func playClick(beat: Int) {
        let isDownbeat = beat == 0
        
        // Use AudioEngine to play guitar sample instead of system sound
        audioEngine.play(midiNote: 60)
        
        // Haptic feedback
        if isDownbeat {
            HapticManager.notification(.success)
        } else {
            HapticManager.impact(.light)
        }
    }
    
    func recordTap() {
        let now = Date()
        
        // Remove old taps (older than 3 seconds)
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 3.0 }
        tapTimes.append(now)
        
        // Need at least 2 taps to calculate tempo
        guard tapTimes.count >= 2 else { return }
        
        // Calculate average interval
        var totalInterval: TimeInterval = 0
        for i in 1..<tapTimes.count {
            totalInterval += tapTimes[i].timeIntervalSince(tapTimes[i-1])
        }
        
        let averageInterval = totalInterval / Double(tapTimes.count - 1)
        let calculatedBPM = Int(60.0 / averageInterval)
        
        // Clamp to valid range
        bpm = min(max(Double(calculatedBPM), 20), 300)
        
        // Update metronome if playing
        if isPlaying {
            updateTempo(calculatedBPM)
        }
    }
    
    private var bpm: Double = 120
}
