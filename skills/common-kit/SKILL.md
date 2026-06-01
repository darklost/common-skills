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
