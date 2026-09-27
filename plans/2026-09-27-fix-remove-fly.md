# fix: remove Fly references from fork docs

Status: approved

> Amends the plan's own prior revision: the AGENTS.md, OPERATIONS.md, and
> deployment/fly/README.md items are the original scope the user requested
> for this plan; the user's amendment adds the README.md item and removes
> the PASEO-README.md constraint. No scope beyond that original request
> plus this amendment.

## Provenance

- main: `7efbf29` — 2026-09-27
- upstream-rebrand: `4c34ff2` — 2026-09-27
- upstream/main: `3fc41c9` (untagged) — 2026-08-22

## Scope

**In scope:**

1. `AGENTS.md`: the remaining Fly narrative (lines 25–28) replaced by an
   explicit rule: this fork does not deploy on Fly and Fly must not be used
   for any deployment work here; the Fly adapter is upstream's, absorbed by
   the rebrand, kept only as an inherited artifact under
   `deployment/fly/`, and `AGENTS.md` is the authority that overrides any
   Fly-sounding language elsewhere in the repo.
2. `README.md`: all Fly narrative removed — the six Fly sites (lines 68,
   129, 165–167, 172, 175, 189–190) rewritten provider-neutrally — and
   replaced by exactly one pointer line linking
   [`deployment/fly/README.md`](deployment/fly/README.md). No `FLY_`
   variable names remain in `README.md`; Fly procedure, adapter behavior,
   `fly-replay`, and configuration detail live only in the Fly deployment
   documentation.
3. `OPERATIONS.md`: Fly-specific narrative (capacity model, failure
   behavior, incident guardrails, metrics — lines 36–121, 245–273,
   321–357) rewritten in provider-neutral language; section structure and
   heading order preserved.
4. `deployment/fly/README.md`: absorbs the operational items only
   `OPERATIONS.md` and `README.md` currently carry — hard-limit semantics,
   restart-vs-replace-on-fresh-host guidance, no-repeat-restart rule —
   so removing them from `OPERATIONS.md` loses no guidance. This absorption
   exists only to service item 3's rewrite; it is not an independent
   content-migration decision.

**Not in scope:**

- Everything else. No code, no scripts, no tests, no config, no CI, no
  `TDD.md`, no renames of anything. Only the four files in the mitigation
  table change.

## Acceptance criteria

1. `git diff main --stat` shows changes only to `AGENTS.md`, `README.md`,
   `OPERATIONS.md`, and `deployment/fly/README.md`.
2. `git grep -in "fly" -- README.md OPERATIONS.md` returns only lines
   referencing the `deployment/fly` path or its files; any residual line is
   listed in the step report for your judgment.
3. `git grep -in "FLY_" -- README.md` returns nothing.
4. `README.md` contains exactly one line linking `deployment/fly/README.md`.
5. Every edited block carries the fork tag
   (`git grep "RAMBLA-FORK:" -- <the four files>` shows it).

## Goal

Remove Fly-as-operating-model bias from the fork's own top-level docs so
agents working here stop treating Fly specifics as this relay's contract.
`AGENTS.md` is where agents get their rules, so the no-Fly rule lives there
and outranks any Fly-sounding language anywhere else in the repo — that is
how upstream's verbatim docs are handled without touching them.

## Merge conflict mitigation

**Files this work changes:**

| File                       | Edit                                                    | Upstream activity                            | Tag                 |
| -------------------------- | ------------------------------------------------------- | -------------------------------------------- | ------------------- |
| `AGENTS.md`                | Fly narrative → explicit no-Fly rule, marked as authority | last touched by rebrand `3c5cb93` 2026-09-26 | `RAMBLA-FORK: fix:` |
| `README.md`                | six Fly sites → provider-neutral prose + one pointer line | last touched by rebrand `4c34ff2` 2026-09-27 | `RAMBLA-FORK: fix:` |
| `OPERATIONS.md`            | provider-neutral rewrite of the Fly narrative sections  | last touched by rebrand `3c5cb93` 2026-09-26 | `RAMBLA-FORK: fix:` |
| `deployment/fly/README.md` | absorb the operational items from `OPERATIONS.md`/`README` | last touched by rebrand `3c5cb93` 2026-09-26 | `RAMBLA-FORK: fix:` |

**Why this shape:** all four files are fork docs, all last touched by our
rebrand commits; edits stay inside blocks the rebrand already owns, so
the conflict surface is one rebrand-wide merge. `OPERATIONS.md` keeps its
section structure; only prose changes.

**Branch:** `fix/remove-fly-doc-bias`

## Cause

The rebrand commit `3c5cb93` brought in upstream's docs nearly unchanged and
`4c34ff2` folded upstream's README into ours still carrying its Fly
narrative: upstream's author runs this relay on Fly, so `README.md`
(`README.md:68,129,165-167,172,175,189-190`), `AGENTS.md`, and
`OPERATIONS.md` speak Fly specifics as this relay's contract, misleading
agents working on the fork.

## Constraints

- No file outside the mitigation table changes — no scripts, no tests, no
  `TDD.md`, no code.
- `README.md` keeps exactly one Fly-related line: the pointer to
  `deployment/fly/README.md`. No `RAMBLA_FLY_*` variable names, no
  `fly-replay`, no Fly procedure or adapter narrative anywhere in it.
- `deployment/fly/README.md` is the single home for Fly detail; nothing is
  duplicated back into the top-level docs.
- `OPERATIONS.md` section structure and heading order are preserved.
- Nothing is renamed — not variables, not files, not names in prose.
- No new procedural content is invented beyond the absorbed items in
  `deployment/fly/README.md`.

## Steps

1. On branch `fix/remove-fly-doc-bias`, make the four doc edits per the
   mitigation table, each block tagged `RAMBLA-FORK: fix:`.

   **Acceptance criteria:** criteria 1–5 hold; the residual-line list for
   criterion 2 is in the step report for your review.

## Verification

- `git diff main --stat` shows exactly the four files.
- The criterion 2–5 greps return only what the criteria allow.
- Step report records the diffs and the residual-line list.

## Risks

- None known. Removing the Fly narrative is the goal, not a loss; Fly
  detail remains in its one intended home, `deployment/fly/README.md`,
  reached through the single pointer line.
