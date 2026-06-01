# Common-Skills 项目搭建实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭建 common-skills skill pack 项目骨架，包含 manifest、安装/卸载脚本、校验脚本、bootstrap 路由 skill 和 release skill。

**Architecture:** 参考 easy-codex 结构，每个 skill 是 `skills/<short-name>/SKILL.md`，以 frontmatter `name` 字段（`common-kit-xxx`）作为安装目标目录名。install.sh 遍历 skills/ 目录复制到 `~/.claude/skills/` 或 `~/.codex/skills/`。

**Tech Stack:** Bash（安装/卸载脚本）、Node.js ESM（校验脚本）、YAML frontmatter（skill 元数据）、JSON（manifest）

**Base:** `/Users/dengke/Documents/workspace/vibecode/common-skills`

---

### Task 1: .gitignore

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: 写入 .gitignore**

```gitignore
node_modules/
.DS_Store
*.log
```

- [ ] **Step 2: 提交**

```bash
git add .gitignore && git commit -m "chore: 添加 .gitignore"
```

---

### Task 2: package.json

**Files:**
- Create: `package.json`

- [ ] **Step 1: 写入 package.json**

```json
{
  "name": "common-skills",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "description": "个人常用 Codex/Claude Code 技能集合",
  "scripts": {
    "validate": "node scripts/validate.mjs"
  },
  "exports": {
    "./manifest": "./common-skills.manifest.json"
  },
  "files": [
    "README.md",
    "scripts",
    "skills",
    "common-skills.manifest.json"
  ],
  "commonSkills": {
    "manifest": "./common-skills.manifest.json",
    "bootstrapSkill": "common-kit",
    "skillsDir": "./skills"
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add package.json && git commit -m "chore: 添加 package.json"
```

---

### Task 3: manifest.json

**Files:**
- Create: `common-skills.manifest.json`

- [ ] **Step 1: 写入 manifest.json**

```json
{
  "manifestVersion": 1,
  "packageName": "common-skills",
  "bootstrapSkill": {
    "name": "common-kit",
    "path": "skills/common-kit/SKILL.md"
  },
  "skillsDir": "skills",
  "skillFileName": "SKILL.md",
  "skills": [
    {
      "name": "common-kit",
      "path": "skills/common-kit/SKILL.md",
      "purpose": "将用户请求路由到对应的 common-kit skill，根据意图匹配并触发已注册的 skill。"
    },
    {
      "name": "common-kit-release",
      "path": "skills/release/SKILL.md",
      "purpose": "基于 git flow release 的自动化发版流程：预检查、版本号确定、从 commits 生成发版说明、执行 release、推送 tag。"
    }
  ],
  "install": {
    "defaultTarget": "~/.claude/skills",
    "altTarget": "~/.codex/skills",
    "script": "scripts/install.sh",
    "uninstallScript": "scripts/uninstall.sh"
  },
  "validation": {
    "scriptPath": "scripts/validate.mjs"
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add common-skills.manifest.json && git commit -m "feat: 添加 manifest.json 技能清单"
```

---

### Task 4: Bootstrap Skill — common-kit

**Files:**
- Create: `skills/common-kit/SKILL.md`

- [ ] **Step 1: 创建目录并写入 SKILL.md**

```bash
mkdir -p skills/common-kit
```

写入 `skills/common-kit/SKILL.md`：

```markdown
---
name: common-kit
description: >
  个人常用技能集的入口路由。当用户意图匹配到已注册的 common-kit skill 时，
  自动触发对应的 skill。可处理「发版」「release」等关键词。
---

# Common-Kit — 个人技能路由

你是 common-kit 技能集的入口，负责将用户的请求路由到对应的具体 skill。

## 已注册 Skill

| 触发关键词 | 对应 Skill | 用途 |
|-----------|-----------|------|
| 发版、发布版本、release、打版本、新版本、切版本、发版说明 | common-kit-release | Git Flow 自动化发版 |

## 工作方式

1. 分析用户输入的意图
2. 匹配上表中的关键词
3. 如果匹配成功，读取并执行对应 skill 的 SKILL.md
4. 如果无法匹配，告知用户当前可用的 skill 列表

## 扩展

新增 skill 后，更新上方的「已注册 Skill」表格即可。
```

- [ ] **Step 2: 提交**

```bash
git add skills/common-kit/SKILL.md && git commit -m "feat: 添加 common-kit bootstrap 路由 skill"
```

---

### Task 5: 更新 release skill 的 name 字段

**Files:**
- Modify: `skills/release/SKILL.md`

- [ ] **Step 1: 修改 frontmatter 中的 name**

将第 2 行 `name: release` 替换为 `name: common-kit-release`：

```diff
 ---
-name: release
+name: common-kit-release
 description: >
```

- [ ] **Step 2: 提交**

```bash
git add skills/release/SKILL.md && git commit -m "refactor: 更新 release skill name 为 common-kit-release"
```

---

### Task 6: validate.mjs — 校验脚本

**Files:**
- Create: `scripts/validate.mjs`

- [ ] **Step 1: 创建 scripts 目录并写入 validate.mjs**

```bash
mkdir -p scripts
```

写入 `scripts/validate.mjs`：

```javascript
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');
const SKILLS_DIR = join(ROOT, 'skills');
const MANIFEST_PATH = join(ROOT, 'common-skills.manifest.json');

function parseFrontmatter(content) {
  const lines = content.split('\n');
  if (lines[0]?.trim() !== '---') return null;

  const end = lines.indexOf('---', 1);
  if (end === -1) return null;

  const fm = {};
  let currentKey = null;
  for (let i = 1; i < end; i++) {
    const line = lines[i];
    const keyMatch = line.match(/^(\w+):\s*(.*)/);
    if (keyMatch) {
      currentKey = keyMatch[1];
      fm[currentKey] = keyMatch[2].trim();
    } else if (currentKey && line.startsWith('  ')) {
      fm[currentKey] += ' ' + line.trim();
    }
  }
  return fm;
}

function validate() {
  const errors = [];
  const manifest = JSON.parse(readFileSync(MANIFEST_PATH, 'utf-8'));
  const declaredSkills = new Map(
    manifest.skills.map((s) => [s.name, s.path])
  );

  // Check manifest skills array
  for (const skill of manifest.skills) {
    const skillPath = join(ROOT, skill.path);
    if (!existsSync(skillPath)) {
      errors.push(`manifest 中声明的 ${skill.name} 文件不存在: ${skill.path}`);
    }
  }

  // Check skills/ directory
  if (!existsSync(SKILLS_DIR)) {
    errors.push('skills/ 目录不存在');
    return errors;
  }

  const dirEntries = readdirSync(SKILLS_DIR);
  for (const entry of dirEntries) {
    const dirPath = join(SKILLS_DIR, entry);
    if (!statSync(dirPath).isDirectory()) continue;

    const skillFile = join(dirPath, 'SKILL.md');
    if (!existsSync(skillFile)) {
      errors.push(`${entry}/ 缺少 SKILL.md`);
      continue;
    }

    const content = readFileSync(skillFile, 'utf-8');
    const fm = parseFrontmatter(content);
    if (!fm) {
      errors.push(`${entry}/SKILL.md frontmatter 格式无效（缺少 --- 包围）`);
      continue;
    }
    if (!fm.name) {
      errors.push(`${entry}/SKILL.md 缺少必填字段: name`);
    }
    if (!fm.description) {
      errors.push(`${entry}/SKILL.md 缺少必填字段: description`);
    }

    // Check that name matches manifest registration
    if (fm.name && !declaredSkills.has(fm.name)) {
      errors.push(
        `${entry}/SKILL.md 的 name "${fm.name}" 未在 manifest.json 的 skills 数组中注册`
      );
    }
  }

  return errors;
}

const errors = validate();
if (errors.length > 0) {
  console.error('❌ 校验失败:');
  for (const err of errors) {
    console.error(`  - ${err}`);
  }
  process.exit(1);
}

console.log('✅ 校验通过');
```

- [ ] **Step 2: 验证校验脚本能正常运行**

```bash
node scripts/validate.mjs
```

Expected: `✅ 校验通过`

- [ ] **Step 3: 提交**

```bash
git add scripts/validate.mjs && git commit -m "feat: 添加 skill 规范性校验脚本"
```

---

### Task 7: uninstall.sh — 卸载脚本

**Files:**
- Create: `scripts/uninstall.sh`

- [ ] **Step 1: 写入 uninstall.sh**

```bash
cat > scripts/uninstall.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${REPO_ROOT}/common-skills.manifest.json"

DEFAULT_TARGET="${HOME}/.claude/skills"
ALT_TARGET="${HOME}/.codex/skills"
TARGET="$DEFAULT_TARGET"

log() { printf '%s\n' "$1"; }

usage() {
  cat <<EOF
Usage: $0 [--target claude|codex]

Options:
  --target claude  从 ~/.claude/skills/ 卸载（默认）
  --target codex   从 ~/.codex/skills/ 卸载
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      case "${2:-}" in
        claude) TARGET="$DEFAULT_TARGET" ;;
        codex)  TARGET="$ALT_TARGET" ;;
        *)      echo "error: unknown target: ${2:-}" >&2; exit 1 ;;
      esac
      shift 2
      ;;
    -h|--help) usage ;;
    *) echo "error: unknown arg: $1" >&2; exit 1 ;;
  esac
done

main() {
  local skill_count=0
  local line

  while IFS= read -r line; do
    local name
    name="$(echo "$line" | tr -d '", ' | sed 's/^"name"://')"
    local target_path="${TARGET}/${name}"

    if [[ -d "$target_path" || -L "$target_path" ]]; then
      rm -rf "$target_path"
      log "removed: ${name}"
      skill_count=$((skill_count + 1))
    fi
  done < <(python3 -c "
import json
with open('${MANIFEST}') as f:
    m = json.load(f)
for s in m['skills']:
    print(f'\"name\": \"{s[\"name\"]}\"')
" 2>/dev/null || node -e "
const m = JSON.parse(require('fs').readFileSync('${MANIFEST}','utf-8'));
m.skills.forEach(s => console.log('\"name\": \"'+s.name+'\"'));
")

  log "uninstall complete: ${skill_count} skills removed from ${TARGET}"
}

main
SCRIPT_EOF

chmod +x scripts/uninstall.sh
```

- [ ] **Step 2: 提交**

```bash
git add scripts/uninstall.sh && git commit -m "feat: 添加卸载脚本"
```

---

### Task 8: install.sh — 安装脚本

**Files:**
- Create: `scripts/install.sh`

- [ ] **Step 1: 写入 install.sh**

```bash
cat > scripts/install.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SKILLS_SOURCE_DIR="${REPO_ROOT}/skills"
MANIFEST="${REPO_ROOT}/common-skills.manifest.json"

DEFAULT_TARGET="${HOME}/.claude/skills"
ALT_TARGET="${HOME}/.codex/skills"
TARGET="$DEFAULT_TARGET"

log() { printf '%s\n' "$1"; }

ensure_dir() {
  local dir_path="$1"
  if [[ ! -d "$dir_path" ]]; then
    mkdir -p "$dir_path"
    log "created directory: ${dir_path}"
  fi
}

install_skill_copy() {
  local skill_dir="$1"
  local skill_name
  local source_path
  local target_path

  skill_name="$2"
  source_path="$(cd -- "$skill_dir" && pwd -P)"
  target_path="${TARGET}/${skill_name}"

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    rm -rf "$target_path"
    cp -R "$source_path" "$target_path"
    log "skill updated: ${skill_name}"
  else
    cp -R "$source_path" "$target_path"
    log "skill installed: ${skill_name}"
  fi
}

extract_skill_name() {
  local skill_file="$1"
  local name
  name="$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed -n 's/^name:\s*//p')"
  if [[ -z "$name" ]]; then
    name="$(basename "$(dirname "$skill_file")")"
  fi
  printf '%s' "$name"
}

remove_stale_skill_targets() {
  local candidate
  local base_name

  [[ -d "$TARGET" ]] || return

  shopt -s nullglob
  for candidate in "${TARGET}/common-kit-"*; do
    base_name="$(basename "$candidate")"
    local found=0
    local skill_dir
    for skill_dir in "$SKILLS_SOURCE_DIR"/*; do
      [[ -d "$skill_dir" ]] || continue
      local skill_file="${skill_dir}/SKILL.md"
      [[ -f "$skill_file" ]] || continue
      local n
      n="$(extract_skill_name "$skill_file")"
      if [[ "$n" == "$base_name" ]]; then
        found=1
        break
      fi
    done
    if [[ "$found" -eq 0 ]]; then
      rm -rf "$candidate"
      log "stale skill removed: ${base_name}"
    fi
  done
  shopt -u nullglob
}

update_repo() {
  log "updating repository: git pull"
  (
    cd "$REPO_ROOT"
    git pull
  )
  log "repository updated"
}

usage() {
  cat <<EOF
Usage: $0 [--target claude|codex] [--update]

Options:
  --target claude  安装到 ~/.claude/skills/（默认）
  --target codex   安装到 ~/.codex/skills/
  --update         先 git pull 再安装
EOF
  exit 0
}

main() {
  local skill_count=0
  local do_update=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)
        case "${2:-}" in
          claude) TARGET="$DEFAULT_TARGET" ;;
          codex)  TARGET="$ALT_TARGET" ;;
          *)      echo "error: unknown target: ${2:-}" >&2; exit 1 ;;
        esac
        shift 2
        ;;
      --update) do_update=1; shift ;;
      -h|--help) usage ;;
      *) echo "error: unknown arg: $1" >&2; exit 1 ;;
    esac
  done

  if [[ "$do_update" -eq 1 ]]; then
    update_repo
  fi

  if [[ ! -d "$SKILLS_SOURCE_DIR" ]]; then
    printf 'error: skills directory not found: %s\n' "$SKILLS_SOURCE_DIR" >&2
    exit 1
  fi

  log "validating skill pack: npm run validate"
  (
    cd "$REPO_ROOT"
    npm run validate
  )

  ensure_dir "$TARGET"
  remove_stale_skill_targets

  shopt -s nullglob
  local skill_dir
  for skill_dir in "$SKILLS_SOURCE_DIR"/*; do
    [[ -d "$skill_dir" ]] || continue
    local skill_file="${skill_dir}/SKILL.md"
    [[ -f "$skill_file" ]] || continue

    local skill_name
    skill_name="$(extract_skill_name "$skill_file")"
    install_skill_copy "$skill_dir" "$skill_name"
    skill_count=$((skill_count + 1))
  done
  shopt -u nullglob

  if [[ "$skill_count" -eq 0 ]]; then
    printf 'error: no skill directories found under skills/\n' >&2
    exit 1
  fi

  cat <<EOF
install complete
- skills synced: ${skill_count}
- target directory: ${TARGET}
- use --update flag next time to git pull before installing
EOF
}

main "$@"
SCRIPT_EOF

chmod +x scripts/install.sh
```

- [ ] **Step 2: 验证 install.sh 能正常运行**

```bash
./scripts/install.sh
```

Expected: 校验通过，skill 安装到 `~/.claude/skills/common-kit` 和 `~/.claude/skills/common-kit-release`

- [ ] **Step 3: 提交**

```bash
git add scripts/install.sh && git commit -m "feat: 添加安装脚本"
```

---

### Task 9: 最终验证

- [ ] **Step 1: 运行完整校验**

```bash
node scripts/validate.mjs
```

Expected: `✅ 校验通过`

- [ ] **Step 2: 查看最终目录结构**

```bash
find . -not -path './.git/*' -not -path './node_modules/*' -not -path './docs/*' | sort
```

Expected:
```
.
./.gitignore
./common-skills.manifest.json
./package.json
./scripts
./scripts/install.sh
./scripts/uninstall.sh
./scripts/validate.mjs
./skills
./skills/common-kit
./skills/common-kit/SKILL.md
./skills/release
./skills/release/SKILL.md
```

- [ ] **Step 3: 推送**

```bash
git push origin main
```
