import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    
    @State private var currentPage = 0
    
    private let pages: [(String, String, String)] = [
        ("guitar", "选择音阶和难度", "从大调、小调、蓝调等多种音阶中选择难度"),
        ("brain.head.profile", "听力训练", "听辨音程和级数，提升听力技巧"),
        ("flame", "每日练习", "保持连续练习，逐步提升听力水平")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 24) {
                        Image(systemName: pages[index].0)
                            .font(.system(size: 80))
                            .foregroundStyle(.orange)
                            .padding(.top, 60)
                        
                        Text(pages[index].1)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(pages[index].2)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            VStack(spacing: 16) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "下一步" : "开始练习")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(UIConstants.cornerRadiusMedium)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - First Launch Manager

@MainActor
class FirstLaunchManager: ObservableObject {
    static let shared = FirstLaunchManager()
    
    private let hasLaunchedKey = "hasLaunchedBefore"
    
    @Published var hasLaunched: Bool {
        didSet {
            UserDefaults.standard.set(hasLaunched, forKey: hasLaunchedKey)
        }
    }
    
    private init() {
        self.hasLaunched = UserDefaults.standard.bool(forKey: hasLaunchedKey)
    }
    
    func markLaunched() {
        hasLaunched = true
    }
}
