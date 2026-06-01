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
      errors.push(
        `manifest 中声明的 ${skill.name} 文件不存在: ${skill.path}`
      );
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
      errors.push(
        `${entry}/SKILL.md frontmatter 格式无效（缺少 --- 包围）`
      );
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
        `${entry}/SKILL.md 的 name "${fm.name}" 未在 manifest.json 中注册`
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
