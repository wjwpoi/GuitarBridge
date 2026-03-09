import SwiftUI

// MARK: - SwiftUI UI Patterns 组件库

// MARK: - Card View
/// 带圆角和背景的卡片容器
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(12)
            .background(.regularMaterial)
            .cornerRadius(12)
    }
}

// MARK: - Icon Button
/// 带图标的按钮组件
struct IconButton: View {
    let label: String
    let icon: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(isActive ? activeColor : .blue)
    }
}

// MARK: - Toggle Icon Button
/// 带图标的切换按钮
struct ToggleIconButton: View {
    let label: String
    let icon: String
    let activeIcon: String
    @Binding var isOn: Bool
    let activeColor: Color
    
    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Label(label, systemImage: isOn ? activeIcon : icon)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(isOn ? activeColor : .blue)
    }
}

// MARK: - Status Badge
/// 状态徽章组件
struct StatusBadge: View {
    let icon: String
    let iconColor: Color
    let text: String
    let textColor: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(textColor.opacity(0.15))
        .cornerRadius(8)
    }
}
