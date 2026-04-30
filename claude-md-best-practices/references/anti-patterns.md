# 16 Anti-Patterns — Detailed Reference

> Loaded on demand by `claude-md-best-practices/SKILL.md` Phase 2 subagents. Each anti-pattern below is tagged with the subagent (A / B / C) responsible for checking it.

---

## Subagent A scope: anti-patterns 1–6, 11

Subagent A owns the size, cache-order, and core hygiene checks. The table below lists the seven anti-patterns this subagent must detect.

| # | Mistake | Symptom | Fix |
|---|---|---|---|
| 1 | **Context Stuffing** | Verbose explanations, "just in case" content | One sentence; delete the buildup |
| 2 | **Static Learnings** | No Learnings section, or never updated | Add dated entries; append after every fix |
| 3 | **Missing Plan Mode guidance** | No workflow section | Add one line: "complex tasks plan first" |
| 4 | **Weak Verification** | Says "run tests" but no commands | Give concrete commands: `test + lint + typecheck` trio |
| 5 | **Permissions undocumented** (team) | Each person has a different allowlist | Document the safe pre-allowed commands |
| 6 | **No Format Standards** | No formatting rules, no hooks | Add a PostToolUse hook to auto-format |
| 11 | **Cache-Hostile ordering** | Learnings at the top | Static sections on top, dynamic sections at the bottom. Optimal order: Quick Reference → Architecture → Conventions → Workflow → Verification → Deep Dive → Learnings → Gotchas. |

### Example: Auto-generated and never pruned

```markdown
# Project Overview
This is a TypeScript monorepo using pnpm workspaces. The packages/
directory contains three packages: api (a Hono backend), web (a
Next.js frontend), and shared (common types). The api package uses
Drizzle ORM to communicate with a PostgreSQL database hosted on Neon...
```

**Problem:** all of this can be discovered with `ls packages/` and reading `package.json`. Lulla et al. show that "auto-generated" files like this increase inference cost by 20%+ without improving correctness. This is the canonical Context Stuffing (#1) pattern.

### Verification scoring (anti-pattern 4)

Score the verification section 0–5:

- 0/5: No verification commands at all
- 1/5: Just "run tests" without a specific command
- 2/5: Specific test command (`npm test`, `pytest`)
- 3/5: Test + lint commands
- 4/5: Test + lint + type-check / build validation
- 5/5: Test + lint + type-check + e2e/screenshot/integration verification

Boris Cherny: "If Claude has that feedback loop, it will 2-3x the quality." Also check for a PostToolUse hook that auto-formats after `Write|Edit`.

### Cache-order guidance (anti-pattern 11)

Prompt caching is prefix-matched. Anything mutated invalidates everything below it in the prefix. Therefore:

```
Quick Reference     <- static (cached first)
Architecture        <- static
Conventions         <- static
Workflow            <- static
Verification        <- static
Deep Dive (links)   <- static
─────────────────────
Learnings           <- dynamic (accumulated from PR review)
Gotchas             <- semi-dynamic (changes as bugs are found)
```

If Learnings is at the top, every PR-review update invalidates the whole CLAUDE.md cache. Move dynamic sections to the bottom.

---

## Subagent B scope: anti-patterns 7–10

Subagent B owns documentation sync and `docs/` health. Skip this subagent entirely if no `docs/` folder exists.

| # | Mistake | Symptom | Fix |
|---|---|---|---|
| 7 | **Stale Documentation** | docs/ out of sync with code | Use `/docu-optimize sync` to catch drift |
| 8 | **Missing Index** | docs/ has no README | Add `docs/README.md` as an index |
| 9 | **Orphan Docs** | Files in docs/ not linked from anywhere | Delete or add to Deep Dive |
| 10 | **Code-Doc Drift** | API signatures in docs don't match code | Align API table to real exports |

### Detection notes

- **Stale Documentation (7):** Compare exported functions/classes in code vs the documented API. Look for documented features that no longer exist and code examples that use outdated signatures.
- **Missing Index (8):** If `docs/` exists, it must have a `README.md` that lists the other files. Otherwise the folder is unwalkable for both humans and Claude.
- **Orphan Docs (9):** Scan all markdown files for inbound links. Anything in `docs/` with zero inbound links is orphan — either delete it or link it from `CLAUDE.md`'s Deep Dive section.
- **Code-Doc Drift (10):** Extract the public API from source (exports, public classes/functions, type definitions) and parse the documented API. Produce a sync table:

```
| Item              | Code           | Docs        | Status        |
|-------------------|----------------|-------------|---------------|
| createUser()      | ✓              | ✓           | SYNCED        |
| deleteUser()      | ✓              | ✗           | UNDOCUMENTED  |
| oldMethod()       | ✗              | ✓           | STALE         |
| updateUser(...)   | (id,data,opts) | (id,data)   | DRIFT         |
```

---

## Subagent C scope: anti-patterns 12–16

Subagent C owns modularity, emphasis, and memory checks.

| # | Mistake | Symptom | Fix |
|---|---|---|---|
| 12 | **Instruction Overload** | Over ~150 imperatives | Merge, split into `.claude/rules/`, keep only top-level in CLAUDE.md |
| 13 | **Missing Modular Rules** | CLAUDE.md > 3k tokens with no split | Split into `.claude/rules/{code-style,testing,security}.md` |
| 14 | **No Feedback Loop** | No mechanism for fixes to flow back into CLAUDE.md | After every fix, tell Claude "Update CLAUDE.md so you don't make that mistake again" |
| 15 | **Critical Rules not emphasized** | Safety/destructive rules in normal tone | Add `IMPORTANT` / `YOU MUST` / bold to the 3-5 most critical lines |
| 16 | **MEMORY.md too long/missing** | `~/.claude/projects/<hash>/memory/MEMORY.md` over 200 lines gets truncated | Split into topic files; keep MEMORY.md under 150 lines |

### Example: Over-emphasis

```markdown
**IMPORTANT: ALWAYS use TypeScript.**
**CRITICAL: NEVER use `any`.**
**YOU MUST run tests before commit.**
**IMPORTANT: prefer named exports.**
```

**Problem:** if everything is shouted as important, nothing is. Emphasis dilution. **Only emphasize the 3-5 most dangerous lines.** This is anti-pattern 15.

### Example: Treating CLAUDE.md as documentation

```markdown
## API Endpoints
- POST /api/users - Create user
- GET /api/users/:id - Get user
- PUT /api/users/:id - Update user
... [50 more endpoints]
```

**Problem:** APIs belong in `docs/api.md`. CLAUDE.md should only have the link: `API reference: [docs/api.md](docs/api.md)`. Keeping reference data in CLAUDE.md is the root cause of Instruction Overload (12) and Missing Modular Rules (13).

### Example: All rules mashed together

A single 5k+ token file with no `.claude/rules/` split. Past 150 instructions, Claude starts randomly ignoring rules. This is anti-pattern 13. Fix by splitting into topic files (`code-style.md`, `testing.md`, `security.md`) under `.claude/rules/`. Smaller CLAUDE.md = better cache hits + better instruction adherence.

### Detection notes

- **Instruction Overload (12):** Count imperative sentences and bullets across `CLAUDE.md` + every file in `.claude/rules/`. Lines containing `must`, `always`, `never`, `should`, `don't` count. Threshold: 150.
- **Missing Modular Rules (13):** Trigger when `CLAUDE.md` > 3k tokens AND no `.claude/rules/` split exists.
- **No Feedback Loop (14):** No "Learnings" section, no dated entries, no mention of correction → CLAUDE.md update workflow. Recommend the phrase: "After every correction, tell Claude: 'Update CLAUDE.md so you don't make that mistake again.'" For teams, recommend `@.claude` tagging on PRs plus a GitHub Action for auto-suggestions.
- **Missing Emphasis (15):** Identify rules about security, destructive operations, or breaking changes that lack `IMPORTANT`, `CRITICAL`, `YOU MUST`, or bold/caps formatting. Apply emphasis only to the top 3–5.
- **MEMORY.md (16):** Always loaded into context, lines beyond 200 are silently truncated.
  - Absent: project has substantial history but no memory file → Claude can't carry knowledge across sessions.
  - Too long (>180 lines): risks important entries being cut off.
  - Monolithic: split into topic files (e.g. `debugging.md`, `patterns.md`) and link them from `MEMORY.md`. Keep `MEMORY.md` under 150 lines to leave room for growth.

---

## Maintenance workflow

Shared across all three subagent scopes. Apply during writing, day-to-day usage, and periodic audits.

### When writing
1. `/init` to generate a skeleton
2. **Immediately delete** anything that can be derived from code
3. Apply the recommended structure template (see `references/recommended-template.md`)
4. Run `wc -l CLAUDE.md`; target < 150 lines

### When using
1. Every time Claude makes a mistake you expected it to know better → "Update CLAUDE.md so you don't make that mistake again"
2. Every time Claude asks you something already in CLAUDE.md → the line's phrasing is unclear; rewrite it
3. Every time Claude keeps violating one specific rule → the file is too long, the rule is being drowned out; **cut redundancy**

### Periodic audit (monthly / major milestone)
```bash
# At project root
/docu-optimize analyze     # full 16-anti-pattern scan
/docu-optimize sync        # align code <-> docs
/docu-optimize insights    # surface rules to add from git history
```
