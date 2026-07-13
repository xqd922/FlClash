# XClash 上游版本合并操作手册

本文档用于指导以后将 FlClash 上游新版本合并到 XClash `optimize` 分支。

它不是一份单纯的 Git 命令清单，而是一套完整的产品迁移方法。目标不是让 Git 显示“合并成功”，而是在获得上游架构、修复和平台能力的同时，继续保持 XClash 已经形成的产品设计、精简方向、默认行为、品牌和性能优化。

本文以合并上游 `v0.8.94`、发布 XClash `v7.0.32` 的实际过程为案例，记录本次如何建立基线、如何审计、如何分类、如何迁移、如何验证、哪些地方第一次处理错了，以及以后怎样避免重演。

---

## 1. 文档目标

后续每次合并上游版本，都应达到以下结果：

1. 明确上游版本、XClash 合并前版本和双方共同基线。
2. 在改代码前，完整记录 XClash 从共同基线开始做过的真实修改。
3. 不遗漏藏在 `Release`、修复、回滚或混合提交中的产品修改。
4. 将每项本地修改分类为：精简、修改、优化、修复或丢弃。
5. 以“合并前最终产品行为”为规格，而不是机械恢复旧代码。
6. 保留上游新架构，避免把已经淘汰的旧控制器、旧 Provider、旧构建脚本重新带回来。
7. 优先在共享根路径恢复行为，不在多个 UI 调用点重复打补丁。
8. 用文档、测试、静态分析和平台编译共同证明结果。
9. 在发布前完成完整审计，不要依赖发布后再凭肉眼发现回退。
10. 标签、分支、CI 和 GitHub Release 最终必须指向同一个经过验证的提交。

---

## 2. 核心原则

### 2.1 合并前最终版本是产品规格

最重要的规则：

> 合并前最终版本的用户可见行为和产品语义，优先于历史提交中的中间实现。

原因：

- 同一功能可能经历“添加 → 调整 → 回滚 → 再恢复”。
- 某个历史提交看起来是优化，但最终版本可能已经撤销。
- 某个 `Release` 提交可能同时包含版本号、配置和真实产品代码。
- 旧实现可能依赖已经被上游重构掉的架构，不能直接复制。

因此必须同时查看：

- 从共同基线到合并前最终版本的全部提交。
- 合并前最终版本与共同基线的最终文件差异。
- 与某个功能有关的完整提交链。
- 最终版本实际运行时的行为。

### 2.2 保留意图，不执着旧实现

合并时应问：

- 用户当初为什么改？
- 最终要消除什么问题？
- 在上游新架构中，哪个共享位置现在负责该行为？
- 能否通过删除上游重新引入的复杂度恢复结果？

不应只问：

- 旧文件中的这几行还能不能复制回来？

例如，本次合并前 IP 刷新由旧流程控制；上游 `v0.8.94` 已改成 Provider 架构。正确处理不是恢复旧控制器，而是让 `checkIpProvider` 只依赖初始化状态与刷新触发器，去掉 Dashboard 组件开关这一错误门槛。

### 2.3 新版骨架与 XClash 产品层分开处理

上游值得保留的通常是：

- Provider / Action 状态架构。
- Core IPC 和生命周期重构。
- 数据库与自定义覆写架构。
- 新版 buildkit 和平台构建能力。
- 上游错误修复和新平台支持。

XClash 必须继续保留的通常是：

- 品牌和包名。
- 默认配置和配置优先级。
- 已主动删除的入口与复杂设置。
- 隐私策略和依赖精简。
- 性能、内存、电量和网络稳定性优化。
- 用户已经习惯的交互语义。

合并的目标应表达为：

> 上游新版架构 + XClash 最终产品行为。

而不是：

> 上游代码 + 所有旧代码。

### 2.4 删除优先于兼容无用设计

如果 XClash 已经明确删除某个功能，而且没有兼容需求，就应删除完整链路：

- 模型字段。
- JSON 序列化字段。
- Provider 状态。
- UI 设置入口。
- 运行时分支。
- 通知或监听组件。
- 本地化文案。
- 不再使用的缓存和辅助类。
- 相关测试中的旧预期。

只隐藏 UI 而保留整套状态和运行逻辑，会让后续上游合并再次把功能带回来，也会让配置格式继续携带无意义字段。

本次主题精简最终删除了：

- `ThemeProps.schemeVariant`。
- `ThemeProps.pureBlack`。
- `ThemeProps.textScale`。
- `TextScale` 模型。
- `TextScaleNotification`。
- `CommonTheme` 全局缓存。
- 对应 ARB 与生成本地化文案。
- 固定的 `DynamicSchemeVariant.content` 行为。

### 2.5 根因修复优先于调用点补丁

修改一个共享函数前，应搜索所有调用者：

```powershell
rg -n "functionName|ProviderName|ConfigField" lib test
```

如果多个页面最终都依赖同一个 Provider、Action 或配置生成函数，应在共享路径修复一次，并增加一条能锁住语义的测试。

典型例子：

- Profile 配置优先级：修复 `makeRealProfileTask`，而不是在导入、启动、更新等调用点分别处理。
- 配置成功后的 Core GC：放在共享 `_setupConfig` 成功路径，不在每种启动方式分别调度。
- IP 刷新：修复 Provider 的依赖，不在 Dashboard 或其他页面手动触发。
- 批量测速懒创建：修复批处理循环，不给每个按钮单独加限制。

---

## 3. 本次 v0.8.94 合并基线

本次实际使用的基线如下：

| 角色 | 引用 | 提交 |
| --- | --- | --- |
| 双方共同基线 | merge base | `672eacc` |
| XClash 合并前最终版本 | `backup/optimize-pre-v0.8.94-20260713` | `9e87fb6` |
| 上游目标版本 | `v0.8.94` | `7e7f1f8` |
| 初次合并提交 | `Merge upstream v0.8.94 architecture` | `612ac0c` |
| 最终修复提交 | `fix: restore full XClash product intent` | `34ba649` |
| 最终 XClash 标签 | `v7.0.32` | `34ba649` |

合并提交 `612ac0c` 的两个父提交分别是：

```text
9e87fb6  XClash 合并前最终版本
7e7f1f8  FlClash 上游 v0.8.94
```

这使得后续可以分别比较：

```powershell
# XClash 从共同基线开始做过什么
git diff 672eacc..9e87fb6

# 上游从共同基线开始做过什么
git diff 672eacc..7e7f1f8

# 初次合并后相对 XClash 合并前版本改变了什么
git diff 9e87fb6..612ac0c

# 最终修复相对初次合并补回了什么
git diff 612ac0c..34ba649
```

---

## 4. 合并前准备

### 4.1 不要在未提交工作树上开始

先确认：

```powershell
git branch --show-current
git status --short
git remote -v
```

要求：

- 当前分支必须是用户指定的分支。本项目本次要求始终停留在 `optimize`。
- 工作树必须干净，或者现有修改已经明确记录并备份。
- `origin` 应指向 XClash 仓库。
- `upstream` 应指向 FlClash 上游仓库。

本仓库远程配置为：

```text
origin    git@github.com:xqdwmq/FlClash.git
upstream  https://github.com/chen08209/FlClash.git
```

### 4.2 建立不可变的合并前备份引用

即使用户要求不切换分支，也可以创建备份分支或标签，但不要 checkout：

```powershell
git branch backup/optimize-pre-vNEXT-YYYYMMDD HEAD
```

然后记录提交：

```powershell
git rev-parse HEAD
git log -1 --oneline backup/optimize-pre-vNEXT-YYYYMMDD
```

这个备份不是为了以后机械还原文件，而是为了：

- 查看合并前最终行为。
- 比较最终文件。
- 找回被合并覆盖的产品语义。
- 证明某项设计在合并前是否真实存在。

### 4.3 获取上游并验证目标标签

```powershell
git fetch upstream --tags
git show -s --oneline upstream/main
git show -s --oneline v0.8.NEXT
```

不要仅凭标签名称判断版本。必须确认：

- 标签指向的提交。
- 上游 changelog。
- 标签后是否还有必须包含的修复。
- 目标提交是否已经包含预期的平台改动。

### 4.4 计算共同基线

```powershell
git merge-base <pre-merge-commit> <upstream-target>
```

保存结果：

```powershell
$base = git merge-base <pre-merge-commit> <upstream-target>
git show -s --oneline $base
```

共同基线是后续审计的核心。没有共同基线，仅比较“当前分支和上游标签”会把双方修改混在一起，无法判断一项代码是谁引入、为什么存在。

---

## 5. 完整审计方法

### 5.1 先列出全部提交，不要过滤提交标题

```powershell
git log --reverse --oneline <base>..<pre-merge>
```

不要先排除：

- `Release ...`。
- `fix`。
- `revert`。
- 合并提交。
- 看起来只改版本号的提交。

本次第一次审计的主要错误之一，就是过早把 Release 提交视为纯版本提交。后来发现部分 Release 提交同时包含真实的性能、平台或产品改动。以后必须先看内容，再决定是否忽略。

推荐输出带文件统计的提交列表：

```powershell
git log --reverse --stat --oneline <base>..<pre-merge>
```

对可疑提交查看完整内容：

```powershell
git show --format=fuller --stat <commit>
git show --format=fuller <commit> -- <related-paths>
```

### 5.2 同时查看最终净差异

提交历史回答“发生过什么”，最终 diff 回答“最后还剩什么”。两者必须一起看：

```powershell
git diff --stat <base>..<pre-merge>
git diff --name-status <base>..<pre-merge>
git diff <base>..<pre-merge> -- <path>
```

如果某项提交后来被完全回滚，它可能出现在提交历史中，但不应恢复到新版本。

如果某项产品意图经过多次重写，最终 diff 可能只剩很小的变化，但必须结合历史理解原因。

### 5.3 按功能链追踪，而不是按单个提交判断

对同一功能搜索所有相关提交：

```powershell
git log --oneline <base>..<pre-merge> -- <path>
git log -S 'specificSymbol' --oneline <base>..<pre-merge>
git log -G 'regularExpression' --oneline <base>..<pre-merge>
```

然后按时间顺序阅读：

```powershell
git show <commit1>
git show <commit2>
git show <commit3>
```

本次典型链路：

- Direct 测速经历修改和中间回滚，最终意图是批量测速跳过 Direct，并隐藏 Direct 卡片上没有意义的延迟入口。
- 启动动画经历多个曲线调整，最终行为是 `300ms + easeOutCubic`，不是历史中出现过的 `easeOutBack`。
- external controller 经历“App 强制覆盖 → Profile 优先 → 独立解析 → 从 UpdateParams 移除”，最终意图是关闭时真正关闭，开启时只服从 Profile 合法字符串，缺失或非法保持空值。
- HCT 自定义颜色曾被删除复杂主题时一起移除，但后来作为明确产品功能恢复，因此应保留 HCT，自定义 `pureBlack`、`textScale` 和 `schemeVariant` 仍应删除。

### 5.4 建立分类表

每项修改至少记录以下字段：

| 字段 | 内容 |
| --- | --- |
| 提交/提交链 | 相关历史提交 |
| 分类 | 精简、修改、优化、修复、丢弃 |
| 修改对象 | UI、配置、Core、Android、构建、发布等 |
| 原问题 | 当时为什么修改 |
| 最终行为 | 合并前最终版本表现 |
| 上游变化 | 新版是否重构或覆盖该行为 |
| 迁移方式 | 删除、保留、重写、由新架构替代 |
| 验证方式 | 测试、分析、平台编译、人工检查 |
| 当前状态 | 已恢复、已保留、明确丢弃、待验证 |

分类定义：

#### 精简

主动移除不必要的入口、状态、文案或视觉噪声。

判断问题：

- 这个功能是否被 XClash 明确删除？
- 上游是否重新引入了它？
- 是否存在死代码、隐藏状态或残余文案？

#### 修改

产品语义、默认值、品牌、配置优先级或渠道行为与上游不同。

判断问题：

- 用户配置与 App 默认值谁优先？
- 包名、进程名、服务名是否属于 XClash？
- 缺少可选密钥是否应该阻断主发布？

#### 优化

性能、内存、电量、网络、构建产物或稳定性改进。

判断问题：

- 优化目标是否仍成立？
- 上游是否已有等价实现？
- 原实现是否依赖旧架构？
- 新版共享路径在哪里？

#### 修复

明确的错误修正，通常应保留，但要确认上游是否已修复。

#### 丢弃

临时实验、已回滚实现、过期文档、被新版架构完整替代的旧代码。

丢弃也必须记录原因，避免下一次审计再次误判为遗漏。

---

## 6. 合并实施顺序

### 6.1 文档先于代码

在执行正式迁移前，先创建或更新：

- 当前版本逐项审计表。
- 合并决策文档。
- 待恢复清单。
- 明确丢弃清单。

这样做可以防止修到一半时被当前代码结构带偏，也能在多人或多 agent 并行时提供统一规格。

### 6.2 合并上游架构

在用户指定分支上执行，不擅自切换：

```powershell
git merge --no-ff <upstream-target>
```

解决冲突时的优先级：

1. 保留上游新架构和新数据结构。
2. 保留 XClash 最终产品语义。
3. 不恢复已淘汰的旧文件。
4. 不为了减少冲突而接受上游默认产品行为。

冲突解决后先确认合并本身可生成代码和编译，再进入产品行为恢复阶段。

### 6.3 按领域恢复，而不是按提交逐个 cherry-pick

推荐领域顺序：

1. 模型和配置语义。
2. Provider / Action / Manager 共享逻辑。
3. Core 和平台生命周期。
4. 构建系统与产物参数。
5. UI 精简和交互。
6. 品牌、包名和服务名。
7. 发布流程和文档。
8. 生成文件与测试。

不推荐直接批量 cherry-pick 旧提交，因为：

- 路径和架构已经改变。
- 旧提交可能包含中间实现。
- 多个提交可能互相抵消。
- 容易重新引入已删除的旧控制器和依赖。
- 冲突解决后表面成功，但语义可能完全不同。

### 6.4 每恢复一项都问四个问题

1. 这项修改的最终产品意图是什么？
2. 上游新版由哪个模块负责这项行为？
3. 能否在一个共享位置解决？
4. 用哪一个最小测试锁住结果？

如果无法回答，不应急着复制代码。

---

## 7. 本次 v0.8.94 的实际处理过程

### 7.1 第一阶段：合入上游架构

初次合并提交为：

```text
612ac0c Merge upstream v0.8.94 architecture
```

该阶段保留了上游的重要架构升级：

- Provider / Action 重构。
- 新版数据库和自定义覆写。
- Core IPC 与平台通信调整。
- 新版 buildkit。
- Windows ARM64 支持。
- Linux 静默启动修复。
- macOS 性能修复。
- 新版 Clash.Meta Core 集成。

这一阶段的问题是：合并虽然在 Git 和架构层面成功，但同时重新带回了不少 XClash 已删除或修改的产品设计。

### 7.2 第二阶段：第一次恢复本地定制

后续提交开始恢复品牌、发布渠道和部分产品修改：

```text
8609e6d Reapply XClash customizations on v0.8.94
3fbad7c Release v7.0.32
265c274 fix: skip optional release channels without keys
e37d378 fix: restore XClash product customizations
1f292b0 fix: preserve intentional product simplifications
4943669 Release v7.0.32 rebuild 2
```

这一轮恢复了很多明显项目，例如：

- XClash 品牌。
- XClashCore 名称。
- 部分 Helper 配置。
- Direct 测速精简。
- 启动动画。
- Android 平板侧栏图标。
- 可选发布渠道缺密钥时跳过。

但是这轮处理仍不完整，原因不是单个冲突没解决，而是审计方法不够彻底。

### 7.3 用户反馈暴露出的根本问题

用户指出：

> 之前好多不要的、优化精简的设计又全部被摘回来了。

这说明“主要功能可用”和“产品行为完整保留”是两件不同的事。

当时仍被上游重新带回或未完整恢复的内容包括：

- 复杂主题字段和运行时分支。
- 纯黑模式。
- 自定义文字缩放。
- 配色变体。
- 通知组件和全局主题缓存。
- Dashboard 相关复杂状态。
- Profile 的 `external-ui` 强制清空。
- external controller 默认地址回退。
- Dashboard 网络组件对 IP 检查的错误门槛。
- 部分网络接口过滤。
- Core GC、图片缓存、MTU 和 FlutterEngine 复用等性能优化。
- Android 网络切换后旧连接清理。
- buildkit 的低内存、`-trimpath` 和 16KB 页面参数。
- Android 独立包名和 Helper 服务全链名称。

### 7.4 暂停错误发布

当更深审计发现遗漏后，正在运行的旧构建 `29273491970` 被取消。

这是正确做法。即使构建已经花费时间，也不能因为“马上就完成”而发布已知不符合产品规格的版本。

发布前应满足：

- 审计清单已经封闭。
- 所有明确保留项均有实现或明确说明。
- 所有明确丢弃项均有理由。
- 关键语义已有测试。
- 完整验证通过。

### 7.5 重新扩大审计范围

第二次审计不再过滤 Release 提交，并按以下方式重新检查：

```powershell
git log --reverse --oneline 672eacc..9e87fb6
git diff --stat 672eacc..9e87fb6
git diff --name-status 672eacc..9e87fb6
```

然后对主题、Profile、网络、Core、Android、buildkit、发布流程分别追踪完整提交链。

这一阶段建立了：

- `docs/pre-v0.8.94-customization-audit.md`
- `docs/upstream-v0.8.94-merge-decisions.md`

前者记录所有历史修改的分类与处理状态；后者记录架构迁移原则、保留内容和丢弃内容。

### 7.6 使用 agent 并行复核

本次使用 agent 复核了互相独立的领域：

- Dashboard 精简。
- 主题精简与自定义颜色。
- Profile 配置生成语义。

适合交给 agent 的任务必须满足：

- 范围清晰。
- 有明确基线，例如 `9e87fb6`。
- 有明确当前目标，例如只读复核，不修改文件。
- 不与主流程写同一组文件。
- 输出必须包含路径、证据、风险和结论。

推荐提示格式：

```text
请只读复核当前 <领域> 相对 <合并前最终提交> 的最终产品行为。
重点检查 <具体语义>。
不要修改文件，返回具体路径、证据、风险和建议。
```

不能只相信 agent 报告“已修改”。必须在主工作树验证：

```powershell
git status --short
git diff -- <paths>
rg -n "symbolsThatShouldDisappear" <paths>
```

本次曾出现 agent 报告 Dashboard 修改完成，但主流程需要再次确认修改是否真实落入当前工作树。最终发现 Dashboard 精简已经存在于 HEAD，因此没有重复写代码。

### 7.7 最终修复提交

完整审计后的最终修复提交为：

```text
34ba649 fix: restore full XClash product intent
```

该提交的总体方向是删除大于新增：

```text
51 files changed, 306 insertions(+), 779 deletions(-)
```

这符合本次目标：上游架构保留，但重新引入的产品复杂度应删除。

---

## 8. 本次各领域的迁移方法

### 8.1 主题系统

#### 合并前最终意图

- 默认使用自动/系统颜色。
- 保留后来明确恢复的 HCT 自定义颜色功能。
- 色块显示 HEX。
- 删除纯黑、自定义文字缩放和配色变体。
- 不维护全局主题缓存和额外通知组件。
- 尺寸间距保持简单固定逻辑。

#### 上游重新带回的问题

- `ThemeProps` 再次出现 `pureBlack`、`textScale`、`schemeVariant`。
- UI 再次出现对应设置。
- 运行时保留纯黑和缩放分支。
- `TextScaleNotification` 和 `CommonTheme` 恢复。
- 颜色生成固定使用 `DynamicSchemeVariant.content`。
- 已删除功能的本地化文案仍存在。

#### 最终处理

- 从模型删除字段。
- 运行 build_runner 更新 Freezed 和 JSON 生成文件。
- 删除设置 UI 和运行时逻辑。
- 删除无调用的主题缓存和通知组件。
- 删除 ARB 文案并重新生成本地化文件。
- 恢复 Flutter 默认 `ColorScheme.fromSeed` 变体，不再强制 `content`。
- 保留系统文字缩放用于测量和可访问性；删除的是 App 自定义缩放功能，不是系统可访问性。
- 修复自动色卡片 HEX：调用 `genColorSchemeProvider` 时使用 `ignoreConfig: true`，否则选中自定义颜色后，自动色卡片会错误显示当前自定义色 HEX。

#### 经验

删除设置时不能只删页面。必须搜索字段名和相关类型：

```powershell
rg -n "TextScale|pureBlack|schemeVariant|CommonTheme|TextScaleNotification" lib arb test
```

### 8.2 Dashboard 精简

#### 合并前最终意图

- 首页只保留标题、组件网格和启动按钮。
- 不显示顶部核心状态或重启快捷按钮。
- 不提供 Dashboard 内编辑、添加、排序入口。
- 网络检测卡片不显示信息图标和说明弹窗。

#### 实际判断

合并前代码仍存在一部分不可达编辑状态机，但用户可见入口已经删除。新版本没有必要复制这段死代码。

最终实现直接保留：

- `dashboardStateProvider`。
- 响应式内容宽度。
- 已持久化组件列表。
- 平台过滤。
- `Grid`。
- `StartButton`。

并彻底删除不可达编辑逻辑。

#### 经验

产品行为一致不等于逐行一致。旧版本中的死代码不是产品规格。

### 8.3 Profile 配置优先级

#### 合并前最终意图

- Profile/YAML 中用户明确写入的值优先。
- App 只补缺省值。
- 自定义脚本、规则和代理组具有明确覆盖顺序。
- `external-ui` 和 `external-ui-url` 不应被强制清空。
- `external-controller` 关闭时真正关闭；开启时只使用 Profile 合法字符串。

#### 最终优先级

一般配置按以下顺序理解：

1. 运行安全必需字段。
2. 用户自定义覆写。
3. Profile 原始显式配置。
4. App 缺省值。

多数 App 默认值使用 `??=` 补齐，避免覆盖 Profile。

`external-controller` 单独处理：

- UI 关闭：输出空字符串。
- UI 开启且 Profile 值为字符串：保留 Profile 值。
- UI 开启但字段缺失或类型非法：输出空字符串。
- 不回退到 `127.0.0.1:9090`。

#### 为什么没有使用 App 默认地址

相关提交链的最终意图是“Profile 决定监听地址，UI 只决定是否允许”。旧版本独立解析函数对缺失或非法值返回空字符串。上游合并后出现的默认地址回退改变了该语义，因此最终删除。

对应测试覆盖：

- 关闭时清空。
- 开启时保留 Profile 地址。
- 缺失时保持空值。
- 非字符串时保持空值。
- 保留 `external-ui` 和 `external-ui-url`。
- Profile 和嵌套 TUN 显式值优先。
- DNS 与自定义 overwrite 行为。

### 8.4 IP 检查与 Dashboard 解耦

#### 问题

上游实现把 IP 检查是否运行与 Dashboard 是否启用网络检测组件绑定。这样当用户隐藏或不显示该组件时，其他需要 IP 信息的流程也不会刷新。

#### 修复

`checkIpProvider` 只依赖：

- App 是否初始化。
- IP 刷新触发计数。

`AppManager` 只监听初始化状态和触发器，不再监听 Dashboard 组件设置。

#### 根因原则

网络状态属于应用状态，不属于某个 Dashboard 组件。UI 可以消费状态，但不应决定状态是否存在。

### 8.5 批量测速

最终保留：

- Direct 不进入批量延迟测试。
- Direct 卡片隐藏无意义延迟入口。
- 测速 FAB 只显示图标。
- 测速目标为当前可见 Tab。
- 每个批次开始时才创建该批次 Future，避免一次性创建全部任务。

错误实现是先为所有代理创建 Future，再按批等待。虽然看起来有批次循环，但实际请求已经全部启动，不能降低瞬时资源占用。

### 8.6 配置应用后的 Core GC

GC 调度放在共享 `_setupConfig` 成功路径：

- 只有配置成功后执行。
- 延迟两秒，避免阻塞配置切换关键路径。
- 所有通过共享 Action 应用配置的入口自动获得该优化。

不要在每个页面、按钮或启动分支单独添加 GC。

### 8.7 Android 运行优化

本次恢复：

- TUN MTU `4064`，Go Core 与 Android `VpnService` 保持一致。
- Flutter 图片缓存上限 `50MB`。
- FlutterEngine 复用。
- 网络类型改变时关闭旧连接。
- 关闭旧连接保留原有节流：五秒内最多两次。
- 过滤虚拟接口，包括 `ppp`。
- 识别 Linux `wlp*` Wi-Fi 接口。
- 保留移动数据优先级。
- Dashboard 之外也能触发 IP 刷新。

平台参数必须跨边界检查。例如 MTU 同时存在于：

- `core/tun/tun.go`
- Android `VpnService.kt`

只改一侧会产生难以定位的设备差异。

### 8.8 buildkit 与构建参数

本次恢复：

- 全局 Go tags：`with_gvisor,no_fake_tcp`。
- `armeabi-v7a` 增加 `with_low_memory`。
- Go 构建增加 `-trimpath`。
- Android arm64/x86_64 增加 16KB 最大页面大小链接参数。
- Helper 名称使用 `XClashHelperService`。

并新增构建工具测试，验证：

- 低内存 tag 只用于 `armeabi-v7a`。
- 16KB 页面参数只用于 Android 64 位目标。

构建参数逻辑应放在 build tool 中统一生成，不应分散复制到工作流、Gradle 和本地脚本。

### 8.9 品牌和平台标识

品牌恢复不能只改应用标题。需要搜索完整链：

```powershell
rg -n "FlClash|XClash|FlClashCore|XClashCore|HelperService" .
```

本次重点恢复：

- Android package ID：`com.xqd922.flclash`。
- XClash 应用名。
- XClashCore。
- `XClashHelperService` Dart 常量。
- buildkit 默认值和配置文件。
- Windows CMake Helper 路径。
- Rust Windows service 名称。
- Inno Setup 进程列表。

内部临时构建名称如果最终会被 buildkit 正确重命名，可以保留上游内部名称，避免无意义改动。品牌检查重点是用户可见产物、运行进程、服务注册和安装器行为。

### 8.10 明确丢弃的旧实现

本次没有恢复：

- 已删除的旧 `lib/controller.dart` 架构。
- 临时关闭 Impeller 的实验。
- 包可见性先加固后回滚的中间提交。
- 过期 Release 备份指南。
- 会丢失 DMG、DEB、RPM、EXE 输出的旧原生打包替代方案。
- 已被新版生命周期完整替代的旧后台定时器。
- 旧 loading 中间实现。

丢弃理由必须写入审计文档。否则以后看到历史提交时，容易再次误认为“漏合并”。

---

## 9. 生成文件与换行符噪声

### 9.1 不手工修改生成文件

涉及模型、Provider、数据库或本地化时，必须修改源文件后重新生成：

```powershell
D:\DevTools\flutter-3.44.1\flutter\bin\dart.bat run build_runner build
D:\DevTools\flutter-3.44.1\flutter\bin\dart.bat run intl_utils:generate
```

本仓库生成文件包括：

- `lib/models/generated/`
- `lib/providers/generated/`
- `lib/database/generated/`
- `lib/l10n/intl/`
- `lib/l10n/l10n.dart`

源模型删除字段后，应检查生成结果是否同步删除序列化、`copyWith`、构造函数和默认值。

### 9.2 Windows CRLF 会制造假修改

build_runner 在 Windows 上可能触碰大量生成文件，仅造成 LF/CRLF 或工作树元数据变化。

不要仅根据 `git status` 判断真实修改。使用：

```powershell
git diff --raw
git diff --numstat
git diff --name-only --ignore-cr-at-eol
```

如果文件只因换行符被标记，且没有真实内容差异，可以恢复：

```powershell
git restore --worktree -- <noise-file>
```

恢复前必须用 `--ignore-cr-at-eol` 确认没有真实改动，不能批量盲目 restore。

### 9.3 `docs/` 默认被忽略

本仓库 `.gitignore` 包含：

```text
docs/
```

已跟踪文档可以正常更新，但新增文档默认不会进入 `git status`。新增审计或操作文档必须显式加入：

```powershell
git add -f docs/<new-document>.md
```

提交前确认：

```powershell
git diff --cached --name-status
```

---

## 10. 验证策略

验证应从最小范围逐步扩大，不能一开始只跑全量测试，也不能只跑聚焦测试后直接发布。

### 10.1 静态符号扫描

对明确删除或改名的设计，先扫描残留：

```powershell
rg -n "CommonTheme|globalState\.theme|TextScale|pureBlack|schemeVariant" lib arb test
rg -n "FlClashHelperService|XClashHelperService" lib plugins services windows
```

扫描结果需要人工判断。例如：

- 系统 `TextScaler` 用于文字测量，应保留。
- 通用 `DynamicSchemeVariant` 模型如果仍有调用可能不是设置残留。
- 文档中提到已删除字段属于正常记录。

### 10.2 格式与补丁检查

```powershell
D:\DevTools\flutter-3.44.1\flutter\bin\dart.bat format <changed-dart-files>
gofmt -w core/tun/tun.go
git diff --check
```

Kotlin 没有单独配置格式器时，保持邻近代码风格并依赖编译验证，不为一次合并新增格式化工具。

### 10.3 依赖和代码生成

```powershell
D:\DevTools\flutter-3.44.1\flutter\bin\flutter.bat pub get
D:\DevTools\flutter-3.44.1\flutter\bin\dart.bat run build_runner build
D:\DevTools\flutter-3.44.1\flutter\bin\dart.bat run intl_utils:generate
```

只有在对应源文件变化时运行需要的生成器，避免无意义触碰全树。

### 10.4 聚焦测试

先针对本次修改运行：

```powershell
D:\DevTools\flutter-3.44.1\flutter\bin\flutter.bat test test/common/task_test.dart
D:\DevTools\flutter-3.44.1\flutter\bin\flutter.bat test test/models/config_test.dart
D:\DevTools\flutter-3.44.1\flutter\bin\flutter.bat test test/providers/app_test.dart
D:\DevTools\flutter-3.44.1\flutter\bin\flutter.bat test test/widgets/input_test.dart
```

根据领域补充测试，不要机械固定为这四个文件。

### 10.5 全量 Flutter 验证

发布前必须运行：

```powershell
D:\DevTools\flutter-3.44.1\flutter\bin\flutter.bat analyze --no-fatal-infos
D:\DevTools\flutter-3.44.1\flutter\bin\flutter.bat test --reporter expanded
```

本次最终结果：

- `flutter analyze --no-fatal-infos` 通过。
- 剩余 12 条既有非致命 info。
- 430 个 Flutter 测试通过。

必须区分：

- 本次新增 warning：需要修复。
- 仓库已有非致命 info：记录但不扩大范围处理。

### 10.6 build tool 测试

```powershell
Push-Location plugins/setup/buildkit/build_tool
D:\DevTools\flutter-3.44.1\flutter\bin\dart.bat test
Pop-Location
```

本次最终 12 个 build tool 测试通过。

### 10.7 Android Kotlin 编译

本次使用：

```powershell
android\gradlew.bat `
  -p android `
  :service:compileDebugKotlin `
  :app:compileDebugKotlin `
  --no-daemon `
  "-Pkotlin.incremental=false"
```

注意 PowerShell 参数必须把 `-Pkotlin.incremental=false` 放在引号中，否则可能被错误解析为 Gradle task。

第一次遇到 Kotlin 增量缓存关闭问题时，不应修改业务代码，应先用禁用增量编译重新验证。最终 Android 编译成功。

### 10.8 发布前最终检查

```powershell
git status --short
git diff --check
git diff --stat
git diff --raw
git diff --cached --check
```

需要确认：

- 工作树只包含预期修改。
- 新文档已强制加入。
- 生成文件只有真实变化。
- 版本号正确。
- `RELEASE.md` 顶部说明与实际实现一致。
- 没有旧品牌和已删除功能残留。

---

## 11. 版本号与发布说明

### 11.1 版本号

本次最终版本：

```yaml
version: 7.0.32+2026071403
```

如果同一个公开版本需要重建，应保持公开版本 `7.0.32`，递增 build number，避免构建产物内部版本完全重复。

本次旧构建已使用 `2026071402`，最终重发使用 `2026071403`。

### 11.2 发布说明必须反映最终审计

`RELEASE.md` 不应只写“合并上游”。至少包含：

- 上游架构与修复。
- XClash 保留的产品定制。
- 恢复的精简设计。
- 性能和稳定性优化。
- 配置语义变化。
- 审计文档位置。

避免发布说明仍描述已经被最终决策否定的行为。例如本次 external controller 最初写成“缺省时使用 App 默认地址”，深度审计后发现不符合最终产品语义，发布说明也必须同步修正。

---

## 12. 提交、推送与重发标签

### 12.1 提交前

```powershell
git add -A
git add -f docs/<new-document>.md
git diff --cached --stat
git diff --cached --check
```

然后提交：

```powershell
git commit -m "fix: restore full XClash product intent"
```

本次没有切换分支，直接在 `optimize` 完成提交。

### 12.2 推送分支

```powershell
git push origin optimize
```

### 12.3 重发相同版本标签

本仓库 `.github/workflows/build.yaml` 只在推送 `v*` 标签时触发。因此重发同一版本需要让标签指向最终提交：

```powershell
git tag -d v7.0.32
git push origin :refs/tags/v7.0.32
git tag v7.0.32
git push origin v7.0.32
```

顺序不能省略：

1. 删除本地旧标签。
2. 删除远程旧标签。
3. 在当前已验证提交创建新标签。
4. 推送新标签触发工作流。

执行后验证：

```powershell
git show -s --oneline v7.0.32
git ls-remote origin refs/tags/v7.0.32
git ls-remote origin refs/heads/optimize
```

远程分支和标签都应指向最终提交。

### 12.4 不要让旧 Draft Release 混淆判断

失败或取消的工作流可能留下未发布 Draft，且资源 URL 使用 `untagged-*`。

检查：

```powershell
gh release view v7.0.32 -R xqdwmq/FlClash `
  --json tagName,name,isDraft,isPrerelease,publishedAt,assets,url
```

正式结果必须满足：

- `isDraft: false`
- `isPrerelease: false`，除非本来就是预发布版本。
- URL 为 `/releases/tag/v7.0.32`。
- 资产属于最新构建。

---

## 13. 跟踪 GitHub Actions

### 13.1 找到新运行

```powershell
gh run list -R xqdwmq/FlClash `
  --workflow build.yaml `
  --limit 8 `
  --json databaseId,headSha,headBranch,status,conclusion,displayTitle,url
```

必须确认：

- `headBranch` 是目标标签。
- `headSha` 是最终提交。
- 不是旧失败运行。

本次最终运行：

```text
Run ID: 29277200325
Tag: v7.0.32
Head SHA: 34ba649c7a76682c2ea7c6164653f14a139bdf00
Conclusion: success
```

### 13.2 等待完整工作流

```powershell
gh run watch 29277200325 -R xqdwmq/FlClash --exit-status
```

不能只看到 Test job 成功就宣布发布完成。需要等待：

- Test。
- Linux AMD64。
- Linux ARM64。
- Windows AMD64。
- Windows ARM64。
- macOS AMD64。
- macOS ARM64。
- Android。
- changelog。
- upload / Release。

### 13.3 验证最终资产

本次正式 Release 包含 14 个资产：

```text
SHA256SUMS
XClash-7.0.32-android-arm64-v8a.apk
XClash-7.0.32-android-armeabi-v7a.apk
XClash-7.0.32-android-x86_64.apk
XClash-7.0.32-linux-amd64.AppImage
XClash-7.0.32-linux-amd64.deb
XClash-7.0.32-linux-amd64.rpm
XClash-7.0.32-linux-arm64.deb
XClash-7.0.32-macos-amd64.dmg
XClash-7.0.32-macos-arm64.dmg
XClash-7.0.32-windows-amd64-setup.exe
XClash-7.0.32-windows-amd64.zip
XClash-7.0.32-windows-arm64-setup.exe
XClash-7.0.32-windows-arm64.zip
```

检查命令：

```powershell
gh release view v7.0.32 -R xqdwmq/FlClash `
  --json tagName,name,isDraft,isPrerelease,publishedAt,targetCommitish,assets,url
```

`targetCommitish` 在 GitHub Release API 中可能显示工作流默认目标分支，不能单独用它判断标签提交。标签实际提交应以以下命令为准：

```powershell
git ls-remote origin refs/tags/v7.0.32
```

---

## 14. 本次踩坑与防止重演的方法

### 14.1 只审计“看起来像功能”的提交

**问题：** Release 提交中的真实改动被漏掉。

**以后：** 先查看所有提交的文件统计，再决定是否属于纯版本提交。

### 14.2 过早发布

**问题：** 部分显眼定制恢复后就重建版本，但深层主题、配置和性能语义尚未审计完成。

**以后：** 审计表必须先达到“每项有处理状态”，再创建标签。

### 14.3 机械恢复旧代码

**问题：** 容易把旧控制器、死状态和已淘汰结构带入新版。

**以后：** 以最终行为为规格，在新版 Provider、Action、Manager 或 buildkit 中重做。

### 14.4 只看 UI，不看完整链路

**问题：** 设置入口虽然删除，但模型字段、运行时分支、本地化和生成文件仍存在。

**以后：** 删除功能时搜索字段名、类型名、文案 key 和所有生成输出。

### 14.5 只看 `git status`

**问题：** Windows 换行符导致大量生成文件假修改。

**以后：** 使用 `git diff --raw`、`--numstat` 和 `--ignore-cr-at-eol` 判断真实内容。

### 14.6 相信并行任务报告而不验证主工作树

**问题：** agent 或并行工作可能在不同工作区、旧上下文或未落盘状态下报告完成。

**以后：** 主流程必须用 Git diff、符号扫描和测试独立确认。

### 14.7 把 App 默认值当安全兜底

**问题：** external controller 的默认地址回退看似合理，但改变了“Profile 决定地址”的产品语义。

**以后：** 默认值是否适用必须从提交链和最终行为确认，不能凭常规设计习惯推断。

### 14.8 只验证 Dart，不验证原生边界

**问题：** Android Kotlin、Go TUN、Helper 服务和构建参数可能在 Flutter 测试全部通过时仍出错。

**以后：** 修改平台代码后至少运行对应编译或构建工具测试。

### 14.9 只确认工作流成功，不确认 Release

**问题：** 旧 Draft、错误标签或缺少资产仍可能存在。

**以后：** 工作流成功后继续核对 Release 状态、资产数量、远程标签和远程分支提交。

---

## 15. 后续合并标准检查表

### 15.1 合并前

- [ ] 当前分支符合用户要求，没有擅自切换。
- [ ] 工作树干净。
- [ ] 创建合并前备份引用。
- [ ] 获取并确认上游目标标签提交。
- [ ] 计算并记录共同基线。
- [ ] 列出共同基线到合并前版本的全部提交。
- [ ] 查看全部提交的文件统计，包括 Release 提交。
- [ ] 查看合并前最终净差异。
- [ ] 建立精简、修改、优化、修复、丢弃分类表。
- [ ] 记录每项修改的初心和最终行为。

### 15.2 合并中

- [ ] 保留上游新架构。
- [ ] 不恢复已淘汰旧控制器。
- [ ] 配置语义在共享生成路径恢复。
- [ ] Provider 行为在共享 Provider/Action 恢复。
- [ ] 平台参数检查 Dart、Kotlin、Go、Rust 和构建脚本边界。
- [ ] 删除功能时清完整链路。
- [ ] 品牌检查包名、进程、服务、安装器和产物。
- [ ] 每项非平凡逻辑至少有一个可运行检查。
- [ ] 文档实时更新处理状态。

### 15.3 代码完成后

- [ ] 运行符号残留扫描。
- [ ] 格式化实际修改文件。
- [ ] 运行需要的代码生成。
- [ ] 清理 CRLF 假修改。
- [ ] 运行聚焦测试。
- [ ] 运行全量 analyze。
- [ ] 运行全量 Flutter test。
- [ ] 运行 build tool test。
- [ ] 编译受影响的原生平台代码。
- [ ] `git diff --check` 通过。
- [ ] `RELEASE.md` 与最终行为一致。
- [ ] 版本号和 build number 正确。
- [ ] 新增 `docs/` 文件已用 `git add -f` 加入。

### 15.4 发布后

- [ ] 当前分支已推送。
- [ ] 标签指向最终验证提交。
- [ ] GitHub Actions `headSha` 正确。
- [ ] 所有平台 job 成功。
- [ ] upload / Release job 成功。
- [ ] Release 不是 Draft。
- [ ] Release 不是错误的预发布状态。
- [ ] 全部预期资产存在。
- [ ] `SHA256SUMS` 存在。
- [ ] 远程标签和远程分支提交已核对。
- [ ] 本地工作树干净。

---

## 16. 推荐的下次合并命令模板

以下命令仅作为模板，提交和版本引用必须替换为实际值：

```powershell
$preMerge = git rev-parse HEAD
$upstreamTarget = 'v0.8.NEXT'

git status --short
git branch --show-current
git branch backup/optimize-pre-$upstreamTarget-YYYYMMDD $preMerge
git fetch upstream --tags

$base = git merge-base $preMerge $upstreamTarget
git show -s --oneline $base
git log --reverse --stat --oneline "$base..$preMerge"
git diff --stat "$base..$preMerge"
git diff --name-status "$base..$preMerge"

# 先完成审计文档，再执行合并
git merge --no-ff $upstreamTarget

# 修改模型/Provider 后
D:\DevTools\flutter-3.44.1\flutter\bin\flutter.bat pub get
D:\DevTools\flutter-3.44.1\flutter\bin\dart.bat run build_runner build

# 修改 ARB 后
D:\DevTools\flutter-3.44.1\flutter\bin\dart.bat run intl_utils:generate

# 最终验证
D:\DevTools\flutter-3.44.1\flutter\bin\flutter.bat analyze --no-fatal-infos
D:\DevTools\flutter-3.44.1\flutter\bin\flutter.bat test --reporter expanded

Push-Location plugins/setup/buildkit/build_tool
D:\DevTools\flutter-3.44.1\flutter\bin\dart.bat test
Pop-Location

android\gradlew.bat -p android `
  :service:compileDebugKotlin `
  :app:compileDebugKotlin `
  --no-daemon `
  "-Pkotlin.incremental=false"

git diff --check
git status --short
```

发布模板：

```powershell
git add -A
git add -f docs/<new-audit-document>.md
git diff --cached --check
git commit -m "merge: integrate upstream v0.8.NEXT"
git push origin optimize

git tag -d v7.0.NEXT
git push origin :refs/tags/v7.0.NEXT
git tag v7.0.NEXT
git push origin v7.0.NEXT

gh run list -R xqdwmq/FlClash --workflow build.yaml --limit 5
```

---

## 17. 最终结论

成功的上游合并不是解决冲突，也不是让测试变绿，而是同时完成三件事：

1. 获得上游新架构和修复。
2. 保持 XClash 已确认的产品行为。
3. 为下一次合并留下可验证的决策记录。

本次 `v0.8.94 → v7.0.32` 最重要的经验是：

> 不要把本地分支理解成一组需要 cherry-pick 的旧代码；应把它理解成一套需要迁移到新架构的产品规格。

只要后续继续坚持“共同基线审计、最终行为优先、共享根路径修复、完整链路删除、发布前全量验证”，就能显著降低上游合并后产品精简和优化被无意恢复的风险。

相关文档：

- `docs/pre-v0.8.94-customization-audit.md`
- `docs/upstream-v0.8.94-merge-decisions.md`
- `RELEASE.md`
