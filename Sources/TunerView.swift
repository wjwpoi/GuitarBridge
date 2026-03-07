import SwiftUI
import AVFoundation
import Accelerate

// MARK: - Tuner
@MainActor
class Tuner: ObservableObject {
    @Published var isListening: Bool = false
    @Published var currentFrequency: Double = 0
    @Published var currentNote: String = "-"
    @Published var currentOctave: Int = 4
    @Published var cents: Double = 0  // -50 to +50
    @Published var isInTune: Bool = false
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    // Note frequencies (A4 = 440Hz)
    private let noteFrequencies: [String: Double] = [
        "C": 261.63, "C#": 277.18, "D": 293.66, "D#": 311.13,
        "E": 329.63, "F": 349.23, "F#": 369.99, "G": 392.00,
        "G#": 415.30, "A": 440.00, "A#": 466.16, "B": 493.88
    ]
    
    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
    }
    
    func start() {
        guard let engine = audioEngine, let input = inputNode else { return }
        
        let format = input.outputFormat(forBus: 0)
        
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            Task { @MainActor in
                self?.processAudio(buffer)
            }
        }
        
        do {
            try engine.start()
            isListening = true
        } catch {
            // Handle error
        }
    }
    
    func stop() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        isListening = false
        reset()
    }
    
    private func reset() {
        currentFrequency = 0
        currentNote = "-"
        currentOctave = 4
        cents = 0
        isInTune = false
    }
    
    private func processAudio(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        
        // Use Accelerate framework for FFT
        let frequency = detectPitch(channelData, frameLength: frameLength)
        
        guard frequency > 50 && frequency < 1500 else { return }
        
        currentFrequency = frequency
        
        // Calculate note
        let (note, octave, centsValue) = frequencyToNote(frequency)
        
        currentNote = note
        currentOctave = octave
        cents = centsValue
        
        // Check if in tune (within ±5 cents)
        isInTune = abs(centsValue) < 5
    }
    
    private func detectPitch(_ data: UnsafeMutablePointer<Float>, frameLength: Int) -> Double {
        // Autocorrelation-based pitch detection
        var autocorrelation = [Float](repeating: 0, count: frameLength)
        
        vDSP_conv(data, 1, data, 1, &autocorrelation, 1, vDSP_Length(frameLength), vDSP_Length(frameLength))
        
        // Find the first peak after the initial decay
        var maxValue: Float = 0
        var maxIndex: vDSP_Length = 0
        
        let minLag = Int(44100.0 / 1500.0)  // Max frequency ~1500Hz
        let maxLag = Int(44100.0 / 50.0)    // Min frequency ~50Hz
        
        for i in minLag..<min(maxLag, frameLength) {
            if autocorrelation[i] > maxValue {
                maxValue = autocorrelation[i]
                maxIndex = vDSP_Length(i)
            }
        }
        
        guard maxValue > 0 else { return 0 }
        
        let sampleRate = 44100.0
        let frequency = sampleRate / Double(maxIndex)
        
        return frequency
    }
    
    private func frequencyToNote(_ frequency: Double) -> (String, Int, Double) {
        // A4 = 440Hz = MIDI note 69
        let a4 = 440.0
        let semitones = 12.0 * log2(frequency / a4)
        let midiNote = Int(round(semitones)) + 69
        
        let noteIndex = midiNote % 12
        let octave = (midiNote / 12) - 1
        
        let noteName = noteNames[noteIndex]
        
        // Calculate cents deviation
        let exactFrequency = a4 * pow(2.0, Double(midiNote - 69) / 12.0)
        let cents = 1200.0 * log2(frequency / exactFrequency)
        
        return (noteName, octave, cents)
    }
}

// MARK: - Tuner View
struct TunerView: View {
    @StateObject private var tuner = Tuner()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTuning: Tuning = .standard
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Note display
                VStack(spacing: 4) {
                    Text(tuner.currentNote)
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(tuner.isInTune ? .green : .primary)
                    
                    Text("\(tuner.currentOctave)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Frequency display
                Text(String(format: "%.1f Hz", tuner.currentFrequency))
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // Tuning meter
                TunerMeter(cents: tuner.cents, isInTune: tuner.isInTune)
                    .frame(height: 60)
                    .padding(.horizontal)
                
                // Tuning selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("目标调弦")
                        .font(.headline)
                    
                    Picker("调弦", selection: $selectedTuning) {
                        ForEach(Tuning.allCases) { tuning in
                            Text(tuning.stringNames.joined(separator: "-")).tag(tuning)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                
                Spacer()
                
                // Start/Stop button
                Button {
                    if tuner.isListening {
                        tuner.stop()
                    } else {
                        tuner.start()
                    }
                } label: {
                    Label(
                        tuner.isListening ? "停止" : "开始调弦",
                        systemImage: tuner.isListening ? "stop.fill" : "mic.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(tuner.isListening ? Color.red : Color.cyan)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("调弦器")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear {
                tuner.stop()
            }
        }
    }
}

// MARK: - Tuner Meter
struct TunerMeter: View {
    let cents: Double
    let isInTune: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let centerX = width / 2
            let indicatorOffset = CGFloat(cents / 50) * (width / 2 - 20)
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(Color.gray.opacity(0.2)))
                
                // Center indicator
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 4, height: 40)
                    .position(x: centerX, y: geometry.size.height / 2)
                
                // Scale markers
                HStack(spacing: 0) {
                    ForEach([-40, -20, 0, 20, 40], id: \.self) { value in
                        VStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 1, height: value == 0 ? 30 : 20)
                            
                            if value != 0 {
                                Text("\(value)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 10)
                
                // Indicator
                Circle()
                    .fill(isInTune ? Color.green : Color.orange)
                    .frame(width: 20, height: 20)
                    .offset(x: indicatorOffset)
                    .animation(.spring(response: 0.2), value: cents)
            }
        }
    }
}

#Preview {
    TunerView()
}
