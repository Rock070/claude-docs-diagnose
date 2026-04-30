March 17, 2026 - 8 min read - ai-cli-tools

ETH Zurich research confirms most context files actually hurt agent performance. Here are 10 concrete CLAUDE.md mistakes — with before/after diffs — and how to fix them.

Danny Huang

## Your CLAUDE.md is probably dragging you down

There's a pattern in engineering that's older than this century. The system works. People keep adding things. Nobody removes anything. The system degrades under its own weight.

Most developers only ever add to their CLAUDE.md, never questioning whether it's actually helping. In February 2026, ETH Zurich published the first rigorous study of AI coding agent context files — Thibaud Gloaguen, Niels Mundler, Mark Muller, Veselin Raychev, and Martin Vechev's [Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988). Headline result: LLM-generated context files reduce task success rate by 3% compared to providing nothing at all. Even hand-written files only improve success by about 4%, while increasing inference cost by over 20%.

The problem isn't that context files are useless — it's that most of them are written badly: too long, too redundant, too rigid. Every bad line of instruction competes with your real task for attention, dilutes the agent's focus, and burns tokens.

This article covers 10 concrete mistakes, each with a before/after diff. If your CLAUDE.md hits any of them, fix it today.

## Mistake 1: The file is too long

The most common failure mode. Developers start with a reasonable 30 lines, then keep appending rules, examples, and documentation until it bloats past 300 lines. It's like a suitcase packed for every possible weather — too heavy to carry, and you end up wearing the same three outfits anyway.

**Why it hurts:** ETH Zurich found that longer context files raise inference cost (over 20%) with diminishing or negative returns on task success. Frontier models can reliably follow about 150-200 instructions; past that threshold they start ignoring rules — and you can't predict which ones get dropped. Addy Osmani [summarized the core problem](https://addyosmani.com/blog/agents-md/): auto-generated content isn't useless, it's redundant — the agent finds it by reading the repo, and providing the same information twice just adds noise.

**Before:**

```markdown
## Project Overview
This is a Next.js 15 application using the App Router with TypeScript...
[20 lines of overview]

## Architecture
[40 lines of architecture details]

## Code Conventions
[30 lines of conventions]

## API Documentation
[50 lines of API docs]

## Database Schema
[40 lines of schema description]

## Deployment
[30 lines of deploy instructions]

## Troubleshooting
[40 lines of known issues]
```

**After:**

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

15 lines. Those 250 lines of API docs, schema descriptions, and troubleshooting belong in real documentation files the agent reads when it needs to — not in a file loaded into every session.

**Rule of thumb:** under 100 lines. Each line should pass the test: "without this line, would the agent make a mistake it couldn't recover from by reading the code?"

## Mistake 2: Restating what the agent can already see

Your repo has `tsconfig.json` with `"strict": true`. `package.json` lists every dependency. `.eslintrc` defines lint rules. Restating these in CLAUDE.md is like sticking a "this is a window" label on a window.

**Why it hurts:** the agent reads your files. When CLAUDE.md says "this is a TypeScript project" and `tsconfig.json` says the same thing, the agent now has two sources of truth to reconcile. Reconciliation costs reasoning tokens for zero value.

**Before:**

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

**After:**

```markdown
## Architecture
- Next.js 15 App Router, PostgreSQL via Prisma, NextAuth.js v5
```

Everything else under "tech stack" is in `package.json`. The agent finds it the first time it reads the file. The only thing worth writing is the non-obvious architectural decisions — things you can't infer from a dependency list.

## Mistake 3: No architecture section

The opposite problem from over-listing tech: providing zero architectural context. Some CLAUDE.md files are all style rules and lint preferences with not a word about how the system fits together. A pile of traffic signs and no map.

**Why it hurts:** without architectural context, the agent makes structurally wrong decisions. It writes a database query directly inside a route handler because it doesn't know you have a repository pattern. It builds a new auth helper because it doesn't know `src/lib/auth.ts` already exists. Style rules are cheap — your linter handles them. Architecture is what the agent genuinely cannot infer quickly from a cold start.

**Before:**

```markdown
## Rules
- Use camelCase for variables
- Use PascalCase for components
- Indent with 2 spaces
- Use single quotes
- Always add trailing commas
```

**After:**

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

The naming and indentation rules in "Before" are already enforced by your linter and Prettier. "After" tells the agent where things live and how they connect — information it would otherwise have to discover with significant exploration.

## Mistake 4: Missing build and test commands

You know how to run your project. The agent doesn't. A surprising number of CLAUDE.md files omit the most basic operational information: how to build, test, lint, and start the project.

**Why it hurts:** without explicit commands, the agent guesses. Your project uses `pnpm test:unit` and it runs `npm test`. The correct command is `turbo build --filter=web` and it tries `npm run build`. Wrong commands waste cycles, produce confusing errors, and force the agent into debugging loops chasing a problem that doesn't exist.

**Before:**

```markdown
## Project
A SaaS platform for inventory management.

## Code Style
[30 lines of style rules]
```

**After:**

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

8 lines. Stops the agent from guessing on every operation. If your project has any non-standard setup (monorepo, custom scripts, environment requirements), these commands are the highest-value content in your entire CLAUDE.md.

## Mistake 5: Over-rigid ALWAYS/NEVER rules

Developers love writing absolutes. "ALWAYS use functional components." "NEVER use any." "ALWAYS write tests before implementation." They feel precise. They're actually brittle.

**Why it hurts:** absolute rules leave no room for legitimate exceptions. The agent follows "NEVER use `any`" and spends 15 minutes writing a complex generic type for a one-off script. It follows "ALWAYS write tests first" and writes a test for a one-line config tweak. As the file grows, rigid instructions also start contradicting each other — "ALWAYS use server components" fights with the form that genuinely needs client-side state.

**Before:**

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

**After:**

```markdown
## Conventions
- Prefer server components; use 'use client' only for interactivity or browser APIs
- Error handling: Result<T, E> pattern — avoid try/catch in business logic
- Named exports preferred; default exports only for pages/layouts (Next.js requirement)
- Type safety: avoid \`any\` — use \`unknown\` with type guards when the type is genuinely uncertain
```

"After" uses "prefer" and "avoid" with explicit exceptions. This gives the agent room to judge while making your intent clear. The removed rules ("always write tests first", "always add JSDoc") are workflow preferences and belong in [skills](https://www.termdock.com/zh/blog/skill-md-vs-claude-md-vs-agents-md), not in always-loaded context.

## Mistake 6: No Constraints section

Conventions tell the agent what to do. Constraints tell it what it absolutely must not do. Many CLAUDE.md files have plenty of conventions and zero constraints, leaving the agent free to make destructive mistakes.

**Why it hurts:** without explicit constraints, the agent will happily edit your migration files to "fix" a schema issue, delete an "unused" test fixture that's actually loaded dynamically by name, or refactor your public API into a breaking change. These mistakes are hard to catch in code review and expensive to fix. A short Constraints section is the highest-ROI content in CLAUDE.md.

**Before:**

```markdown
## Guidelines
- Write clean, readable code
- Follow SOLID principles
- Keep functions small
```

These are empty wishes. They prevent nothing. This is what actually prevents damage:

**After:**

```markdown
## Constraints
- Never modify files in prisma/migrations/ — generate new migrations instead
- Never change the signature of functions exported from src/api/public/
- Never delete test fixture files in tests/fixtures/ (loaded dynamically by name)
- Never commit .env files or hardcode secrets
- GraphQL schema changes require running pnpm codegen after modification
```

Each constraint targets a specific, recoverable-but-expensive mistake. "Write clean code" teaches nothing. "Never modify migration files" prevents a production incident.

## Mistake 7: Duplicating linter rules

Your ESLint config enforces `no-unused-vars`. Your Prettier config enforces 2-space indentation. CLAUDE.md then says "no unused variables" and "use 2-space indentation". Two guards posted at the same door.

**Why it hurts:** the linter enforces rules deterministically. CLAUDE.md doesn't. If the agent writes code that violates the linter, the linter catches it on save or in CI. Restating linter rules in CLAUDE.md doesn't make the agent follow them more carefully — it just burns context window on rules that already have automated backstops. Worse, if your linter config changes and CLAUDE.md doesn't, you now have contradictory instructions.

**Before:**

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

**After:**

```markdown
## Code Style
- ESLint and Prettier are configured. Run \`pnpm lint\` to check.
- If lint fails after changes, fix violations before considering the task done.
```

2 lines instead of 9. The linter is the source of truth. CLAUDE.md just needs to tell the agent the linter exists and must be respected.

## Mistake 8: Ignoring AGENTS.md cross-tool compatibility

Putting all agent context only in CLAUDE.md creates tool lock-in. Claude Code reads CLAUDE.md. Codex CLI, Copilot CLI, Gemini CLI, and Cursor don't — they read AGENTS.md.

**Why it hurts:** teams evolve. The tool you use today may not be the tool you use six months from now. If all your project context lives in CLAUDE.md, switching to Codex CLI or adding Gemini CLI as a secondary tool means either copying everything to AGENTS.md (DRY violation) or losing all your context engineering work when you use the new tool.

**Before:**

```
project-root/
  CLAUDE.md          # 80 lines of project context
  (no AGENTS.md)
```

**After:**

```
project-root/
  AGENTS.md          # 70 lines — standard project context
  CLAUDE.md          # 10 lines — Claude Code-only instructions
```
```markdown
# CLAUDE.md
Read AGENTS.md for project architecture and conventions.

## Claude Code-Specific
- When compacting, preserve the full list of modified files
- Prefer subagents for research tasks
```

AGENTS.md holds portable project context. CLAUDE.md only holds Claude Code-specific instructions (compaction behavior, subagent preferences, permission overrides). All AI CLI tools pick up project context from AGENTS.md; Claude Code reads both. For the full layering strategy, see [SKILL.md vs CLAUDE.md vs AGENTS.md](https://www.termdock.com/zh/blog/skill-md-vs-claude-md-vs-agents-md).

## Mistake 9: Not version-controlling CLAUDE.md

Some developers put CLAUDE.md in `.gitignore`, treating it as a personal preference file. Some create it locally and never commit it. The file lives on a single machine.

**Why it hurts:** CLAUDE.md is project documentation. It encodes architectural decisions, naming conventions, hard constraints — things that apply to every contributor, human or AI. Not version-controlling it means team members get inconsistent agent behavior, new developers start from zero, and the file is one `rm` away from being lost forever. It also means you have no history of how your context engineering evolved — no way to correlate agent performance changes with CLAUDE.md edits.

**Before:**

```
# .gitignore
CLAUDE.md
.claude/
```

**After:**

```
# .gitignore
# Version-control CLAUDE.md and AGENTS.md — they're project docs.
# Only ignore personal settings:
.claude/settings.local.json
```

Commit CLAUDE.md. Commit AGENTS.md. Commit skills under `.claude/skills/`. Review changes to these files in PRs the same way you review code. The ETH Zurich study tested repos that included context files committed by developers and found they outperformed LLM-generated ones — partly because committed files were reviewed, refined, and maintained by people who understood the project.

Managing these context files across multiple project workspaces — keeping CLAUDE.md, AGENTS.md, and skills in sync as you switch between repos — is exactly what [Termdock](https://www.termdock.com/zh)'s workspace system helps with. Switch workspaces and the session state restores fully; every terminal in that workspace auto-loads the right project context.

Try Termdock — Session Recovery works out of the box. [Free download →](https://github.com/termdock/termdock-issues/releases)

## Mistake 10: Stuffing in task-specific content that should be a skill

Your CLAUDE.md has 40 lines on "How to create a Database Migration", 30 lines on "PR Review Checklist", 25 lines on "Deploy Process". These aren't project context — they're task workflows. And they load into every session whether you need them or not — like bringing a snow shovel to the beach.

**Why it hurts:** task-specific workflows load into every session, even when you're doing something completely unrelated. Fixing a CSS bug? Those 40 lines of migration workflow are burning context window for nothing. The [Agent Skills system](https://www.termdock.com/zh/blog/skill-md-vs-claude-md-vs-agents-md) exists precisely to solve this — a skill loads only when the current task matches its description. Putting task workflows in CLAUDE.md completely defeats the on-demand loading design.

**Before:**

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

**After (CLAUDE.md):**

```markdown
## Constraints
- Never modify files in src/db/migrations/
- DB commands: pnpm db:generate, pnpm db:migrate, pnpm db:status
```

**After (`.claude/skills/database-migration/SKILL.md`):**

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

Hard constraints stay in CLAUDE.md (globally relevant). The full workflow moves into a skill (loaded only when relevant). The PR review checklist becomes another skill. Deploy becomes another skill. Your baseline context drops from 100+ lines of mixed content to 15 lines of architecture and constraints.

## Checklist

Audit your CLAUDE.md against this table right now:

| Check | Pass/Fail |
| --- | --- |
| Under 100 lines total |  |
| Has an Architecture section |  |
| Has a Constraints section |  |
| Has build/test/lint Commands |  |
| No content duplicated from linter/tsconfig/package.json |  |
| No ALWAYS/NEVER without exceptions |  |
| AGENTS.md exists with portable project context |  |
| CLAUDE.md and AGENTS.md committed to git |  |
| Task workflows live in `.claude/skills/`, not CLAUDE.md |  |
| File is hand-written, not `/init`-generated |  |

**Summary of this table:** 10 checks to validate your CLAUDE.md. If more than 3 fail, your context file is probably hurting agent performance instead of helping.

Fix half of them and you'll see a measurable lift in agent performance — faster task completion, lower token cost, fewer cases of the agent ignoring instructions because they were buried in noise. The [complete AI CLI tools guide](https://www.termdock.com/zh/blog/ai-cli-tools-guide) has a ready-to-use template plus a global view of context engineering across all major tools.

Free Download

### Ready to streamline your terminal workflow?

Multi-terminal drag-and-drop layout, workspace Git sync, built-in AI integration, AST code analysis — all in one app.

[Download Termdock →](https://github.com/termdock/termdock-issues/releases)

## Related articles

March 16, 2026 - ai-cli-tools

### [The complete 2026 AI CLI tools guide: from install to multi-agent workflows](https://www.termdock.com/zh/blog/ai-cli-tools-guide)

Comprehensive guide to every major AI terminal coding tool in 2026. Covers install, pricing, context engineering, multi-agent workflows, MCP integration, terminal emulator pairings, and security best practices for Claude Code, Gemini CLI, Copilot CLI, Codex CLI, aider, Crush, OpenCode, Goose, and Amp.

ai-cliclaude-codegemini-clicopilot-cliterminaldeveloper-tools

March 16, 2026 - agent-skills

### [SKILL.md vs CLAUDE.md vs AGENTS.md: when to use which](https://www.termdock.com/zh/blog/skill-md-vs-claude-md-vs-agents-md)

A full comparison of SKILL.md, CLAUDE.md, and AGENTS.md — what each is for, which tools read each, and how to layer them for optimal AI agent performance.

skill-mdclaude-mdagents-mdcontext-engineeringagent-skills

March 20, 2026 - ai-cli-tools

### [Git Worktree multi-agent conflict resolution: diagnosing and fixing 6 common problems](https://www.termdock.com/zh/blog/git-worktree-conflicts-ai-agents)

Fix the conflicts that show up when multiple AI agents share git worktrees. Covers lock files, index.lock, branch conflicts, merge failures, stale worktrees, and build artifact contamination.

git-worktreemulti-agentconflictsclaude-codetroubleshootingai-cli

March 20, 2026 - ai-cli-tools

### [Build an MCP Server with Claude Code in 20 minutes](https://www.termdock.com/zh/blog/build-first-mcp-server-claude-code)

Step-by-step tutorial: build a working MCP server in TypeScript, wire it into Claude Code, and call its tools live.

mcpmodel-context-protocolclaude-codetutorialai-cliserver

March 20, 2026 - ai-cli-tools

### [The CLAUDE.md writing guide: context engineering for AI CLI tools](https://www.termdock.com/zh/blog/claude-md-writing-guide)

Write a CLAUDE.md that actually lifts AI agent performance, from scratch. Five sections, real examples, token-budget control, and a complete testing strategy.

claude-mdcontext-engineeringclaude-codeworkflowai-clibest-practices
