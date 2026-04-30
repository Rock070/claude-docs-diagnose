# CLAUDE.md Best Practices — Skill Packaging Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the Chinese-language `CLAUDE-MD-BEST-PRACTICES.md` and its three source documents into an English Claude Code skill (`claude-md-best-practices/`) ready for distribution on GitHub, with a complete `README.md`, `SKILL.md`, references, license, and install instructions.

**Architecture:**
- Skill follows Anthropic's progressive-disclosure anatomy: `SKILL.md` (≤ 500 lines) for behaviour, `references/` for the three long source docs and the detailed 16-anti-pattern descriptions (loaded only when needed).
- Runtime execution mirrors `docu-optimize`'s 3-phase model: **Phase 1 sequential discovery → Phase 2 parallel subagents (single message, multiple `Task` calls) → Phase 3 sequential synthesis**. Subagents are read-only; only the main agent writes.
- Token discipline: each subagent gets only the slice of references it needs (project path + file inventory + one anti-pattern subset). The main `SKILL.md` body stays under 500 lines and never inlines the long Anthropic / Addy Osmani / termdock source docs.
- Repo root contains the GitHub-facing artifacts (`README.md`, `LICENSE`, `.gitignore`, install commands) plus the skill subdirectory `claude-md-best-practices/`.
- All Chinese content is translated to English; tables, code blocks, and citations are preserved verbatim.

**Tech Stack:** Plain Markdown, YAML frontmatter, shell installer snippet, Claude Code `Task` tool for subagents.

---

## File Structure

```
claude-docs-diagnose/                         (repo root, becomes the GitHub repo)
├── README.md                                 (NEW — GitHub landing page)
├── LICENSE                                   (NEW — MIT)
├── .gitignore                                (NEW)
├── install.sh                                (NEW — one-line installer)
├── claude-md-best-practices/                 (NEW skill directory)
│   ├── SKILL.md                              (NEW — phased orchestration, ≤ 500 lines)
│   └── references/
│       ├── anti-patterns.md                  (NEW — full 16-mistake details, loaded on demand)
│       ├── recommended-template.md           (NEW — extracted CLAUDE.md template + cheatsheet)
│       ├── claude-best-practices.md          (MOVED from root — Anthropic official, English)
│       ├── agents-md.md                      (MOVED from root — Addy Osmani, English)
│       └── claude-md-common-mistakes.md      (MOVED from root — translated from Chinese)
├── docs/
│   └── superpowers/plans/2026-04-30-claude-md-best-practices-skill.md (THIS PLAN)
└── CLAUDE-MD-BEST-PRACTICES.md               (DELETE after content is migrated)
```

**Why this layout:** The skill subdirectory mirrors Anthropic's recommended skill anatomy (`SKILL.md` + `references/`), so users can drop the entire `claude-md-best-practices/` folder under `~/.claude/skills/` (or `<project>/.claude/skills/`) and it will be discovered automatically. The repo root holds the GitHub-only artifacts (`README.md`, `LICENSE`) which are not part of the skill itself.

---

## Task 1: Translate Chinese source docs into English

**Files:**
- Read: `CLAUDE-MD-BEST-PRACTICES.md`
- Read: `claude-md-common-mistakes.md`
- Translation output is consumed by Tasks 2 and 3 (do not write yet — pass through to those tasks).

- [ ] **Step 1: Read both Chinese source files in full.**

Run: `wc -l CLAUDE-MD-BEST-PRACTICES.md claude-md-common-mistakes.md`
Expected: ~248 lines and several hundred lines respectively.

Use the `Read` tool on each file and capture every section heading, table, code fence, citation link, and emoji marker (`✅`, `❌`).

- [ ] **Step 2: Translate `CLAUDE-MD-BEST-PRACTICES.md` to English.**

Translation rules:
- Preserve heading levels exactly (`#`, `##`, `###`).
- Preserve table column counts and row order; translate cell content only.
- Preserve code fences verbatim (do **not** translate code, paths, commands, or shell snippets).
- Preserve citation URLs (arxiv links, anthropic docs links, blog links) and the file references at the bottom.
- Replace Chinese-only punctuation (`「」`, `：`, `（）`) with English equivalents (`"..."`, `:`, `(...)`).
- Keep the `TL;DR`, the "16 common mistakes" table headings, the anti-pattern section, and the "One-page cheatsheet" intact.
- Translate the three callouts in "One-page cheatsheet" (`Three rules to live by`, `Three numbers to remember`, `One workflow to internalize`) into natural English while keeping the exact numeric thresholds (`2.5k`, `150`, `200`).

Hold the English markdown in memory (or save to a temp scratch path) — Task 3 will write it into `claude-md-best-practices/SKILL.md` after adding skill frontmatter.

- [ ] **Step 3: Translate `claude-md-common-mistakes.md` to English.**

Same rules as Step 2. The output of this step replaces the Chinese file when Task 2 moves files into `references/`.

- [ ] **Step 4: Sanity-check both translations.**

For each translated document, verify:
- Heading count matches the original (`grep -c '^#' <original>` vs the translation).
- Code-fence count matches (`grep -c '^```' <original>` vs the translation).
- All URLs from the original appear in the translation (`grep -oE 'https?://[^ )]+' <original> | sort -u` vs the translation).

If any count mismatches, re-translate the missing block before continuing.

- [ ] **Step 5: Commit.**

```bash
git add -A
git commit -m "docs: translate CLAUDE-MD-BEST-PRACTICES and claude-md-common-mistakes to English"
```

(The translated files still live at the root after this commit; Task 2 will move them into the skill structure.)

---

## Task 2: Create the skill directory and move references

**Files:**
- Create: `claude-md-best-practices/` (directory)
- Create: `claude-md-best-practices/references/` (directory)
- Move: `claude-best-practices.md` → `claude-md-best-practices/references/claude-best-practices.md`
- Move: `agents-md.md` → `claude-md-best-practices/references/agents-md.md`
- Move: `claude-md-common-mistakes.md` (English version from Task 1) → `claude-md-best-practices/references/claude-md-common-mistakes.md`

- [ ] **Step 1: Create directories.**

Run:
```bash
mkdir -p claude-md-best-practices/references
```

- [ ] **Step 2: Move the three reference docs.**

Run:
```bash
git mv claude-best-practices.md claude-md-best-practices/references/claude-best-practices.md
git mv agents-md.md claude-md-best-practices/references/agents-md.md
git mv claude-md-common-mistakes.md claude-md-best-practices/references/claude-md-common-mistakes.md
```

Expected: all three files now sit under `claude-md-best-practices/references/`.

- [ ] **Step 3: Verify references are intact.**

Run:
```bash
ls claude-md-best-practices/references/
wc -l claude-md-best-practices/references/*.md
```

Expected: three files listed, each with non-zero line counts close to the originals (≈ 600 / 400 / 500 lines respectively).

- [ ] **Step 4: Commit.**

```bash
git add -A
git commit -m "refactor: move reference docs into claude-md-best-practices/references/"
```

---

## Task 3: Write SKILL.md (phased subagent orchestration) and split heavy content into references/

**Files:**
- Create: `claude-md-best-practices/SKILL.md`
- Create: `claude-md-best-practices/references/anti-patterns.md`
- Create: `claude-md-best-practices/references/recommended-template.md`
- Delete: `CLAUDE-MD-BEST-PRACTICES.md` (root) — its content is split between SKILL.md (lean orchestration) and the two new reference files (heavy detail).

**Why split:** The Chinese source mixes orchestration ("how to audit") with reference data (the 16-mistake table, the template, anti-pattern examples, the cheatsheet). Inlining all of that into `SKILL.md` would balloon the file past 500 lines and force every triggered run to load ~3.5k tokens of detail the main agent rarely needs verbatim. Following `docu-optimize`'s pattern, `SKILL.md` stays a thin orchestrator (≤ 350 lines target) and dispatches subagents that read only the slice they need.

- [ ] **Step 1: Write `claude-md-best-practices/references/anti-patterns.md`.**

Move the entire **"16 common mistakes" table**, the **"Anti-patterns: don't write this way"** section (with its `❌ Auto-generated and not pruned` / `❌ Over-emphasis` / etc. examples), and the **maintenance workflow** section (Step "When writing", "When using", "Periodic audit") from the English translation produced in Task 1 into `references/anti-patterns.md`.

Add this header at the top of the file:

```markdown
# 16 Anti-Patterns — Detailed Reference

> This file is loaded on demand by `claude-md-best-practices/SKILL.md`. Each anti-pattern below maps to one of three subagent groups (A / B / C) defined in SKILL.md Phase 2.

## Subagent A scope: anti-patterns 1–6, 11
[move table rows 1–6 and 11 here, with full explanations]

## Subagent B scope: anti-patterns 7–10
[move table rows 7–10 here, with full explanations]

## Subagent C scope: anti-patterns 12–16
[move table rows 12–16 here, with full explanations]
```

- [ ] **Step 2: Write `claude-md-best-practices/references/recommended-template.md`.**

Move the **"Recommended structure template"** code block, the **"One-page cheatsheet"** section (Three rules / Three numbers / One workflow), and the **"Team environment supplement"** table from the English translation into `references/recommended-template.md`.

Add this header:

```markdown
# Recommended CLAUDE.md Template + Cheatsheet

> This file is loaded on demand by `claude-md-best-practices/SKILL.md` when the skill needs to generate a new CLAUDE.md or rewrite an existing one. Keep the user's actual CLAUDE.md output trimmed to ≤ 150 lines / ~2.5k tokens.
```

- [ ] **Step 3: Write `claude-md-best-practices/SKILL.md` (lean orchestrator).**

Write to `claude-md-best-practices/SKILL.md`:

````markdown
---
name: claude-md-best-practices
description: Audit, write, and maintain CLAUDE.md files following the battle-tested practices from Anthropic (Boris Cherny, Thariq Shihipar), Addy Osmani, termdock, and the ETH Zurich / Lulla et al. ICSE JAWs 2026 empirical studies. Use when the user asks to write, review, audit, prune, optimize, or fix a CLAUDE.md / AGENTS.md / GEMINI.md, complains that Claude is ignoring rules, mentions context bloat or token budgets for instruction files, asks about MEMORY.md being truncated, wants to split a monolithic CLAUDE.md into .claude/rules/ modules, or refers to the 16 common CLAUDE.md mistakes. Also trigger when the user invokes /claude-md-audit or asks "is my CLAUDE.md too long".
argument-hint: [analyze|audit|optimize|apply|create|prune]
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, Task]
license: MIT
---

# CLAUDE.md Best Practices

You are a CLAUDE.md-quality specialist. You audit, prune, and rewrite `CLAUDE.md` (and `AGENTS.md` / `GEMINI.md`) files following the battle-tested practices from Anthropic and the empirical studies from ETH Zurich and Lulla et al. (ICSE JAWs 2026).

## Target Metrics

- **Ideal CLAUDE.md size:** ~2.5k tokens (~100–150 lines)
- **Maximum recommended:** 4k tokens
- **Warning threshold:** 5k+ tokens (causes context rot)
- **Instruction cap:** ≤ 150 imperative rules across CLAUDE.md + `.claude/rules/`

## Core Principles (TL;DR — in priority order)

1. **Only write what is undiscoverable.** If `ls` / `cat package.json` / `git log` reveals it, don't write it.
2. **Cache-friendly ordering.** Static sections (Quick Reference, Architecture, Conventions, Workflow, Verification, Deep Dive links) on top; dynamic sections (Learnings, Gotchas) at the bottom — prompt cache prefix matching is destroyed when the top changes.
3. **Loaded every session → only universal rules.** Domain-specific workflows go in [skills](https://code.claude.com/docs/en/skills); personal preferences in `~/.claude/CLAUDE.md`; local-only in `./CLAUDE.local.md` (gitignore).
4. **Hierarchy, not single file.** Use `~/.claude/CLAUDE.md` (user), `./CLAUDE.md` (project, git-checked-in), `./packages/*/CLAUDE.md` (sub-scoped), `./.claude/rules/*.md` (topic-modular).
5. **Treat CLAUDE.md as code.** Review when wrong. Prune monthly. PR-review changes.

The Boris Cherny test for every line: **"If I delete this line, will Claude make a mistake?"** If no → delete.

---

## Execution Strategy

**CRITICAL: Phase 2 MUST launch all 3 subagents in a SINGLE message with 3 simultaneous `Task` tool calls. Subagents are read-only; only the main agent writes files.**

This keeps subagent tool output (long file reads, anti-pattern detail lookups) **out of the main agent's context** so the user-facing reasoning stays cheap. Each subagent receives only the slice of references it needs.

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
4. Check the auto-memory file: `~/.claude/projects/<hash>/memory/MEMORY.md` (flag if > 180 lines — truncated at 200).
5. Detect environment: solo / private VPS vs team / shared repo (ask if unclear). Permission-hygiene checks only apply to the team case.

Save this inventory in your working memory — you will pass it verbatim to every Phase 2 subagent.

### Phase 2 — Parallel Analysis (3 subagents in one message)

Use `subagent_type: "general-purpose"`. Each subagent gets: project path, full file inventory from Phase 1, and its specific anti-pattern slice. Subagents read `references/anti-patterns.md` for the relevant sub-section.

#### Subagent A — Size, Cache Order, and Core Hygiene (anti-patterns 1–6, 11)

Hand the subagent: file inventory + path to `references/anti-patterns.md` (Subagent A scope).
It reports on: token bloat, missing Learnings section, missing Plan-mode workflow, weak verification (score 0–5), undocumented permissions (team only), missing format hooks, cache-hostile ordering.

Output: `{ token_count, line_count, instruction_count, verification_score, anti_patterns_found: [...] }`

#### Subagent B — Documentation Sync and docs/ Health (anti-patterns 7–10)

Hand the subagent: file inventory + path to `references/anti-patterns.md` (Subagent B scope) + the project's `docs/` tree (if any).
It reports on: stale documentation, missing `docs/README.md` index, orphan docs, code-doc drift (compare exported symbols vs documented API).

Output: `{ docs_inventory: [...], drift: [...], orphans: [...], missing_index: bool }`

Skip this subagent entirely if no `docs/` folder exists.

#### Subagent C — Modularity, Emphasis, Memory (anti-patterns 12–16)

Hand the subagent: file inventory + path to `references/anti-patterns.md` (Subagent C scope) + the MEMORY.md path.
It reports on: instruction overload (count imperatives across CLAUDE.md + `.claude/rules/`), missing modular rules split, missing feedback loop ("update CLAUDE.md after corrections"), un-emphasized critical rules, MEMORY.md truncation risk.

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

- `SKILL.md` body: target ≤ 350 lines, hard cap 500.
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
- Invokes `/claude-md-audit` or asks "is my CLAUDE.md too long".

---

## References

- [references/anti-patterns.md](references/anti-patterns.md) — Full detail on the 16 common mistakes (loaded on demand by Phase 2 subagents).
- [references/recommended-template.md](references/recommended-template.md) — Recommended CLAUDE.md structure + cheatsheet (loaded in `optimize` / `apply` / `create` modes).
- [references/claude-best-practices.md](references/claude-best-practices.md) — Anthropic's official best practices doc.
- [references/agents-md.md](references/agents-md.md) — Addy Osmani's "AGENTS.md as a living list of code smells".
- [references/claude-md-common-mistakes.md](references/claude-md-common-mistakes.md) — termdock's 10-mistake write-up.

External research:
- [Lulla et al. — ICSE JAWs 2026](https://arxiv.org/abs/2601.20404) (124 PR paired experiment)
- [ETH Zurich — Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988) (Gloaguen, Mündler, Müller, Raychev, Vechev)

---

$ARGUMENTS
````

- [ ] **Step 4: Delete the original Chinese root file.**

Run:
```bash
git rm CLAUDE-MD-BEST-PRACTICES.md
```

- [ ] **Step 5: Verify SKILL.md and reference files are well-formed.**

Run:
```bash
wc -l claude-md-best-practices/SKILL.md \
       claude-md-best-practices/references/anti-patterns.md \
       claude-md-best-practices/references/recommended-template.md
head -8 claude-md-best-practices/SKILL.md
```

Expected:
- `SKILL.md` between 180 and 350 lines (well under the 500-line cap).
- `references/anti-patterns.md` between 150 and 400 lines.
- `references/recommended-template.md` between 60 and 200 lines.
- First 8 lines of `SKILL.md` show the frontmatter starting with `---`, including `name:`, `description:`, `argument-hint:`, `allowed-tools:`, `license:`, and the closing `---`.

If `SKILL.md` exceeds 350 lines, move the **"Modes"** section or the **"When This Skill Triggers"** section into `references/usage.md`.

- [ ] **Step 6: Verify Phase 2 anti-pattern coverage maps cleanly.**

Run:
```bash
grep -c "Subagent A scope" claude-md-best-practices/references/anti-patterns.md
grep -c "Subagent B scope" claude-md-best-practices/references/anti-patterns.md
grep -c "Subagent C scope" claude-md-best-practices/references/anti-patterns.md
```

Expected: each prints `1`. The three scopes together cover all 16 anti-patterns (1–6, 11 + 7–10 + 12–16).

- [ ] **Step 7: Commit.**

```bash
git add -A
git commit -m "feat: add claude-md-best-practices skill with phased subagent orchestration"
```

---

## Task 4: Author top-level README.md for GitHub

**Files:**
- Create: `README.md` (repo root)

- [ ] **Step 1: Write the README.**

Write to `/README.md`:

```markdown
# claude-md-best-practices

A Claude Code skill that audits, writes, and maintains `CLAUDE.md` files using the battle-tested patterns from Anthropic, Boris Cherny, Thariq Shihipar, Addy Osmani, termdock, and the ETH Zurich / Lulla et al. (ICSE JAWs 2026) empirical studies.

## Why

> ETH Zurich found that auto-generated `AGENTS.md` files **decreased** task success by 2–3% and increased reasoning cost by 20%+. Hand-written files only improved success by ~4% — and still cost 19% more tokens.

Most `CLAUDE.md` files are too long, too redundant, and too prescriptive. Every bad line competes with the user's actual task for the model's attention. This skill encodes the rules for writing instruction files that **earn their token cost**.

## What it does

When triggered, the skill:
- Reviews your existing `CLAUDE.md` against a 16-point anti-pattern checklist.
- Suggests cuts (every line that Claude could have discovered on its own).
- Re-orders content for prompt-cache friendliness (static on top, dynamic at the bottom).
- Recommends a modular `.claude/rules/` split if the file is over ~3k tokens.
- Points to deeper references for the official Anthropic, Addy Osmani, and termdock guidance.

## How it runs (token-aware)

The skill follows the same 3-phase model as Anthropic's `docu-optimize`:

1. **Phase 1 — Discovery (sequential):** the main agent inventories your CLAUDE.md hierarchy, `.claude/` ecosystem, `docs/` tree, and `MEMORY.md`.
2. **Phase 2 — Parallel analysis (3 subagents, single message):** three `Task`-spawned subagents work in parallel, each focused on a slice of the 16 anti-patterns. Subagents are **read-only** — their long tool output never enters the main context, keeping token cost low.
3. **Phase 3 — Synthesis (sequential):** the main agent collects subagent reports and produces the user-facing audit (and an optimized draft, in `optimize`/`apply` mode).

Detailed anti-pattern explanations live in `references/anti-patterns.md` and are loaded only by the subagent that needs them — never inlined into the main `SKILL.md`.

## Install

### Option A — install for the current user (recommended)

```bash
git clone https://github.com/<your-username>/claude-md-best-practices.git
cp -r claude-md-best-practices/claude-md-best-practices ~/.claude/skills/
```

After restart, Claude Code auto-discovers the skill. Test it with:

> "Audit my `CLAUDE.md`."

### Option B — install per project

```bash
mkdir -p .claude/skills
cp -r path/to/claude-md-best-practices/claude-md-best-practices .claude/skills/
```

### Option C — one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/claude-md-best-practices/main/install.sh | bash
```

## Usage

Once installed, trigger the skill by asking Claude any of:

- "Audit my CLAUDE.md."
- "Write a CLAUDE.md for this repo."
- "My CLAUDE.md is 600 lines, help me prune it."
- "Split this CLAUDE.md into modular rules."

You can also invoke it explicitly:

```
/skill claude-md-best-practices
```

## What's in this repo

| Path | Purpose |
|---|---|
| `claude-md-best-practices/SKILL.md` | The skill itself — frontmatter + 3-phase orchestration (~300 lines) |
| `claude-md-best-practices/references/anti-patterns.md` | Detailed 16-mistake catalog, loaded on demand by Phase 2 subagents |
| `claude-md-best-practices/references/recommended-template.md` | Recommended CLAUDE.md template + cheatsheet, loaded in `optimize`/`apply` modes |
| `claude-md-best-practices/references/claude-best-practices.md` | Anthropic's official best-practices doc (loaded on demand) |
| `claude-md-best-practices/references/agents-md.md` | Addy Osmani's `AGENTS.md` research roundup |
| `claude-md-best-practices/references/claude-md-common-mistakes.md` | termdock's 10-mistake write-up |
| `README.md` | This file |
| `LICENSE` | MIT |

## The 16-point checklist (summary)

1. Context Stuffing
2. Static Learnings
3. Missing Plan Mode guidance
4. Weak Verification
5. Undocumented Permissions
6. No Format Standards
7. Stale Documentation
8. Missing Index
9. Orphan Docs
10. Code-Doc Drift
11. Cache-Hostile Ordering
12. Instruction Overload (>150 imperatives)
13. Missing Modular Rules
14. No Feedback Loop
15. Critical Rules Not Emphasized
16. MEMORY.md Truncation

Full table with symptoms and fixes lives in `claude-md-best-practices/SKILL.md`.

## References

- [Anthropic — Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Addy Osmani — AGENTS.md as a living list of code smells](https://addyosmani.com/blog/agents-md/)
- [termdock — 10 common CLAUDE.md mistakes](https://www.termdock.com/zh/blog/claude-md-common-mistakes)
- [Lulla et al. — ICSE JAWs 2026 paired experiment](https://arxiv.org/abs/2601.20404)
- [ETH Zurich — Evaluating AGENTS.md (Gloaguen, Mündler, Müller, Raychev, Vechev)](https://arxiv.org/abs/2602.11988)

## Contributing

Issues and pull requests welcome. If you find a CLAUDE.md anti-pattern not covered by the 16-point checklist, open an issue with a concrete example.

## License

MIT — see [LICENSE](LICENSE).
```

- [ ] **Step 2: Verify all internal links resolve.**

Run:
```bash
grep -oE '\]\(([^)]+)\)' README.md | sed -E 's/\]\((.*)\)/\1/' | grep -v '^http' | while read p; do test -e "$p" && echo "OK: $p" || echo "MISSING: $p"; done
```

Expected: every non-`http` link prints `OK:` (LICENSE, claude-md-best-practices/SKILL.md, etc.). If any prints `MISSING:`, fix the path before continuing.

- [ ] **Step 3: Commit.**

```bash
git add README.md
git commit -m "docs: add top-level README for GitHub distribution"
```

---

## Task 5: Add LICENSE, .gitignore, and install.sh

**Files:**
- Create: `LICENSE`
- Create: `.gitignore`
- Create: `install.sh`

- [ ] **Step 1: Write LICENSE (MIT).**

Write to `/LICENSE`:

```
MIT License

Copyright (c) 2026 Rock Wang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Write .gitignore.**

Write to `/.gitignore`:

```
.DS_Store
node_modules/
.env
.env.*
*.log

# Claude Code local artefacts
.claude/local/
.claude/settings.local.json
```

- [ ] **Step 3: Write install.sh.**

Write to `/install.sh`:

```bash
#!/usr/bin/env bash
# install.sh — install claude-md-best-practices into ~/.claude/skills/

set -euo pipefail

REPO_URL="https://github.com/<your-username>/claude-md-best-practices.git"
SKILL_NAME="claude-md-best-practices"
TARGET_DIR="${HOME}/.claude/skills"

mkdir -p "${TARGET_DIR}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "Cloning ${REPO_URL} ..."
git clone --depth 1 "${REPO_URL}" "${TMP_DIR}/repo"

if [ -d "${TARGET_DIR}/${SKILL_NAME}" ]; then
  echo "Existing ${SKILL_NAME} skill found. Replacing."
  rm -rf "${TARGET_DIR}/${SKILL_NAME}"
fi

cp -r "${TMP_DIR}/repo/${SKILL_NAME}" "${TARGET_DIR}/${SKILL_NAME}"

echo
echo "Installed: ${TARGET_DIR}/${SKILL_NAME}"
echo "Restart Claude Code, then trigger with:  \"Audit my CLAUDE.md.\""
```

- [ ] **Step 4: Make install.sh executable.**

Run:
```bash
chmod +x install.sh
```

- [ ] **Step 5: Commit.**

```bash
git add LICENSE .gitignore install.sh
git commit -m "chore: add LICENSE, .gitignore, and install.sh"
```

---

## Task 6: Verify skill structure end-to-end

**Files:** all (read-only verification)

- [ ] **Step 1: Verify final tree.**

Run:
```bash
find . -type f -not -path './.git/*' -not -path './docs/*' | sort
```

Expected output exactly:
```
./.gitignore
./LICENSE
./README.md
./claude-md-best-practices/SKILL.md
./claude-md-best-practices/references/agents-md.md
./claude-md-best-practices/references/anti-patterns.md
./claude-md-best-practices/references/claude-best-practices.md
./claude-md-best-practices/references/claude-md-common-mistakes.md
./claude-md-best-practices/references/recommended-template.md
./install.sh
```

If any file is missing or extra, fix before continuing.

- [ ] **Step 2: Verify SKILL.md frontmatter.**

Run:
```bash
head -5 claude-md-best-practices/SKILL.md
```

Expected:
- Line 1: `---`
- Line 2: `name: claude-md-best-practices`
- A line beginning with `description:` (single line, ~700 chars or less).
- A line `argument-hint: [analyze|audit|optimize|apply|create|prune]`.
- A line `allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, Task]`.
- A line `license: MIT` before the closing `---`.

Then verify the orchestration structure:

```bash
grep -n "^## Phase" claude-md-best-practices/SKILL.md
grep -n "^### Subagent" claude-md-best-practices/SKILL.md
```

Expected: three `## Phase` lines (Phase 1, Phase 2, Phase 3) and three `### Subagent` lines (Subagent A, B, C).

- [ ] **Step 3: Verify line counts.**

Run:
```bash
wc -l claude-md-best-practices/SKILL.md claude-md-best-practices/references/*.md README.md
```

Expected:
- `SKILL.md` between 180 and 350 lines (hard cap 500).
- `references/anti-patterns.md` between 150 and 400 lines.
- `references/recommended-template.md` between 60 and 200 lines.
- The three pre-existing reference files between 200 and 800 lines each.
- `README.md` between 100 and 220 lines.

- [ ] **Step 4: Verify no Chinese characters remain in user-facing files.**

Run:
```bash
LC_ALL=C grep -rl '[^\x00-\x7F]' README.md claude-md-best-practices/SKILL.md claude-md-best-practices/references/*.md || echo "All ASCII clean"
```

Expected: `All ASCII clean` OR a small list containing only files where non-ASCII is intentional (e.g., curly quotes, em-dashes). If any Chinese-Han ideographs remain, return to Task 1 and finish the translation.

(Han ideograph spot-check:)
```bash
grep -lP '[\x{4e00}-\x{9fff}]' README.md claude-md-best-practices/SKILL.md claude-md-best-practices/references/claude-md-common-mistakes.md || echo "No CJK found"
```

Expected: `No CJK found`.

- [ ] **Step 5: Verify all Markdown links resolve.**

Run:
```bash
for f in README.md claude-md-best-practices/SKILL.md; do
  echo "=== $f ==="
  grep -oE '\]\(([^)]+)\)' "$f" \
    | sed -E 's/\]\((.*)\)/\1/' \
    | grep -v '^http' \
    | grep -v '^#' \
    | while read p; do
        # Resolve link relative to the file's directory
        dir=$(dirname "$f")
        full="$dir/$p"
        test -e "$full" && echo "OK: $p" || echo "MISSING: $p (in $f)"
      done
done
```

Expected: every relative link prints `OK:`. Fix any `MISSING:` paths.

- [ ] **Step 6: Final commit if anything changed during verification.**

```bash
git status
# If clean, nothing to do.
# If anything was fixed:
git add -A
git commit -m "fix: address verification findings"
```

- [ ] **Step 7: Tag and push.**

```bash
git log --oneline
```

Expected: 5–6 commits visible (translate, refactor, SKILL.md, README, LICENSE/install, optional fixes).

Show the user the final tree and ask whether to push to GitHub:

```bash
find . -type f -not -path './.git/*' -not -path './docs/*' | sort
```

---

## Self-Review

**1. Spec coverage.** The user asked for four things (three in the original `/writing-plan` request plus one follow-up):

| Request | Where it's handled |
|---|---|
| Translate `CLAUDE-MD-BEST-PRACTICES.md` to English | Task 1 (translation source for Task 3 splits) |
| Use the create-skill workflow to convert this repo into a skill | Tasks 2 + 3 (skill folder, frontmatter, lean SKILL.md, references/) |
| Make it a downloadable GitHub skill with full README.md | Tasks 4 + 5 (README, LICENSE, install.sh, .gitignore) |
| Use `docu-optimize`-style subagents and watch token usage | Task 3 Step 3 (3-phase model, 3 parallel subagents, references split out, dedicated **Token Discipline** section) and README "How it runs" section |

All four are covered.

**2. Placeholder scan.** No "TODO", "TBD", or "fill in later" tokens in any task. Every shell command and frontmatter block is concrete. The repo URL placeholder `<your-username>` is intentional and is documented as something the user will customize before pushing.

**3. Type/name consistency.** Skill folder is `claude-md-best-practices/` and the frontmatter `name:` field is `claude-md-best-practices` everywhere (Tasks 2, 3, 4, 5, 6). The reference filenames match between Task 2 (move), Task 3 (create + link), Task 4 (README table), and Task 6 (find expected output). Subagent names (A / B / C) match between SKILL.md Phase 2 (Step 3 in Task 3) and the headers inside `references/anti-patterns.md` (Step 1 in Task 3). The 16 anti-pattern numbers partition cleanly: A covers 1–6 + 11, B covers 7–10, C covers 12–16 — together exactly 16, no overlap.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-04-30-claude-md-best-practices-skill.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

**Which approach?**
