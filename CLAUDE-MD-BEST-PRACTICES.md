# CLAUDE.md Best Practices Guide

> Synthesized from: Anthropic's official docs (code.claude.com/docs), Addy Osmani's research roundup, termdock's 10 common mistakes, the docu-optimize framework by Boris Cherny / Thariq Shihipar, and empirical research from ETH Zurich and Lulla et al. (ICSE JAWs 2026).

---

## TL;DR

**A good CLAUDE.md is a "list of knowledge that cannot be derived from the code", not a "project manual".**

- ETH Zurich research: LLM-auto-generated context files **decrease task success rate by 2-3%** and **increase inference cost by 20%+**.
- Hand-written files only improve success rate by about **4%**, while still adding 19% cost.
- Most CLAUDE.md files are too long, too verbose, too rigid. Every bad line of instruction is competing with your real task for attention.
- **Target: ~2.5k tokens (about 100-150 lines). Cap at 4k tokens. Anything over 5k enters context rot.**

---

## Core Principles (5)

### 1. Only write what is "non-discoverable"
Claude can already read files, run commands, and walk directories. Repeating what it can find on its own is just noise.

| Write | Don't write |
|---|---|
| Tool gotchas ("`pnpm test` swallows error output, use `pnpm test --reporter=verbose`") | "This is a React project" |
| Non-obvious conventions ("All API routes must go through `lib/api-client.ts`") | A full directory tree |
| Known landmines ("Read `docs/db.md` before touching `migrations/`") | How to run `npm install` |
| Workflow instructions ("Plan mode first, then implementation") | An explanation of what TypeScript is |

**The test (Boris Cherny):** for every line, ask "would Claude make a mistake without this line?" If not, delete it.

### 2. Cache-friendly ordering
Prompt cache uses prefix matching. **Static content goes on top, dynamic content goes on the bottom**, otherwise every Learnings update invalidates the entire cache.

```
Quick Reference     <- static (unchanged every session, cached first)
Architecture        <- static
Conventions         <- static
Workflow            <- static
Verification        <- static
Deep Dive (links)   <- static
─────────────────────
Learnings           <- dynamic (accumulated from PR review)
Gotchas             <- semi-dynamic (changes as bugs are found)
```

### 3. Loaded every session -> only put universally applicable things
CLAUDE.md eats tokens every conversation. **Only put broadly applicable things.**
- Domain knowledge, task-specific workflows -> use [skills](https://code.claude.com/docs/en/skills) (loaded on demand)
- Personal preferences -> `~/.claude/CLAUDE.md` (user-level)
- Project conventions -> `./CLAUDE.md` (checked into git)

### 4. Hierarchy, not single file
**A single root CLAUDE.md is not enough for any complex project.** Claude supports automatic hierarchical loading:

```
~/.claude/CLAUDE.md              # personal preferences across all projects
./CLAUDE.md                       # project root (checked into git)
./CLAUDE.local.md                 # personal local (gitignored)
./packages/api/CLAUDE.md          # submodule scoped context
./packages/web/CLAUDE.md          # submodule scoped context
.claude/rules/code-style.md       # topic modularization (path-scoped)
.claude/rules/testing.md
```

Claude pulls in child CLAUDE.md files automatically when working in subdirectories.

### 5. Treat CLAUDE.md like code
- Review when things go wrong
- Prune regularly (monthly or after major milestones)
- Test changes: after editing, observe whether Claude's behavior actually shifts
- Check into git, review in PRs

---

## Recommended structure template

```markdown
# Project Name

## Quick Reference
[One-line project description]
- Start: `pnpm dev`
- Test: `pnpm test`
- Type check: `pnpm typecheck`
- Lint: `pnpm lint`

## Architecture
- Monorepo (pnpm workspaces): `packages/api`, `packages/web`, `packages/shared`
- API: Hono + Drizzle + PostgreSQL (Neon)
- Web: Next.js App Router + React Server Components
- Auth: all API routes go through `requireSession()` in `lib/auth.ts`

## Conventions
- Always go through `lib/api-client.ts`, never `fetch` directly
- Error types go through `lib/errors.ts`, don't throw `new Error`
- Data layer is only called from Server Components / Server Actions, never Client Components

## Workflow
- For complex tasks, enter Plan mode first; wait for user approval before implementing
- Split large changes into chunks; run verification after each chunk
- Always run verification commands after edits (see below)

## Verification
Run these to confirm nothing is broken:
```bash
pnpm typecheck && pnpm lint && pnpm test
```
UI changes must be manually verified in the browser on the golden path plus one edge case.

## Deep Dive (read on demand)
- Architecture details: [docs/architecture.md](docs/architecture.md)
- API reference: [docs/api.md](docs/api.md)
- Deployment: [docs/deployment.md](docs/deployment.md)
- DB migration conventions: [docs/db.md](docs/db.md)

## Learnings
<!-- Accumulated from PR review and corrections; include dates -->
- 2026-04-12: `useSearchParams` doesn't work inside RSC, use the `searchParams` prop
- 2026-03-28: Run `pnpm db:generate` before Drizzle migrations or schema will drift

## Gotchas
- `pnpm test --reporter=verbose` is required to see full error output
- Neon serverless times out on the first query after cold start, just retry
- `app/api/webhook/stripe` requires body parser disabled (already configured, don't touch)
```

---

## 16 Common Mistakes Checklist (combined)

| # | Mistake | Symptom | Fix |
|---|---|---|---|
| 1 | **Context Stuffing** | Verbose explanations, "just in case" content | One sentence; delete the buildup |
| 2 | **Static Learnings** | No Learnings section, or never updated | Add dated entries; append after every fix |
| 3 | **Missing Plan Mode guidance** | No workflow section | Add one line: "complex tasks plan first" |
| 4 | **Weak Verification** | Says "run tests" but no commands | Give concrete commands: `test + lint + typecheck` trio |
| 5 | **Permissions undocumented** (team) | Each person has a different allowlist | Document the safe pre-allowed commands |
| 6 | **No Format Standards** | No formatting rules, no hooks | Add a PostToolUse hook to auto-format |
| 7 | **Stale Documentation** | docs/ out of sync with code | Use `/docu-optimize sync` to catch drift |
| 8 | **Missing Index** | docs/ has no README | Add docs/README.md as an index |
| 9 | **Orphan Docs** | Files in docs/ not linked from anywhere | Delete or add to Deep Dive |
| 10 | **Code-Doc Drift** | API signatures in docs don't match code | Align API table to real exports |
| 11 | **Cache-Hostile ordering** | Learnings at the top | Static on top, dynamic on bottom (see example above) |
| 12 | **Instruction Overload** | Over ~150 imperatives | Merge, split into `.claude/rules/`, keep only top-level in CLAUDE.md |
| 13 | **Missing Modular Rules** | CLAUDE.md > 3k tokens with no split | Split into `.claude/rules/{code-style,testing,security}.md` |
| 14 | **No Feedback Loop** | No mechanism for fixes to flow back into CLAUDE.md | After every fix, tell Claude "Update CLAUDE.md so you don't make that mistake again" |
| 15 | **Critical Rules not emphasized** | Safety/destructive rules in normal tone | Add `IMPORTANT` / `YOU MUST` / bold to the 3-5 most critical lines |
| 16 | **MEMORY.md too long/missing** | `~/.claude/projects/<hash>/memory/MEMORY.md` over 200 lines gets truncated | Split into topic files; keep MEMORY.md under 150 lines |

---

## Anti-patterns: Don't write it like this

### ❌ Auto-generated and never pruned
```markdown
# Project Overview
This is a TypeScript monorepo using pnpm workspaces. The packages/
directory contains three packages: api (a Hono backend), web (a
Next.js frontend), and shared (common types). The api package uses
Drizzle ORM to communicate with a PostgreSQL database hosted on Neon...
```
**Problem:** all of this can be discovered with `ls packages/` and reading `package.json`. Lulla et al. show that "auto-generated" files like this increase inference cost by 20%+ without improving correctness.

### ❌ Over-emphasis
```markdown
**IMPORTANT: ALWAYS use TypeScript.**
**CRITICAL: NEVER use `any`.**
**YOU MUST run tests before commit.**
**IMPORTANT: prefer named exports.**
```
**Problem:** if everything is shouted as important, nothing is. Emphasis dilution. **Only emphasize the 3-5 most dangerous lines.**

### ❌ Treating CLAUDE.md as documentation
```markdown
## API Endpoints
- POST /api/users - Create user
- GET /api/users/:id - Get user
- PUT /api/users/:id - Update user
... [50 more endpoints]
```
**Problem:** APIs belong in `docs/api.md`. CLAUDE.md should only have the link: `API reference: [docs/api.md](docs/api.md)`.

### ❌ All rules mashed together
A single 5k+ token file with no `.claude/rules/` split. Past 150 instructions, Claude starts randomly ignoring rules.

---

## Maintenance workflow

### When writing
1. `/init` to generate a skeleton
2. **Immediately delete** anything that can be derived from code
3. Apply the recommended structure template above
4. Run `wc -l CLAUDE.md`; target < 150 lines

### When using
1. Every time Claude makes a mistake you expected it to know better -> "Update CLAUDE.md so you don't make that mistake again"
2. Every time Claude asks you something already in CLAUDE.md -> the line's phrasing is unclear; rewrite it
3. Every time Claude keeps violating one specific rule -> the file is too long, the rule is being drowned out; **cut redundancy**

### Periodic audit (monthly / major milestone)
```bash
# At project root
/docu-optimize analyze     # full 16-anti-pattern scan
/docu-optimize sync        # align code <-> docs
/docu-optimize insights    # surface rules to add from git history
```

---

## Team environment notes

| Item | Personal / private VPS | Team / shared repo |
|---|---|---|
| Permissions | `--dangerously-skip-permissions` is acceptable | Must document the allowlist |
| CLAUDE.md in git | Optional | **Required**, with PR review |
| Personal preferences | OK to put in `./CLAUDE.md` | Put in `~/.claude/CLAUDE.md` or `./CLAUDE.local.md` (gitignored) |
| Hooks | As needed | Recommend a team-wide PostToolUse format hook |

---

## One-page cheatsheet

> **Three rules to live by:**
> 1. If Claude can find it itself -> don't write it
> 2. Static on top, dynamic on the bottom
> 3. Prune monthly; cut every line that hasn't made Claude better

> **Three numbers to remember:**
> - **2.5k tokens** = target
> - **150** = instruction ceiling
> - **200** = MEMORY.md line cap before truncation

> **One workflow to internalize:**
> Correct Claude -> immediately say "update CLAUDE.md" -> audit monthly and cut redundancy

---

## References

- [Anthropic official Best Practices](https://code.claude.com/docs/en/best-practices) — `claude-best-practices.md` in this directory
- [Addy Osmani: AGENTS.md as living list of code smells](https://addyosmani.com/blog/agents-md/) — `agents-md.md` in this directory
- [termdock: 10 common CLAUDE.md mistakes](https://www.termdock.com/zh/blog/claude-md-common-mistakes) — `claude-md-common-mistakes.md` in this directory
- [docu-optimize skill](file:///Users/rock.wang/.claude/skills/docu-optimize/SKILL.md) — full 16-anti-pattern framework
- [Lulla et al. ICSE JAWs 2026](https://arxiv.org/abs/2601.20404) — 124 PR paired experiment
- [ETH Zurich: Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988) — Gloaguen, Mündler, Müller, Raychev, Vechev
