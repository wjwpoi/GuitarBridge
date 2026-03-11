import Foundation
import SwiftUI

enum Interval: String, CaseIterable, Identifiable, Codable {
    case unison = "同音"
    case minorSecond = "小二度"
    case majorSecond = "大二度"
    case minorThird = "小三度"
    case majorThird = "大三度"
    case perfectFourth = "纯四度"
    case tritone = "三全音"
    case perfectFifth = "纯五度"
    case minorSixth = "小六度"
    case majorSixth = "大六度"
    case minorSeventh = "小七度"
    case majorSeventh = "大七度"
    case octave = "八度"
    
    var id: String { rawValue }
    
    var semitones: Int {
        switch self {
        case .unison: return 0
        case .minorSecond: return 1
        case .majorSecond: return 2
        case .minorThird: return 3
        case .majorThird: return 4
        case .perfectFourth: return 5
        case .tritone: return 6
        case .perfectFifth: return 7
        case .minorSixth: return 8
        case .majorSixth: return 9
        case .minorSeventh: return 10
        case .majorSeventh: return 11
        case .octave: return 12
        }
    }
    
    static func from(semitones: Int) -> Interval? {
        return allCases.first { $0.semitones == semitones }
    }
}

enum TrainingMode: String, CaseIterable, Identifiable, Codable {
    case scaleDegrees = "音阶"
    case intervals = "音程"
    case chords = "和弦"
    
    var id: String { rawValue }
}

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    
    var id: String { rawValue }
    
    var intervalRange: [Int] {
        switch self {
        case .easy: return [0, 7]
        case .medium: return [0, 4, 7, 11]
        case .hard: return [0, 2, 4, 5, 7, 9, 11]
        }
    }
}

enum ScaleType: String, CaseIterable, Identifiable, Codable {
    case major = "大调"
    case minor = "小调"
    case blues = "蓝调"
    case dorian = "多利亚"
    case phrygian = "弗里几亚"
    case lydian = "利底亚"
    case mixolydian = "混合利底亚"
    case locrian = "洛克里亚"
    case pentatonicMajor = "大调五声"
    case pentatonicMinor = "小调五声"
    case harmonicMinor = "和声小调"
    case melodicMinor = "旋律小调"
    
    var id: String { rawValue }
    
    // 音阶音程（相对于根音）
    var intervals: [Int] {
        switch self {
        case .major: return [0, 2, 4, 5, 7, 9, 11]
        case .minor: return [0, 2, 3, 5, 7, 8, 10]
        case .blues: return [0, 3, 5, 6, 7, 10]
        case .dorian: return [0, 2, 3, 5, 7, 9, 10]
        case .phrygian: return [0, 1, 3, 5, 7, 8, 10]
        case .lydian: return [0, 2, 4, 6, 7, 9, 11]
        case .mixolydian: return [0, 2, 4, 5, 7, 9, 10]
        case .locrian: return [0, 1, 3, 5, 6, 8, 10]
        case .pentatonicMajor: return [0, 2, 4, 7, 9]
        case .pentatonicMinor: return [0, 3, 5, 7, 10]
        case .harmonicMinor: return [0, 2, 3, 5, 7, 8, 11]
        case .melodicMinor: return [0, 2, 3, 5, 7, 9, 11]
        }
    }
}

enum SolfegeNote: String, CaseIterable, Identifiable, Codable {
    case doFirst = "主音 (I)"
    case re = "上主音 (II)"
    case mi = "中音 (III)"
    case fa = "下属音 (IV)"
    case sol = "属音 (V)"
    case la = "下中音 (VI)"
    case ti = "导音 (VII)"
    
    var id: String { rawValue }
    
    var intervalFromRoot: Int {
        switch self {
        case .doFirst: return 0
        case .re: return 2
        case .mi: return 4
        case .fa: return 5
        case .sol: return 7
        case .la: return 9
        case .ti: return 11
        }
    }
}

enum TrainingState: Equatable {
    case idle
    case playingAnchor
    case playingTarget
    case awaitingAnswer
    case showingResult(correct: Bool)
    case completed
}

@MainActor
class TrainingEngine: ObservableObject {
    @Published var state: TrainingState = .idle
    @Published var currentKey: String = "C"
    @Published var selectedDegree: SolfegeNote = .doFirst
    @Published var trainingMode: TrainingMode = .scaleDegrees
    @Published var scaleType: ScaleType = .major
    @Published var difficulty: Difficulty = .easy
    let anchorPlayCount = 3
    @Published var correctCount: Int = 0
    @Published var totalAttempts: Int = 0
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var sessionStartTime: Date?
    @Published var anchorNote: FretPosition?
    @Published var targetNote: FretPosition?
    @Published var currentInterval: Int = 0
    @Published var userAnswer: FretPosition?
    @Published var lastAnswerCorrect: Bool?
    
    private var audioEngine: AudioEngine?
    private var playbackSessionToken: Int = 0
    private var currentTuning: Tuning = .standard
    private var previousTargetPosition: FretPosition?
    var sleep: @Sendable (UInt64) async -> Void = { duration in
        try? await Task.sleep(nanoseconds: duration)
    }
    
    /// 用户可配置的问题数量（优先使用，否则使用难度默认值）
    @AppStorage("customQuestionCount") var customQuestionCount: Int = 0
    
    var questionsPerSession: Int {
        // 优先使用用户自定义数量
        if customQuestionCount > 0 {
            return customQuestionCount
        }
        // 否则使用难度默认值
        switch difficulty {
        case .easy: return 5
        case .medium: return 10
        case .hard: return 15
        }
    }
    var completedQuestions = 0
    
    func configure(audioEngine: AudioEngine, tuning: Tuning) {
        self.audioEngine = audioEngine
        self.currentTuning = tuning
    }
    
    func startTraining() {
        sessionStartTime = Date()
        correctCount = 0
        totalAttempts = 0
        currentStreak = 0
        completedQuestions = 0
        playbackSessionToken += 1
        state = .playingAnchor
        playAnchorNotes(sessionToken: playbackSessionToken)
    }
    
    private func playAnchorNotes(sessionToken: Int) {
        guard sessionToken == playbackSessionToken else { return }
        guard let anchor = anchorNote else {
            startQuestion()
            return
        }
        
        audioEngine?.play(midiNote: anchor.midiNote)
        Task { @MainActor in
            guard sessionToken == self.playbackSessionToken else { return }
            for _ in 0..<2 {
                await self.sleep(PracticeConstants.Audio.anchorNoteDelay)
                guard sessionToken == self.playbackSessionToken else { return }
                self.audioEngine?.play(midiNote: anchor.midiNote)
            }
            await self.sleep(PracticeConstants.Audio.anchorToTargetDelay)
            guard sessionToken == self.playbackSessionToken else { return }
            self.playTargetNote(sessionToken: sessionToken)
        }
    }
    
    private func playTargetNote(sessionToken: Int) {
        guard sessionToken == playbackSessionToken else { return }
        state = .playingTarget
        
        guard let target = targetNote else {
            state = .awaitingAnswer
            return
        }
        
        audioEngine?.play(midiNote: target.midiNote)
        
        Task { @MainActor in
            await self.sleep(PracticeConstants.Audio.targetToAnswerDelay)
            guard sessionToken == self.playbackSessionToken else { return }
            self.state = .awaitingAnswer
        }
    }
    
    func startQuestion() {
        guard completedQuestions < questionsPerSession else {
            state = .completed
            #if DEBUG
            print("[Training] Session completed: \(correctCount)/\(questionsPerSession)")
            #endif
            saveToUserDefaults()
            return
        }
        
        generateQuestion()
        playbackSessionToken += 1
        state = .playingAnchor
        playAnchorNotes(sessionToken: playbackSessionToken)
    }
    
    private func visibleFretRange() -> ClosedRange<Int> {
        let maxVisibleFret = min(12, 8 + (correctCount * 2))
        return 0...max(4, maxVisibleFret)
    }

    private func candidatePositions(in fretRange: ClosedRange<Int>) -> [FretPosition] {
        var positions: [FretPosition] = []
        for string in 1...6 {
            for fret in fretRange {
                positions.append(GuitarMath.fretPosition(string: string, fret: fret, tuning: currentTuning))
            }
        }
        return positions
    }

    private func weightedAnchorCandidates(from positions: [FretPosition], keyIndex: Int) -> [FretPosition] {
        let scaleIntervals = Set(scaleType.intervals)
        let previous = previousTargetPosition
        return positions.filter { position in
            let semitonesFromKey = (position.midiNote % 12 - keyIndex + 12) % 12
            guard scaleIntervals.contains(semitonesFromKey) else { return false }
            guard let previous else { return true }
            return abs(position.fret - previous.fret) <= 4 && abs(position.string - previous.string) <= 2
        }
    }

    private func pickAnchor(from visiblePositions: [FretPosition], keyIndex: Int) -> FretPosition {
        let nearbyCandidates = weightedAnchorCandidates(from: visiblePositions, keyIndex: keyIndex)
        let fallbackCandidates = visiblePositions.filter {
            let semitonesFromKey = ($0.midiNote % 12 - keyIndex + 12) % 12
            return scaleType.intervals.contains(semitonesFromKey)
        }
        if !nearbyCandidates.isEmpty && Int.random(in: 0..<100) < 75 {
            return nearbyCandidates.randomElement() ?? visiblePositions[0]
        }
        return (fallbackCandidates.randomElement() ?? visiblePositions.randomElement()) ?? GuitarMath.fretPosition(string: 3, fret: 5, tuning: currentTuning)
    }

    private func pickTarget(for anchor: FretPosition, in visiblePositions: [FretPosition], keyIndex: Int) -> FretPosition {
        let scaleIntervals = scaleType.intervals
        let semitonesFromKey = (anchor.midiNote % 12 - keyIndex + 12) % 12
        let anchorDegreeIndex = scaleIntervals.firstIndex(of: semitonesFromKey) ?? 0
        let availableDegrees = (0..<scaleIntervals.count).filter { $0 != anchorDegreeIndex }
        let targetDegreeIndex = availableDegrees.randomElement() ?? 0
        let targetSemitones = scaleIntervals[targetDegreeIndex]
        currentInterval = abs(targetSemitones - semitonesFromKey)

        let candidates = visiblePositions.filter { position in
            guard position != anchor else { return false }
            let candidateSemitones = (position.midiNote % 12 - keyIndex + 12) % 12
            guard candidateSemitones == targetSemitones else { return false }
            return abs(position.fret - anchor.fret) <= 5 && abs(position.string - anchor.string) <= 2
        }

        if !candidates.isEmpty && Int.random(in: 0..<100) < 80 {
            return candidates.min {
                let left = abs($0.fret - anchor.fret) + abs($0.string - anchor.string) * 2
                let right = abs($1.fret - anchor.fret) + abs($1.string - anchor.string) * 2
                return left < right
            } ?? candidates[0]
        }

        let relaxedCandidates = visiblePositions.filter { position in
            guard position != anchor else { return false }
            let candidateSemitones = (position.midiNote % 12 - keyIndex + 12) % 12
            return candidateSemitones == targetSemitones
        }
        return relaxedCandidates.randomElement() ?? anchor
    }
    
    private func generateQuestion() {
        let keyIndex = getKeyMidiIndex()
        let visiblePositions = candidatePositions(in: visibleFretRange())

        let anchor = pickAnchor(from: visiblePositions, keyIndex: keyIndex)
        let target = pickTarget(for: anchor, in: visiblePositions, keyIndex: keyIndex)

        anchorNote = anchor
        targetNote = target
        previousTargetPosition = target
    }
    
    func submitAnswer(_ position: FretPosition) {
        userAnswer = position
        let isCorrect = position.midiNote == targetNote?.midiNote
        let sessionToken = playbackSessionToken
        
        if isCorrect {
            HapticManager.notification(.success)
            correctCount += 1
            currentStreak += 1
            if currentStreak > bestStreak { bestStreak = currentStreak }
            totalAttempts += 1
            completedQuestions += 1
            lastAnswerCorrect = true
            state = .showingResult(correct: true)
            
            Task { @MainActor in
                await self.sleep(PracticeConstants.Audio.correctAnswerDelay)
                guard sessionToken == self.playbackSessionToken else { return }
                self.nextQuestion(sessionToken: sessionToken)
            }
        } else {
            HapticManager.notification(.error)
            currentStreak = 0
            totalAttempts += 1
            lastAnswerCorrect = false
            state = .showingResult(correct: false)
            
            Task { @MainActor in
                await self.sleep(PracticeConstants.Audio.wrongAnswerDelay)
                guard sessionToken == self.playbackSessionToken else { return }
                self.userAnswer = nil
                self.lastAnswerCorrect = nil
                self.state = .awaitingAnswer
            }
        }
    }
    
    func nextQuestion(sessionToken: Int? = nil) {
        if let sessionToken, sessionToken != playbackSessionToken { return }
        userAnswer = nil
        lastAnswerCorrect = nil
        startQuestion()
    }
    
    private func saveToUserDefaults() {
        let sessionData: [String: Any] = [
            "date": Date().timeIntervalSince1970,
            "correct": correctCount,
            "total": questionsPerSession,
            "difficulty": difficulty.rawValue,
            "scale": scaleType.rawValue
        ]
        var sessions = UserDefaults.standard.array(forKey: "practiceSessions") as? [[String: Any]] ?? []
        sessions.insert(sessionData, at: 0)
        if sessions.count > 100 { sessions = Array(sessions.prefix(100)) }
        UserDefaults.standard.set(sessions, forKey: "practiceSessions")
    }
    
    func reset() {
        playbackSessionToken += 1
        sessionStartTime = nil
        state = .idle
        anchorNote = nil
        targetNote = nil
        userAnswer = nil
        completedQuestions = 0
    }
    
    // 重新播放锚点音（供用户在学习模式中参考）
    func replayAnchorNote() {
        guard let anchor = anchorNote else { return }
        
        audioEngine?.play(midiNote: anchor.midiNote)
    }
    
    // 重新播放目标音
    func replayTargetNote() {
        guard let target = targetNote else { return }
        
        audioEngine?.play(midiNote: target.midiNote)
    }
    
    // MARK: - Helper functions for key-based note generation
    
    private func getKeyMidiIndex() -> Int {
        return GuitarMath.noteNames.firstIndex(of: currentKey) ?? 0
    }
    
    private func getNotesForKey(_ keyIndex: Int, string: Int, fret: Int) -> [Int] {
        let openMidi = currentTuning.openStringMidiNotes[string - 1]
        let scaleIntervals = scaleType.intervals
        
        var notes: [Int] = []
        
        // Find all notes within current scale on this string
        for f in 0...15 {
            let midi = openMidi + f
            let noteIndex = midi % 12
            let semitonesFromKey = (noteIndex - keyIndex + 12) % 12
            
            if scaleIntervals.contains(semitonesFromKey) {
                notes.append(midi)
            }
        }
        
        return notes
    }
}
