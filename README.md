# claude-md-best-practices

A Claude Code skill that audits, writes, and maintains `CLAUDE.md` files using battle-tested patterns from Anthropic (Boris Cherny, Thariq Shihipar), Addy Osmani, termdock, and the ETH Zurich / Lulla et al. (ICSE JAWs 2026) empirical studies.

## Why

> ETH Zurich found that auto-generated `AGENTS.md` files **decreased** task success by 2–3% and increased reasoning cost by 20%+. Hand-written files only improved success by ~4% — and still cost 19% more tokens.

Most `CLAUDE.md` files are too long, too redundant, and too prescriptive. Every bad line competes with the user's actual task for the model's attention. This skill encodes the rules for writing instruction files that **earn their token cost**.

## What it does

When triggered, the skill:

- Audits your existing `CLAUDE.md` against a 16-point anti-pattern checklist.
- Suggests cuts (every line that Claude could have discovered on its own).
- Reorders content for prompt-cache friendliness (static on top, dynamic at the bottom).
- Recommends a modular `.claude/rules/` split if the file exceeds ~3k tokens.
- Generates a fresh `CLAUDE.md` for projects that don't have one (in `create` mode).

## How it runs (token-aware)

The skill follows the same 3-phase model as Anthropic's `docu-optimize`:

1. **Phase 1 — Discovery (sequential):** the main agent inventories your `CLAUDE.md` hierarchy, `.claude/` ecosystem, `docs/` tree, and `MEMORY.md`.
2. **Phase 2 — Parallel analysis (3 subagents, single message):** three `Task`-spawned subagents work in parallel, each focused on a slice of the 16 anti-patterns. Subagents are **read-only** — their long tool output never enters the main context, keeping token cost low.
3. **Phase 3 — Synthesis (sequential):** the main agent collects the subagent reports and produces the user-facing audit (and an optimized draft, in `optimize` / `apply` mode).

Detailed anti-pattern explanations live in `claude-md-best-practices/references/anti-patterns.md` and are loaded only by the subagent that needs them — never inlined into the main `SKILL.md`.

## Install

### Option A — install for the current user (recommended)

```bash
git clone https://github.com/Rock070/claude-docs-diagnose.git
cd claude-docs-diagnose
cp -r ./claude-md-best-practices ~/.claude/skills/
```

After Claude Code auto-discovers the skill, test it with:

> "Audit my CLAUDE.md."

### Option B — install per project

```bash
mkdir -p .claude/skills
cp -r path/to/claude-md-best-practices/claude-md-best-practices .claude/skills/
```

### Option C — one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/Rock070/claude-docs-diagnose/main/install.sh | bash
```

(See `install.sh` for what this script does.)

## Usage

Once installed, trigger the skill by asking Claude any of:

- "Audit my CLAUDE.md."
- "Write a CLAUDE.md for this repo."
- "My CLAUDE.md is 600 lines, help me prune it."
- "Split this CLAUDE.md into modular rules."
- "Is my CLAUDE.md too long?"

You can also invoke it explicitly via `/skill claude-md-best-practices`.

### Modes

- **analyze** (default) — report only, no writes.
- **audit** — full ecosystem audit including `.claude/` and `MEMORY.md`.
- **optimize** — analyze + produce an optimized `CLAUDE.md` draft (do not apply).
- **apply** — analyze + write the optimized version directly to `CLAUDE.md` (confirms first).
- **create** — generate a fresh `CLAUDE.md` from project structure when none exists.
- **prune** — drop redundant lines from an existing `CLAUDE.md` without restructuring.

## What's in this repo

| Path | Purpose |
|---|---|
| `claude-md-best-practices/SKILL.md` | The skill itself — frontmatter + 3-phase orchestration (~180 lines) |
| `claude-md-best-practices/references/anti-patterns.md` | Detailed 16-mistake catalog, loaded on demand by Phase 2 subagents |
| `claude-md-best-practices/references/recommended-template.md` | Recommended `CLAUDE.md` template + cheatsheet, loaded in `optimize`/`apply`/`create` modes |
| `claude-md-best-practices/references/claude-best-practices.md` | Anthropic's official best-practices doc (English) |
| `claude-md-best-practices/references/agents-md.md` | Addy Osmani's `AGENTS.md` research roundup (English) |
| `claude-md-best-practices/references/claude-md-common-mistakes.md` | termdock's 10-mistake write-up (English) |
| `install.sh` | One-liner installer that copies the skill into `~/.claude/skills/` |
| `LICENSE` | MIT |
| `README.md` | This file |

## The 16-point checklist (summary)

Grouped by the Phase 2 subagent that owns the check.

**Subagent A — Size, cache order, and core hygiene**

| # | Mistake |
|---|---|
| 1 | Context Stuffing |
| 2 | Static Learnings |
| 3 | Missing Plan Mode guidance |
| 4 | Weak Verification |
| 5 | Undocumented Permissions (team) |
| 6 | No Format Standards |
| 11 | Cache-Hostile Ordering |

**Subagent B — Documentation sync and `docs/` health**

| # | Mistake |
|---|---|
| 7 | Stale Documentation |
| 8 | Missing `docs/` Index |
| 9 | Orphan Docs |
| 10 | Code-Doc Drift |

**Subagent C — Modularity, emphasis, memory**

| # | Mistake |
|---|---|
| 12 | Instruction Overload (>150) |
| 13 | Missing Modular Rules |
| 14 | No Feedback Loop |
| 15 | Critical Rules Not Emphasized |
| 16 | `MEMORY.md` Truncation |

Full table with symptoms and fixes lives in `claude-md-best-practices/references/anti-patterns.md`.

## Target metrics

- **Ideal `CLAUDE.md` size:** ~2.5k tokens (~100–150 lines)
- **Maximum recommended:** 4k tokens
- **Warning threshold:** 5k+ tokens (causes context rot)
- **Instruction cap:** ≤ 150 imperative rules across `CLAUDE.md` + `.claude/rules/`

## References

- [Anthropic — Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Addy Osmani — AGENTS.md as a living list of code smells](https://addyosmani.com/blog/agents-md/)
- [termdock — 10 common CLAUDE.md mistakes](https://www.termdock.com/zh/blog/claude-md-common-mistakes)
- [Lulla et al. — ICSE JAWs 2026 paired experiment](https://arxiv.org/abs/2601.20404)
- [ETH Zurich — Evaluating AGENTS.md (Gloaguen, Mündler, Müller, Raychev, Vechev)](https://arxiv.org/abs/2602.11988)

## Contributing

Issues and pull requests welcome. If you find a `CLAUDE.md` anti-pattern not covered by the 16-point checklist, open an issue with a concrete example.

## License

MIT — see [LICENSE](LICENSE).
