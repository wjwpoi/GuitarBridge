# GuitarBridge 实施计划与进度

> 本文档是当前代码库的工作契约。修改代码前先更新本文件；完成一项代码工作后，必须同步更新状态、验收结果和遗留问题。

## 目标与决策

- 跨平台是硬需求，继续使用 Flutter，不回退到 Swift-only 实现。
- 不再进行第二次全量重写；保留现有 UI 与基础模型，对核心闭环做定向重构。
- 发布前必须同时满足：可构建、可听见、可交互、可恢复、可测试。

## 本轮边界（CI/Release）

本轮只收敛文档契约和 CI/Release 流水线，不扩展训练、音频或 UI 功能。后续协作者必须先完成本文档对应门禁，再处理其他 TODO。

- 允许修改：`.github/workflows/`、Android release signing 接入所需的最小 Gradle 配置、构建/打包辅助脚本和本文档。
- 不允许顺手修改：`lib/` 训练状态机、音频播放算法、持久化模型、指板 UI、Swift 功能迁移。
- Release 不得公开上传 debug 签名 APK；没有正式签名密钥时只能生成 CI 验证制品，不能伪装成可发布安装包。
- iOS CI 构建保持 `--no-codesign`，产物必须明确标注为 unsigned，不能宣称可直接安装。
- 发布制品必须来自与 CI 相同的质量门禁和构建定义；禁止 Release workflow 偷换 Flutter 版本、跳过测试或使用 `continue-on-error`。
- Workflow action 依赖必须固定到完整 commit SHA，并用行尾注释保留对应 major tag；禁止直接依赖可移动的 `@v2`、`@v4`、`@v5`。

## 当前交接状态（2026-07-28）

- 工作分支：`review/flutter-cross-platform-refactor`。
- Pull Request：[#1 refactor: stabilize cross-platform GuitarBridge](https://github.com/wjwpoi/GuitarBridge/pull/1)，目标分支为 `main`，必须保留现有提交历史，禁止 squash。
- 首次 CI 失败对应的 PR HEAD：`f6f7d8194e1c0c0641efe7a23c4c41f040b9463a`；后续以 PR 页面最新 HEAD 为准。
- 首次 GitHub Actions 运行：[CI run 30333751004](https://github.com/wjwpoi/GuitarBridge/actions/runs/30333751004)。format、lockfile、analyze 均通过，`flutter test --coverage` 失败：61 项通过、27 项失败；六个平台构建因质量门禁失败而全部正确跳过。
- 27 项失败具有同一根因：`test/training_engine_test.dart` 的 `MockAudioEngine extends AudioEngine` 会执行父类字段初始化，`AudioEngine` 又在构造阶段求值 `SoLoud.instance`，Ubuntu 单元测试进程因此尝试加载不存在的 `libflutter_soloud_plugin.so`。这是测试边界泄漏，不是 27 个独立业务错误。
- 当前状态不得合并。下一位协作者只能先完成下文“接管入口：CI 音频测试隔离”，待新一轮质量门禁通过后再观察六个平台构建的真实结果。

## 当前风险基线

以下项目已经在工作区完成初步实现，但尚未通过固定 Flutter SDK 的完整验证，提交前仍视为风险项：

- SoLoud 初始化、采样加载和合成回退已接通；需要验证 Android、iOS、macOS、Windows、Linux、Web 的 API 和资源行为。
- 题目已保存目标弦位/品位，默认精确判定；需要验证旧调用方和完整训练状态机。
- 训练异步任务已加入 generation token，题目池改为有限生成；需要补充页面销毁和重复启动回归验证。
- 指板绘制与点击已共用品距坐标，并保留同音位置；需要做窄屏和各平台交互检查。
- 统计、streak、设置已接入持久化；需要验证迁移旧 JSON、重启恢复和清除语义。
- Flutter 平台目录和 lockfile 已生成；CI/Release 已统一到可复用构建定义，六平台真实构建仍需对应 runner 完成。
- Ubuntu 质量门禁中的训练测试尚未与 SoLoud 原生动态库隔离；首次 PR CI 已证明当前测试替身仍会加载插件。

## 分阶段 TODO

### P0：跨平台可运行基线

- [x] 纳入 Android、iOS、macOS、Windows、Linux、Web 平台工程目录。
- [x] 固定 Flutter/Dart 版本和 pub 依赖，提交 `pubspec.lock`。
- [x] 修复 CI：format、analyze、test 必须阻断；矩阵定义覆盖六个平台。
- [x] 构建脚本遇到任一平台失败时必须返回非零状态，并按主机选择可执行目标。
- [x] 真实初始化 SoLoud，加载三种音色采样，缺失时使用可听见的合成回退；Web 产物已确认包含插件 WASM。
- [x] 定义 GitHub Actions 六平台 release build 矩阵；实际 runner 结果仍待完成。
- [x] Release 调用与 CI 相同的可复用质量/构建定义，失败会阻断发布，不重复维护一套门禁。
- [x] 定义六平台可审计制品、平台/架构命名和 SHA256 校验生成；实际 artifact 下载和 tag 发布仍待 runner 完成。
- [x] Android Release 只有在正式 signing secrets 存在时才允许进入公开 Release；CI 验证制品明确不是公开发布包。

### P1：训练正确性

- [x] 用不可变题目模型保存锚点和目标的弦、品、MIDI。
- [x] 默认按精确弦位/品位判定；保留可配置的音高类判定模式。
- [x] 等待回答时不得显示目标位置或目标音名提示。
- [x] 为训练异步流程增加 generation token，`reset`、新一轮和页面销毁后旧任务不得回写状态。
- [x] 题目池显式生成和打乱，题量超过可用题目数时按有限池确定性循环。
- [x] 指板点击和绘制共用同一品距坐标，完整支持 0–22 品及所有同音位置。

### P1：数据与设置

- [x] 统计页读取 `StreakManager` 的真实记录并在完成训练后立即刷新。
- [x] 连续练习按本地日期去重但保留历史日期，修复 current/best streak。
- [x] 清除统计同时清除记录和 streak 持久化数据。
- [x] 设置中的题量、显示选项、音量和音色真正影响 Home/TrainingEngine，并在重启后恢复。

### P2：质量与发布

- [x] 为数学、题目池、FSM 取消、持久化、采样映射、关键 Widget 增加回归测试。
- [x] 修复训练测试对 `AudioEngine` 具体类的继承依赖，使纯 Dart/Flutter 单元测试不加载 SoLoud 动态库；不得通过跳过测试或修改 runner 环境掩盖问题。
- [ ] 发布工作流复用已通过 CI 门禁的构建定义，上传带平台/架构标识的制品和 SHA256 校验文件（当前未在 CI runner 上完成闭环）。
- [ ] 明确尚未迁移的 Swift 功能：调音器、节拍器、日志、分享、录音、Watch/Widget。

### P1：交给后续协作者的功能 TODO

以下任务不属于本轮 CI/Release 修改范围。每项开始前必须先补充目标、影响范围、验收命令和边界，再单独提交代码和文档：

- [ ] 音频：实现真实 active voice crossfade，或删除 crossfade 能力和误导性文案；六平台各做一次可听输出 smoke test。
- [x] 音频生命周期：为 reset、重复 start、页面销毁增加停止旧 voice 的接口和回归测试；generation token 只保护状态，不等于停止音频。
- [ ] 音频错误：初始化失败、采样缺失、题库为空时提供用户可见状态和重试/降级路径。
- [ ] 数据恢复：手动验收完成训练后 Stats 即时刷新、重启恢复 records/streak/设置、清除后页面和持久化数据均为空。
- [ ] 数据迁移：为损坏 JSON、缺失字段和未来 schema 版本定义稳定迁移/报错策略；不得静默丢失历史。
- [ ] UI/交互：完成窄屏、横竖屏、触摸/鼠标、键盘和可访问性检查；同步 Onboarding、README 的六平台文案；排查 Web release 的 Cupertino icon 字体告警。
- [ ] Swift 辅助功能：调音器、节拍器、日志、分享、录音、Watch/Widget；核心闭环和六平台构建稳定前不得插队。

## 验收标准

1. `dart format --set-exit-if-changed .`、`flutter analyze`、`flutter test --coverage` 全部通过。
2. Android、iOS（unsigned）、macOS、Windows、Linux、Web 均能在对应 CI runner 完成 release build；iOS 产物必须明确 unsigned，不能作为可安装发布包。
3. 首次启动可播放根音和目标音；clean、overdrive、distortion 均有可听见输出或明确错误状态。
4. 点击错误弦位/品位不会判对；点击正确目标位置会进入下一题；等待回答界面不泄露答案。
5. 训练中 reset、重复 start、离开页面不会出现旧音频任务改变当前状态。
6. 完成训练后统计立即出现，应用重启后记录、streak 和设置仍存在。

## 核心实现约定

- `TrainingQuestion` 必须同时保存 `root` 和 `target` 的 `stringIndex`、`fret`、`midi`，UI 点击回传完整 `FretPosition`。
- 默认 `AnswerMode.exactPosition` 比较弦和品；未来若增加听音练习模式，`AnswerMode.pitchClass` 必须是显式配置，不能隐式替代精确寻址。
- 训练异步流程以 generation token 绑定；每次 `start`、`reset`、完成或销毁都使旧 token 失效。
- 题目池一次性按当前调性、调弦、难度生成并打乱；题量超过池容量时先消耗完整一轮，再按模循环作为明确降级策略，禁止无界递归。
- 指板绘制和点击都由同一个 `fretX(fret)` 坐标函数计算；完整指板显示 0–22 品，不能删除同音位置。
- `UserPreferences` 是唯一设置来源，题量、显示开关、音量和音色都必须序列化；Home、Settings 和 TrainingEngine 通过同一对象同步。
- `StreakManager.records` 是统计页的唯一数据入口；日期 streak 按本地日去重，但不得删除历史日期，清除操作必须同时清空两类存储。

## 实施进度

| 阶段 | 状态 | 说明 |
| --- | --- | --- |
| 文档、TODO、验收标准 | 已完成 | 本文档先于代码变更创建 |
| 平台工程与可复现流水线 | 阻塞 | `d273466` 已补齐可复用 CI/Release 定义；PR #1 首次运行在 Ubuntu 训练测试加载 SoLoud 动态库时失败，六平台构建尚未开始 |
| 音频与训练核心 | 进行中 | 训练题目已改为具体弦位，题库有限生成并支持确定性循环，增加 generation token；SoLoud 3.x 异步句柄已校正，待各平台播放验证 |
| 持久化、统计、设置 | 进行中 | 已修复 streak 历史/清除、暴露真实 records、设置序列化并接入 Home；单元测试已覆盖，待手动重启恢复检查 |
| 测试与发布验证 | 阻塞 | macOS 本地全量 88 项通过，但 Ubuntu CI 为 61 通过、27 失败；必须先隔离原生音频依赖，再以 GitHub runner 结果为准 |

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
| 2 | `build:` | 固定 SDK/依赖、恢复 CI 门禁、生成平台工程 | `84b1460`, `01a3b73`, `f33accf` |
| 3 | `feat:` | 位置感知题目、有限题库和可取消训练 FSM | `bfeb78c`, `187244e` |
| 4 | `feat/fix:` | SoLoud 采样、合成回退和 Flutter 3.32 API 兼容 | `c4385c8` |
| 5 | `feat/fix:` | 设置、记录、streak 持久化和本地日期语义 | `ea3f151`, `eaadc98` |
| 6 | `test/chore:` | 领域模型、采样映射、存储、Widget 回归测试和零 issue lint | `b3e20ac`, `ca87a41` |
| 7 | `fix/build:` | SDK 验证产生的平台兼容性、无签名构建和脚本入口修复 | `6a2814c`, `70579c9`, `04da3ba` |
| 8 | `docs:` | 最终进度、真实验证结果和未迁移功能清单 | `f126fae`, `c497719`, `9587036` |
| 9 | `ci:` | CI/Release 共用六平台构建、签名门禁、制品打包和 SHA256 校验 | `d273466`，待 runner 实际闭环 |
| 10 | `docs:` | 记录 PR #1 首次 CI 失败、SoLoud 测试边界根因和后续模型接管限制 | 本行所在提交 |

### 接管入口：CI 音频测试隔离（唯一 P0）

下一位模型必须从本节开始，不得先处理其他 TODO。

- 目标：让 `TrainingEngine` 依赖一个不包含第三方插件初始化的最小音频端口，使训练单元测试使用纯 fake，生产环境仍由 `AudioEngine`/SoLoud 提供实现。
- 允许修改：新增一个位于 `lib/engine/` 的最小端口文件，以及 `lib/engine/audio_engine.dart`、`lib/engine/training_engine.dart`、`test/training_engine_test.dart` 和本文档。
- 端口只暴露训练状态机实际需要的成员：`bool get isReady` 与 `Future<void> playNote(int midiNote)`。`AudioEngine` 实现该端口；测试 fake 直接实现端口，不得继承或构造 `AudioEngine`。
- 不允许修改：`.github/workflows/`、SoLoud 采样/播放算法、训练题目生成、UI、持久化、平台工程和依赖版本。不得安装/复制 `libflutter_soloud_plugin.so` 到质量门禁，不得使用 `continue-on-error`，不得跳过 27 项测试，不得仅根据操作系统条件绕过测试。
- 提交顺序：本交接文档提交之后，使用一个独立 `fix:` 提交完成端口隔离；验证完成后再用一个独立 `docs:` 提交回填命令结果、CI run URL 和六平台状态。若实现前发现边界需要扩大，必须先修改本文档并单独提交，不得直接改代码。
- 本地验收：`dart format --output=none --set-exit-if-changed .`、`flutter analyze`、`flutter test test/training_engine_test.dart`、`flutter test --coverage`，预期全量 88 项通过。
- CI 验收：PR #1 的 Quality gates 成功，随后 Android、iOS unsigned、macOS unsigned、Windows、Linux、Web 六个 build job 全部成功。任一平台出现新失败时，先在本文档记录 runner、失败步骤、日志 URL、根因假设和允许修改范围，再创建该平台独立修复提交。
- 合并门禁：所有 PR checks 成功后使用 merge commit 合入 `main`，禁止 squash、禁止在红灯或 skipped 状态下强制合并。Release/tag 不属于此修复提交；Android 正式发布仍受 signing secrets 门禁约束。

### 下一提交门禁：流水线与依赖

- 变更范围：CI/release 工作流、Android release signing 的最小配置、制品打包/校验和本文档；不修改 `lib/`。
- 必须满足：Flutter 版本固定为 3.32.8；CI 与 Release 共用一份质量/构建定义；action 固定完整 commit SHA；六平台构建失败阻断；所有构建制品可下载；Release 生成带平台/架构标识的压缩包和 SHA256 文件；无正式 Android signing secrets 时不得创建公开 Release。
- 验收命令：本地执行 YAML 语法检查、`dart format --output=none --set-exit-if-changed .`、`flutter analyze`、`flutter test`；GitHub runner 实际执行六平台 release matrix 和 tag release dry-run/发布流程。
- 产物契约：Android 为正式签名的 ABI APK；iOS 为明确标注的 unsigned `.app` 压缩包；macOS/Windows/Linux 为可运行目录的压缩包；Web 为静态部署 zip；每个制品旁边有同名 `.sha256`。
- 签名契约：Android 使用 `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD` 四个 GitHub Actions secrets；签名密钥不进入仓库、日志或 artifact；CI 普通分支只验证构建，不发布签名包。
- 未签名边界：iOS 和 macOS 产物文件名必须包含 `unsigned`，Release notes 必须说明不可直接分发；Apple Developer ID/App Store 签名、公证，以及 Windows 代码签名/安装器是独立后续发布任务，不得在本轮伪造完成状态。

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
- 日期契约补充：所有 streak 日期比较先转换到本地时区再截断到日，不能直接使用 UTC 字符串的年月日字段。

### 下一提交门禁：回归测试

- 变更范围：训练 FSM、采样映射、存储设置和关键 Widget 的测试夹具。
- 必须满足：测试不依赖真实音频设备或固定等待；覆盖精确位置与音高类判定、reset/start 取消、有限题库、样本八度映射、streak 历史/清除和旧偏好默认值。
- 验收命令：`dart format --output=none --set-exit-if-changed .`、`flutter analyze`、`flutter test --coverage`。

### 下一提交门禁：跨平台构建矩阵修复

- 变更范围：CI Linux 构建 job、macOS/Linux shell 构建脚本和 Windows PowerShell 构建脚本。
- 必须满足：CI 至少覆盖 Android、iOS（无签名）、macOS、Windows、Linux、Web；本地主机的 `all` 只选择该主机可执行的平台，不把不可能的目标伪装成成功。
- 脚本约定：本地 iOS 构建默认使用 `--no-codesign`，签名由发布流程另行处理。
- Shell 入口必须保留可执行权限（`tool/build.sh` mode `100755`），可直接从仓库根目录调用。
- 验收命令：对应主机运行 `./tool/build.sh all` 或 `./tool/build.ps1 -Platform all`；CI 失败必须阻断合并。

### 下一提交门禁：平台工程基线

- 变更范围：Flutter 生成的 Android、iOS、macOS、Windows、Linux、Web 工程、`.metadata` 和 `pubspec.lock`。
- 必须满足：六个平台源文件纳入版本控制；iOS deployment target >=13.0、macOS >=10.15，匹配 `flutter_soloud 3.4.0`；生成文件不覆盖业务代码；依赖版本由 lockfile 固定。
- 验收命令：`flutter pub get`、`flutter analyze`、`flutter test`，以及当前 macOS 主机可执行的 Web/macOS/iOS/Android 构建。

### SDK 验证记录（2026-07-28）

- Flutter 3.32.8 / Dart 3.8.1 已安装到工作区临时 SDK。
- `flutter pub get` 成功，lockfile 当前解析 `flutter_soloud 3.5.4`（满足 `^3.4.0` 且仍兼容 Flutter 3.32）；Web 产物包含 `worker.dart.js`、插件 JS 和 WASM 资源。
- 首次格式化发现并修复指板 Widget 括号错误和测试导入位置错误；训练专项测试当前 27 项通过。
- `flutter analyze` 已达到 `No issues found`，加入 UTC/local streak 回归后全量测试 88 项通过。
- `bash -x ./tool/build.sh web --release` 已通过；脚本首字节为标准 shebang，文件 mode 为 `100755`。
- `actionlint 1.7.12` 和 Ruby YAML 解析均通过三个 workflow；所有外部 action 已固定完整 commit SHA。
- `flutter build web --release`、Web zip `unzip -t` 和 SHA256 生成/校验已通过；构建仍报告 Cupertino icon 字体告警，留给 UI/资源 TODO 处理。

### Release 构建记录（2026-07-28）

| 平台 | 结果 | 说明 |
| --- | --- | --- |
| Web | 通过 | `flutter build web --release` 成功，`build/web` 约 25 MB，包含 SoLoud WASM 资源 |
| macOS | 环境阻塞 | Xcode 16.3 可用，但本机没有 CocoaPods；临时安装因系统 Ruby 2.6 与当前 Xcode SDK 头文件不匹配失败 |
| iOS | 环境阻塞 | 与 macOS 共用 CocoaPods，未执行插件编译 |
| Android | 环境阻塞 | 本机没有 Android SDK 和 Java，CI Ubuntu job 负责验证 |
| Linux | 未执行 | 需要 Linux 主机或 CI Ubuntu job |
| Windows | 未执行 | 需要 Windows 主机或 CI Windows job |

当前代码级门禁通过，Apple/Android/桌面三项仍需在具备对应工具链的 CI runner 上完成；不能把本机环境阻塞误报为平台代码通过。

CI/Release 代码已提交，但不能把本机 actionlint、Web 构建或测试结果当作六平台 runner 通过；下一次 tag 发布前必须保存 GitHub Actions run URL、六个 artifact 名称和最终校验文件结果。

## CI 验证记录（2026-07-28，提交 `fd482aa`）

[CI run 30338274483](https://github.com/wjwpoi/GuitarBridge/actions/runs/30338274483)

| 阶段 | 结果 | 耗时 |
| --- | --- | --- |
| Quality gates | ✅ pass | 1m53s |
| Build Linux | ✅ pass | 1m39s |
| Build iOS (unsigned) | ✅ pass | 3m42s |
| Build macOS (unsigned) | ✅ pass | 4m21s |
| Build Android APKs | ✅ pass | — |
| Build Windows | ❌ fail | 2m33s |
| Build Web | ✅ pass | 50s |

### Windows 失败根因

`windows-latest` 当前解析为 `windows-2025`（Windows Server 2025，含 VS2026）。Flutter 3.32.8 生成的 Windows CMake 工程期望 Visual Studio 16 2019，但该 runner 不含该版本。

```
CMake Error at CMakeLists.txt:3 (project):
  Generator Visual Studio 16 2019 could not find any instance of Visual Studio.
```

修复方向：将 Windows runner 固定为 `windows-2022` 或 `windows-2019`，待后续升级 Flutter SDK 时重新生成工程以适配新版 Visual Studio。

### 修复边界

- 允许修改：`.github/workflows/build.yml` 中 Windows job 的 `runs-on`，本文档。
- 不允许修改：CMakeLists.txt、Flutter 版本、任何其他文件。

## 当前阶段：音频与数据门禁验证（2026-07-28）

### 音频与 SDK 兼容性 ✅

- `flutter_soloud 3.5.4` 满足 `^3.4.0`，与 Flutter 3.32.8 可解析。
- `_playSample` 和 `_playSynthesized` 均在 `finally` 块中停止和释放 handle/source。
- `playNote` 采样缺失时回退到 `_playSynthesized`。
- 所有音色模式通过同一 `playNote` 接口。
- `sample_config_test.dart` 3 项通过。

### 数据、设置与统计 ✅

- `UserPreferences.fromJson` 对每个字段使用 `?? defaultValue`。
- `addStreak` 通过 `_localDay` 按本地日期去重；UTC/local 同一日期正确去重。
- `clearRecords` 和 `clearStreaks` 同时清除持久化和缓存。
- `storage_service_test.dart` 7 项通过。

### 全量测试

- 全量 88 项通过。

### 下一提交：音频生命周期

- 目标：`reset`、重复 `start`、页面 `dispose` 时停止当前播放中的旧 voice。
- 当前问题：`TrainingEngine` 的 `start()` 不做停止；`AudioEngine.playNote()` 内部延时 800ms，quick reset 会导致旧回调与新 play 重叠。
- 允许修改：`lib/engine/training_audio_port.dart`、`lib/engine/audio_engine.dart`、`lib/engine/training_engine.dart`、`test/training_engine_test.dart`、本文档。
- 端口需新增 `Future<void> stopAll()`。
- 验收：`flutter analyze`、`flutter test test/training_engine_test.dart`、全量 88+ 项通过。

### 下一提交：数据迁移与错误恢复

- 目标：损坏 JSON、缺失字段时返回安全默认值，不崩溃、不静默丢失。
- 允许修改：`lib/services/storage_service.dart`、`lib/models/practice_record.dart`、`test/storage_service_test.dart`、本文档。
- 策略：`jsonDecode` 包在 try-catch 中；`fromMap` 使用安全转换和默认值；新增 `schemaVersion` 字段。
- 验收：`flutter test test/storage_service_test.dart` 新增损坏数据恢复用例。
