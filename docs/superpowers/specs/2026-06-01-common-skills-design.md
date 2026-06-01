# Common-Skills 项目设计规格

## 概述

个人常用技能（Skill）集合项目，参考 easy-codex 结构，以 skill pack 形式组织和管理。每个 skill 封装一个可复用的开发工作流，安装到 `~/.claude/skills/`（默认）或 `~/.codex/skills/`。

## 项目结构

```
common-skills/
├── common-skills.manifest.json    ← 技能清单
├── package.json                   ← npm 包声明
├── README.md
├── .gitignore
├── scripts/
│   ├── install.sh                 ← 安装/同步 skill 到目标目录
│   ├── uninstall.sh               ← 卸载
│   └── validate.mjs               ← 校验 SKILL.md 规范性
└── skills/
    ├── common-kit/                ← bootstrap 路由 skill
    │   └── SKILL.md
    └── release/
        ├── SKILL.md
        └── agents/                ← 预留（暂空）
```

## 命名约定

- 目录名：短名（`release`、`common-kit`）
- SKILL.md 中 `name` 字段：`common-kit-xxx`（全限定名，如 `common-kit-release`）
- 安装时以 `name` 字段值作为目标目录名

## 核心组件

### manifest.json

声明所有 skill 及其用途，包含安装配置和校验脚本路径。

- `bootstrapSkill`：入口 skill，用于路由用户请求
- `skills` 数组：每个 skill 的 name、path、purpose
- `install`：defaultTarget（`~/.claude/skills`）、altTarget（`~/.codex/skills`）

### Bootstrap Skill (`common-kit`)

轻量路由 skill，读取 manifest 中所有注册 skill 的 name/purpose，根据用户意图匹配并触发对应 skill。新增 skill 时只需在 manifest 的 `skills` 数组中注册即可。

### install.sh

遍历 `skills/` 目录，以 SKILL.md 中的 `name` 作为目标目录名复制到目标。

- 默认目标：`~/.claude/skills/`
- `--target codex`：切换到 `~/.codex/skills/`
- `--update`：先 `git pull` 再安装
- 自动清理已删除的 stale skill

### validate.mjs

校验每个 skill 目录：
- SKILL.md 存在性
- frontmatter 必填字段（name、description）
- 目录结构合法性

### release skill

从 ViewStateKing 迁移并通用化。基于 git flow release 的自动化发版流程：
- 预检查（工作区、分支、git flow 状态）
- 版本号确定
- 从 commits 生成发版说明
- 执行 git flow release start/finish
- 推送 tag

## 已注册 Skill 列表

| name | purpose |
|------|---------|
| common-kit | 路由用户请求到对应的 common-kit skill |
| common-kit-release | 基于 git flow release 的自动化发版流程 |

## 安装方式

```bash
git clone https://github.com/darklost/common-skills.git
cd common-skills
./scripts/install.sh                 # 安装到 ~/.claude/skills/
./scripts/install.sh --target codex  # 安装到 ~/.codex/skills/
```

## 扩展方式

新增 skill 的步骤：
1. 在 `skills/<name>/SKILL.md` 创建 skill 文件，name 设置为 `common-kit-xxx`
2. 在 `manifest.json` 的 `skills` 数组中注册
3. 运行 `./scripts/install.sh` 同步
