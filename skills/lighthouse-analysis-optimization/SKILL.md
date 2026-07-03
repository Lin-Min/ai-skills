---
name: lighthouse-analysis-optimization
description: 对任意网页执行 Lighthouse 性能分析（chrome-devtools-mcp 优先，无 MCP 则 lighthouse CLI）。默认先出审计报告，AskQuestion 询问是否继续优化；继续则确认项目范围、出带文件的优化清单并改代码。主流程见 SKILL.md，细节按阶段读 reference 文件。Use when the user asks to run Lighthouse, analyze page performance, measure LCP/CLS/TTFB, or produce an optimization checklist for a URL.
---

# Lighthouse 性能审计

通用技能，不依赖具体项目或 AI 工具（Cursor / Claude Code / Codex CLI 等）。依赖 chrome-devtools-mcp 或官方 `lighthouse` CLI。

## 何时读哪个文件

| 阶段 / 步骤 | 读取 |
|-------------|------|
| 步骤 2 能力自检 | [tools.md](tools.md) |
| 步骤 1–4 审计 | [phase-a-audit.md](phase-a-audit.md) |
| 步骤 5 / 6 / 8 交互 | [askquestion.md](askquestion.md) |
| 步骤 7 优化清单 | [phase-b-optimize.md](phase-b-optimize.md) |
| 步骤 9 回归 | [regression.md](regression.md) |
| 意图不明时 | [examples.md](examples.md) |

**阶段 A 只读** `tools.md` + `phase-a-audit.md`；进入阶段 B 后再读其余文件。

## 主流程（严格按序）

| 步 | 阶段 | 动作 | 详见 |
|---|---|---|---|
| 1 | A | **解析输入**：URL / 路由 / device / 本地\|线上 | [phase-a-audit.md](phase-a-audit.md) |
| 2 | A | **能力自检**：MCP 或 CLI | [tools.md](tools.md) |
| 3 | A | **执行审计**：用户指定 URL；失败重试最多 5 次；MCP 须先 emulate | [phase-a-audit.md](phase-a-audit.md) |
| 4 | A | **输出审计报告**：评分、指标、结论；简要摘要无「涉及文件」 | [phase-a-audit.md](phase-a-audit.md) |
| 5 | A→B | **AskQuestion：是否继续优化** | [askquestion.md](askquestion.md) |
| 6 | B | **AskQuestion：确认项目范围**（范围未明时） | [askquestion.md](askquestion.md) |
| 7 | B | **读代码 + 优化清单**（带「涉及文件」） | [phase-b-optimize.md](phase-b-optimize.md) |
| 8 | B | **AskQuestion：选择执行项** | [askquestion.md](askquestion.md) |
| 9 | B | **改代码 + 回归** | [regression.md](regression.md) |

## 意图分支

- **只问是否达标** → 步骤 3、4 后结束；全绿写「达标，无必改项」，**跳过 5–9**。
- **明确不要优化**（「只分析」「不要改代码」）→ 步骤 4 后结束，**跳过 5–9**。
- **默认**（「分析某 URL 性能」）→ 步骤 4 后 **AskQuestion 步骤 5**；选继续才进入 6–9。
- **一开始就要优化且已指明项目** → 步骤 4 后可**跳过步骤 5**；改代码前仍须步骤 6（已指明则复述确认）。

## 全局必守

**lab vs field**：Lighthouse 是实验室工具；CWV 达标看 CrUX 现场数据。报告**全文最多提 1 次**，放末尾一句，开头不科普。

**输出克制**：

- 直接给结论，不复述技能内部流程（「我先 emulate…」）。
- 步骤 5 / 6 / 8 的选项**禁止写在报告正文**，必须用 AskQuestion。
- 阶段 A **不读仓库、不改文件**；线上 URL 5 次不可达**禁止代测本地**。
- device 与 MCP/CLI 模式一旦选定，**全程锁定**至回归结束。
- 不自动 commit / push / 部署；用户选「到此为止」立即收束。

**禁止输出**：无证据的猜测、全绿仍硬凑 P0/P1/P2、冗长 CWV 科普、无关项目代码改动。

## 示例

见 [examples.md](examples.md)。
