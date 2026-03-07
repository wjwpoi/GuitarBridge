import SwiftUI

// MARK: - Scale Data
struct ScalePattern: Identifiable {
    let id = UUID()
    let name: String
    let intervals: [Int]  // semitones from root
    let positions: [(string: Int, fret: Int)]  // pattern positions
}

struct ScaleLibrary {
    // Major scale patterns (pentatonic extended)
    static let majorPatterns: [ScalePattern] = [
        ScalePattern(
            name: "Major Pentatonic",
            intervals: [0, 2, 4, 7, 9],
            positions: [
                (1, 0), (1, 2), (1, 3), (1, 5), (1, 7),
                (2, 0), (2, 2), (2, 3), (2, 5), (2, 7),
                (3, 0), (3, 2), (3, 3), (3, 5), (3, 7),
                (4, 0), (4, 2), (4, 3), (4, 5), (4, 7),
                (5, 0), (5, 2), (5, 3), (5, 5), (5, 7),
                (6, 0), (6, 2), (6, 3), (6, 5), (6, 7),
            ]
        ),
    ]
    
    // Minor pentatonic
    static let minorPentatonicPatterns: [ScalePattern] = [
        ScalePattern(
            name: "Minor Pentatonic",
            intervals: [0, 3, 5, 7, 10],
            positions: [
                (1, 0), (1, 3), (1, 5), (1, 7), (1, 10),
                (2, 0), (2, 3), (2, 5), (2, 7), (2, 10),
                (3, 0), (3, 3), (3, 5), (3, 7), (3, 10),
                (4, 0), (4, 3), (4, 5), (4, 7), (4, 10),
                (5, 0), (5, 3), (5, 5), (5, 7), (5, 10),
                (6, 0), (6, 3), (6, 5), (6, 7), (6, 10),
            ]
        ),
    ]
    
    // Blues scale
    static let bluesPatterns: [ScalePattern] = [
        ScalePattern(
            name: "Blues Scale",
            intervals: [0, 3, 5, 6, 7, 10],
            positions: [
                (1, 0), (1, 3), (1, 5), (1, 6), (1, 7), (1, 10),
                (2, 0), (2, 3), (2, 5), (2, 6), (2, 7), (2, 10),
                (3, 0), (3, 3), (3, 5), (3, 6), (3, 7), (3, 10),
                (4, 0), (4, 3), (4, 5), (4, 6), (4, 7), (4, 10),
                (5, 0), (5, 3), (5, 5), (5, 6), (5, 7), (5, 10),
                (6, 0), (6, 3), (6, 5), (6, 6), (6, 7), (6, 10),
            ]
        ),
    ]
    
    // Dorian mode
    static let dorianPatterns: [ScalePattern] = [
        ScalePattern(
            name: "Dorian Mode",
            intervals: [0, 2, 3, 5, 7, 9, 10],
            positions: [
                (1, 0), (1, 2), (1, 3), (1, 5), (1, 7), (1, 9), (1, 10),
                (2, 0), (2, 2), (2, 3), (2, 5), (2, 7), (2, 9), (2, 10),
                (3, 0), (3, 2), (3, 3), (3, 5), (3, 7), (3, 9), (3, 10),
                (4, 0), (4, 2), (4, 3), (4, 5), (4, 7), (4, 9), (4, 10),
                (5, 0), (5, 2), (5, 3), (5, 5), (5, 7), (5, 9), (5, 10),
                (6, 0), (6, 2), (6, 3), (6, 5), (6, 7), (6, 9), (6, 10),
            ]
        ),
    ]
    
    static var allPatterns: [String: [ScalePattern]] {
        [
            "大调五声": majorPatterns,
            "小调五声": minorPentatonicPatterns,
            "蓝调": bluesPatterns,
            "多利亚": dorianPatterns,
        ]
    }
}

// MARK: - Scale Chart View
struct ScaleChartView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRoot = 0
    @State private var selectedType = 0
    
    let roots = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    let types = ["大调", "小调", "大调五声", "小调五声", "蓝调", "多利亚"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Root note picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<roots.count, id: \.self) { index in
                            Button(action: { selectedRoot = index }) {
                                Text(roots[index])
                                    .font(.headline)
                                    .frame(width: 44, height: 44)
                                    .background(selectedRoot == index ? Color.cyan : Color(Color.gray.opacity(0.2)))
                                    .foregroundColor(selectedRoot == index ? .white : .primary)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding()
                }
                
                // Scale type picker
                Picker("音阶类型", selection: $selectedType) {
                    ForEach(0..<types.count, id: \.self) { index in
                        Text(types[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Scale info
                VStack(alignment: .leading, spacing: 8) {
                    Text("根音: \(roots[selectedRoot])")
                        .font(.headline)
                    
                    Text("音阶: \(types[selectedType])")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Notes in scale
                    let notesInScale = getScaleNotes(root: selectedRoot, type: selectedType)
                    Text("音符: \(notesInScale.joined(separator: " - "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // Scale diagram
                ScaleDiagram(root: roots[selectedRoot], type: types[selectedType])
                    .padding()
                
                Spacer()
            }
            .navigationTitle("音阶图谱")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    func getScaleNotes(root: Int, type: Int) -> [String] {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        
        let intervals: [Int]
        switch type {
        case 0: // Major
            intervals = [0, 2, 4, 5, 7, 9, 11]
        case 1: // Minor
            intervals = [0, 2, 3, 5, 7, 8, 10]
        case 2: // Major Pentatonic
            intervals = [0, 2, 4, 7, 9]
        case 3: // Minor Pentatonic
            intervals = [0, 3, 5, 7, 10]
        case 4: // Blues
            intervals = [0, 3, 5, 6, 7, 10]
        case 5: // Dorian
            intervals = [0, 2, 3, 5, 7, 9, 10]
        default:
            intervals = [0, 2, 4, 5, 7, 9, 11]
        }
        
        return intervals.map { noteNames[(root + $0) % 12] }
    }
}

// MARK: - Scale Diagram
struct ScaleDiagram: View {
    let root: String
    let type: String
    
    private let stringNames = ["E", "B", "G", "D", "A", "E"]
    private let frets = 12
    
    var body: some View {
        VStack(spacing: 0) {
            // Fret numbers
            HStack(spacing: 0) {
                ForEach(1...frets, id: \.self) { fret in
                    Text("\(fret)")
                        .font(.caption2)
                        .frame(width: 24, height: 16)
                        .foregroundColor(.gray)
                }
            }
            
            // Fretboard
            GeometryReader { geometry in
                let stringSpacing = geometry.size.width / 6
                let fretSpacing = geometry.size.height / 5
                
                ZStack {
                    // Fretboard
                    Rectangle()
                        .fill(Color(hex: "2d1b0e"))
                    
                    // Frets
                    ForEach(1...5, id: \.self) { fret in
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 1)
                            .offset(y: CGFloat(fret) * fretSpacing)
                    }
                    
                    // Strings
                    ForEach(0..<6, id: \.self) { string in
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: string == 0 || string == 5 ? 2 : 1)
                            .offset(x: CGFloat(string) * stringSpacing - geometry.size.width / 2 + stringSpacing / 2)
                    }
                    
                    // Note dots
                    ForEach(0..<6, id: \.self) { stringIndex in
                        ForEach(1...frets, id: \.self) { fret in
                            let noteIndex = getNoteIndex(string: stringIndex, fret: fret)
                            let rootIndex = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"].firstIndex(of: root) ?? 0
                            let isInScale = isNoteInScale(noteIndex: noteIndex, rootIndex: rootIndex)
                            let isRoot = noteIndex == rootIndex
                            
                            if isInScale {
                                Circle()
                                    .fill(isRoot ? Color.orange : Color.cyan.opacity(0.7))
                                    .frame(width: isRoot ? 16 : 12, height: isRoot ? 16 : 12)
                                    .position(
                                        x: CGFloat(stringIndex) * stringSpacing,
                                        y: CGFloat(fret) * fretSpacing - fretSpacing / 2
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getNoteIndex(string: Int, fret: Int) -> Int {
        // Standard tuning: E4(64), B3(59), G3(55), D3(50), A2(45), E2(40)
        let openNotes = [64, 59, 55, 50, 45, 40]
        let midiNote = openNotes[string] + fret
        return midiNote % 12
    }
    
    func isNoteInScale(noteIndex: Int, rootIndex: Int) -> Bool {
        let intervals: [Int]
        switch type {
        case "大调":
            intervals = [0, 2, 4, 5, 7, 9, 11]
        case "小调":
            intervals = [0, 2, 3, 5, 7, 8, 10]
        case "大调五声":
            intervals = [0, 2, 4, 7, 9]
        case "小调五声":
            intervals = [0, 3, 5, 7, 10]
        case "蓝调":
            intervals = [0, 3, 5, 6, 7, 10]
        case "多利亚":
            intervals = [0, 2, 3, 5, 7, 9, 10]
        default:
            intervals = [0, 2, 4, 5, 7, 9, 11]
        }
        
        let relativeIndex = (noteIndex - rootIndex + 12) % 12
        return intervals.contains(relativeIndex)
    }
}

#Preview {
    ScaleChartView()
}
