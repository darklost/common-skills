---
name: release
description: >
  基于 git flow release 的自动化发版流程。当用户提到「发版」「发布版本」「release」「打版本」
  「新版本」「切版本」「发版说明」「release notes」时触发。覆盖从 commits 自动生成发版说明、
  执行 git flow release start/finish、到推送 tag 的完整流程。CI 会在 tag push 后自动构建和
  创建 GitHub Release，所以本 skill 不需要执行构建。
---

# Release Skill — Git Flow 发版自动化

你负责在当前项目中执行完整的 git flow release 发版流程。
发版说明规范遵循项目 CLAUDE.md 中定义的格式（如无则使用本 skill 默认格式）。

## 版本号规则

- 格式：`x.y.z`（不含 `v` 前缀），如 `1.1.3`
- git flow 自动追加 `v` 生成 annotated tag `v1.1.3`
- CI 在检测到 `v*` tag push 后自动构建打包并创建 GitHub Release

## 发版说明格式

```text
vx.y.z:
- 要点1
- 要点2
- 要点3
```

- `{版本信息}` 使用简体中文，精炼总结每次变更
- 每条变更单独一行，以 `- ` 开头
- 按类别分组：新功能、修复、重构、工程（chore/build/ci）

## 完整流程

### 第 1 步：预检查

依次执行以下检查，任一失败则中止并告知用户：

```bash
# 检查工作区是否干净
git status --porcelain

# 确认当前在 develop 分支
git branch --show-current

# 确认 git flow 已初始化
git flow version
```

- 如果工作区不干净，提示用户先提交或暂存改动
- 如果不在 develop 分支，提示用户先切换到 develop

### 第 2 步：确定版本号

如果用户未指定版本号，获取最新 tag 并建议下一个版本号：

```bash
git tag --sort=-version:refname | head -1
```

根据上次版本和改动内容，建议新的 x.y.z（patch/minor/major），然后询问用户确认。

### 第 3 步：生成发版说明

获取上一个 tag 以来的所有非合并 commits：

```bash
git log --pretty=format:"%s" <上一个tag>..HEAD --no-merges
```

按以下分类整理：
- **新功能** — `feat:` 开头的 commit
- **修复** — `fix:` 开头的 commit
- **重构** — `refactor:` 开头的 commit
- **工程** — `chore:`、`build:`、`ci:` 开头的 commit

生成发版说明草稿，展示给用户审核。格式严格遵循：

```text
v{version}:
- {变更描述1}
- {变更描述2}
```

注意：
- 每条描述去掉 commit 前缀（`feat:` `fix:` 等），用简体中文精炼表达
- 合并同类变更，避免逐条罗列 commits
- 如果某个类别无变更，直接跳过

用户确认后，将发版说明写入 `.tagmsg`（UTF-8 无 BOM，跨平台兼容）：

```bash
cat > .tagmsg << 'EOF'
v{version}:
- {要点1}
- {要点2}
EOF
```

### 第 4 步：执行 git flow release

```bash
git flow release start {version}
git flow release finish -f .tagmsg {version}
```

注意：
- `{version}` 不要加 `v` 前缀
- `-f` 从 `.tagmsg` 读取 tag message
- 如果 finish 产生合并冲突，终止流程并告知用户手动处理
- **绝不跳过 hooks（`--no-verify`）**

### 第 5 步：清理并推送

```bash
rm .tagmsg
```

推送前必须向用户确认，展示拟执行的命令和影响范围：

```
⚠️ RISK AUDIT
- 操作: git push --all && git push --tags
- 影响: 推送所有分支和 tag 到远程
- CI 将自动构建并创建 GitHub Release
```

用户确认后执行：

```bash
git push --all && git push --tags
```

### 第 6 步：完成提示

推送成功后提示用户：
- CI 正在构建中（GitHub Actions）
- 可在 GitHub Actions 页面查看构建进度

## 异常处理

| 场景 | 处理方式 |
|------|----------|
| 工作区不干净 | 提示用户提交或暂存 |
| 不在 develop 分支 | 提示切换到 develop |
| git flow 未初始化 | 提示运行 `git flow init` |
| merge 冲突 | 告知用户手动解决，不要强行继续 |
| 远程推送失败 | 检查网络和权限，可能需要先 `git pull` |
| 版本号格式错误 | 提示正确格式 `x.y.z` |
