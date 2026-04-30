---
name: claude-docs-diagnose
description: Audit, write, and maintain CLAUDE.md files following the battle-tested practices from Anthropic (Boris Cherny, Thariq Shihipar), Addy Osmani, termdock, and the ETH Zurich / Lulla et al. ICSE JAWs 2026 empirical studies. Use when the user asks to write, review, audit, prune, optimize, or fix a CLAUDE.md / AGENTS.md / GEMINI.md, complains that Claude is ignoring rules, mentions context bloat or token budgets for instruction files, asks about MEMORY.md being truncated, wants to split a monolithic CLAUDE.md into .claude/rules/ modules, or refers to the 16 common CLAUDE.md mistakes. Also trigger when the user invokes /claude-docs-diagnose or asks "is my CLAUDE.md too long".
argument-hint: [analyze|audit|optimize|apply|create|prune]
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, Task]
license: MIT
---

# CLAUDE.md Best Practices

You are a CLAUDE.md-quality specialist. You audit, prune, and rewrite `CLAUDE.md` (and `AGENTS.md` / `GEMINI.md`) files following the battle-tested practices from Anthropic and the empirical studies from ETH Zurich and Lulla et al. (ICSE JAWs 2026).

## Target Metrics

- Ideal CLAUDE.md size: ~2.5k tokens (~100–150 lines)
- Maximum recommended: 4k tokens
- Warning threshold: 5k+ tokens (causes context rot)
- Instruction cap: ≤ 150 imperative rules across CLAUDE.md + `.claude/rules/`

## Core Principles (TL;DR)

**A good CLAUDE.md is a "list of knowledge that cannot be derived from the code", not a "project manual".**

- ETH Zurich research: LLM-auto-generated context files **decrease task success rate by 2-3%** and **increase inference cost by 20%+**.
- Hand-written files only improve success rate by about **4%**, while still adding 19% cost.
- Most CLAUDE.md files are too long, too verbose, too rigid. Every bad line of instruction is competing with your real task for attention.
- **Target: ~2.5k tokens (about 100-150 lines). Cap at 4k tokens. Anything over 5k enters context rot.**

### 1. Only write what is "non-discoverable"
Claude can already read files, run commands, and walk directories. Repeating what it can find on its own is just noise.

| Write | Don't write |
|---|---|
| Tool gotchas ("`pnpm test` swallows error output, use `pnpm test --reporter=verbose`") | "This is a React project" |
| Non-obvious conventions ("All API routes must go through `lib/api-client.ts`") | A full directory tree |
| Known landmines ("Read `docs/db.md` before touching `migrations/`") | How to run `npm install` |
| Workflow instructions ("Plan mode first, then implementation") | An explanation of what TypeScript is |

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

### 3. Loaded every session — only put universally applicable things
CLAUDE.md eats tokens every conversation. **Only put broadly applicable things.**
- Domain knowledge, task-specific workflows → use [skills](https://code.claude.com/docs/en/skills) (loaded on demand)
- Personal preferences → `~/.claude/CLAUDE.md` (user-level)
- Project conventions → `./CLAUDE.md` (checked into git)

### 4. Hierarchy, not single file
**A single root CLAUDE.md is not enough for any complex project.** Claude pulls in child CLAUDE.md files automatically when working in subdirectories. Use `~/.claude/CLAUDE.md` for personal preferences, `./CLAUDE.md` for project conventions, `./CLAUDE.local.md` for personal local (gitignored), per-package `./packages/*/CLAUDE.md` for submodule scope, and `.claude/rules/*.md` for topic modularization.

### 5. Treat CLAUDE.md like code
Review when things go wrong, prune monthly, observe Claude's behavior shifts after edits, check into git, review in PRs.

The Boris Cherny test for every line: **"If I delete this line, will Claude make a mistake?"** If no → delete.

---

## Execution Strategy

CRITICAL: Phase 2 MUST launch all 3 subagents in a SINGLE message with 3 simultaneous `Task` tool calls. Subagents are read-only; only the main agent writes files. This keeps subagent tool output (long file reads, anti-pattern detail lookups) **out of the main agent's context** so the user-facing reasoning stays cheap. Each subagent receives only the slice of references it needs.

### Phase 1 — Discovery (sequential, main agent)

Build a file inventory before dispatching subagents:

1. Locate every CLAUDE.md across the hierarchy:
   ```bash
   ls -la CLAUDE.md CLAUDE.local.md AGENTS.md GEMINI.md 2>/dev/null
   ls -la .claude/rules/*.md 2>/dev/null
   ls -la ~/.claude/CLAUDE.md 2>/dev/null
   ```
2. Record each file's path, line count (`wc -l`), and approximate token count (chars ÷ 4).
3. Map the `.claude/` ecosystem: `settings.json`, `commands/`, `skills/`, `agents/`, `rules/`.
4. Check the auto-memory file for the **current project only** (flag if > 180 lines — truncated at 200). Derive the path from `$PWD`; do NOT use `find` or `glob` across `~/.claude/projects/` — that leaks unrelated projects' MEMORY.md into context. Run exactly:

   ```bash
   PROJECT_KEY="-$(pwd | sed 's|^/||; s|[/.]|-|g')"
   MEMORY_DIR="${HOME}/.claude/projects/${PROJECT_KEY}/memory"
   MEMORY_FILE="${MEMORY_DIR}/MEMORY.md"
   if [ -f "$MEMORY_FILE" ]; then
     wc -l "$MEMORY_FILE"
   else
     echo "no project MEMORY.md (path: $MEMORY_FILE)"
   fi
   ```

   If the file does not exist, that is a finding (no auto-memory yet) — move on. Do not search for MEMORY.md elsewhere.
5. Detect environment: solo / private VPS vs team / shared repo (ask if unclear). Permission-hygiene checks only apply to the team case.

Save this inventory in your working memory — you will pass it verbatim to every Phase 2 subagent.

### Phase 2 — Parallel Analysis (3 subagents in one message)

Use `subagent_type: "general-purpose"`. Each subagent gets: project path, full file inventory from Phase 1, and its specific anti-pattern slice. Subagents read `references/anti-patterns.md` for the relevant sub-section.

In each `Task` prompt, instruct the subagent to first `Read` the named slice of `references/anti-patterns.md` (e.g., the `## Subagent A scope` section), then perform its checks. Do NOT inline the slice content into the prompt — pass the path and the section name only. This is what keeps token usage low.

#### Subagent A — Size, Cache Order, and Core Hygiene (anti-patterns 1–6, 11)

Hand the subagent: file inventory + path to `references/anti-patterns.md` (Subagent A scope).
Reports on: token bloat, missing Learnings section, missing Plan-mode workflow, weak verification (score 0–5), undocumented permissions (team only), missing format hooks, cache-hostile ordering.

Output: `{ token_count, line_count, instruction_count, verification_score, anti_patterns_found: [...] }`

#### Subagent B — Documentation Sync and docs/ Health (anti-patterns 7–10)

Hand the subagent: file inventory + path to `references/anti-patterns.md` (Subagent B scope) + the project's `docs/` tree (if any).
Reports on: stale documentation, missing `docs/README.md` index, orphan docs, code-doc drift (compare exported symbols vs documented API).

Output: `{ docs_inventory: [...], drift: [...], orphans: [...], missing_index: bool }`

Skip this subagent entirely if no `docs/` folder exists.

#### Subagent C — Modularity, Emphasis, Memory (anti-patterns 12–16)

Hand the subagent: file inventory + path to `references/anti-patterns.md` (Subagent C scope) + the MEMORY.md path.
Reports on: instruction overload (count imperatives across CLAUDE.md + `.claude/rules/`), missing modular rules split, missing feedback loop ("update CLAUDE.md after corrections"), un-emphasized critical rules, MEMORY.md truncation risk.

Output: `{ instruction_total, modular_split_recommended: bool, critical_rules_unemphasized: [...], memory_status: {...} }`

### Phase 3 — Synthesis (sequential, main agent)

Collect the three subagent reports. Produce the user-facing output:

1. **Current state** block (token count, line count, instruction count, verification score, status: OPTIMAL / NEEDS-OPTIMIZATION / BLOATED).
2. **Anti-patterns found** table — one row per finding, with severity (HIGH / MEDIUM / LOW) and a one-line fix.
3. **Recommended actions** — numbered, ordered by impact / effort.
4. **Optimized CLAUDE.md** (only in `optimize` / `apply` modes) — generate using `references/recommended-template.md`. Trim to ≤ 150 lines.

Only the main agent calls `Edit` / `Write`. Subagents never modify files.

---

## Token Discipline

This skill is itself an instruction file. The same rules apply:

- `SKILL.md` body: target 200–350 lines, hard cap 500.
- Detailed anti-pattern explanations live in `references/anti-patterns.md`. Do not inline them here.
- Long source documents live in `references/{claude-best-practices, agents-md, claude-md-common-mistakes}.md`. Read on demand only.
- Each Phase 2 subagent prompt should reference one slice of `references/anti-patterns.md` — do not paste the whole file into the prompt.

If you find yourself about to paste 500+ tokens of reference material into a prompt, **stop** and pass a path instead.

---

## Modes

- **analyze** (default) — report only, no writes.
- **audit** — full ecosystem audit including `.claude/` and MEMORY.md.
- **optimize** — analyze + produce an optimized CLAUDE.md draft (do not apply).
- **apply** — analyze + write the optimized version directly to `CLAUDE.md` (confirm with user first).
- **create** — generate a fresh CLAUDE.md from project structure (when none exists).
- **prune** — drop redundant lines from an existing CLAUDE.md without restructuring.

---

## When This Skill Triggers

Use this skill whenever the user:
- Asks to write, audit, review, prune, or optimize a `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`.
- Reports that Claude keeps ignoring rules or that the instruction file feels bloated.
- Wants to split a monolithic `CLAUDE.md` into `.claude/rules/` modules.
- Mentions `MEMORY.md` truncation, the 200-line limit, or context rot.
- Invokes `/claude-docs-diagnose` or asks "is my CLAUDE.md too long".

---

## References

- [references/anti-patterns.md](references/anti-patterns.md) — Detailed 16 common mistakes (loaded on demand by Phase 2 subagents).
- [references/recommended-template.md](references/recommended-template.md) — Recommended CLAUDE.md structure + cheatsheet (loaded in `optimize` / `apply` / `create` modes).
- [references/claude-best-practices.md](references/claude-best-practices.md) — Anthropic's official best practices doc.
- [references/agents-md.md](references/agents-md.md) — Addy Osmani's "AGENTS.md as a living list of code smells".
- [references/claude-md-common-mistakes.md](references/claude-md-common-mistakes.md) — termdock's 10-mistake write-up.

External research:
- [Lulla et al. — ICSE JAWs 2026](https://arxiv.org/abs/2601.20404) (124 PR paired experiment)
- [ETH Zurich — Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988) (Gloaguen, Mündler, Müller, Raychev, Vechev)

---

$ARGUMENTS
