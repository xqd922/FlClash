# Release 备份与恢复指南

本文档说明如何管理和恢复已备份的 release 版本。

## 📋 当前状态

### 保留的 Release Tags
- **v7.0.0** 到 **v7.0.19**（共 20 个）
- 这些 tags 仍然存在于仓库中，可以正常使用

### 已备份并删除的 Release Tags
- **v7.0.20** 到 **v7.0.37**（共 18 个）
- 已从主仓库删除，但完整备份在专用分支中

## 🗂️ 备份位置

### 1. 备份分支
每个被删除的 tag 都有对应的独立分支：

```
backup/v7.0.20
backup/v7.0.21
backup/v7.0.22
...
backup/v7.0.37
```

### 2. Tags 信息文件
完整的 tags 和 commit 哈希映射保存在：
- **分支**：`optimize-backup`
- **文件**：`.tags_backup_v7.0.20-37.txt`

查看文件内容：
```bash
git show optimize-backup:.tags_backup_v7.0.20-37.txt
```

## 🔄 如何获取备份版本的安装包

### 方法 1：从备份分支构建（推荐）

#### 步骤 1：切换到目标备份分支
```bash
# 例如：获取 v7.0.35 版本
git checkout backup/v7.0.35
```

#### 步骤 2：构建安装包
```bash
# Android
flutter build apk --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

#### 步骤 3：安装包位置
- **Android APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Windows**: `build/windows/x64/runner/Release/`
- **macOS**: `build/macos/Build/Products/Release/FlClash.app`
- **Linux**: `build/linux/x64/release/bundle/`

### 方法 2：临时恢复 Tag 并构建

如果需要从特定 tag 构建（例如为了触发 CI/CD）：

```bash
# 1. 从备份分支创建临时 tag
git tag v7.0.35 backup/v7.0.35

# 2. 推送到远程（可选，如果需要触发 GitHub Actions）
git push origin v7.0.35

# 3. 构建
flutter build apk --release

# 4. 构建完成后删除临时 tag（可选）
git tag -d v7.0.35
git push origin --delete v7.0.35
```

### 方法 3：使用 Commit Hash 直接检出

```bash
# 1. 查看 tags 备份文件获取 commit hash
git show optimize-backup:.tags_backup_v7.0.20-37.txt

# 2. 根据输出找到目标版本的 commit，例如：
# v7.0.35 3a97a82461bf1951f4bdc8d51386c18181487142

# 3. 检出该 commit
git checkout 3a97a82461bf1951f4bdc8d51386c18181487142

# 4. 构建
flutter build apk --release

# 5. 构建完成后返回主分支
git checkout main  # 或 optimize
```

## 📦 查看所有备份版本

### 列出所有备份分支
```bash
git branch -r | grep "backup/"
```

### 查看特定版本的详细信息
```bash
# 查看某个备份分支的提交信息
git log backup/v7.0.35 -1

# 查看该版本的文件列表
git ls-tree -r backup/v7.0.35 --name-only
```

## 🔧 完全恢复某个 Release Tag

如果想永久恢复某个已删除的 tag：

```bash
# 1. 从备份分支重建 tag
git tag v7.0.35 backup/v7.0.35

# 2. 推送到远程
git push origin v7.0.35
```

## 🧹 清理备份（慎用）

如果确定不再需要某些备份：

```bash
# 删除本地备份分支
git branch -D backup/v7.0.35

# 删除远程备份分支
git push origin --delete backup/v7.0.35
```

## 📊 备份版本映射表

| Tag 版本 | Commit Hash | 备份分支 |
|---------|------------|---------|
| v7.0.20 | bef7aa5 | backup/v7.0.20 |
| v7.0.21 | 411ef07 | backup/v7.0.21 |
| v7.0.22 | 3db0f47 | backup/v7.0.22 |
| v7.0.23 | 6c23fd1 | backup/v7.0.23 |
| v7.0.24 | 320580b | backup/v7.0.24 |
| v7.0.25 | 43469b0 | backup/v7.0.25 |
| v7.0.26 | f206f1c | backup/v7.0.26 |
| v7.0.27 | 79132b8 | backup/v7.0.27 |
| v7.0.28 | 0a7e09a | backup/v7.0.28 |
| v7.0.29 | ed9fba2 | backup/v7.0.29 |
| v7.0.30 | 2ca4d7d | backup/v7.0.30 |
| v7.0.31 | 48f9797 | backup/v7.0.31 |
| v7.0.32 | e9db63f | backup/v7.0.32 |
| v7.0.33 | 0bd94bd | backup/v7.0.33 |
| v7.0.34 | f3e5db0 | backup/v7.0.34 |
| v7.0.35 | 3a97a82 | backup/v7.0.35 |
| v7.0.36 | 699dcaf | backup/v7.0.36 |
| v7.0.37 | 1c3369e | backup/v7.0.37 |

*完整的 commit hash 可以在 `.tags_backup_v7.0.20-37.txt` 中查看*

## ⚠️ 重要提醒

1. **备份分支不要修改**：这些分支是只读的快照，修改会破坏备份完整性
2. **构建前检查依赖**：不同版本可能需要不同的 Flutter SDK 版本
3. **GitHub Releases**：原 GitHub Releases 页面上的 v7.0.20-37 release 可能失去 tag 关联，但本地可以完全恢复
4. **主分支代码**：`optimize-backup` 分支包含最新的 v7.0.37 完整代码

## 📝 历史记录

- **2026-06-16**: 备份 v7.0.20 到 v7.0.37，从主仓库删除这些 tags
- **操作原因**: 回退到 v7.0.19 版本，重新开始开发

---

**创建时间**: 2026-06-16  
**最后更新**: 2026-06-16
