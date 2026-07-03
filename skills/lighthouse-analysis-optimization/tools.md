# 工具选型与数据来源

阶段 A 步骤 2 必读。执行前做能力自检，选定 MCP 或 CLI 分支后全程锁定，回归时不得切换。

## 步骤 0：能力自检（每次必做）

不同 AI 工具的 MCP 配置路径各异，**不要读配置文件判断**，直接检测当前会话是否可调用 `chrome-devtools-*` 或 `mcp_chrome-devtools_*` 工具。

1. **有 MCP 工具** → 进入 **MCP 分支**。
2. **无 MCP，有 npx** → 进入 **CLI 分支**（官方 `npx lighthouse`，默认移动端）：
   ```bash
   npx -y lighthouse <目标URL> --output=json --output-path=./lighthouse-report.json --chrome-flags="--headless=new" --only-categories=performance,accessibility,seo,best-practices
   ```
   - **CLI 分支特指官方 `npx lighthouse`**，别混用 chrome-devtools-mcp 自带 CLI（数据同样残缺）。
   - **device 对齐**：CLI 默认 mobile + 4G；测桌面端加 `--preset=desktop`。MCP 的 device 须与此一致。
3. **两者都没有** → 询问是否安装 chrome-devtools-mcp：

   | 工具        | 安装方式 |
   | ----------- | -------- |
   | Cursor      | `~/.cursor/mcp.json` 或 `.cursor/mcp.json`：`{"mcpServers":{"chrome-devtools":{"command":"npx","args":["-y","chrome-devtools-mcp@latest"]}}}` |
   | Claude Code | `claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest` |
   | Codex CLI   | `~/.codex/config.toml` 追加 `[mcp_servers.chrome-devtools]` |
   | 其他/不确定 | `npx -y chrome-devtools-mcp@latest`，请用户查阅所用工具的 MCP 文档 |

   装完提醒重启 AI 工具；`npx` 不可用则提示安装 Node.js。CLI 兜底可用时不必强制装 MCP。

需登录或填表单再审计时，用 MCP 的 `click`/`fill`/`fill_form`/`upload_file`/`handle_dialog`。

## 数据来源分工

| 想要的数据                                     | 正确来源                                                                                              | 说明                                                                                                |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| A11y / SEO / Best Practices 分                 | `lighthouse_audit`                                                                                    | **excludes performance**；report.json 里性能指标为 null                                             |
| LCP / CLS / TTFB                               | `performance_start_trace` + `analyze_insight`                                                         | trace 自身无限速，须先用 `emulate` 套限速                                                           |
| 真实 INP                                       | trace + **真实交互**                                                                                  | 加载态测不到，须 `autoStop:false` 后交互再 `stop_trace`                                             |
| FCP                                            | `evaluate_script` 读 Performance API / 原始 trace                                                     | trace 摘要不直接吐 FCP                                                                              |
| **TBT / Speed Index / 官方分 / opportunities** | **Lighthouse CLI**                                                                                    | MCP trace/insight 不产出                                                                            |
| 真实用户现场数据                               | MCP：trace 附带的 **CrUX field**；CLI：**PageSpeed Insights**                                       | `npx lighthouse` JSON **不含** CrUX，CLI 分支要去 PSI 取                                            |

一句话：**CWV/归因走 MCP+emulate，完整指标表走 CLI，达标看 CrUX。**

## 已知注意事项

- MCP `lighthouse_audit` 的 Performance 分在无头/CDP 下偏高，以 Trace 的 LCP/TTFB 为准；CLI 分数即官方标准分。
- TTFB 受服务器侧影响，前端无法完全消除；需结合后端日志。
- `SSL_ERROR_*`、`ERR_CONNECTION_*` 等按 [phase-a-audit.md](phase-a-audit.md) 的 URL 可达性重试，禁止本地代测。
- **Nginx `upstream keepalive`**：须同步提高 Node `server.keepAliveTimeout`；改 nginx 前确认用户授权。
- MCP 测试前冷启动：`navigate_page → type: reload, ignoreCache: true`；CLI 每次新开浏览器，天然冷启动。
- 同任务勿混用 MCP 与 CLI 分数做前后对比；回归须与首次审计同一模式、同一 device。
- CLI 会在当前目录写 `lighthouse-report.json`（多次运行还有 `lighthouse-1/2/3.json`）。任务结束后删除或确认 `.gitignore` 已忽略。
