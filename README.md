# GuitarBridge

相对音准训练工具，帮助用户在调性内识别音程。

## 功能

- **调性训练** - 选择调性，识别音程关系
- **音阶训练** - 12种大调/小调、五声音阶、蓝调音阶
- **相对音准** - 不需要绝对音准，训练内心听觉
- **练习统计** - 记录时长、准确率、连续练习

## 架构

```
GuitarBridgeApp.swift          # App 入口
├── ContentView.swift         # 主界面
│   ├── TrainingOptionsView   # 选项区域（调性、音阶、难度）
│   ├── FretboardSectionView # 指板区域
│   └── TrainingStatusView   # 状态区域（进度、统计）
├── AudioEngine.swift         # 音频引擎（采样播放）
├── TrainingEngine.swift      # 训练逻辑
├── Models/                   # 数据模型
│   ├── PracticeRecord       # 练习记录
│   └── UserPreferences      # 用户设置
└── Utils/                    # 工具类
    ├── Constants.swift      # 常量定义
    └── Theme.swift          # 样式主题
```

## 技术栈

- SwiftUI + AVFoundation
- XcodeGen 项目管理
- Swift 6

## 开发

```bash
# 生成项目
xcodegen generate

# 编译
xcodebuild -project GuitarBridge.xcodeproj -scheme GuitarBridge -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## 团队

- **萨拉托加** - 产品/需求
- **翔鹤** - 开发
- **加贺** - 测试
