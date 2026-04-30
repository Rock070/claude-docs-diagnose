# CLAUDE.md 最佳實踐指南

> 綜合來源：Anthropic 官方文件（code.claude.com/docs）、Addy Osmani 的研究綜述、termdock 的 10 個常見錯誤、Boris Cherny / Thariq Shihipar 的 docu-optimize 框架，以及 ETH Zurich 與 Lulla et al. (ICSE JAWs 2026) 的實證研究。

---

## TL;DR

**好的 CLAUDE.md 是「不能從 code 推導出的知識清單」，不是「專案說明書」。**

- ETH Zurich 研究：LLM 自動生成的 context 檔案使任務成功率**降低 2–3%**、推理成本**增加 20%+**。
- 人工撰寫的檔案僅提升約 **4%** 成功率，仍會增加 19% 成本。
- 多數 CLAUDE.md 寫得太長、太冗、太死板，每一行壞指令都在跟你的真實任務搶 attention。
- **目標：~2.5k tokens（約 100–150 行）。上限 4k tokens。超過 5k 進入 context rot。**

---

## 核心原則（5 條）

### 1. 只寫「不可發現」的資訊
Claude 已能讀檔、跑指令、爬目錄。重複它能自己發現的內容只是雜訊。

| 該寫 | 不該寫 |
|---|---|
| 工具陷阱（"`pnpm test` 會吃掉錯誤訊息，請用 `pnpm test --reporter=verbose`"）| 「這是個 React 專案」 |
| 非顯而易見的慣例（"所有 API 路由必須走 `lib/api-client.ts`"） | 完整的目錄樹 |
| 已知的地雷（"動 `migrations/` 前先看 `docs/db.md`"）| `npm install` 怎麼跑 |
| 流程指令（"先 plan mode，再 implementation"）| 解釋 TypeScript 是什麼 |

**檢驗法（Boris Cherny）**：對每一行問「拿掉這行 Claude 會犯錯嗎？」如果不會 → 刪掉。

### 2. Cache-friendly 排序
Prompt cache 用前綴匹配。**靜態內容放上面，動態內容放下面**，否則每次 Learnings 一更新就把整個 cache 失效。

```
Quick Reference     ← 靜態（每個 session 都不變，最先 cache）
Architecture        ← 靜態
Conventions         ← 靜態
Workflow            ← 靜態
Verification        ← 靜態
Deep Dive (links)   ← 靜態
─────────────────────
Learnings           ← 動態（從 PR review 累積）
Gotchas             ← 半動態（隨 bug 發現變動）
```

### 3. 每個 session 都載入 → 只放普世適用
CLAUDE.md 每次對話都吃 token。**只放廣泛適用的事**。
- 領域知識、特定 workflow → 用 [skills](https://code.claude.com/docs/en/skills)（按需載入）
- 個人偏好 → `~/.claude/CLAUDE.md`（user 層級）
- 專案規範 → `./CLAUDE.md`（git 簽入）

### 4. 階層而非單檔
**單一根目錄 CLAUDE.md 對任何複雜專案都不夠**。Claude 支援階層自動載入：

```
~/.claude/CLAUDE.md              # 跨所有專案的個人偏好
./CLAUDE.md                       # 專案根（簽入 git）
./CLAUDE.local.md                 # 個人本地（gitignore）
./packages/api/CLAUDE.md          # 子模組 scoped context
./packages/web/CLAUDE.md          # 子模組 scoped context
.claude/rules/code-style.md       # 主題模組化（path-scoped）
.claude/rules/testing.md
```

Claude 在進入子目錄工作時自動 pull in 子層 CLAUDE.md。

### 5. 把 CLAUDE.md 當 code 對待
- Review when things go wrong
- Prune regularly（每月或重大里程碑後）
- Test changes：改完觀察 Claude 行為是否真的變了
- 簽入 git，PR review

---

## 推薦結構模板

```markdown
# 專案名稱

## Quick Reference
[一行專案描述]
- 啟動：`pnpm dev`
- 測試：`pnpm test`
- 型別檢查：`pnpm typecheck`
- Lint：`pnpm lint`

## Architecture
- Monorepo（pnpm workspaces）：`packages/api`、`packages/web`、`packages/shared`
- API：Hono + Drizzle + PostgreSQL（Neon）
- Web：Next.js App Router + React Server Components
- 認證：所有 API 路由經 `lib/auth.ts` 的 `requireSession()`

## Conventions
- 永遠走 `lib/api-client.ts`，不要直接 `fetch`
- 錯誤型別走 `lib/errors.ts`，不要 throw `new Error`
- 資料層只在 Server Component / Server Action 呼叫，不在 Client Component

## Workflow
- 複雜任務先進 Plan mode，等使用者批准再實作
- 大型變更切成 chunk，每個 chunk 跑一次 verification
- 改完一定跑 verification 命令（見下）

## Verification
跑這些指令確認沒壞東西：
```bash
pnpm typecheck && pnpm lint && pnpm test
```
UI 變更必須在瀏覽器手動驗證 golden path 與一個 edge case。

## Deep Dive (按需閱讀)
- 架構細節：[docs/architecture.md](docs/architecture.md)
- API 參考：[docs/api.md](docs/api.md)
- 部署流程：[docs/deployment.md](docs/deployment.md)
- DB migration 規範：[docs/db.md](docs/db.md)

## Learnings
<!-- 從 PR review 與修正累積；附日期 -->
- 2026-04-12：`useSearchParams` 在 RSC 內無效，改用 `searchParams` prop
- 2026-03-28：Drizzle migration 跑前要 `pnpm db:generate`，否則 schema drift

## Gotchas
- `pnpm test --reporter=verbose` 才看得到完整錯誤
- Neon serverless 在 cold start 第一個 query 會 timeout，retry 即可
- `app/api/webhook/stripe` 必須關掉 body parser（已設好別動）
```

---

## 16 個常見錯誤檢查表（合併版）

| # | 錯誤 | 症狀 | 修正 |
|---|---|---|---|
| 1 | **Context Stuffing** | 冗長解釋、「以防萬一」內容 | 一句話講完，刪掉鋪陳 |
| 2 | **Static Learnings** | 沒有 Learnings 區塊或從未更新 | 加上 dated entries，每次修正後 append |
| 3 | **Missing Plan Mode 指引** | 沒有 workflow 段落 | 加「複雜任務先 plan」一行 |
| 4 | **Weak Verification** | 只說「跑測試」沒給指令 | 給具體指令：`test + lint + typecheck` 三件套 |
| 5 | **Permissions 未文件化**（團隊） | 每人 allowlist 不同 | 文件化安全的 pre-allowed 命令 |
| 6 | **No Format Standards** | 沒提格式、沒 hooks | 加 PostToolUse hook 自動 format |
| 7 | **Stale Documentation** | docs/ 與 code 不同步 | 用 `/docu-optimize sync` 抓 drift |
| 8 | **Missing Index** | docs/ 沒 README | 加 docs/README.md 當 index |
| 9 | **Orphan Docs** | docs/ 內檔案沒被任何地方連結 | 刪掉或加進 Deep Dive |
| 10 | **Code-Doc Drift** | 文件中的 API 簽名與 code 不符 | API table 對齊真實 export |
| 11 | **Cache-Hostile 排序** | Learnings 在最上面 | 靜態上、動態下（見上方範例） |
| 12 | **Instruction Overload** | 超過 ~150 條 imperative | 合併、拆到 `.claude/rules/`，CLAUDE.md 只留頂層 |
| 13 | **Missing Modular Rules** | CLAUDE.md > 3k token 還沒拆 | 拆成 `.claude/rules/{code-style,testing,security}.md` |
| 14 | **No Feedback Loop** | 沒機制把修正回流到 CLAUDE.md | 每次修正後對 Claude 說「Update CLAUDE.md so you don't make that mistake again」 |
| 15 | **Critical Rules 沒強調** | 安全/破壞性規則用一般語氣 | 對最關鍵的 3–5 條加 `IMPORTANT` / `YOU MUST` / 粗體 |
| 16 | **MEMORY.md 過長/缺失** | `~/.claude/projects/<hash>/memory/MEMORY.md` 超過 200 行被截斷 | 拆主題檔，MEMORY.md 控在 150 行內 |

---

## 反模式：別這樣寫

### ❌ 自動生成後不修剪
```markdown
# Project Overview
This is a TypeScript monorepo using pnpm workspaces. The packages/
directory contains three packages: api (a Hono backend), web (a
Next.js frontend), and shared (common types). The api package uses
Drizzle ORM to communicate with a PostgreSQL database hosted on Neon...
```
**問題**：全部都能用 `ls packages/` 和讀 `package.json` 自己發現。Lulla et al. 證實這類「auto-generated」檔案讓推理成本增加 20%+ 而沒提升正確率。

### ❌ 過度強調
```markdown
**IMPORTANT: ALWAYS use TypeScript.**
**CRITICAL: NEVER use `any`.**
**YOU MUST run tests before commit.**
**IMPORTANT: prefer named exports.**
```
**問題**：全部都喊重要 = 都不重要。emphasis dilution。**只對最危險的 3–5 條加強調**。

### ❌ 把 CLAUDE.md 當文件
```markdown
## API Endpoints
- POST /api/users - Create user
- GET /api/users/:id - Get user
- PUT /api/users/:id - Update user
... [50 more endpoints]
```
**問題**：API 應該在 `docs/api.md`，CLAUDE.md 只放 link：`API 參考：[docs/api.md](docs/api.md)`。

### ❌ 所有規則糊成一團
單檔 5k+ tokens 沒有 `.claude/rules/` 拆分。Claude 過 150 條指令就會隨機忽略規則。

---

## 維護工作流

### 寫的時候
1. `/init` 產生骨架
2. **立刻刪掉** 所有能從 code 推導出的內容
3. 套用上方推薦結構模板
4. 跑 `wc -l CLAUDE.md`，目標 < 150 行

### 用的時候
1. 每次 Claude 犯錯但你預期它應該知道 → 「Update CLAUDE.md so you don't make that mistake again」
2. 每次 Claude 問你已寫在 CLAUDE.md 的問題 → 表示該行 phrasing 不清楚，重寫
3. 每次 Claude 一直違反某條規則 → 檔案太長，rule 被淹沒了，**砍冗餘**

### 定期審計（每月 / 重大里程碑）
```bash
# 在專案根
/docu-optimize analyze     # 跑完整 16 條 anti-pattern 檢查
/docu-optimize sync        # 對齊 code ↔ docs
/docu-optimize insights    # 從 git history 自動找出該加的 rule
```

---

## 團隊環境補充

| 項目 | 個人 / 私人 VPS | 團隊 / 共享 repo |
|---|---|---|
| Permissions | `--dangerously-skip-permissions` 可接受 | 必須文件化 allowlist |
| CLAUDE.md 簽入 git | 隨意 | **必須**簽入並 PR review |
| Personal 偏好 | 寫在 `./CLAUDE.md` 也 OK | 寫在 `~/.claude/CLAUDE.md` 或 `./CLAUDE.local.md`（gitignore） |
| Hooks | 看需要 | 建議全隊共用 PostToolUse format hook |

---

## 一頁速查

> **Three rules to live by:**
> 1. 如果 Claude 能自己發現 → 不要寫
> 2. 靜態在上、動態在下
> 3. 每月 prune 一次，砍掉沒讓 Claude 變更好的每一行

> **Three numbers to remember:**
> - **2.5k tokens** = 目標
> - **150** = 指令上限
> - **200** = MEMORY.md 行數截斷上限

> **One workflow to internalize:**
> 修正 Claude → 立刻說「update CLAUDE.md」→ 每月 audit 砍冗餘

---

## 參考資料

- [Anthropic 官方 Best Practices](https://code.claude.com/docs/en/best-practices) — 此目錄 `claude-best-practices.md`
- [Addy Osmani: AGENTS.md as living list of code smells](https://addyosmani.com/blog/agents-md/) — 此目錄 `agents-md.md`
- [termdock: 10 個 CLAUDE.md 常見錯誤](https://www.termdock.com/zh/blog/claude-md-common-mistakes) — 此目錄 `claude-md-common-mistakes.md`
- [docu-optimize skill](file:///Users/rock.wang/.claude/skills/docu-optimize/SKILL.md) — 16 anti-patterns 完整框架
- [Lulla et al. ICSE JAWs 2026](https://arxiv.org/abs/2601.20404) — 124 PR paired experiment
- [ETH Zurich: Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988) — Gloaguen, Mündler, Müller, Raychev, Vechev
