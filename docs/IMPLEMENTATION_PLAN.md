# GuitarBridge 实施计划与进度

> 本文档是当前代码库的工作契约。修改代码前先更新本文件；完成一项代码工作后，必须同步更新状态、验收结果和遗留问题。

## 目标与决策

- 跨平台是硬需求，继续使用 Flutter，不回退到 Swift-only 实现。
- 不再进行第二次全量重写；保留现有 UI 与基础模型，对核心闭环做定向重构。
- 发布前必须同时满足：可构建、可听见、可交互、可恢复、可测试。

## 当前风险基线

以下项目已经在工作区完成初步实现，但尚未通过固定 Flutter SDK 的完整验证，提交前仍视为风险项：

- SoLoud 初始化、采样加载和合成回退已接通；需要验证 Android、iOS、macOS、Windows、Linux、Web 的 API 和资源行为。
- 题目已保存目标弦位/品位，默认精确判定；需要验证旧调用方和完整训练状态机。
- 训练异步任务已加入 generation token，题目池改为有限生成；需要补充页面销毁和重复启动回归验证。
- 指板绘制与点击已共用品距坐标，并保留同音位置；需要做窄屏和各平台交互检查。
- 统计、streak、设置已接入持久化；需要验证迁移旧 JSON、重启恢复和清除语义。
- Flutter 平台目录和 lockfile 尚未生成；CI 工作流已收紧，需用真实构建结果校正平台配置。

## 分阶段 TODO

### P0：跨平台可运行基线

- [ ] 纳入 Android、iOS、macOS、Windows、Linux、Web 平台工程目录。
- [ ] 固定 Flutter/Dart 版本和 pub 依赖，提交 `pubspec.lock`。
- [ ] 修复 CI：format、analyze、test 必须阻断；至少构建 Android、Web、macOS、Windows。
- [ ] 构建脚本遇到任一平台失败时必须返回非零状态。
- [ ] 真实初始化 SoLoud，加载三种音色采样，缺失时使用可听见的合成回退。

### P1：训练正确性

- [ ] 用不可变题目模型保存锚点和目标的弦、品、MIDI。
- [ ] 默认按精确弦位/品位判定；保留可配置的音高类判定模式。
- [ ] 等待回答时不得显示目标位置或目标音名提示。
- [ ] 为训练异步流程增加 generation token，`reset`、新一轮和页面销毁后旧任务不得回写状态。
- [ ] 题目池显式生成和打乱，题量超过可用题目数时有确定的错误/降级策略。
- [ ] 指板点击和绘制共用同一品距坐标，完整支持 0–22 品及所有同音位置。

### P1：数据与设置

- [ ] 统计页读取 `StreakManager` 的真实记录并在完成训练后立即刷新。
- [ ] 连续练习按本地日期去重但保留历史日期，修复 current/best streak。
- [ ] 清除统计同时清除记录和 streak 持久化数据。
- [ ] 设置中的题量、显示选项、音量和音色真正影响 Home/TrainingEngine，并在重启后恢复。

### P2：质量与发布

- [ ] 为数学、题目池、FSM 取消、持久化、采样映射、关键 Widget 增加回归测试。
- [ ] 发布工作流复用已通过 CI 的构建，上传 APK、Web 压缩包和校验文件。
- [ ] 明确尚未迁移的 Swift 功能：调音器、节拍器、日志、分享、录音、Watch/Widget。

## 验收标准

1. `flutter format --set-exit-if-changed .`、`flutter analyze`、`flutter test --coverage` 全部通过。
2. Android、Web、macOS、Windows 至少能完成 release build；iOS/Linux 工程能完成依赖解析和 debug build。
3. 首次启动可播放根音和目标音；clean、overdrive、distortion 均有可听见输出或明确错误状态。
4. 点击错误弦位/品位不会判对；点击正确目标位置会进入下一题；等待回答界面不泄露答案。
5. 训练中 reset、重复 start、离开页面不会出现旧音频任务改变当前状态。
6. 完成训练后统计立即出现，应用重启后记录、streak 和设置仍存在。

## 核心实现约定

- `TrainingQuestion` 必须同时保存 `root` 和 `target` 的 `stringIndex`、`fret`、`midi`，UI 点击回传完整 `FretPosition`。
- 默认 `AnswerMode.exactPosition` 比较弦和品；未来若增加听音练习模式，`AnswerMode.pitchClass` 必须是显式配置，不能隐式替代精确寻址。
- 训练异步流程以 generation token 绑定；每次 `start`、`reset`、完成或销毁都使旧 token 失效。
- 题目池一次性按当前调性、调弦、难度生成并打乱；题量超过池容量时取模循环但不重复同一轮中的题目，禁止无界递归。
- 指板绘制和点击都由同一个 `fretX(fret)` 坐标函数计算；完整指板显示 0–22 品，不能删除同音位置。
- `UserPreferences` 是唯一设置来源，题量、显示开关、音量和音色都必须序列化；Home、Settings 和 TrainingEngine 通过同一对象同步。
- `StreakManager.records` 是统计页的唯一数据入口；日期 streak 按本地日去重，但不得删除历史日期，清除操作必须同时清空两类存储。

## 实施进度

| 阶段 | 状态 | 说明 |
| --- | --- | --- |
| 文档、TODO、验收标准 | 已完成 | 本文档先于代码变更创建 |
| 平台工程与可复现流水线 | 进行中 | 已固定 SDK/依赖、恢复质量门禁并修复构建脚本；平台目录和 lockfile 待生成 |
| 音频与训练核心 | 进行中 | 训练题目已改为具体弦位，题库有限生成并支持确定性循环，增加 generation token；训练提交安全性待 SDK 验证，音频另行提交 |
| 持久化、统计、设置 | 进行中 | 已修复 streak 历史/清除、暴露真实 records、设置序列化并接入 Home；待 SDK 验证和测试补齐 |
| 测试与发布验证 | 进行中 | 已增加题目、采样映射、存储回归测试；等待临时 Flutter SDK 完成安装后执行 |

## 本轮不做

- 不在核心闭环稳定前迁移所有 Swift 辅助功能。
- 不用 `continue-on-error` 隐藏质量问题。
- 不以“等待一段时间”模拟音频播放成功。

## 协作与提交时间线

本项目按“文档先行、功能分组、提交即时间线”推进，以便低上下文或低能力模型也能按照明确契约继续工作：

1. 每次代码修改前，先在本文件更新目标、影响范围、验收命令和待办状态。
2. 每个独立功能组使用一个提交；不要把平台工程、领域逻辑、音频、数据设置和测试混在同一个提交中。
3. 代码提交后立即回写本文件的实施进度、验证结果和遗留风险，并另提交一个 `docs:` 提交；若文档与代码必须原子同步，则在同一功能提交中同时包含文档变更，并在提交信息中说明。
4. 提交前至少执行与影响范围匹配的格式化、静态分析和测试；跨平台改动必须记录每个平台的构建结果或明确阻塞原因。
5. 后续协作者先阅读本文件和最近的提交记录，再开始修改；不得依赖未记录在文档中的隐式状态。

### 提交时间线

| 顺序 | 提交类型 | 内容 | 状态 |
| --- | --- | --- | --- |
| 1 | `docs:` | 建立架构决策、TODO、验收标准和协作规则 | 已提交 `b3fb36d` |
| 2 | `build:` | 固定 SDK/依赖、恢复 CI 门禁、生成平台工程 | 配置待提交，平台工程待 SDK 安装 |
| 3 | `feat:` | 位置感知题目、有限题库和可取消训练 FSM | 待提交 |
| 4 | `feat:` | SoLoud 采样与合成回退 | 待提交 |
| 5 | `feat:` | 设置、记录和 streak 持久化 | 待提交 |
| 6 | `test:` | 领域模型、采样映射、存储和 Widget 回归测试 | 待提交 |
| 7 | `fix:` | SDK 验证产生的平台兼容性修复 | 待产生 |
| 8 | `docs:` | 最终进度、真实验证结果和未迁移功能清单 | 待产生 |

### 下一提交门禁：流水线与依赖

- 变更范围：CI/release 工作流、`.gitignore`、`pubspec.yaml`、跨平台构建脚本和 README 启动说明。
- 必须满足：Flutter 版本固定为 3.32.8；`pubspec.lock` 不再被忽略；format、analyze、test 和资源数量检查会阻断流水线；构建脚本遇到失败返回非零状态。
- 验收命令：`dart format --output=none --set-exit-if-changed .`、`flutter analyze`、`flutter test`；平台目录生成后追加各平台 release/debug 构建。

### 下一提交门禁：训练核心

- 变更范围：`TrainingQuestion`、`TrainingEngine`、指板点击/绘制和 Home 训练回调。
- 必须满足：题量超过有限题库时按已打乱的题库循环但不递归；非法服务调用不会崩溃；精确弦位模式与显式音高类兼容模式均有测试；generation token 能阻止 reset/start 后旧异步任务回写。
- 验收命令：`dart format --output=none --set-exit-if-changed .`、`flutter analyze`、`flutter test test/training_engine_test.dart`。

### 下一提交门禁：音频与 SDK 兼容性

- 变更范围：`AudioEngine`、采样映射和 `flutter_soloud` 版本约束。
- 必须满足：依赖版本与固定 Flutter 3.32.8 可解析；SoLoud 的异步 `play` 句柄被正确等待和释放；采样缺失时仍可合成音；所有音色模式都能走同一播放接口。
- 验收命令：`flutter pub get`、`flutter analyze`、`flutter test test/sample_config_test.dart`；至少执行一个桌面或 Web 构建确认插件注册。
- 兼容性决策：`flutter_soloud 4.x` 要求 Flutter 3.41+，本阶段固定使用 API 兼容且要求 Flutter >=3.3 的 `3.4.0`，后续升级 SDK 时单独评估。

### 下一提交门禁：数据、设置与统计

- 变更范围：`PracticeRecord`、`StorageService`、`StreakManager`、Home/Settings/Stats 页面和应用生命周期。
- 必须满足：旧 JSON 缺失新增字段时使用稳定默认值；同一当地日期只计一次 streak 但保留历史日期；清除统计同时清除 records/streaks 和内存缓存；设置变更立即影响训练并可在重启后恢复。
- 验收命令：`flutter test test/storage_service_test.dart`、`flutter analyze`；手动检查完成训练后 Stats 页面即时刷新。

### 下一提交门禁：回归测试

- 变更范围：训练 FSM、采样映射、存储设置和关键 Widget 的测试夹具。
- 必须满足：测试不依赖真实音频设备或固定等待；覆盖精确位置与音高类判定、reset/start 取消、有限题库、样本八度映射、streak 历史/清除和旧偏好默认值。
- 验收命令：`dart format --output=none --set-exit-if-changed .`、`flutter analyze`、`flutter test --coverage`。
