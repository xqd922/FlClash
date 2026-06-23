## v(7.0.22)

### ✨ 新功能

- 默认启用 `allow-lan`

### 🐛 修复

- `external-controller` 改为跟随 profile 配置文件
  - 移除设置页面的 External Controller 开关
  - 启动代理时读取 profile 中的 `external-controller` 地址
  - 停止代理时仅运行时关闭，不修改配置文件
  - 保留用户配置的 `external-ui` 和 `external-ui-url`
- 从 `UpdateParams` 移除 `externalController`，`updateConfig` 不再干预
  - 删除 `updateConfigPayload` workaround
  - external controller 完全由配置文件 + `setupConfig` 管理

### 🧪 测试

- 新增 `external_controller` 单元测试
- 新增 `update_config` payload 测试

## v(7.0.21)

### 🔄 重构

- 统一所有平台的应用名称为 XClash
  - Android: XClash (Release), XClash Debug (Debug)
  - Windows: XClash.exe, XClashCore.exe, XClashHelperService.exe
  - macOS: XClash.app, XClashCore
  - Linux: XClash, XClashCore（AppImage、DEB、RPM 包）
- 更新核心二进制路径和锁文件命名
- 更新所有打包配置中的应用显示名称和关键词

## v(7.0.20)

### 🐛 修复

- Android 平板桌面模式下隐藏 NavigationRail 顶部的应用图标，遵循 Material Design 规范

### 📚 文档

- 添加 release 备份与恢复指南，说明如何从备份分支构建历史版本

## v(7.0.19)

### 🔒 安全

- Android 安装显示名改为 `XClash`，与上游 `FlClash` 做品牌区分，降低“同名应用但包名/签名不同”引发的安全软件仿冒/灰产误报概率
- 发版流程在未配置 F-Droid deploy key 时跳过 F-Droid 同步步骤，避免发布页产生无关错误提示

## v(7.0.18)

### 🔒 安全

- Android 移除 `QUERY_ALL_PACKAGES` 和未使用的 `CHANGE_NETWORK_STATE` 权限，降低应用包可见性和静态扫描风险
- Android 停止扫描其他应用 APK / dex 内容，改为仅枚举桌面启动应用
- Android 内部广播接收器改为不可导出，收紧应用内服务广播暴露面

## v(7.0.17)

### 🔧 变更

- Android 强制关闭 Impeller 渲染，用于测试字体观感、图形兼容性和部分机型渲染稳定性

## v(7.0.16)

### 🗑️ 移除

- 移除 Android / Dart 侧残留的 Firebase Crashlytics 配置、开关、状态同步和服务接口，减少安全软件静态扫描误判点

## v(7.0.15)

### 🐛 修复

- Android 改为独立包名 `com.xqd922.flclash`，避免与上游同包名不同签名导致的安全软件误报
- 同步发布版本到 `7.0.15`

## v(7.0.14)

### ✨ 优化

- 外部控制器（`external-controller`）改为 yaml 优先：profile 里写了就用 yaml 的值，UI 开关仅在字段留空 / 缺失时兜底，方便自定义监听地址（如 `0.0.0.0:9090` / `[::]:9090`）
- 默认测速链接由 `https://` 切到 `http://www.gstatic.com/generate_204`，免去 TLS 握手开销，单次测速通常可缩短 100–200ms；已自定义过的用户不受影响，需要切换可在 设置 → 通用 → 测速链接 点 reset

## v(7.0.13)

### 🐛 修复

- 修复代理页面在多次切换配置/模式后，手动选择页点击测速可能无响应的问题
- 回退 Android 网络检测失败后的 loading 状态处理，恢复之前的行为

## v(7.0.12)

### 🐛 修复

- 修复 Android 网络检测失败后可能长期停留在 loading，导致回前台后不再自动刷新 IP 的问题
- 修复 VPN 状态切换时 IP 刷新的触发条件异常，避免状态变化后漏刷

### ✨ 优化

- 回前台时基于 Android service 实际运行态做轻量自愈，降低 core、service 与界面状态不一致的概率
- 首次 URL 导入订阅后追加 providers、groups 和 IP 的补刷新，并为 providers 增加短重试
- IP 检查不再依赖 dashboard 的网络检测卡片是否显示

## v(7.0.11)

### ✨ 优化

- Android 内存回收策略调整：仅在 `onTrimMemory(TRIM_MEMORY_RUNNING_LOW+)` 时触发 Go GC，减少非必要 GC 带来的电量与性能抖动
- 前台通知更新策略优化：首次使用 `startForeground`，后续改为 `NotificationManager.notify` 增量更新，降低服务更新开销
- 挂起策略重构：改为联合判断「熄屏 + Doze 空闲模式」后再挂起核心，避免仅熄屏场景的误挂起
- 新增 Doze 状态切换监听与挂起状态去抖，卸载模块时强制恢复核心，降低后台驻留期间的异常状态风险

## v(7.0.10)

### ✨ 优化

- VpnService/CommonService 添加 onTrimMemory 回调，响应系统内存压力时主动触发 Go GC
- VPN 启动前检测并清理残留 TUN 接口，防止 zombie FD 占用内存
- 网络类型切换（WiFi↔移动数据）时自动关闭旧连接，强制通过新网络路径重连
- FlutterEngine 缓存复用，Activity 重建时不再重复创建引擎，降低内存分配

## v(7.0.9)

### ✨ 优化

- TUN MTU 从 9000 降为 4064，减少 gvisor 每包 buffer 分配，降低内核内存占用
- Flutter 图片缓存上限从 100MB 降为 50MB
- 图标加载使用 cacheWidth/cacheHeight 按实际显示尺寸解码，避免全尺寸缓存
- Go 构建添加 -trimpath，减少二进制元数据内存占用
- Android arm64/x86_64 构建添加 16KB 页对齐（-extldflags max-page-size=16384）

## v(7.0.8)

### ✨ 优化

- 构建标签添加 no_fake_tcp，禁用 gvisor 伪 TCP 栈，降低内核 CPU 开销
- 低端设备（armeabi-v7a）启用 with_low_memory 标签，减少内存占用
- 默认日志级别从 info 改为 error，减少日志 I/O 开销
- 应用后台时暂停流量/运行时间更新，避免无效 FFI 调用
- Android 启用 Impeller 渲染引擎，降低 GPU 功耗
- VPN 服务声明 SUPPORTS_ALWAYS_ON，获得更优系统调度
- 批量测速改为懒加载执行，避免同时启动大量协程导致 CPU 峰值
- 配置应用完成后延迟触发 GC，及时回收 Go 核心内存

## v(7.0.7)

### 🐛 修复

- 修复内网 IP 显示为 VPN/热点地址而非真实网络 IP 的问题

### ✨ 优化

- 流量统计环形图颜色微调

## v(7.0.6)

### 🐛 修复

- 修复代理页面 Tab 栏下拉按钮时有时无的问题

### ✨ 优化

- 流量统计环形图颜色加深，提升对比度

## v(7.0.5)

### ✨ 优化

- 流量统计环形图颜色调浅，提升可读性

## v(7.0.3)

### ✨ 优化

- 配置页面悬浮按钮改为紧凑样式（仅图标）

### 🔧 变更

- 启动按钮动画曲线恢复为 easeOutBack
- 工具页面免责声明不再强制退出应用

## v(7.0.2)

### ✨ 优化

- 批量测速跳过 Direct 代理，Direct 卡片不再显示延迟图标
- 测速悬浮按钮改为紧凑样式（仅图标）
- 启动按钮动画优化：时长 300ms，曲线改为 easeOutCubic
- 代理卡片默认紧凑尺寸

### 🔧 变更

- 默认主题跟随系统、关闭选项卡动画、开启 IPv6、关闭统一延迟
- 移除首次启动免责声明和数据收集弹窗

## v(7.0.1)

### ✨ 优化

- 批量测速跳过 Direct 代理
- Direct 代理卡片不再显示延迟图标
- 代理卡片默认使用紧凑尺寸

### 🔧 变更

- 默认主题模式改为跟随系统
- 关闭选项卡切换动画
- 默认开启 IPv6
- 默认关闭统一延迟
- 移除首次启动免责声明和数据收集弹窗

## v(7.0.0)

### ✨ 优化

- 精简主题系统：仅保留自动取色（Material You）+ 主题模式切换

### 🗑️ 移除

- 移除手动颜色选择、纯黑模式、文字缩放、配色方案变体
- 仅保留中文和英文两种语言
- 移除 Firebase Crashlytics 和 Analytics
