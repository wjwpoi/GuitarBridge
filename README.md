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

### Web / PWA

Web 版复用同一套训练引擎、等宽指板、真实吉他采样和本地练习记录。首次访问时点击「开启声音，进入训练」，浏览器会在这次用户操作中激活音频；之后即可点击任意指板音符试听或开始训练。

- 桌面、平板和手机使用同一网址，布局会自动适配；
- 支持浏览器「添加到主屏幕」或「安装应用」；
- 设置、练习记录与连续练习天数保存在当前浏览器；
- 中文字体（思源黑体 / 宋体子集）与引擎兜底字体均随包发布，运行时不访问 Google 域名，适合国内网络；
- 支持浅色 / 深色 / 跟随系统；
- Release 构建包含 PWA 离线缓存、SoLoud WebAssembly 和 19 个真实吉他采样。

```bash
# --no-web-resources-cdn 会把 CanvasKit 一起打包，不再依赖 www.gstatic.com
flutter build web --release --no-web-resources-cdn
pnpm --dir web_host install --frozen-lockfile
pnpm --dir web_host run build
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
│   ├── audio_engine.dart              # 跨平台真实吉他采样与 SoLoud 播放
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
调性建立 → 物理锚点 → 听觉挑战 → 寻址判定 → 反馈与回炉
```

1. **调性建立**：选择调性、音阶、调弦与难度（训练中锁定，避免题目与指板不一致）
2. **物理锚点**：播放基准音，并在指板上标出它的位置（每题随机换弦换把位）
3. **听觉挑战**：紧接着播放调内一个八度以内的上行目标音
4. **寻址判定**：在指板上点击任意同音高的位置；答错会提示「偏高 / 偏低 / 八度不对」
5. **反馈与回炉**：答对或揭示后显示音程名称与所有同音位置；没有首答正确的音程会在本轮稍后再出现一次

计分规则：正确率与连击只统计**第一次就答对**的题；重试后找到的音记为「已解决」但不计入正确率。
每轮结束后显示各音程的首答表现，统计页汇总最近 30 轮的「音程掌握度」。

快捷键（桌面/Web）：`空格` 开始或重听两音，`R` 基准音，`T` 目标音，`Esc` 结束本轮。

## 训练引擎状态机

```
idle → playingRoot → waitingAnswer ⟲（答错重试）→ showingResult → playingRoot → ...
  ↑                        │ 看答案 / 达到上限                          ↓
  └──────────────────── completed ←（题目完成或「结束本轮」）←───────────┘
```

## 技术亮点

- **自适应等宽指板** — 宽屏一次显示 0–22 品；窄屏保持 44px 触控目标并自动滚动到基准音
- **SoLoud audio backend** — CC0 真实吉他多采样，按 MIDI 就近根音重调；采样首次解码后缓存，换音时淡出避免爆音
- **Pitch-based answers** — 按音高判定，任何同音高位置都算对
- **Balanced interval sampling** — 每轮按音程均衡抽题，不受指板位置组合数量干扰；错题音程本轮回炉
- **First-try scoring** — 正确率、连击、音程掌握度都基于首次作答
- **Adaptive planning** — 按最近 30 轮的首答表现给薄弱音程多分配题目，每个音程至少保留一题
- **Design tokens** — `GbColors` 定义浅色/深色两套语义色，所有界面共享同一视觉系统

修改界面中文文案后需重新生成字体子集（否则 `test/font_coverage_test.dart` 会失败）：

```bash
pip install fonttools
python3 tool/subset_fonts.py --sans NotoSansSC[wght].ttf --serif NotoSerifSC[wght].ttf
```

## 实施文档

当前 TODO、验收标准和实施进度见 [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md)。代码变更必须先更新该文档。


## License

MIT
