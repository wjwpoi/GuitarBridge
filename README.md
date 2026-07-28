# GuitarBridge v3.0 — Flutter 跨平台版

> 相对音准训练工具 | 调性内音程识别 | 吉他指板训练

## 重构说明

从原 SwiftUI + AVFoundation 项目完全重构为 **Flutter + Dart** 跨平台架构。

### 为什么选择 Flutter？

| 维度 | SwiftUI (原) | Flutter (新) |
|------|-------------|-------------|
| 平台支持 | macOS/iOS/Watch | iOS/Android/Windows/macOS/Linux/Web |
| 开发语言 | Swift 6 (Actor/Sendable) | Dart (易学易用) |
| 音频引擎 | AVFoundation (Apple only) | flutter_soloud (全平台) |
| 开发工具 | Xcode (macOS only) | VS Code / Android Studio (全平台) |
| 热重载 | SwiftUI Preview | Hot Reload (秒级) |
| 社区生态 | Apple 限定 | Google 维护，插件丰富 |

## 快速开始

### 前置条件

1. 安装 Flutter SDK 3.32.8（Dart 3.8+）
   ```bash
   # macOS
   brew install flutter
   # Windows
   choco install flutter
   # 或从 https://flutter.dev 下载
   ```

2. 安装平台工具链
   - iOS: Xcode 16+
   - Android: Android Studio + SDK
   - Windows: Visual Studio 2022 (Desktop C++)
   - macOS: Xcode CLT

### 启动

```bash
cd GuitarBridge

# 安装依赖
flutter pub get

# 运行（自动检测连接设备）
flutter run

# 运行在特定平台
flutter run -d windows
flutter run -d macos
flutter run -d chrome
```

### 测试

```bash
flutter test
```

## 项目结构

```
lib/
├── main.dart                          # 入口：初始化 + 路由
├── models/
│   ├── note.dart                      # 音符、音程、级数
│   ├── scale.dart                     # 12种音阶 + 调性
│   ├── tuning.dart                    # 6种调弦配置
│   └── practice_record.dart           # 练习记录 + 用户设置
├── core/
│   ├── guitar_math.dart               # 音程计算、指板数学(17.817品距)
│   ├── constants.dart                 # 全局常量
│   └── theme.dart                     # 主题 + 音色配色
├── engine/
│   ├── audio_engine.dart              # 跨平台音频(采样+合成+crossfade)
│   └── training_engine.dart           # 训练状态机(6状态)
├── services/
│   ├── storage_service.dart           # 数据持久化
│   ├── streak_manager.dart            # 连续练习管理
│   └── haptic_manager.dart            # 触感反馈
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart           # 主训练界面
│   │   ├── onboarding_screen.dart     # 首次引导
│   │   ├── stats_screen.dart          # 练习统计
│   │   └── settings_screen.dart       # 设置页
│   └── widgets/
│       ├── fretboard_widget.dart      # 指板(CustomPainter)
│       ├── training_options.dart      # 选项面板
│       ├── training_status.dart       # 状态+操作
│       ├── completion_animation.dart  # 完成动画
│       └── scale_chart.dart           # 音阶图表
└── test/
    └── guitar_math_test.dart          # 单元测试(音程/调性/指板)
```

## 核心逻辑

```
调性建立 → 物理锚点 → 听觉挑战 → 寻址判定
```

1. **调性建立**：选择 C大调 / G大调 / A小调...
2. **物理锚点**：播放基准音，与指板位置对应
3. **听觉挑战**：播放调内另一个音
4. **寻址判定**：用户在指板上点击目标位置

## 训练引擎状态机

```
idle → playingRoot → waitingAnswer → showingResult → playingRoot → ...
  ↑                                                         ↓
  └───────────────── completed ←────────────────────────────┘
```

## 技术亮点

- **17.817 品距公式** — 物理准确的指板比例绘制
- **SoLoud audio backend** — 三种音色采样，缺失采样时自动合成正弦波
- **Position-aware answers** — 精确到弦和品的寻址判定
- **Duplicate prevention** — 同一音程组合不会重复出题
- **6-state FSM** — 完整的训练生命周期管理

## 实施文档

当前 TODO、验收标准和实施进度见 [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md)。代码变更必须先更新该文档。


## License

MIT
