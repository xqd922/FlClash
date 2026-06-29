# Release Process

发版提交按下面顺序执行，避免把功能改动和发版元信息混在同一个 commit 里：

1. 先提交代码改动
   - 功能修复
   - 依赖替换
   - 测试
   - 生成文件

2. 再单独提交发版信息
   - `pubspec.yaml` 版本号
   - `RELEASE.md`
   - 发版专用提交信息，格式固定为 `Release vX.Y.Z`

3. 最后再推分支、更新 tag、触发 GitHub Actions 发版

如果需要重发某个版本，也遵循同样规则：

1. 先把代码 commit 推上去
2. 再补或重写 `Release vX.Y.Z` 提交
3. 再强推对应 tag
