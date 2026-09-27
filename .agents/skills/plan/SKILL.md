---
name: plan
description: Plan a fix, feature, or refactor in the Rambla relay fork. Every plan opens with a merge-conflict mitigation section that keeps merges from upstream small and conflict-free. Use whenever the user asks to plan work in this repo, or before writing code for a fix or feature here.
---

# Planning work on the Rambla Relay fork

Rambla Relay is its own product, permanently forked from upstream Paseo
Relay. Merges come from upstream, nothing goes back, so every line we touch
in an upstream file can conflict on every future merge. The code lives at
this repo's root: Elixir sources in `lib/`, tests in `test/`.

## Mandatory reads before any plan

Read, in this order, before planning anything: **`AGENTS.md`** (the repo's
binding rules — every agent reads this even if its harness never
auto-loads it), **`TDD.md`** (the testing discipline), and
**`OPERATIONS.md`** (how the relay runs and its invariants).

**Do not redesign.** This relay is mission-critical infrastructure with a
frozen public protocol. The plan may not propose structural changes,
dependency changes, protocol changes, or renames beyond the rebrand — those
require the user's explicit direction and are out of scope by default.

**Test-first, always.** This repo runs on test-driven development, full
stop, because the relay is mission-critical infrastructure and every edit
carries that weight. The plan's steps are written so the test comes FIRST —
before the code it verifies, in every step of every plan. Nothing is merged
or considered done until its tests exist and pass; a plan that cannot say
how a step will be tested is not ready to write.

## When rules conflict

If any rules conflict or one cannot be followed, stop and ask the user — never improvise an exception.

## The plan stays short

Past ~500 words of your own prose on a routine plan, you are implementing inside the plan file: stop and strip back to scope, files, and steps.

## What a plan is

- **A constraint on the coder, not a script for one.** It states the outcome,
  the scope, the files, and the limits.
- **Acceptance criteria at both levels.** A numbered `## Acceptance criteria`
  section the user approved, and criteria ending every step. Criteria are
  what coder and reviewer check against; instructions are hints — when a
  result contradicts a criterion, the criterion wins. A step with
  instructions but no criteria is incomplete.
- **No implementation code.** No function bodies, no exact import
  lines, nothing the coder could paste. A hard-to-describe shape is sketched
  as a type or signature: at most 5 lines, no bodies, no defaults, no inline
  comments. Never reproduce library or API documentation; the coder
  may search docs.
- **Citations only for load-bearing facts.** A claim about this repo's code
  that a placement or scope decision rests on is a `file.ex:120` link.
  Nothing else gets a citation; no unverified claim goes in.
- **Public record.** Written to `plans/YYYY-MM-DD-fix-<slug>.md` (or
  `feat-`), 1 file, nothing else in it. The plan never links outside the
  fork repo.

## Who does what

- **Supervisor — you, the planner.** Hold the request, decide scope and
  placement, ask the user, write the plan, report. The only writer of the
  plan file.
- **Researcher — a subagent, mandatory.** Runs the repository searches;
  returns files, line numbers, citations. No placement opinions, ever.
- **Reviewer — 1 subagent, blind.** Spawned with the fixed prompt below,
  never this skill.

Subagents run the same model as you, unless the user says otherwise — omit
`provider`/`model` when spawning; pass one only if the user asked.

**NEVER run a command that discards work you didn't write** — no `git
checkout`, `restore`, `stash`, `reset --hard`, or `clean`. Other agents
work in this checkout; uncommitted changes are theirs. If one overlaps a
file your plan needs, ask the user and wait — uncommitted work has no undo,
and one `git checkout` has destroyed hours of another agent's work here.

## Reading rules

- **The supervisor never searches the repository.** Repo-wide grep is
  researcher work. Open only files the researcher named, ±30 lines around a
  load-bearing spot; files flagged large (2000+ lines) as exact ranges only.
  Reading a whole large file fills your context and degrades the plan.
- **Never read or grep a minified file — not even partially.** They are 1
  line and hundreds of KB; any read or grep returns the whole line and
  buries the context. To learn what a bundled library does, search that
  library's documentation. Report a minified file as minified and move on.
- A researcher is reusable: send it follow-up questions as they come up. When
  its context is bloated by a broad search and the next question is narrower,
  spawn a fresh researcher for that question instead.

## Workflow

1. **Frame the request.** Restate it as a scope guess in chat — 2 lines, not
   a plan.
2. **Spawn the researcher** with the fixed prompt below. It returns file
   paths and line numbers.
3. **Spot-check and decide.** Open the named regions, decide placement per
   the rules below. More research needed? Back to the researcher, never your
   own searching.
4. **Confirm with the user.** Confirm scope, then propose the shape (see
   "Ask the user"): the design or architecture, the step breakdown or the
   decision to have 1 step, and the numbered acceptance criteria. The user
   may approve, edit, or replace the criteria; approval is explicit and
   precedes writing the plan. Skip the shape question only when the
   placement rules yield exactly 1 path and no upstream code is copied —
   scope is always confirmed, criteria never skipped.
5. **Write the plan.** Check the plan against the skeleton above — that is
   the style checklist here; this repo has no style checker — then spawn the
   blind reviewer, fix
   and re-review (see "Every plan is reviewed"). Report and stop.

### Researcher prompt — fill the blank, change nothing

```markdown
You are a fact gatherer for a plan in this repo. Find where <REQUEST> lives:
which files, modules, and line numbers are involved. Return facts only —
paths, line numbers, quotes of at most 3 lines. No placement opinions, no
recommendations. Never read or grep a minified or 1-line file — not even
partially; report it as minified and move on. If the question is about a
bundled library, search its documentation instead. Flag any file over 2000
lines.
```

## Ask the user when a decision is theirs

Ask in plain English, multiple choice, at most 3 options, your recommendation
first, each option's cost in 1 line. Wait for the answer before writing.

- **Copying upstream code into a `*_rambla.ex` module always goes to the
  user.** Editing their file keeps their future fixes and risks conflicts;
  copying ours conflicts never and hears from upstream never.
- **If the request needs no decision, do not ask and do not invent
  alternatives.** Adding a switch to an existing settings section never means
  proposing a new settings page — that is scope invention.
- Anything else this skill does not clearly cover: ask.

## Scope

The scope is exactly what the user asked — not rounded up, not trimmed
where it is awkward. The mitigation
table is binding: every file this work may create or edit gets a row —
tests included. No file outside the table may change.

## Acceptance criteria

Propose them with the shape of the plan, before breaking work into steps
(workflow step 4). Draft them yourself; restating the user's own criteria
still counts as a proposal. Numbered — the user approves by number, steps
cite by number.

- Testable: an automated test can assert it. The relay has no UI — every
  criterion is behavior a test can exercise through the relay's real
  interface (a WebSocket client, a control call), not implementation-internal.
- Observable through the real interface, not implementation-internal.
- No section, or unapproved criteria, means no plan.

## Plan status

The first line under the title is one line:

```
Status: unapproved | approved | coding | done
```

No other statuses, no timeline, no dates — the file date and git history
cover that. `unapproved` on write. The user approving criteria + plan, plus
the reviewer's ACCEPT, make it `approved`.

**Status transitions are the one exception to plan-file read-only, and
they belong to the supervisor alone.** The plan file is otherwise
read-only to every agent, forever (the `code` skill binds this). The
supervisor sets `approved` when the reviewer's ACCEPT and the user's
approval are both in hand; the supervisor sets `coding — 3f2a1b9,
completed through step 2` (last commit hash, steps completed) as the coder
reports steps accepted, and `done` when the final step lands. The coder
and reviewer never touch the file; they report, the supervisor writes.
Never code a plan that is not
`approved`.

## Steps and the accept-reject loop

- **Large plans are broken into steps; small plans are not.** You decide
  from the research, and say so when proposing the shape; the user can
  override. A 1-step plan is a single work item, never labeled "step 1";
  the plan-level criteria are its criteria. Only multi-step plans number
  their steps.
- **Steps are closed.** Each step ends with its red test written first and
  failing, then the code that passes it, its red/green evidence recorded in
  `TDD.md` (the `code` skill's Tests section requires this — `AGENTS.md`
  makes it mandatory for every behavior change), a commit, and the status
  line updated. The app may be mid-feature between steps; the step itself
  works.
- **Each step runs its own accept-reject loop with a fresh coder and a
  fresh reviewer** — never reuse a coder across steps. The reviewer checks
  the code against that step's criteria, you present the step to the user
  (what was done, what it looks like, how it was tested), then the next
  step starts.
- **Decide where the user weighs in, and write it into the plan.** Mark
  the steps where the user reviews the result before the plan continues.
  Err toward more user involvement when the step touches protocol or
  load-bearing relay behavior.

## Every plan works on its own new branch — no exceptions

Every feature or fix happens on a new `feat/<slug>` or `fix/<slug>` branch,
named from the plan's title. **Work never happens directly on main** — not
for one-step plans, not for small fixes, not ever. There is no one-step
exception: a 1-step plan still gets its own branch. Main is the fork's
release line; it receives only reviewed, merged plan branches.

## Merge conflict mitigation

Every file gets a deliberate placement decision. Decide with the rules
below, record in the skeleton's mitigation table. A revision gets better,
never longer.

## Placement decision

First match wins.

1. **New code with no upstream counterpart** → new `*_rambla.ex` (or
   `_rambla_test.exs`) file. Any
   size; a new file can never conflict.
2. **Replacing most of an upstream function** → ask the user
   first (see above). Never on your own judgment.
3. **Changing some of upstream's logic** → our logic in a `*_rambla.ex`
   helper module, called in 1 line at the upstream site.
4. **At most 5 changed lines** (a guard clause, a wrong default) → edit in
   place, minimally.

Before deciding, ask the researcher how this app already does this kind of
thing, and say so in the plan with a citation when it drives the placement.

Inside upstream files: our edits in 1 contiguous block per file; new imports
at the END of the import block; every diverging site tagged with the one-line
fork tag (format in the `code` skill — category and plan file name are
decided here, so write the tag into the plan's step for that edit); never
reformat, rename, or move upstream code you are not changing. If upstream
already fixed the same problem, say so and cite the upstream commit; the
coder ports it verbatim — its code never enters the plan.

Upstream activity for the table comes from
`git log upstream-rebrand -- <path>`. **Always `upstream-rebrand`, never
`upstream/main`** — main is unrebranded, so the diff shows every rebrand
line as a change, or is empty.

**Branch:** every plan gets its own `feat/<slug>` or `fix/<slug>` branch —
see "Every plan works on its own new branch — no exceptions" above. State
the branch name here regardless of how many files the table has.

## How git decides conflicts — do not relitigate this

Per file, git merges both sides' changed line ranges silently when even
1 unchanged base line separates them; touching or overlapping ranges
conflict. New files never conflict. A `_rambla` file is ours alone —
upstream never has it, so it never conflicts. Every other file, including
upstream's test files, can conflict. Line counts are not the measure —
which files change, and how active upstream is in them, is.

## Provenance

3 bullets, no prose — everything below is predicated on this state. Run
`just provenance` from the repo root:

```bash
# 1. main — what the plan is written against
git log -1 --format='- main: %h — %cs' main

# 2. upstream-rebrand — the rebrand commit main last took
r=$(git merge-base main upstream-rebrand)
git log -1 --format='- upstream-rebrand: %h — %cs' "$r"

# 3. upstream/main — the upstream commit that rebrand was made from
u=$(git merge-base upstream-rebrand upstream/main)
git log -1 --format='- upstream/main: %h — %cs' "$u"
```

Never read a hash from a commit's subject line — a commit message is
whatever the author typed, never a source of truth. Bullet 2 works for both
this repo's history shapes: main currently descends linearly from the seed
rebrand commit, and future rebrands arrive as merge commits; merge-base
finds the newest rebrand commit main contains either way.

For the tag on bullet 3: upstream is fetched with `--no-tags`, so
`git describe` can't name it — `git ls-remote --tags --refs upstream` gets
it in 1 network call; if nothing contains that commit, write `(untagged)`.
Never blank, never guessed.

## Required output

The plan uses this exact skeleton, in this order.

```markdown
# fix: <short title> <- or "feat: <short title>"

Status: unapproved

## Provenance

- main: `d89926e8a` — 2026-09-22
- upstream-rebrand: `61b044d8b` — 2026-09-21
- upstream/main: `135a3b4c9` (untagged) — 2026-09-21

## Scope

**In scope:**

1. <Each thing this work delivers, one per line. Nothing vague.>
2. ...

**Not in scope:**

- <Each adjacent thing this work deliberately does not touch. Name the
  tempting ones — the neighbouring bug, the refactor the file is begging
  for. If it isn't listed here and isn't in the list above, it isn't
  happening.>

## Acceptance criteria

1. <Numbered, testable, observable through the real interface. The user
   approved this exact list before the plan was written; steps cite these
   numbers.>
2. ...

## Goal

<One or two sentences: what bug is fixed or what feature is added.>

## Merge conflict mitigation

**Files this work changes:**

| File                                | Edit                                      | Upstream activity                         | Tag                 |
| ----------------------------------- | ----------------------------------------- | ----------------------------------------- | ------------------- |
| `lib/rambla_relay/foo.ex`           | one alias + one call into the new module  | last touched 3 weeks ago, twice this year | `RAMBLA-FORK: fix:` |
| `lib/rambla_relay/thing_rambla.ex`  | <what lives there>                        | new                                       | `RAMBLA-FORK: fix:` |
| `test/thing_rambla_test.exs`        | <what it covers>                          | new                                       | `RAMBLA-FORK: fix:` |

Fill the activity column from `git log upstream-rebrand -- <path>` for every
file without `_rambla` in its name. Files with `_rambla` in the name are ours alone
and can never conflict, so their activity entry is just `new` or `existing`.
The Tag column states the fork tag's category for that file; the coder
writes the full tag (category, plan file name, one clause) per block.

**Why this shape:** <one or two sentences — the judgment call, stated so a
reviewer can disagree with it. What we'd lose by copying more, what we'd risk
by editing more.>

**Branch:** `fix/<slug>` — every plan works on its own new branch.

## Cause

<Only for a fix. Two to four sentences, in prose, never as a code quote:
what actually goes wrong, in the
code, with `file.ex:120` references. Traced, not guessed — if you haven't
found it yet, you aren't ready to write the plan.>

## Constraints

<The coder's limits, as bullets: files that may not change beyond the table,
behavior that may not change, code that may not be added (abstractions,
options, error handling for impossible cases), upstream tests that may not
be touched.>

## Steps

0. Read the `code` skill before writing anything. If a step below turns out
   to be wrong, stop and report back to the supervisor — do not amend this plan
   and do not re-decide placement while coding.
1. <One action per step. Name the file. Say what changes — never how.
   End the step with its **Acceptance criteria** — testable conditions the
   step's code must satisfy, citing the plan-level criteria it delivers
   where it does. When the user reviews this
   step's result before the plan continues, say so here.>
2. ...

## Verification

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `ulimit -Sn 100000` then `mix test test/<your_test_file>.exs`
- Red/green evidence for every step recorded in `TDD.md`, in the format of
  the existing entries.
- `git grep "RAMBLA-FORK:" -- <each upstream file edited>` — every one must
  show a tag.
- <Anything that has to be seen working over a real WebSocket, named
  specifically.>

## Risks

<Bullets. What could break elsewhere. "None known" is a valid answer if
you've actually looked.>
```

If the plan needs a merge-conflict decision you cannot make, say so in the
table's place instead of guessing, and stop for the user.

## Every plan is reviewed

Before review, check the plan against the skeleton above and fix silently —
style is never the reviewer's job and never the user's. (rambla has a
`fork/check-plan.mjs` style checker; this repo's plan count doesn't justify
one yet — the skeleton is the checklist.)

### Reviewer prompt — fill the 2 blanks, change nothing

```markdown
You are reviewing a plan for the Rambla relay fork. Do not trust it.

The user's request, verbatim: <REQUEST>

The plan: plans/<FILE>

Read the plan, then open every existing file in its mitigation table —
every row that names a file on disk; rows for files the plan will create
name nothing yet, so note their placement and move on. Never
read a minified file; for files over 2000 lines, read the cited
regions plus the edit sites, not the whole file. Judge errors in this order: 0. implementation code in the plan — function bodies, import lines,
pasteable snippets; the only allowed sketch is a type or signature of at
most 5 lines; 1. a placement decision the user was
never asked; 2. a claim the code does not support; 3. a file the edit needs
that the mitigation table misses; 4. scope beyond the request; 5. a
described edit that cannot fit the current code — a name already taken, a
function not where the plan says; 6. a step without acceptance criteria,
or criteria too vague for a test to assert, or steps whose red/green
evidence duty (TDD.md) the plan never provides for; 7. a status line that
is anything but `unapproved` — plans are reviewed before approval, and
your ACCEPT is what lets the user approve it. "Does it compile" is not your job — the
code does not exist yet. Style, wording, and link format are not your
job. Reply ACCEPT, or REJECT with a numbered list, each item backed by
file.ex:120 evidence you opened yourself.
```

**Fix and re-review, at most 2 rounds.** Still rejected after that: stop and
bring both positions to the user to decide.

## Review round templates

Use these exactly. They are the only thing the user gets between rounds.

**Link the plan file in exactly 3 places, and nowhere else:** when you send
it for review, when the reviewer rejects, and when the reviewer accepts.
Change reports never link it.

The link is chat, and the link text is
the filename. The target starts at the workspace root —
`rambla-relay/plans/<file>`. Never a filesystem-absolute path: no
`/home/...` target in chat or in any file, ever. Links written inside
repo files (a plan, the changelog) are relative to that file instead:

```markdown
Sent [2026-09-22-feat-load-client-diagnostics.md](rambla-relay/plans/2026-09-22-feat-load-client-diagnostics.md) for review.
```

**Reviewer rejected:**

```markdown
The reviewer rejected [2026-09-22-feat-load-client-diagnostics.md](rambla-relay/plans/2026-09-22-feat-load-client-diagnostics.md).

Accepted 6 of 7 items. Rejected:

1. <the specific thing, and briefly why — 25 words maximum>
2. ...
```

Never reproduce the reviewer's own words.
Don't say what happens next — going back for a fix is understood.

**Reviewer accepted:**

```markdown
The reviewer accepted [2026-09-22-feat-load-client-diagnostics.md](rambla-relay/plans/2026-09-22-feat-load-client-diagnostics.md), all 7 items:

1. <what the item is — 25 words maximum>
2. ...

Files to change:

- [socket.ex:120](rambla-relay/lib/rambla_relay/socket.ex#L120) — <what changes there>
- ...

Conflict mitigation: <the approach in 25 words or less>
```

File references inside the plan file are relative (`../lib/rambla_relay/...`).

## Reporting to the user

Report every plan change as it happens, 1 line each. Close with a final
report: where the plan stands, for a reader who saw none of the updates.
Decided things, never reasoning. Concerns first. No effort, no line counts.
Read git and test output yourself; say what it means in 1 line.

## Planning ends when the user approves

The status line stays `unapproved` until both have accepted: the reviewer,
then the user. Then flip it to `approved` — the one
edit allowed to you, per "Plan status" above. Bring the user the plan and
the verdict, and **stop
there**: no code, no tests, no branch, no head start. The `code` skill runs
from an `approved` plan; the supervisor continues to own the status line
(`coding`, `done`) from there.
