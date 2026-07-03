# 贡献指南

感谢为本仓库贡献 AI Agent Skills。

本仓库的技能格式面向**多种 AI 编程工具**，编写时请保持工具无关：流程依赖通用能力（读写文件、Shell、MCP 等），不要在正文中硬编码某一产品名称。

## 创建新技能

1. 复制模板：

```bash
cp -R skills/_template skills/your-skill-name
```

2. 编辑 `skills/your-skill-name/SKILL.md`：
   - 将 `name` 设为与目录名一致（小写、连字符、最多 64 个字符）
   - 用第三人称撰写具体的 `description`，同时说明**做什么**和**何时使用**
   - 主文件保持简洁，详细内容放到 `reference.md` 或 `scripts/`

3. 提交 PR 前先校验：

```bash
./scripts/validate.sh your-skill-name
```

4. 更新 [README.md](README.md) 中的技能列表。

## SKILL 编写清单

### 核心质量

- [ ] `description` 具体明确，包含关键触发词
- [ ] `description` 同时包含「做什么」和「何时使用」
- [ ] `description` 使用第三人称
- [ ] `SKILL.md` 正文不超过 500 行
- [ ] 全文术语一致
- [ ] 示例具体，避免空泛
- [ ] 正文工具无关，不写死 Cursor / Claude 等专有操作（除非该技能确实只适用于某一工具）

### 结构

- [ ] 文件引用仅一层（从 `SKILL.md` 到同级文件）
- [ ] 长内容采用渐进式披露
- [ ] 工作流步骤清晰
- [ ] 无时效性信息，或已标注弃用说明

### 脚本（如包含）

- [ ] 脚本解决实际问题，而非把问题推给 Agent
- [ ] 已说明所需依赖包
- [ ] 错误处理明确且有帮助
- [ ] 路径使用正斜杠，不用 Windows 反斜杠

## 各工具存储位置

| 工具 | 个人目录 | 项目目录 |
|------|----------|----------|
| Cursor | `~/.cursor/skills/skill-name/` | `.cursor/skills/skill-name/` |
| Claude Code | `~/.claude/skills/skill-name/` | （以官方文档为准） |
| Codex | `~/.codex/skills/skill-name/` | `.agents/skills/skill-name/` 或 `.codex/skills/skill-name/` |

本仓库 `install.sh` 默认安装到**个人目录**。项目级共享请手动复制或由团队自行约定。

### Codex 特别注意

Codex 需在 `~/.codex/config.toml` 中启用 skills 功能后才会加载：

```toml
[features]
skills = true
```

**请勿**将技能安装到 `~/.codex/skills/.system/`，该目录为 Codex 内置技能保留。

### Cursor 特别注意

**请勿**将技能安装到 `~/.cursor/skills-cursor/`，该目录为 Cursor 内置技能保留。

## Pull Request 规范

- 尽量一个 PR 只包含一个技能
- 本地运行 `./scripts/validate.sh`
- 在 PR 中简要说明技能的触发场景
- 更新 README 技能表格
