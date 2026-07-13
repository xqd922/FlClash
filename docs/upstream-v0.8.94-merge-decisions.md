# XClash 合并上游 v0.8.94 取舍说明

## 1. 审计范围

逐提交和逐版本结论见 `docs/pre-v0.8.94-customization-audit.md`。

- 当前分支：`optimize`，合并前提交 `9e87fb6`。
- 共同基线：`672eacc`。
- 上游目标：`v0.8.94`，提交 `7e7f1f8`。
- 本地独有提交：85 个；净修改 122 个文件，新增 3,073 行、删除 4,704 行。
- 上游自共同基线后的主要变化：自定义覆写、新 Provider/Action 架构、数据库与 IPC 重构、Windows ARM64、Linux 静默启动修复、macOS 性能修复和新版 Core。
- 试合并得到 49 个文本或修改/删除冲突，因此不能用全局 `ours` 或 `theirs` 机械解决。

## 2. 修改初心

本分支的目标不是简单改名，而是把 FlClash 调整为一个更精简、偏隐私、适合个人长期维护的 XClash 发行版：

1. 统一 XClash 品牌，只维护中文和英文。
2. 移除 Firebase/Crashlytics，避免个人发行包默认携带遥测和 Google Services 构建依赖。
3. 让 Profile/YAML 中的显式配置优先，App 设置只补缺省值，避免订阅内容被无条件覆盖。
4. 改善 Android 后台耗电、VPN/Core 状态恢复和 IP 刷新。
5. 默认隐藏日志、请求记录等低频诊断入口，降低导航和界面信息密度。
6. 默认跟随系统主题，同时保留高级用户自定义主色的能力。
7. 简化构建和发布步骤，使附属发布渠道失败不阻断主要产物。

## 3. 合并原则

本次采用“上游架构 + XClash 产品语义”：

- Core、IPC、Provider/Action、数据库、平台插件和构建基础以 v0.8.94 为准。
- 不恢复上游已经删除的旧 `lib/controller.dart`。
- 不手工拼接 Freezed、JSON、Riverpod 和本地化生成文件；源模型解决后统一重新生成。
- 品牌、隐私政策和明确的默认体验在上游新结构上做最小移植。
- Android 优化和配置优先级只保留需求，不原样搬运旧生命周期或旧 Map 后处理实现。

## 4. 保留

### 4.1 发行版身份

- XClash、XClashCore、XClashHelperService 的跨平台品牌一致性。
- 仓库和更新地址指向 XClash 发行仓库。
- 仅发布中文和英文；不恢复日语、俄语资源。

### 4.2 隐私与依赖

- 移除 Firebase、Crashlytics、Analytics、Google Services 配置和无效设置入口。
- 保留启动时必要的免责声明流程，但工具页不再提供重复入口。

### 4.3 明确产品偏好

- 默认主题跟随系统。
- 日志和请求记录入口默认隐藏，但用户可重新开启。
- 代理卡片默认使用紧凑样式。
- 自定义主色和十六进制色值展示的需求。
- 简洁 Dashboard、隐藏编辑入口、稳定无滚动叠色的 AppBar。
- 默认关闭页面切换动画，并使用 HTTP 204 地址减少测速中的 TLS 干扰。

### 4.4 行为需求

- Profile 显式值不应被 App 默认值无条件覆盖。
- Profile DNS 配置不能只因缺少 `dns.enable` 就被整体替换。
- `external-controller` 必须有统一解析规则，并在 UI 关闭时真正关闭。
- Android 恢复时以真实 Service/Core 状态为准，而不是只相信 Flutter 内存状态。
- 生成配置只删除 `null`、保留空字符串，并按稳定顶层顺序输出。

## 5. 调整后保留

### 5.1 配置优先级

旧实现直接修改最终 `rawConfig`。v0.8.94 已引入标准、脚本和自定义覆写，因此改为使用上游覆写体系表达优先级：

1. 应用运行和安全必需字段。
2. 用户自定义覆写。
3. Profile 原始显式配置。
4. App 缺省值。

`external-controller` 单独处理：UI 关闭时为空；UI 开启且 Profile 有合法地址时使用 Profile；缺失或非法时保持空值，不由 App 强塞默认地址。

### 5.2 Android 优化

- 保留“进入 Doze 且屏幕关闭才挂起”的需求。
- 保留恢复时同步 VPN/Core/UI 和刷新 IP 的需求。
- 基于 v0.8.94 的新 Core/Provider API 重做，不恢复旧控制器和旧 Service 调用链。
- Android 签名容错仅用于 PR/测试构建；正式 tag/release 缺少签名必须失败。

### 5.3 主题和界面

- 不恢复合并前已主动删除的 `schemeVariant`、`pureBlack`、`textScale` 复杂主题项。
- 主题固定使用 `content` 配色算法，文字缩放跟随系统；默认采用系统主题和空预设颜色列表。
- 在上游主题组件上最小增加 HCT 自定义色和 HEX 展示，不整体恢复旧主题实现。
- Dashboard 保持 XClash 的简洁布局，删除编辑状态机和核心状态头部，同时复用 v0.8.94 的新 Provider 数据源。

### 5.4 构建发布

- 以上游 v0.8.94 的 Rust/Core、Windows ARM64 和平台插件构建链为基础。
- Telegram 通知可以 non-blocking；正式分发步骤必须明确报告失败。
- XClash 产物命名继续保留。
- `tray_manager` 使用公共稳定版本；新版 Rust/Core buildkit 继续保留，旧原生构建脚本不直接恢复。

## 6. 丢弃

- 所有旧 v7.0.0-v7.0.31 版本号、旧发布说明和 `bb4d7ff` 错误升版。
- `5018953` 包可见性加固及 `482efd0` 回滚形成的无效历史链。
- `3aeb754` Android Impeller 临时测试开关。
- `core/singbox/engine.go`：孤立、未接入且与提交主题无关。
- `.scratch/restore-color-picker/` 一次性开发拆解资料。
- 旧 `lib/controller.dart` 和围绕旧控制器的实现。
- 删除空字符串的实现；空字符串可能表达显式清空，必须保留。
- Direct 测速的中间实现；最终产品行为仍为批量测速跳过 Direct、Direct 卡片隐藏延迟入口。
- DNS IPv6 来回修改的中间状态。
- 旧版 `flutter_distributor` 替换方案和会隐式安装系统依赖的构建脚本。
- 只隐藏 Dashboard 编辑入口却保留不可达编辑逻辑的中间实现；最终版本应完整删除编辑状态机。
- 所有旧生成文件和旧锁文件的手工差异。

## 7. 合并热点

- `lib/common/task.dart`：以上游覆写流程为主体，重新验证 Profile/App/overwrite 优先级。
- `lib/models/config.dart`：保留上游模型，最小恢复 XClash 默认值和可见性字段。
- `lib/application.dart`、`lib/manager/app_manager.dart`：迁移 Android 恢复行为，不恢复旧控制器。
- Android Gradle/Service：保留新版构建链，重新移除 Firebase，并复核通知前台状态机。
- `pubspec.yaml`：以上游依赖为基线；`pubspec.lock` 重新生成。
- macOS/Windows/Linux 工程：保留上游平台修复和插件体系，再恢复 XClash 名称。
- 本地化：ARB 源文件手工处理，只生成中英文输出。

## 8. 验证清单

- `flutter pub get`、代码生成、`flutter analyze --no-fatal-infos`、`flutter test --reporter expanded`。
- 无旧 `lib/controller.dart` import，无 Firebase/Crashlytics/Google Services 残留。
- 仅注册中文和英文 locale。
- Profile、DNS、`external-controller`、自定义 overwrite 和空字符串显式清空均有测试。
- Android 前后台、Doze、进程重建、VPN 残留、IP 刷新需真机验证。
- Windows x64/ARM64、macOS Core/Rust、Linux 静默启动和各平台 XClash 产物名需分别验证。

## 9. 不可被上游重新摘回的精简设计

合并前 `optimize` 分支是产品行为基线。以下内容不是旧实现包袱，而是主动做出的界面降噪与行为修正；后续升级必须在新架构上继续保留：

- Dashboard 保持精简，不恢复编辑状态机、编辑入口和 Core 状态头部。
- 网络检测不显示说明信息图标；工具页不恢复重复的免责声明入口。
- AppBar 不使用滚动染色、阴影或表面叠加效果。
- 代理页批量延迟测试跳过 `Direct`，`Direct` 卡片不显示无意义的延迟入口。
- 代理页延迟测试使用 56×56 纯图标 FAB，不恢复带文字的扩展按钮。
- 延迟测试始终针对当前可见 Tab 对应的代理组，不能仅依赖持久化的组名。
- 启动按钮使用 300ms、`easeOutCubic`，避免恢复过冲动画。
- Android 平板 NavigationRail 不显示桌面应用图标；图标只在 Windows/Linux 侧栏显示。
- 日志和请求入口默认隐藏，页面切换动画默认关闭，代理卡片默认紧凑。
- 主题默认颜色列表保持为空，只提供系统/自动颜色；自定义色继续使用 HCT、HEX 展示和增删交互。

审计时不能只检查冲突文件。应同时回放共同基线到合并前版本之间所有带有 `remove`、`hide`、`simplify`、`compact`、`default`、`revert`、`restore legacy` 含义的本地提交，并逐项确认其产品意图在新架构中仍然成立。
