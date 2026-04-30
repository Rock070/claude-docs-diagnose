# Recommended CLAUDE.md Template + Cheatsheet

> Loaded on demand by `claude-docs-diagnose/SKILL.md` in `optimize`, `apply`, or `create` modes. Use the template as the structural baseline when generating or rewriting a CLAUDE.md. Keep output ≤ 150 lines / ~2.5k tokens.

---

## Recommended structure template

````markdown
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
````

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
> 1. If Claude can find it itself → don't write it
> 2. Static on top, dynamic on the bottom
> 3. Prune monthly; cut every line that hasn't made Claude better

> **Three numbers to remember:**
> - **2.5k tokens** = target
> - **150** = instruction ceiling
> - **200** = MEMORY.md line cap before truncation

> **One workflow to internalize:**
> Correct Claude → immediately say "update CLAUDE.md" → audit monthly and cut redundancy
