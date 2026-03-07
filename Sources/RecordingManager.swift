import Foundation
import AVFoundation

// MARK: - Note Event
struct NoteEvent: Identifiable, Codable {
    let id = UUID()
    let midiNote: Int
    let timestamp: TimeInterval  // seconds from start
    let duration: TimeInterval  // seconds
    let velocity: UInt8
    
    var noteName: String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (midiNote / 12) - 1
        let note = names[midiNote % 12]
        return "\(note)\(octave)"
    }
}

// MARK: - Recording Session
struct RecordingSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    var name: String
    let trainingMode: String
    let duration: TimeInterval
    let notes: [NoteEvent]
    let accuracy: Double
    
    init(trainingMode: String, duration: TimeInterval, notes: [NoteEvent], accuracy: Double) {
        self.id = UUID()
        self.date = Date()
        self.name = "练习 \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
        self.trainingMode = trainingMode
        self.duration = duration
        self.notes = notes
        self.accuracy = accuracy
    }
}

// MARK: - Recording Manager
@MainActor
class RecordingManager: ObservableObject {
    static let shared = RecordingManager()
    
    @Published var isRecording: Bool = false
    @Published var currentSession: RecordingSession?
    @Published var recordings: [RecordingSession] = []
    @Published var playbackSpeed: Double = 1.0
    @Published var isPlaying: Bool = false
    
    private var recordedNotes: [NoteEvent] = []
    private var sessionStartTime: Date?
    private var trainingMode: String = ""
    private var audioEngine: AudioEngine?
    
    private var playbackTask: Task<Void, Never>?
    
    init() {
        loadRecordings()
    }
    
    // MARK: - Recording
    
    func startRecording(trainingMode: String) {
        recordedNotes = []
        sessionStartTime = Date()
        self.trainingMode = trainingMode
        isRecording = true
    }
    
    func recordNote(midiNote: Int, velocity: UInt8 = 80) {
        guard isRecording, let startTime = sessionStartTime else { return }
        
        let timestamp = Date().timeIntervalSince(startTime)
        
        // Check if this note is already being held (for chords)
        if let existingIndex = recordedNotes.lastIndex(where: { $0.midiNote == midiNote && $0.duration == 0 }) {
            // Note already recorded, update its duration
            let existing = recordedNotes[existingIndex]
            recordedNotes[existingIndex] = NoteEvent(
                midiNote: midiNote,
                timestamp: existing.timestamp,
                duration: timestamp - existing.timestamp,
                velocity: velocity
            )
        } else {
            // New note - record as held (duration = 0 means still playing)
            let note = NoteEvent(midiNote: midiNote, timestamp: timestamp, duration: 0, velocity: velocity)
            recordedNotes.append(note)
        }
    }
    
    func stopNote(midiNote: Int) {
        guard isRecording, let startTime = sessionStartTime else { return }
        
        // Find the note that's still playing and close it
        if let existingIndex = recordedNotes.lastIndex(where: { $0.midiNote == midiNote && $0.duration == 0 }) {
            let existing = recordedNotes[existingIndex]
            let endTime = Date().timeIntervalSince(startTime)
            
            recordedNotes[existingIndex] = NoteEvent(
                midiNote: midiNote,
                timestamp: existing.timestamp,
                duration: endTime - existing.timestamp,
                velocity: existing.velocity
            )
        }
    }
    
    func stopRecording(accuracy: Double = 0) -> RecordingSession? {
        guard isRecording, let startTime = sessionStartTime else { return nil }
        
        isRecording = false
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Close any open notes
        recordedNotes = recordedNotes.map { note in
            if note.duration == 0 {
                return NoteEvent(
                    midiNote: note.midiNote,
                    timestamp: note.timestamp,
                    duration: duration - note.timestamp,
                    velocity: note.velocity
                )
            }
            return note
        }
        
        let session = RecordingSession(
            trainingMode: trainingMode,
            duration: duration,
            notes: recordedNotes,
            accuracy: accuracy
        )
        
        recordings.insert(session, at: 0)
        saveRecordings()
        
        currentSession = session
        recordedNotes = []
        sessionStartTime = nil
        
        return session
    }
    
    func cancelRecording() {
        isRecording = false
        recordedNotes = []
        sessionStartTime = nil
    }
    
    // MARK: - Playback
    
    func configure(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
    }
    
    func playRecording(_ session: RecordingSession) {
        guard !isPlaying, let engine = audioEngine else { return }
        
        isPlaying = true
        playbackTask = Task {
            for note in session.notes {
                guard !Task.isCancelled else { break }
                
                // Play the note
                engine.play(midiNote: note.midiNote)
                
                // Wait for note duration (adjusted by playback speed)
                let waitTime = UInt64(note.duration * 1_000_000_000 / playbackSpeed)
                try? await Task.sleep(nanoseconds: waitTime)
            }
            
            isPlaying = false
        }
    }
    
    func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
    }
    
    // MARK: - Storage
    
    private func saveRecordings() {
        if let data = try? JSONEncoder().encode(recordings) {
            UserDefaults.standard.set(data, forKey: "recordings")
        }
    }
    
    private func loadRecordings() {
        if let data = UserDefaults.standard.data(forKey: "recordings"),
           let saved = try? JSONDecoder().decode([RecordingSession].self, from: data) {
            recordings = saved
        }
    }
    
    func deleteRecording(_ session: RecordingSession) {
        recordings.removeAll { $0.id == session.id }
        saveRecordings()
    }
    
    func renameRecording(_ session: RecordingSession, to name: String) {
        if let index = recordings.firstIndex(where: { $0.id == session.id }) {
            recordings[index].name = name
            saveRecordings()
        }
    }
}
