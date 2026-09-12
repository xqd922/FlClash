# 可变字体 wght 轴钉住 —— 修改思路与复用方案

> 适用：本 fork 的 `graphics` 基线，以及任何 Flutter 3.41+ 应用在「系统回退中文字体是
> 可变字体」的设备上出现的**界面文字整体变粗**问题。
> 台账条目见 [CUSTOMIZATIONS.md](CUSTOMIZATIONS.md) 的 2026-09-12 字体条目。

---

## 1. 问题现象与根因

### 1.1 现象

在红米 K70（HyperOS）等设备上，从旧版本升级到 Flutter 3.41+ 引擎构建的包后：
- 标题、列表头、标签（M3 的 title/label 系列文字角色）明显变粗；
- 中文比拉丁文字变粗得更明显；
- 纯英文界面几乎看不出变化。

### 1.2 根因链（四环缺一不可）

1. **引擎破坏性变更**：Flutter 3.41 起，`TextStyle.fontWeight` 会隐式写入可变字体的
   `wght` 轴（官方说明 [font-weight-variation](https://docs.flutter.dev/release/breaking-changes/font-weight-variation)，
   实现 PR flutter/flutter#175771，追踪 issue #148026）。**即使 fontWeight 未指定，
   引擎也会强制 wght=400**（作者解释：部分可变字体默认轴值不是 400，不显式设置会渲染错误）。
2. **系统回退字体是可变字体**：应用没有设置 fontFamily 时，中文文字回退到系统字体。
   HyperOS（小米/红米）是 MiSans——可变字体；Windows 11 的 Segoe UI Variable 同理。
   ColorOS、部分三星机型类似。
3. **Material 3 大量使用 w500 文字角色**：`titleMedium`/`titleSmall`/`labelLarge` 等都是
   w500。旧引擎下这些角色对可变回退字体"无效"（一律渲染默认字重），新引擎下真实生效。
4. **项目代码几乎没改**：v0.8.96→v0.8.97 的显式 `fontWeight` 改动只有个位数行，
   字体资源、ThemeData、textTheme 用法跨版本几乎一致——**观感差异全部来自引擎行为变化**。

### 1.3 新旧行为对照表

| 文字样式 | 旧引擎 (<3.41) | 新引擎 (3.41+) |
|---|---|---|
| 拉丁文（Roboto/Segoe 静态字体）w500 | w500 生效 | w500 生效（不变） |
| 中文（MiSans VF 等）w400/未指定 | 默认字重(≈400) | 强制 400（不变） |
| 中文 w500/w600/w700 | **默认字重(≈400)** | **真实 wght 500/600/700（变粗）** |

结论：要"恢复旧观感"，只需对可变字体显式钉住 `wght=400`；拉丁文和静态字体自动不受影响。

---

## 2. 诊断思路（换一个项目/设备时怎么确认病因）

按顺序排查，任何一步不成立就另找原因：

1. **代码层排除**：`grep -rn "fontFamily\|fontWeight" lib/` —— 确认没有全局 fontFamily
   覆盖、显式字重改动极少。若存在大量显式字重改动，先 diff 掉无关变量。
2. **引擎版本对照**：确认"看起来正常"的旧包与"变粗"的新包各自构建用的 Flutter 版本。
   分界线是 **3.41**（stable 引入隐式 wght）。两边都在 3.41+ 或都在 3.40-，则另有原因。
3. **设备回退字体确认**：Android 中文设备的系统字体（HyperOS=MiSans、ColorOS=Sans/,
   三星=One UI Sans…）是否为可变字体。可用 `adb shell dumpsys | grep -i font` 粗查或
   直接以"该厂商中文字体 + variable font"搜索求证。
4. **语义确认（钉住是否有效）**：引擎对同时携带 `fontWeight` 与显式
   `fontVariations: [FontVariation('wght', x)]` 的样式，以**显式 fontVariations 优先**
   （引擎用 `weightAxisSet` 标记检测用户是否已指定 wght）。这是整个方案的理论前提。
5. **最小验证**：写一个 widget 测试，构造 `ThemeData(typography: <钉住后的 Typography>)`，
   断言 `textTheme.titleMedium!.fontVariations` 包含 `FontVariation('wght', 400)`
   （本仓库已实现，见 §5）。

---

## 3. 修复方案的关键决策（为什么这么做）

| 决策 | 备选项 | 选择理由 |
|---|---|---|
| **注入点：`ThemeData(typography:)`** | 构造后 `copyWith(textTheme:)` | 组件主题（ListTile/AppBar 等）在 `ThemeData` **构造期间**就从
      textTheme 派生样式（`theme_data.dart: textTheme = defaultTextTheme.merge(textTheme)`），
      事后 copyWith 不会重新派生，组件依旧变粗。只有从构造入口注入才能全覆盖 |
| **钉住值：400** | 字体真实默认轴值 | 旧引擎行为 = "用字体默认轴值渲染"，MiSans VF 默认实例是 Regular(400)。
      若某设备默认轴值非 400（如个别 430/370 的定制字体），可按设备微调（见 §8） |
| **覆盖层级：Typography 全部 5 个子主题** | 只改 black/white | `Typography` 还有 `englishLike`/`dense`/`tall` 三个度量主题（`tall` 服务
      CJK locale），一起钉住才是超集、无死角 |
| **不动 `toSoftBold`/`toBold`** | 顺手加钉 | `copyWith` 保留已存在的 `fontVariations`（`fontVariations ?? this.fontVariations`），
      所有调用点都从 textTheme 派生，天然继承钉住；多此一举反而引入语义耦合 |
| **显式传 `platform: defaultTargetPlatform`** | 省略 | `Typography.material2021` 自身默认 `platform: TargetPlatform.android`，
      而 `ThemeData` 内部解析为 `platform ??= defaultTargetPlatform`；不显式传在桌面端会
      选错度量主题 |
| **中文注释保留在代码里** | 纯代码 | 这是"本地定制"，注释写明失效条件（上游重构时别丢） |

**自动覆盖 vs 需要手动钉的边界**：
- ✅ 自动覆盖：所有从 `Theme.of(context).textTheme` / `context.textTheme` 派生的样式，
  以及其上任意层 `copyWith(...)`、`TextStyle.merge`（merge 保留基线的 fontVariations）、
  `TextStyle.apply`（`fontVariations ?? this.fontVariations`）。
- ⚠️ 手动钉：**从零构造**且带 `fontWeight != normal` 的 `TextStyle` 字面量
  （`const TextStyle(fontWeight: FontWeight.w600, ...)`）——它没有基线可继承。
  判断标准：该样式是否可能承载 CJK。纯拉丁（如 error 页的英文文案）可以不钉。

---

## 4. 具体实现（逐文件）

### 4.1 `lib/common/text.dart` —— 三级扩展（核心）

```dart
// Flutter 3.41 起 fontWeight 会隐式写入可变字体的 wght 轴，而 HyperOS 等系统的
// 中文回退字体 MiSans 是可变字体，界面文字因此整体变粗。显式钉住 wght 轴可让
// 可变字体按默认字重渲染；Roboto 等静态字体不支持该轴，不受影响。
const _kDefaultWeightVariations = <FontVariation>[FontVariation('wght', 400)];

extension TextStyleExtension on TextStyle {
  // ...原有 toLight/toLighter/toSoftBold/toBold/toJetBrainsMono/adjustSize 不动...

  /// 单条样式钉住。手动钉"从零构造"的样式时使用。
  TextStyle get toDefaultWeight =>
      copyWith(fontVariations: _kDefaultWeightVariations);
}

extension TextThemeExtension on TextTheme {
  /// 整套文字主题钉住：15 个槽位逐一处理，空槽位保持 null。
  TextTheme get toDefaultWeight => TextTheme(
    displayLarge: displayLarge?.toDefaultWeight,
    displayMedium: displayMedium?.toDefaultWeight,
    displaySmall: displaySmall?.toDefaultWeight,
    headlineLarge: headlineLarge?.toDefaultWeight,
    headlineMedium: headlineMedium?.toDefaultWeight,
    headlineSmall: headlineSmall?.toDefaultWeight,
    titleLarge: titleLarge?.toDefaultWeight,
    titleMedium: titleMedium?.toDefaultWeight,
    titleSmall: titleSmall?.toDefaultWeight,
    bodyLarge: bodyLarge?.toDefaultWeight,
    bodyMedium: bodyMedium?.toDefaultWeight,
    bodySmall: bodySmall?.toDefaultWeight,
    labelLarge: labelLarge?.toDefaultWeight,
    labelMedium: labelMedium?.toDefaultWeight,
    labelSmall: labelSmall?.toDefaultWeight,
  );
}

extension TypographyExtension on Typography {
  /// Typography 5 个子主题全部钉住（tall 服务 CJK locale，不能漏）。
  Typography get toDefaultWeight => Typography(
    black: black.toDefaultWeight,
    white: white.toDefaultWeight,
    englishLike: englishLike.toDefaultWeight,
    dense: dense.toDefaultWeight,
    tall: tall.toDefaultWeight,
  );
}
```

要点：
- `FontVariation` 来自 dart:ui，`package:material_ui/material_ui.dart` 已再导出，无需额外 import。
- `_kDefaultWeightVariations` 是 const，使 `const TextStyle(..., fontVariations: ...)` 的
  调用点能保持 const。
- TextTheme 的 15 个槽位是 Flutter 当前完整集合（display/headline/title/body/label 各
  三档）；上游若增删槽位，此文件会有编译错误——**这是故意的**，防止漏钉新槽位。

### 4.2 `lib/application.dart` —— 构造期注入（唯一入口）

```dart
const _pageTransitionsTheme = PageTransitionsTheme(...);

/// 钉住可变字体 wght 轴的统一入口：HyperOS 等系统的中文回退字体 MiSans 是
/// 可变字体，若不显式指定，Flutter 3.41+ 会按 fontWeight 加重显示。
ThemeData buildAppTheme({required ColorScheme colorScheme}) => ThemeData(
  useMaterial3: true,
  pageTransitionsTheme: _pageTransitionsTheme,
  colorScheme: colorScheme,
  typography: Typography.material2021(
    platform: defaultTargetPlatform,
    colorScheme: colorScheme,
  ).toDefaultWeight,
).withAppShapes;
```

`MaterialApp` 使用处（浅色/深色各一次）：

```dart
final lightColorScheme = _getAppColorScheme(brightness: Brightness.light);
final darkColorScheme = _getAppColorScheme(brightness: Brightness.dark)
    .toPureBlack(themeProps.pureBlack);
...
theme: buildAppTheme(colorScheme: lightColorScheme),
darkTheme: buildAppTheme(colorScheme: darkColorScheme),
```

要点：
- `typography:` 的 ColorScheme 必须与 `colorScheme:` **同一实例**：Typography 的
  black/white 主题在构造时已按 scheme 着色，两者不一致会导致文字颜色错乱
  （深色模式尤其明显，`toPureBlack` 变换后的 scheme 必须也传给 typography）。
- 提取成 `buildAppTheme` 顶层函数不只是为了整洁：它是可测性的关键（§5），也让
  上游合并时冲突面收敛到一个函数。
- 需要 `import 'package:flutter/foundation.dart'`（`defaultTargetPlatform`）。

### 4.3 不需要改的地方（以及为什么）

| 位置 | 为什么不用改 |
|---|---|
| `toSoftBold` / `toBold` 扩展 | `copyWith` 保留基线 fontVariations；调用点全部源自 textTheme |
| `DefaultTextStyle.merge` 的调用（如 tab_segment） | merge 以"其他字段非空才覆盖"合并，钉住的 fontVariations 存活 |
| 纯拉丁文的 scratch 样式（error 页英文文案） | 拉丁字体是静态字体，fontWeight 行为新旧一致，钉了也是 no-op |
| `Icon(..., fontWeight: ...)` | 图标字体是静态字体，该参数本就不影响渲染 |

---

## 5. 验证与门禁

### 5.1 单元测试（两处，锁两层语义）

`test/common/text_test.dart` —— 锁**扩展本身**：
- 浅色/深色两种 `Typography.material2021(...).toDefaultWeight` 构造的 ThemeData，
  断言 display/headline/title/body/label 代表槽位的 `fontVariations` 含
  `FontVariation('wght', 400)`；
- 派生样式保留钉住：`pinned.toDefaultWeight.copyWith(fontWeight: w600)` 与
  scratch 样式 `.toDefaultWeight` 均含钉住。

`test/application_test.dart` —— 锁**真实主题的端到端**：
- 对 `buildAppTheme` 产出的真实 ThemeData（浅/深两轮）断言 textTheme 代表槽位
  fontVariations 含 `FontVariation('wght', 400)`。
- 这条测试同时把 lib 根目录覆盖率抬到门禁之上（历史教训：覆盖率 floor 差 0.4%
  曾卡住发版，提取 `buildAppTheme` 后 lib 组 19.6%→22.0%）。

### 5.2 本地门禁（CI 同款，必须全绿再推）

```bash
export PUB_HOSTED_URL=https://pub.dev   # 本机镜像环境必须，防依赖漂移
dart format --output=none --set-exit-if-changed lib test tool plugins setup.dart
flutter analyze --no-fatal-infos
flutter test --coverage
dart run tool/check_coverage.dart coverage/lcov.info 75
```

### 5.3 真机验收

HyperOS 设装新包后对比：标题/列表头不再发粗，英文粗细不变；深色模式文字颜色正常
（验证 typography 与 colorScheme 同源没做错）。

---

## 6. 复用场景 A：合并上游新版本后的存活检查（runbook）

每次 `git merge upstream/<新tag>` 后按序执行：

1. **主题构造点检查**
   ```bash
   grep -n "buildAppTheme\|typography:" lib/application.dart
   ```
   两者都必须存在且 `buildAppTheme` 内含 `.toDefaultWeight`。上游若重构了
   `MaterialApp` 构造（如 v0.8.97 那次 material_ui 迁移量级），把 §4.2 的注入
   重新套到新结构上——注入位置原则不变：**必须走 `ThemeData` 构造参数**。

2. **扩展文件检查**
   ```bash
   grep -n "toDefaultWeight\|_kDefaultWeightVariations" lib/common/text.dart
   ```
   合并冲突解决后确认 15 个 TextTheme 槽位齐全（缺槽位会编译报错，属预期保护）。

3. **反向污染检查**：上游是否引入了会**覆盖**钉住的代码——
   ```bash
   grep -rn "fontVariations" lib/ --include="*.dart" | grep -v common/text.dart
   grep -rn "typography:" lib/ --include="*.dart" | grep -v application.dart
   ```
   出现其他写入点时逐个判断：是覆盖 wght 轴（需要处理）还是别的轴（无关）。

4. **测试与门禁**：跑 §5.2 全套 + §5.1 的两个测试文件。

5. **真机抽查**：HyperOS 设备过一遍主界面/代理页/设置页。

历史记录：v0.8.97→v0.8.98-pre.1 的增量完全不碰主题/字体，钉住零冲突，
无需重验（已核对 diff）。

---

## 7. 复用场景 B：移植到其他 Flutter 项目的通用配方

任何 Flutter 3.41+ 项目（不限于本仓库）按七步走：

1. 新建 `lib/theme/font_weight_fix.dart`（或并入已有样式扩展文件），粘贴 §4.1 的
   常量与三个扩展。若项目无 material_ui，import 换成 `package:flutter/material.dart`。
2. 找到项目的 `ThemeData(...)` 构造点（`MaterialApp.theme` / `darkTheme`），
   套 §4.2 的 `typography:` 注入。若项目已有自定义 `typography:`，在其结果上链
   `.toDefaultWeight`；若已有自定义 `textTheme:`，改为在该 textTheme 上
   `.toDefaultWeight` 后传入（二者取其一即可，不要都传）。
3. 全库搜 `TextStyle(` 中带 `fontWeight:` 且**不从 textTheme 派生**的字面量，
   逐个判断是否承载 CJK，是则 `.toDefaultWeight` 或内联 fontVariations。
4. 补 §5.1 形态的两条测试。
5. 跑 `flutter analyze` + 相关测试。
6. 真机/模拟器验证（可造一个 w500 文本 + 中文系统字体的模拟器）。
7. 在项目文档记录钉住值与决策日期（参考本文件）。

---

## 8. 可调参数与变体

| 需求 | 改法 | 代价 |
|---|---|---|
| 某设备默认轴值不是 400 | 把 `_kDefaultWeightVariations` 的 400 改为实测值（如 370/430） | 极低；建议先在真机确认 |
| 只想救"过粗"的角色、保留标题粗体 | 删掉 TextTheme 扩展里的 title/display 槽位映射，仅钉 body/label | 中；上下级对比会变得生硬 |
| 仅 Android 生效、不动桌面 | `buildAppTheme` 里按 `defaultTargetPlatform == TargetPlatform.android` 决定是否 `.toDefaultWeight` | 低；但 Windows 11（Segoe UI Variable）同样受益于钉住，不建议 |
| 想要"更粗"（反向需求） | 钉住值改大（如 500），或去掉钉住让引擎按 fontWeight 渲染 | 低；等于回到上游默认行为 |

---

## 9. 已知边界与排错

| 症状 | 原因 | 处理 |
|---|---|---|
| 个别位置仍然粗 | 该样式是从零构造的 TextStyle 带显式 fontWeight | 按 §4.3 判断后手动 `.toDefaultWeight` |
| 深色模式文字颜色不对 | typography 与 colorScheme 传入的 scheme 不一致 | 两者必须同源（§4.2 要点） |
| 分析器报 `FontVariation` 未定义 | import 不含 material/painting 再导出 | import material（或 material_ui） |
| 升级 Flutter 后行为又变 | 引擎改了隐式 wght 的优先级语义（当前：显式 fontVariations 优先） | 关注 flutter/flutter#148026，必要时调整方案 |
| 中文粗细仍与旧版有细微差别 | 设备回退字体默认轴值 ≠ 400 | 按 §8 实测调整钉住值 |

---

## 10. 参考资料

- 官方破坏性变更：https://docs.flutter.dev/release/breaking-changes/font-weight-variation
- 实现讨论：flutter/flutter#148026，PR flutter/flutter#175771
  （要点：fontWeight 隐式驱动 wght；未指定时强制 400；显式 fontVariations 覆盖隐式值；
  FontWeight 支持 1–1000 任意值，`index` 废弃改用 `value`）
- 相关上游 issue：chen08209/FlClash#2082（ColorOS 字体渲染）、#248（嫌字太细的反向需求）
- 本仓库台账：[CUSTOMIZATIONS.md](CUSTOMIZATIONS.md)
