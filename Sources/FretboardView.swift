import SwiftUI

struct FretboardView: View {
    let tuning: Tuning
    let theme: Theme
    let onFretTapped: (FretPosition) -> Void
    let isDisabled: Bool
    let selectedPosition: FretPosition?
    let lastAnswerCorrect: Bool?
    var showDegrees: Bool = false
    var showScale: Bool = false
    var currentScale: ScaleType = .major
    var currentKey: String = "C"
    var showNoteNames: Bool = true
    var showFretNumbers: Bool = true
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 2) {
                // Header - 只显示品号
                HStack(spacing: 0) {
                    Text("").frame(width: 30)
                    ForEach(0..<23, id: \.self) { fret in
                        Text(fret > 0 ? "\(fret)" : "").font(.caption).frame(maxWidth: .infinity).foregroundColor(.secondary)
                    }
                }
                
                // Strings
                ForEach([1, 2, 3, 4, 5, 6], id: \.self) { stringNum in
                    fretRow(stringNum: stringNum)
                }
            }
            .padding(8)
        }
    }
    
    private func fretRow(stringNum: Int) -> some View {
        HStack(spacing: 0) {
            // 不显示弦号
            Text("").frame(width: 30)
            ForEach(0..<23, id: \.self) { fret in
                fretButton(string: stringNum, fret: fret)
            }
        }
    }
    
    private func fretButton(string: Int, fret: Int) -> some View {
        let openMIDI = tuning.openStringMidiNotes[string - 1]
        let midi = openMIDI + fret
        let note = GuitarMath.noteNames[midi % 12]
        
        // Use GuitarMath.fretPosition for validated FretPosition creation
        let position = GuitarMath.fretPosition(string: string, fret: fret, tuning: tuning)
        let isSelected = selectedPosition?.midiNote == position.midiNote
        let showCorrect = isSelected && lastAnswerCorrect == true
        let showIncorrect = isSelected && lastAnswerCorrect == false
        let isInScale = isNoteInScale(midi % 12)
        
        // 显示内容根据 showDegrees 和 showNoteNames 决定
        let displayText: String?
        let textColor: Color
        
        if showDegrees {
            // 显示级数模式：只显示罗马数字
            displayText = scaleDegreeLabel(for: midi)
            // 级数使用更深的颜色确保可见
            textColor = isInScale ? .blue : .orange
        } else if showNoteNames {
            // 显示音名
            displayText = note
            textColor = showScale && isInScale ? .blue : .primary
        } else if showFretNumbers && fret > 0 {
            // 只显示品号（当 showFretNumbers 为 true 时）
            displayText = "\(fret)"
            textColor = showScale && isInScale ? .blue : .secondary
        } else {
            displayText = nil
            textColor = .primary
        }
        
        return Button {
            HapticManager.impact(.light)
            onFretTapped(position)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor(for: showCorrect, showIncorrect: showIncorrect, isInScale: isInScale))
                
                if let text = displayText {
                    Text(text)
                        .font(showDegrees ? .system(size: 14, weight: .bold) : .system(size: 12, weight: .semibold))
                        .foregroundColor(textColor)
                }
            }
            .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
    
    private func scaleDegreeLabel(for midiNote: Int) -> String? {
        // Use currentKey as the root to calculate scale degrees
        let keyIndex = GuitarMath.noteNames.firstIndex(of: currentKey) ?? 0
        
        // Calculate semitones from current key
        let noteIndex = midiNote % 12
        let semitones = (noteIndex - keyIndex + 12) % 12
        let degrees = currentScale.intervals
        
        // 判断是否为升降音（黑键：1,3,6,8,10）
        let isSharp = [1, 3, 6, 8, 10].contains(noteIndex)
        
        // Find which degree this note is in the scale
        if let index = degrees.firstIndex(of: semitones) {
            let degreeNames = ["I", "II", "III", "IV", "V", "VI", "VII"]
            let degree = index < degreeNames.count ? degreeNames[index] : nil
            // 添加升降标记
            if let deg = degree {
                return isSharp ? "\(deg)#" : deg
            }
            return nil
        }
        
        // 不在音阶内时显示音名，确保始终有内容显示
        let noteName = GuitarMath.noteNames[noteIndex]
        return isSharp ? "\(noteName)#" : noteName
    }
    
    private func backgroundColor(for showCorrect: Bool, showIncorrect: Bool, isInScale: Bool) -> Color {
        if showCorrect {
            return theme.accentGlowColor.opacity(0.8)
        } else if showIncorrect {
            return Color.red.opacity(0.8)
        } else if showScale && isInScale {
            // 显示音阶时使用蓝色高亮
            return Color.blue.opacity(0.5)
        }
        return theme.inlayColor.opacity(0.5)
    }
    
    private func isNoteInScale(_ noteIndex: Int) -> Bool {
        let keyIndex = GuitarMath.noteNames.firstIndex(of: currentKey) ?? 0
        let semitones = (noteIndex - keyIndex + 12) % 12
        return currentScale.intervals.contains(semitones)
    }
}
