2026年3月17日8 分鐘閱讀ai-cli-tools

ETH Zurich 研究證實多數 context 檔案反而傷害 agent 表現。這裡是 10 個具體的 CLAUDE.md 錯誤 — 附修改前後對比 — 以及如何修正。

Danny Huang

## 你的 CLAUDE.md 很可能在拖後腿

工程界有一個跨越世紀的模式。系統可以運作。人們往上加東西。沒人移除任何東西。系統在自身重量下退化。

多數開發者寫完 CLAUDE.md 後只會往上加東西，從不質疑它是否真的有用。2026 年 2 月，蘇黎世聯邦理工學院（ETH Zurich）發表了第一篇嚴格研究 AI coding agent context 檔案的論文——Thibaud Gloaguen、Niels Mundler、Mark Muller、Veselin Raychev、Martin Vechev 的 [Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988) 。核心結論：LLM 生成的 context 檔案比完全不提供，任務成功率降低 3%。即使人工撰寫的檔案也只提升約 4%，同時推理成本增加超過 20%。

問題不是 context 檔案沒用，而是多數人寫得太爛——太長、太冗餘、太死板。每一行壞指令都在跟你的實際任務搶注意力，稀釋 agent 的專注度、浪費 token。

這篇文章涵蓋 10 個具體錯誤，每個附修改前後對比。如果你的 CLAUDE.md 中了任何一條，今天就修。

## 錯誤 1：檔案太長

最常見的失敗模式。開發者從合理的 30 行開始，然後不斷追加規則、範例、文件，直到膨脹到 300 行以上。就像為每種可能天氣打包的行李箱——太重搬不動，結果你還是只穿那三套衣服。

**為什麼有害：** ETH Zurich 研究發現，越長的 context 檔案推理成本越高（超過 20%），但任務成功率的回報遞減甚至為負。前沿模型能可靠遵循大約 150-200 條指令，超過這個閾值就會開始忽略規則——而且你無法預測它丟掉哪些。Addy Osmani [總結了核心問題](https://addyosmani.com/blog/agents-md/) ：自動生成的內容不是沒用，是冗餘——agent 讀 repo 就能找到，提供兩次同樣的資訊只是增加噪音。

**修改前：**

```markdown
## Project Overview
This is a Next.js 15 application using the App Router with TypeScript...
[20 行概述]

## Architecture
[40 行架構細節]

## Code Conventions
[30 行慣例]

## API Documentation
[50 行 API 文件]

## Database Schema
[40 行 schema 描述]

## Deployment
[30 行 deploy 指令]

## Troubleshooting
[40 行已知問題]
```

**修改後：**

```markdown
## Architecture
- Next.js 15 App Router, TypeScript strict, Tailwind CSS
- Database: PostgreSQL 16 via Prisma
- Auth: NextAuth.js v5 with GitHub + Google providers

## Conventions
- Server components by default; 'use client' only for interactivity
- Error handling: Result<T, E> pattern (see src/lib/result.ts)
- No default exports except pages and layouts

## Constraints
- Never modify files in prisma/migrations/
- All API routes validate input with Zod

## Commands
- Test: pnpm test | Lint: pnpm lint | Build: pnpm build
```

15 行。那 250 行的 API 文件、schema 描述、troubleshooting 指南屬於實際的文件檔案，agent 需要時會自己去讀——不該放在每次 session 都載入的檔案裡。

**原則：** 100 行以下。每一行要通過這個測試：「拿掉這行，agent 會犯一個它讀程式碼也無法自己恢復的錯誤嗎？」

## 錯誤 2：重述 agent 已經看得到的資訊

你的 repo 有 `tsconfig.json` 且 `"strict": true` 。 `package.json` 列出了所有依賴。`.eslintrc` 定義了 lint 規則。在 CLAUDE.md 重述這些，就像在窗戶上貼一張「這是窗戶」的標示。

**為什麼有害：** Agent 會讀你的檔案。當 CLAUDE.md 說「這是 TypeScript 專案」而 `tsconfig.json` 說一樣的事，agent 現在有兩個 source of truth 要調和。調和過程花推理 token，卻零價值。

**修改前：**

```markdown
## Tech Stack
- Language: TypeScript 5.4
- Runtime: Node.js 22
- Package manager: pnpm
- Framework: Next.js 15
- CSS: Tailwind CSS 4.0
- Testing: Vitest 3.0, Playwright 1.50
- Linting: ESLint 9 with flat config
- Formatting: Prettier 3.5
```

**修改後：**

```markdown
## Architecture
- Next.js 15 App Router, PostgreSQL via Prisma, NextAuth.js v5
```

其他所有「tech stack」的內容都在 `package.json` 裡。Agent 第一次讀檔就會找到。唯一值得寫的是不明顯的架構決策——光看依賴列表推斷不出來的東西。

## 錯誤 3：沒有架構區塊

跟過度列舉技術相反的問題：完全不提供架構 context。有些 CLAUDE.md 全是 style 規則和 lint 偏好，對系統如何組合在一起隻字未提。一堆交通號誌，但沒有地圖。

**為什麼有害：** 沒有架構 context，agent 會做出結構上錯誤的決策。它在 route handler 裡直接寫資料庫查詢，因為不知道你有 repository 模式。它建了一個新的 auth helper，因為不知道 `src/lib/auth.ts` 裡已經有了。Style 規則很廉價——linter 會管。架構是 agent 從冷啟動真正無法快速推斷的東西。

**修改前：**

```markdown
## Rules
- Use camelCase for variables
- Use PascalCase for components
- Indent with 2 spaces
- Use single quotes
- Always add trailing commas
```

**修改後：**

```markdown
## Architecture
- Monorepo: apps/web (Next.js), apps/api (Fastify), packages/shared
- Database queries in src/repositories/, never in route handlers
- Auth: centralized in packages/shared/auth — do not create parallel auth logic
- Event system: BullMQ queues in src/jobs/, producers in src/services/

## Conventions
- Error handling: Result<T, E> (see packages/shared/result.ts)
- No default exports except pages
```

「修改前」的命名慣例和縮排規則，你的 linter 和 Prettier 已經在強制執行了。「修改後」告訴 agent 東西在哪、怎麼連接——這些是它需要大量探索才能自己發現的資訊。

## 錯誤 4：缺少 build 和測試指令

你知道怎麼跑你的專案。Agent 不知道。大量 CLAUDE.md 省略了最基本的操作資訊：如何 build、測試、lint、啟動。

**為什麼有害：** 沒有明確指令，agent 會猜。你的專案用 `pnpm test:unit` ，它跑 `npm test` 。正確指令是 `turbo build --filter=web` ，它試 `npm run build` 。錯誤的指令浪費執行週期、產生令人困惑的錯誤、迫使 agent 陷入除錯迴圈去修一個根本不存在的問題。

**修改前：**

```markdown
## Project
A SaaS platform for inventory management.

## Code Style
[30 行 style 規則]
```

**修改後：**

```markdown
## Project
SaaS inventory management platform. Turborepo monorepo.

## Commands
- Install: pnpm install
- Dev: pnpm dev (starts all apps)
- Test unit: pnpm test:unit
- Test e2e: pnpm test:e2e (requires running dev server)
- Lint: pnpm lint
- Build: turbo build --filter=web
- DB migrate: pnpm db:migrate
- DB seed: pnpm db:seed
```

8 行。讓 agent 在每一個操作任務上不用猜。如果你的專案有非標準設定（monorepo、自訂 script、環境需求），這些指令是你整個 CLAUDE.md 中價值最高的內容。

## 錯誤 5：過度死板的 ALWAYS/NEVER 規則

開發者熱愛寫絕對規則。「ALWAYS 用 functional component。」「NEVER 用 any。」「ALWAYS 先寫測試再寫實作。」這些感覺很精確。實際上它們是脆弱的。

**為什麼有害：** 絕對規則不留合理例外的空間。Agent 遵循「NEVER 用 `any` 」然後花 15 分鐘為一個臨時腳本寫複雜的 generic type。它遵循「ALWAYS 先寫測試」然後為一行 config 修改寫測試。隨著檔案增長，死板指令之間也會互相衝突——「ALWAYS 用 server component」跟那個真的需要 client-side state 的表單打架。

**修改前：**

```markdown
## Rules
- ALWAYS use functional components, NEVER use class components
- ALWAYS write tests before writing implementation code
- NEVER use \`any\` type
- ALWAYS use named exports, NEVER use default exports
- NEVER use inline styles
- ALWAYS add JSDoc comments to public functions
- NEVER mutate state directly
```

**修改後：**

```markdown
## Conventions
- Prefer server components; use 'use client' only for interactivity or browser APIs
- Error handling: Result<T, E> pattern — avoid try/catch in business logic
- Named exports preferred; default exports only for pages/layouts (Next.js requirement)
- Type safety: avoid \`any\` — use \`unknown\` with type guards when the type is genuinely uncertain
```

「修改後」用「prefer」和「avoid」搭配明確的例外。這給 agent 判斷空間，同時清楚傳達你的意圖。被移除的規則（「always 先寫測試」、「always 加 JSDoc」）是 workflow 偏好，屬於 [skills](https://www.termdock.com/zh/blog/skill-md-vs-claude-md-vs-agents-md) ，不該放在永遠載入的 context 裡。

## 錯誤 6：沒有 Constraints 區塊

Conventions 告訴 agent 該做什麼。Constraints 告訴它絕對不能做什麼。很多 CLAUDE.md 有大量 conventions 但零 constraints，放任 agent 犯破壞性錯誤。

**為什麼有害：** 沒有明確限制，agent 會開心地修改你的 migration 檔案來「修復」schema 問題、刪掉「沒用到」但其實是用名稱動態載入的測試 fixture、或把你的 public API 重構成 breaking change。這些錯誤在 code review 中很難發現，修復成本極高。短短的 constraints 區塊是 CLAUDE.md 中 ROI 最高的內容。

**修改前：**

```markdown
## Guidelines
- Write clean, readable code
- Follow SOLID principles
- Keep functions small
```

這些是空洞的願望。它們阻止不了任何事。以下才能真正防止損害：

**修改後：**

```markdown
## Constraints
- Never modify files in prisma/migrations/ — generate new migrations instead
- Never change the signature of functions exported from src/api/public/
- Never delete test fixture files in tests/fixtures/ (loaded dynamically by name)
- Never commit .env files or hardcode secrets
- GraphQL schema changes require running pnpm codegen after modification
```

每條 constraint 針對一個具體的、可恢復但成本高的錯誤。「Write clean code」什麼都沒教。「Never modify migration files」防止一次 production 事故。

## 錯誤 7：重複 linter 規則

你的 ESLint config 強制 `no-unused-vars` 。Prettier config 強制 2 格縮排。CLAUDE.md 又說「不要 unused variables」和「用 2 格縮排」。兩個守衛站在同一扇門前。

**為什麼有害：** Linter 確定性地強制規則。CLAUDE.md 不會。Agent 寫了違反 linter 的程式碼，linter 在下次存檔或 CI 就會抓到。在 CLAUDE.md 重述 linter 規則不會讓 agent 更認真遵守——只是在已經有自動化後盾的規則上浪費 context window。更糟的是，如果你的 linter config 改了但 CLAUDE.md 沒更新，你就有矛盾的指令。

**修改前：**

```markdown
## Code Style
- 2 spaces for indentation
- Semicolons required
- Single quotes for strings
- Trailing commas in multi-line structures
- Max line length: 100 characters
- No unused variables
- No console.log in production code
- Use arrow functions for callbacks
- Destructure props in function signatures
```

**修改後：**

```markdown
## Code Style
- ESLint and Prettier are configured. Run \`pnpm lint\` to check.
- If lint fails after changes, fix violations before considering the task done.
```

2 行取代 9 行。Linter 是 source of truth。CLAUDE.md 只需要告訴 agent linter 存在，而且要尊重它。

## 錯誤 8：忽略 AGENTS.md 的跨工具相容性

把所有 agent context 只建在 CLAUDE.md 裡會造成工具鎖定。Claude Code 讀 CLAUDE.md。Codex CLI、Copilot CLI、Gemini CLI、Cursor 不讀——它們讀 AGENTS.md。

**為什麼有害：** 團隊會演進。你今天用的工具不一定是六個月後用的。如果所有專案 context 都在 CLAUDE.md，切換到 Codex CLI 或加入 Gemini CLI 作為輔助工具，意味著要麼把所有東西複製到 AGENTS.md（違反 DRY），要麼用新工具時完全失去 context engineering 的成果。

**修改前：**

```
project-root/
  CLAUDE.md          # 80 行專案 context
  (沒有 AGENTS.md)
```

**修改後：**

```
project-root/
  AGENTS.md          # 70 行 — 標準專案 context
  CLAUDE.md          # 10 行 — 僅 Claude Code 專屬指令
```
```markdown
# CLAUDE.md
Read AGENTS.md for project architecture and conventions.

## Claude Code-Specific
- When compacting, preserve the full list of modified files
- Prefer subagents for research tasks
```

AGENTS.md 放可攜的專案 context。CLAUDE.md 只放 Claude Code 專屬指令（compaction 行為、subagent 偏好、權限覆寫）。所有 AI CLI 工具從 AGENTS.md 取得專案 context；Claude Code 兩個都讀。完整的分層策略請看 [SKILL.md vs CLAUDE.md vs AGENTS.md](https://www.termdock.com/zh/blog/skill-md-vs-claude-md-vs-agents-md) 。

## 錯誤 9：沒有版本控制 CLAUDE.md

有些開發者把 CLAUDE.md 放進 `.gitignore` ，認為它是個人偏好檔案。有些只在本機建立，從不 commit。檔案只存在一台機器上。

**為什麼有害：** CLAUDE.md 是專案文件。它編碼了架構決策、命名慣例、硬性限制——這些適用於每一個貢獻者，不管是人還是 AI。不做版本控制意味著團隊成員得到不一致的 agent 行為、新開發者從零開始、檔案距離徹底遺失只差一個 `rm` 。也代表你沒有 context engineering 演進的歷史——無法把 agent 表現變化跟 CLAUDE.md 的修改關聯起來。

**修改前：**

```
# .gitignore
CLAUDE.md
.claude/
```

**修改後：**

```
# .gitignore
# 版本控制 CLAUDE.md 和 AGENTS.md — 它們是專案文件。
# 只忽略個人設定：
.claude/settings.local.json
```

Commit CLAUDE.md。Commit AGENTS.md。Commit `.claude/skills/` 裡的 skills。在 PR 中審查這些檔案的變更，就像審查程式碼一樣。ETH Zurich 的研究測試了包含開發者 commit 的 context 檔案的 repo，發現它們表現優於 LLM 生成的——部分原因是 commit 過的檔案經過了理解專案的人的審查、精煉、維護。

管理這些 context 檔案跨多個專案工作區——在切換 repo 時讓 CLAUDE.md、AGENTS.md 和 skills 保持同步——正是 [Termdock](https://www.termdock.com/zh) 的 workspace 系統能幫上忙的地方。切換工作區時完整恢復 session 狀態，該工作區的每個終端自動載入正確的專案 context。

Try Termdock — Session Recovery works out of the box. [Free download →](https://github.com/termdock/termdock-issues/releases)

## 錯誤 10：塞入應該是 skill 的任務特定內容

你的 CLAUDE.md 有 40 行「如何建立 Database Migration」、30 行「PR Review Checklist」、25 行「Deploy 流程」。這些不是專案 context，是任務 workflow。而且它們每次 session 都載入，不管你需不需要——就像帶著雪鏟去海灘。

**為什麼有害：** 任務特定的 workflow 會載入到每個 session，即使你在做完全無關的事。在修 CSS bug？那 40 行 migration workflow 正在白白消耗 context window。 [Agent Skills 系統](https://www.termdock.com/zh/blog/skill-md-vs-claude-md-vs-agents-md) 正是為了解決這個問題——skill 只在當前任務符合 description 時才載入。把任務 workflow 放在 CLAUDE.md 裡完全違背了按需載入的設計意圖。

**修改前：**

```markdown
## Database Migration Workflow
1. Read the current schema in src/db/schema.ts
2. Check existing migrations in src/db/migrations/
3. Verify no pending migrations: run pnpm db:status
4. Modify the schema first
5. Generate migration: pnpm db:generate
6. Never write migration SQL by hand
7. Run pnpm db:migrate on dev
8. Run integration tests
9. If tests fail, do NOT modify the migration — drop and regenerate
[...]

## PR Review Checklist
1. Check test coverage
2. Verify no console.log statements
3. Check for hardcoded secrets
4. Verify API backward compatibility
[...]

## Deployment Steps
1. Run full test suite
2. Build production assets
[...]
```

**修改後（CLAUDE.md）：**

```markdown
## Constraints
- Never modify files in src/db/migrations/
- DB commands: pnpm db:generate, pnpm db:migrate, pnpm db:status
```

**修改後（`.claude/skills/database-migration/SKILL.md` ）：**

```markdown
---
name: database-migration
description: >
  Use when creating, modifying, or reviewing database migrations.
  Triggers on: migration files, schema changes, Drizzle ORM modifications.
---

## Database Migration Workflow
1. Read current schema: src/db/schema.ts
2. Check existing migrations for naming conventions
3. Verify no pending migrations: pnpm db:status
4. Modify schema first, then generate: pnpm db:generate
5. Never write migration SQL by hand
6. Test: pnpm db:migrate && pnpm test:integration
7. If tests fail, drop and regenerate — never edit the migration file
```

硬性限制留在 CLAUDE.md（全域適用）。完整 workflow 移到 skill（只在相關時載入）。PR review checklist 變成另一個 skill。Deploy 變成另一個 skill。你的基準 context 從 100 多行混雜內容降到 15 行架構和限制。

## 檢查清單

現在就用這張表審查你的 CLAUDE.md：

| 檢查項目 | 通過/不通過 |
| --- | --- |
| 總共 100 行以下 |  |
| 有 Architecture 區塊 |  |
| 有 Constraints 區塊 |  |
| 有 build/test/lint Commands |  |
| 沒有從 linter/tsconfig/package.json 重複的內容 |  |
| 沒有不帶例外的 ALWAYS/NEVER |  |
| AGENTS.md 存在且包含可攜的專案 context |  |
| CLAUDE.md 和 AGENTS.md 已 commit 到 git |  |
| 任務 workflow 在 `.claude/skills/` 裡，不在 CLAUDE.md 裡 |  |
| 檔案是人工撰寫的，不是 `/init` 生成的 |  |

**這張表的摘要：** 10 個檢查點驗證你的 CLAUDE.md。如果超過 3 個不通過，你的 context 檔案很可能在傷害 agent 表現而不是幫助它。

修正其中一半，你就會看到可衡量的 agent 表現提升——更快的任務完成、更低的 token 成本、更少 agent 因為指令埋在噪音裡而忽略它們的情況。 [AI CLI 工具完整指南](https://www.termdock.com/zh/blog/ai-cli-tools-guide) 有一個可以直接用的範本，以及所有主要工具的 context engineering 全局觀。

Free Download

### Ready to streamline your terminal workflow?

Multi-terminal drag-and-drop layout, workspace Git sync, built-in AI integration, AST code analysis — all in one app.

[Download Termdock →](https://github.com/termdock/termdock-issues/releases)

## 相關文章

2026年3月16日 ·ai-cli-tools

### [2026 AI CLI 工具完全指南：從安裝到多 Agent 工作流](https://www.termdock.com/zh/blog/ai-cli-tools-guide)

完整涵蓋 2026 年所有主流 AI 終端寫程式工具的指南。包含 Claude Code、Gemini CLI、Copilot CLI、Codex CLI、aider、Crush、OpenCode、Goose、Amp 的安裝教學、定價分析、context engineering、多 Agent 工作流、MCP 整合、終端模擬器搭配，以及安全最佳實踐。

ai-cliclaude-codegemini-clicopilot-cliterminaldeveloper-tools

2026年3月16日 ·agent-skills

### [SKILL.md vs CLAUDE.md vs AGENTS.md：什麼時候用哪個](https://www.termdock.com/zh/blog/skill-md-vs-claude-md-vs-agents-md)

完整比較 SKILL.md、CLAUDE.md、AGENTS.md 三種設定檔 — 各自的用途、哪些工具會讀取、如何分層配置讓 AI agent 效能最佳化。

skill-mdclaude-mdagents-mdcontext-engineeringagent-skills

2026年3月20日 ·ai-cli-tools

### [Git Worktree 多 Agent 衝突排除：6 種問題的診斷與修復](https://www.termdock.com/zh/blog/git-worktree-conflicts-ai-agents)

修復多 AI agent 使用 git worktree 時遇到的衝突。涵蓋 lock 檔、index.lock、branch 衝突、合併失敗、過期 worktree、build 產物汙染。

git-worktreemulti-agentconflictsclaude-codetroubleshootingai-cli

2026年3月20日 ·ai-cli-tools

### [20 分鐘用 Claude Code 建一個 MCP Server](https://www.termdock.com/zh/blog/build-first-mcp-server-claude-code)

手把手教學：用 TypeScript 建一個能用的 MCP server，接上 Claude Code，實際呼叫 tool 測試。

mcpmodel-context-protocolclaude-codetutorialai-cliserver

2026年3月20日 ·ai-cli-tools

### [CLAUDE.md 撰寫指南：AI CLI 工具的 Context Engineering](https://www.termdock.com/zh/blog/claude-md-writing-guide)

從零開始寫出真正提升 AI agent 表現的 CLAUDE.md。五個區塊、實際範例、token 預算控制、測試策略完整教學。

claude-mdcontext-engineeringclaude-codeworkflowai-clibest-practices