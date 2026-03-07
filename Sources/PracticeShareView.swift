import SwiftUI

// MARK: - Share Card View
struct PracticeShareCard: View {
    let accuracy: Double
    let duration: TimeInterval
    let correctCount: Int
    let totalCount: Int
    let streak: Int
    let achievements: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("🎸")
                    .font(.title)
                Text("GuitarBridge 练习报告")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            // Stats
            HStack(spacing: 20) {
                StatItem(value: String(format: "%.0f%%", accuracy), label: "准确率", color: accuracyColor)
                StatItem(value: "\(Int(duration / 60))", label: "分钟", color: .cyan)
                StatItem(value: "\(correctCount)/\(totalCount)", label: "题数", color: .green)
            }
            
            Divider()
            
            // Streak & Achievements
            HStack {
                Label("\(streak) 天连续", systemImage: "flame.fill")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Label("\(achievements) 徽章", systemImage: "star.fill")
                    .font(.subheadline)
                    .foregroundColor(.yellow)
            }
            
            // Footer
            Text("用 GuitarBridge 学习吉他")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    var accuracyColor: Color {
        if accuracy >= 90 { return .green }
        if accuracy >= 70 { return .orange }
        return .red
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Share View
struct PracticeShareView: View {
    @Environment(\.dismiss) private var dismiss
    
    let accuracy: Double
    let duration: TimeInterval
    let correctCount: Int
    let totalCount: Int
    let streak: Int
    let achievements: Int
    
    @State private var isSaving = false
    @State private var showSaveSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Preview card
                    PracticeShareCard(
                        accuracy: accuracy,
                        duration: duration,
                        correctCount: correctCount,
                        totalCount: totalCount,
                        streak: streak,
                        achievements: achievements
                    )
                    .padding()
                    
                    // Share buttons
                    VStack(spacing: 12) {
                        Button {
                            shareImage()
                        } label: {
                            Label("分享图片", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cyan)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            saveToPhotos()
                        } label: {
                            Label("保存到相册", systemImage: "photo")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    if showSaveSuccess {
                        Text("✅ 已保存到相册")
                            .foregroundColor(.green)
                    }
                }
                .padding()
            }
            .navigationTitle("分享练习")
            .toolbar { ToolbarItem(placement: .principal) { Text("") } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    func shareImage() {
        let renderer = ImageRenderer(content: PracticeShareCard(
            accuracy: accuracy,
            duration: duration,
            correctCount: correctCount,
            totalCount: totalCount,
            streak: streak,
            achievements: achievements
        ))
        
        renderer.scale = 3.0
        
        #if canImport(UIKit)
        if let image = renderer.uiImage {
            let activityVC = UIActivityViewController(
                activityItems: [image],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
        #endif
    }
    
    func saveToPhotos() {
        let renderer = ImageRenderer(content: PracticeShareCard(
            accuracy: accuracy,
            duration: duration,
            correctCount: correctCount,
            totalCount: totalCount,
            streak: streak,
            achievements: achievements
        ))
        
        renderer.scale = 3.0
        
        #if canImport(UIKit)
        if let image = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            showSaveSuccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSaveSuccess = false
            }
        }
        #endif
    }
}

// MARK: - Quick Share Button
struct QuickShareButton: View {
    let accuracy: Double
    let duration: TimeInterval
    let correctCount: Int
    let totalCount: Int
    let streak: Int
    let achievements: Int
    
    var body: some View {
        ShareLink(
            item: generateShareText(),
            subject: Text("GuitarBridge 练习报告"),
            message: Text(generateShareText())
        ) {
            Label("分享", systemImage: "square.and.arrow.up")
        }
    }
    
    func generateShareText() -> String {
        """
        🎸 GuitarBridge 练习报告
        
        准确率: \(String(format: "%.0f%%", accuracy))
        练习时长: \(Int(duration / 60)) 分钟
        完成题数: \(correctCount)/\(totalCount)
        连续天数: \(streak)
        
        用 GuitarBridge 学习吉他！
        """
    }
}

#Preview {
    PracticeShareView(
        accuracy: 85,
        duration: 1800,
        correctCount: 17,
        totalCount: 20,
        streak: 7,
        achievements: 5
    )
}
