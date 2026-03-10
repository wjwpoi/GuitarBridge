import SwiftUI

// MARK: - 训练状态视图
/// 显示训练进度、正确率、连胜等信息
struct TrainingStatusView: View {
    // MARK: - Observed Objects
    @ObservedObject var trainingEngine: TrainingEngine
    
    // MARK: - Properties
    let selectedKey: String
    let selectedScale: ScaleType
    let difficulty: Difficulty
    let onStartStop: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 10) {
            // 进度条和问题计数
            HStack(alignment: .top) {
                // 问题进度
                VStack(alignment: .leading, spacing: 2) {
                    Text("问题 \(trainingEngine.completedQuestions + 1)/\(trainingEngine.questionsPerSession)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(trainingEngine.completedQuestions), total: Double(trainingEngine.questionsPerSession))
                        .tint(.green)
                }
                
                Spacer()
                
                // 正确计数
                VStack(alignment: .trailing, spacing: 2) {
                    Text("正确")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(trainingEngine.correctCount)/\(trainingEngine.questionsPerSession)")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                // 连胜计数
                VStack(alignment: .trailing, spacing: 2) {
                    Text("连胜")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(trainingEngine.currentStreak)")
                            .font(.subheadline)
                    }
                }
            }
            
            // 错误提示
            if trainingEngine.lastAnswerCorrect == false, let correct = trainingEngine.targetNote {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("正确位置: 第\(correct.fret)品")
                        .font(.caption)
                    Spacer()
                }
                .padding(UIConstants.paddingSmall)
                .background(.yellow.opacity(0.2))
                .cornerRadius(UIConstants.cornerRadiusSmall)
            }
            
            // 开始/停止按钮
            Button(action: onStartStop) {
                Label(
                    trainingEngine.state == .idle ? "开始训练" : "停止",
                    systemImage: trainingEngine.state == .idle ? "play.fill" : "stop.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .scaleEffect(trainingEngine.state == .idle ? 1.0 : 1.02)
            .animation(.easeInOut(duration: 0.2), value: trainingEngine.state)
            .tint(trainingEngine.state == .idle ? .green : .red)
        }
        .padding(UIConstants.paddingLarge)
        .background {
            RoundedRectangle(cornerRadius: UIConstants.cornerRadiusMedium)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        }
    }
}
