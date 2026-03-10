import SwiftUI

// MARK: - 训练选项视图
/// 包含调性、音阶、调弦、难度等训练选项
struct TrainingOptionsView: View {
    // MARK: - Bindings
    @Binding var selectedKey: String
    @Binding var selectedScale: ScaleType
    @Binding var selectedTuning: Tuning
    @Binding var difficulty: Difficulty
    @Binding var showDegrees: Bool
    @Binding var showScale: Bool
    @Binding var showSettings: Bool
    
    // MARK: - Constants
    private let keys = ["C", "D", "E", "F", "G", "A", "B"]
    private let difficulties = Difficulty.allCases
    private let scales = ScaleType.allCases
    private let tunings = Tuning.allCases
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            // 第一行：调性、音阶、调弦
            HStack(spacing: 12) {
                // 调性选择器
                VStack(alignment: .leading, spacing: 2) {
                    Text("调性")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("调性", selection: $selectedKey) {
                        ForEach(keys, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }
                
                // 音阶选择器
                VStack(alignment: .leading, spacing: 2) {
                    Text("音阶")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("音阶", selection: $selectedScale) {
                        ForEach(scales) { scale in
                            Text(scale.rawValue).tag(scale)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // 调弦选择器
                VStack(alignment: .leading, spacing: 2) {
                    Text("调弦")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("调弦", selection: $selectedTuning) {
                        ForEach(tunings) { tuning in
                            Text(tuning.rawValue).tag(tuning)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Spacer()
            }
            
            // 第二行：难度选择器
            VStack(alignment: .leading, spacing: 4) {
                Text("难度")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("难度", selection: $difficulty) {
                    ForEach(difficulties) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .tint(.blue)
            }
            
            // 第三行：显示选项
            HStack(spacing: 16) {
                // 显示级数开关
                Toggle(isOn: $showDegrees) {
                    Label("级数", systemImage: "number")
                }
                .font(.subheadline)
                .tint(showDegrees ? .blue : .gray)
                
                // 显示音阶按钮
                Button {
                    showScale.toggle()
                } label: {
                    Label(showScale ? "隐藏" : "显示", systemImage: showScale ? "eye.slash.fill" : "eye.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(showScale ? .orange : .blue)
                
                Spacer()
                
                // 音色设置按钮
                Button {
                    showSettings = true
                } label: {
                    Label("音色", systemImage: "speaker.wave.3.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.orange)
            }
        }
        .padding(UIConstants.paddingLarge)
        .background(.regularMaterial)
        .cornerRadius(UIConstants.cornerRadiusMedium)
    }
}
