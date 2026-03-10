import SwiftUI

struct CompletionAnimationView: View {
    let correctCount: Int
    let totalQuestions: Int
    let streak: Int
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var scale: CGFloat = 0.5
    
    private var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctCount) / Double(totalQuestions) * 100
    }
    
    private var accuracyColor: Color {
        if accuracy >= 80 { return .green }
        if accuracy >= 60 { return .orange }
        return .red
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 24) {
                // Trophy icon
                Image(systemName: accuracy >= 80 ? "trophy.fill" : "star.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(accuracyColor)
                    .scaleEffect(scale)
                
                Text("练习完成!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if showContent {
                    VStack(spacing: 12) {
                        HStack {
                            Text("正确率")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(accuracy))%")
                                .fontWeight(.semibold)
                                .foregroundStyle(accuracyColor)
                        }
                        
                        HStack {
                            Text("正确数量")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(correctCount)/\(totalQuestions)")
                                .fontWeight(.semibold)
                        }
                        
                        if streak > 1 {
                            HStack {
                                Text("最佳连胜")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .foregroundStyle(.orange)
                                    Text("\(streak)")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(UIConstants.cornerRadiusMedium)
                    
                    Button {
                        HapticManager.impact(.medium)
                        onDismiss()
                    } label: {
                        Text("再来一次")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .padding(32)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showContent = true
                }
            }
        }
    }
}
