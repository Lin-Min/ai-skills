# ai-skills

用于管理和分享 **AI Agent Skills** 的轻量 Git 仓库，技能格式通用，不绑定某一 AI 产品。

同一套 `SKILL.md` 可安装到不同工具的个人技能目录，在各工具中由 Agent 自动发现或手动引用。

## 支持的工具

| 工具 | 个人技能目录 | 安装参数 |
|------|-------------|----------|
| [Cursor](https://cursor.com/docs) | `~/.cursor/skills/` | `--target cursor` |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `~/.claude/skills/` | `--target claude` |
| [Codex](https://developers.openai.com/codex/skills) | `~/.codex/skills/` | `--target codex` |

默认 `./scripts/install.sh` 会安装到**上述全部**目录（`--target all`）。

> 技能正文请避免写死某一工具名称；流程应依赖通用能力（文件读写、Shell、MCP 等）。各工具的项目级技能目录（如 `.cursor/skills/`）需手动复制或自行扩展脚本。

## 快速开始

```bash
git clone https://github.com/Lin-Min/ai-skills.git
cd ai-skills
./scripts/install.sh
```

只安装到某一工具：

```bash
./scripts/install.sh --target cursor
./scripts/install.sh --target claude lighthouse-analysis-optimization
./scripts/install.sh --target codex
```

验证安装：

```bash
./scripts/list.sh
ls ~/.cursor/skills/ ~/.claude/skills/ ~/.codex/skills/
```

在对应工具中通过 `@技能名` 引用，或由 Agent 根据 `description` 自动加载。

## 可用技能

| 技能 | 说明 |
| --- | --- |
| [lighthouse-analysis-optimization](skills/lighthouse-analysis-optimization/) | Lighthouse 性能分析（MCP 优先 / CLI 回退）；先出审计报告，可选继续优化并改代码 |

运行 `./scripts/list.sh` 可查看各工具下的安装状态。

## 脚本说明

| 脚本 | 用途 |
| --- | --- |
| `./scripts/install.sh` | 安装全部技能到所有支持的工具 |
| `./scripts/install.sh --target <平台>` | 指定安装目标（`cursor` / `claude` / `codex` / `all`） |
| `./scripts/install.sh <name>` | 安装指定技能 |
| `./scripts/install.sh --link` | 使用符号链接而非复制（适合本地开发） |
| `./scripts/install.sh --force` | 覆盖已有安装 |
| `./scripts/validate.sh` | 校验技能 frontmatter 与目录规范 |
| `./scripts/list.sh` | 列出技能及各工具安装状态 |

可通过环境变量覆盖安装路径：

```bash
export AI_SKILLS_CURSOR_DIR=~/.cursor/skills
export AI_SKILLS_CLAUDE_DIR=~/.claude/skills
export AI_SKILLS_CODEX_DIR=~/.codex/skills
```

## 技能目录结构

```text
skills/
└── your-skill-name/
    ├── SKILL.md          # 必需
    ├── reference.md      # 可选
    └── scripts/          # 可选工具脚本
```

模板位于 `skills/_template/`，安装脚本会自动跳过该目录。

## 贡献

编写规范与提交清单见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

MIT — 详见 [LICENSE](LICENSE)。
