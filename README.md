# Common Skills

个人常用 Claude Code / Codex 技能集合，提供可复用的自动化工作流。

## 技能列表

| 技能名称 | 触发方式 | 用途 |
|---------|---------|------|
| `common-kit` | 自动（入口路由） | 分析用户意图，匹配并分发到对应的子技能 |
| `common-kit-release` | 发版 / release / 打版本 / 新版本 | Git Flow 自动化发版：预检查 → 版本号确定 → 发版说明生成 → release 执行 → tag 推送 |

## 快速开始

### 安装

```bash
# 安装到 Claude Code（默认）
bash scripts/install.sh

# 安装到 Codex
bash scripts/install.sh --target codex

# 先拉取最新代码再安装
bash scripts/install.sh --update
```

安装后，技能将被复制到 `~/.claude/skills/`（或 `~/.codex/skills/`），Claude Code 即可自动识别并调用。

### 卸载

```bash
bash scripts/uninstall.sh

# 从 Codex 卸载
bash scripts/uninstall.sh --target codex
```

### 校验

```bash
npm run validate
```

校验技能目录结构与 `common-skills.manifest.json` 的一致性，包括：
- SKILL.md 文件是否存在
- frontmatter 格式是否正确
- `name` / `description` 必填字段检查
- manifest 注册一致性

## 目录结构

```
common-skills/
├── scripts/
│   ├── install.sh          # 安装脚本
│   ├── uninstall.sh        # 卸载脚本
│   └── validate.mjs        # 技能规范性校验
├── skills/
│   ├── common-kit/
│   │   └── SKILL.md        # 入口路由技能
│   └── release/
│       └── SKILL.md        # 发版自动化技能
├── common-skills.manifest.json  # 技能注册清单
├── package.json
└── README.md
```

## 新增技能

1. 在 `skills/` 下创建新目录（如 `skills/my-skill/`）
2. 在其中创建 `SKILL.md`，包含符合规范的 frontmatter：
   ```markdown
   ---
   name: common-kit-my-skill
   description: 技能简述
   ---

   # 技能标题

   具体指令...
   ```
3. 在 `common-skills.manifest.json` 的 `skills` 数组中注册
4. 在 `skills/common-kit/SKILL.md` 的「已注册 Skill」表格中添加路由条目
5. 运行 `npm run validate` 确认无误

## 许可

Private — 个人使用。
