# 阶段 A：审计

主流程步骤 1–4。阶段 A **立即执行、不前置询问项目范围**，**不读工作区、不写「涉及文件」**。

## 输入约定

### 目标 URL（必填）

- **完整 URL**（含 `http(s)://`）→ 直接执行，不因未确认项目而阻塞。
- **只给路由/路径**（`/xxx`、「首页」）→ 用当前工作区推断 `localhost` URL，在报告中复述；域名/端口明显不符则在末尾注明。后续若继续优化，步骤 6 再确认项目。
- **完全没给 URL** → 用户已指明项目则在该项目内推断；否则先询问。

### device（可选，默认 mobile）

| 用户描述里出现                               | 判定 device               |
| -------------------------------------------- | ------------------------- |
| PC、桌面、desktop、大屏                      | `desktop`                 |
| 移动端、手机、mobile、小屏                     | `mobile`                  |
| 都没提到                                     | 默认 `mobile`             |

- 两端都提到 → 反问先测哪个，或按序两个都跑。
- 一旦定了 device，**全程锁定**（MCP/CLI、回归均一致）。

### 本地 vs 线上（影响回归，须先判定）

`localhost` / `127.0.0.1` / `*.local` / 内网私有 IP → **本地**；其余 → **线上**。

- **本地**：改完可即时回归（优先 `build` + `preview`，dev server 指标仅供参考）。
- **线上**：改完**不能直接回归**，须先部署。详见 [regression.md](regression.md)。

TTFB 在 localhost 与生产差异大；测本地时在报告中标注「本地环境，指标仅供参考」。

## URL 可达性（必守，高于一切兜底）

用户给**完整线上 URL** 时，**只审计该 URL**，不得替换为其他域名或工作区本地服务。

**失败判定**：`CHROME_INTERSTITIAL_ERROR`、`ERR_CONNECTION_*`、`SSL_ERROR_*`、空白页、4xx/5xx、DNS/备案拦截等，导致无法完成审计步骤。

**重试规则**：

1. 对**同一 URL** 重试，**最多 5 次**。
2. 每次间隔 5–15s；可换 MCP/CLI，**不得改 URL**。
3. **5 次均失败** → 输出简短失败报告，**禁止**：本地 build 后代测、推测分数、读仓库出清单。
4. 失败报告末尾可写 1 句：站点恢复后可重新审计。

**允许测本地**（与上条互斥）：URL 本身是 localhost/内网；只给路由且推断出 localhost；用户明确要求测本地预览。

工作区域名与目标 URL 相同**不构成**本地代测理由。

## 分析流程

### 步骤 1：Lighthouse 审计（A11y / SEO / BP）

**MCP 分支**：

```
chrome-devtools-navigate_page  →  type: url, url: <目标 URL>
chrome-devtools-lighthouse_audit  →  device: <所选 device>, mode: navigation
```

导航失败或空白/错误页则停止。记录三类分数及 fail/warn（Performance 分不可信，交给步骤 2）。

取失败明细：`lighthouse_audit` 给出 report.json 路径（通常在 `/tmp`）。**Grep 搜不到 `/tmp`**，用 shell `jq`：

```bash
jq -r '.audits | to_entries[] | select(.value.score!=null and .value.score<1 and .value.scoreDisplayMode=="binary") | "\(.key): \(.value.title)"' <report.json>
jq -r '.audits["errors-in-console"].details.items[]?' <report.json>
```

**CLI 分支**：见 [tools.md](tools.md) 的 `npx lighthouse` 命令，四项分数一并处理，**跳过步骤 2**，直接步骤 3。

### 步骤 2：Performance Trace（仅 MCP）

**先 emulate 对齐 device**（否则数值无意义）：

```
# 移动端
chrome-devtools-emulate  →  cpuThrottlingRate: 4, networkConditions: "Slow 4G", viewport: "412x915x2.625,mobile,touch"
# 桌面端
chrome-devtools-emulate  →  cpuThrottlingRate: 1
```

```
chrome-devtools-navigate_page  →  type: url, url: <目标 URL>
chrome-devtools-performance_start_trace  →  reload: true, autoStop: true, filePath: ./trace.json
```

对每个 Insight Set 调用 `performance_analyze_insight`，关注 `LCPBreakdown`、`DocumentLatency`、`CLSCulprits`、`RenderBlocking`、`ImageDelivery`。

- **测真实 INP**：`autoStop:false` → 交互 → `performance_stop_trace`。
- 无法套限速 → 报告标注「未限速，数值偏乐观」，建议 CLI。
- Trace 摘要含 **CrUX field**（有则优先看）。

### 步骤 3：提取关键指标

CWV：**LCP / INP / CLS**。INP 是交互指标，lab 用 **TBT** 作代理。TTFB 辅助诊断 LCP。

**MCP**：Trace 可靠拿 LCP、CLS、TTFB。FCP 用 `evaluate_script`：

```js
() => ({
  fcp: performance.getEntriesByName("first-contentful-paint")[0]?.startTime,
  ttfb: performance.getEntriesByType("navigation")[0]?.responseStart,
});
```

TBT 只能定性（RenderBlocking Insight）；精确值须 CLI。

**CLI**：读 `lighthouse-report.json` 的 `categories.*.score`、`audits["first-contentful-paint"]` 等，及 opportunities/diagnostics。

**多次运行**：

- 正式结论（优化/回归/对外报告）：**3 次取中位数**。
- 快速查看：**1 次**，注明「单次采样」。
- 波动 >30% → 注明环境不稳定。

### 步骤 4：截图（可选）

MCP：`take_screenshot → fullPage: true`  
CLI：`npx -y lighthouse <url> --view`

## 阶段 A 输出格式

```
## Lighthouse 审计结果（工具：MCP / CLI）

**审计 URL：** …
**设备：** mobile / desktop

### 评分概览
| 类别 | 分数 |
|------|------|
| Performance | x/100 |
| Accessibility | x/100 |
| SEO | x/100 |
| Best Practices | x/100 |

### 关键指标
- FCP / LCP / TBT / CLS / TTFB（附目标与判定）
- 结论：达标 / 不达标 / 需改进（可附 CrUX 一行）

### 主要发现（有 fail 才写，≤5 条）
- 问题 → 改法方向（无文件路径）

---
（全文末尾最多 1 句 lab vs CrUX 提醒）
```

**只问是否达标**：只留结论 + 1~3 条原因；**不触发步骤 5**。

**URL 5 次不可达**：只输出 URL + 错误 + 重试次数，不收束后询问。

## 阶段 A 输出边界

| 只输出 | 不要输出 |
|--------|----------|
| 评分表、指标、达标结论；简要问题摘要（无文件路径） | 读仓库、带路径清单、改代码、线上失败后代测本地 |
| 失败报告 | 性能分数、本地 build、报告后询问 |

- 审计报告 ≤ 一屏；简要摘要 ≤ 5 条。
- A11y/SEO/BP 满分时一行带过。
- 默认不贴截图/trace；不保存到仓库。
