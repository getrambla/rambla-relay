---
name: code
description: Implement a fix or feature in the Rambla fork of upstream Paseo Relay, following an approved plan's merge-conflict mitigation table. Covers the starting gates (approved plan, committed plan, right branch), the mandatory reads (AGENTS.md, TDD.md, OPERATIONS.md), where code is allowed to go, how small an edit in an upstream file has to be, tagging divergences, per-step commits and review, which tests to run, and when to stop and ask. Use when writing or changing code in this repo, or when implementing a plan from the plan skill.
---

# Writing code in the Rambla Relay fork

## Where the code is

**The repo root is the code** — this is a permanent, terminal fork of
upstream `getpaseo/paseo-relay`, rebranded by script. Every module, test,
and mix task lives at the root, and that is where commands run. Elixir
sources are in `lib/`, tests in `test/`.

Nothing is ever contributed upstream and the fork is never rebased. Upstream
is merged in via the rebrand branch, roughly monthly, forever.

**Do not redesign.** This relay is mission-critical infrastructure with a
frozen public protocol. Structural changes, dependency changes, protocol
changes, and renames beyond the rebrand require the user's explicit approval
in the plan — never the coder's or planner's judgment.

**Test-first, always.** This is mission-critical infrastructure, and every
edit is treated with that gravity: the failing test is written FIRST, before
the code it verifies, in every step of every plan. Nothing is done until its
tests exist and pass. "Tests" below is not a phase at the end — it is how
every step begins, and `TDD.md` governs the details.

## Who does what

Three roles, kept separate.

- **Supervisor** — holds the user's request, the plan, and the reviewer's
  verdicts. Reads little itself — see "The supervisor reads little" below.
  The supervisor briefs the coder with each step's **acceptance criteria**
  from the plan — what must be observably true when the step is done — and
  nothing else. The brief may not contain numbers, formulas, designs, or any
  implementation instruction of any kind that does not come from the plan or
  the user. If the supervisor believes it knows the cause or the fix, that
  is for the coder to find; state it as a question to confirm or refute,
  never as an instruction.
- **Coder** (a subagent) — writes the tests and the code. Edits code only.
- **Reviewer** (a separate subagent) — checks the work against the plan and
  against this skill's rules. Never the agent that wrote the code. Reviewing
  is read-only: it reports, it does not fix.

Subagents run the same model as the supervisor, unless the user says
otherwise. When spawning subagents, do not set the provider/model fields —
omitting `provider` runs the new agent on your own provider and current
model. Pass a provider/model only when the user asked for a different one.

**Accept/reject loop, every time.** The reviewer returns ACCEPT or REJECT.
ACCEPT means all three: the work matches the plan, the reviewer ran the tests
itself and saw them pass, and nothing changed outside the mitigation table.
REJECT is a numbered list of deficiencies, sent to the coder only. Re-review
is blind — re-send the same original instructions, never a summary of what
was fixed. **At most 2 fix-and-rereview rounds**; still rejected after that,
stop and bring both positions to the user to decide.

**The unit of review is the plan step.** Each step is one submission: the
coder codes that step (tests first, per the Tests section), then a fresh
blind reviewer verifies that step against its acceptance criteria before the
supervisor commissions the next. Multi-step plans start a **fresh coder and
a fresh reviewer for every step** — neither role carries over from the step
before. A step without an ACCEPT may not be built upon — reporting a step
as done without its reviewer verdict is a violation, not a shortcut.
Reviewing several steps in one batch after the fact is not compliance; it
is the violation this rule exists to prevent.

**The plan file is read-only — no agent edits it, ever.** The coder, the
reviewer, and the supervisor may read it; not one of them may edit it,
and none may quietly work around it. When the plan turns out wrong,
incomplete, or inconsistent with the code: stop and report to the
supervisor with your reasons — do not re-decide placement mid-edit. The
supervisor takes it to the user, work stays stopped, and the user amends
the plan in a separate planning session if they agree. A plan exists for
every task sent to implementation; whether one is needed is never the
coder's call.

## Step 0 — read these first

Before any planning or coding in this repo, these files are **mandatory
reads**, in this order:

1. **`AGENTS.md`** — the repo's binding rules. Every agent reads this before
   touching anything, even if its harness never auto-loads it.
2. **`TDD.md`** — the testing discipline. Tests are not optional here.
3. **`OPERATIONS.md`** — how the relay runs, its invariants, and what may
   never change casually.
4. **The plan** for this work, in `plans/`. Its mitigation table is the
   complete list of files that may be created or edited — a contract, not
   a suggestion. Its Provenance section says which commit of main the plan
   was written against — if main has moved since, every line number in it
   is suspect, so say so before starting.
5. **The `plan` skill**, sections "What a plan is" (the citation rule) and
   "How git decides conflicts — do not relitigate this". This skill is how
   you apply them while coding, and does not repeat the reasoning behind
   them.

## Starting the work — the three gates

Before the first line of code, pass all three, in order:

1. **The plan is approved.** The plan's `Status:` line reads `approved`.
   Anything else — **STOP and tell the user.** Nothing is coded against an
   unapproved plan.
2. **The approved plan is committed.** If the plan file sits uncommitted in
   the working tree, commit the plan file itself as part of the coding
   work, before the first code step. That commit records the user's
   approval; it is not an edit, and the plan stays read-only after it.
3. **The branch is right.**
   - On a `fixes-YYYY-MM-DD` branch — parallel work with other agents:
     ask the user to confirm they want this plan done in parallel with the
     others, and include the plan's complexity in the message — whether it
     is a 1-step simple plan or a multi-step complex plan. Start only
     after they confirm.
   - On main: check out a new `feat/<feature-name>` or `fix/<fix-name>`
     branch, named from the plan's title. **Never work directly on main.**
     There is no one-step exception: every plan, including a 1-step plan,
     gets its own new branch. Main receives only reviewed, merged plan
     branches.

## Reading rules

These rules bind the coder AND the reviewer.

- **Never read or grep a minified file — not even partially.** They are 1
  line and hundreds of KB; any read returns the whole line and buries your
  context. To learn what a bundled library does, search its documentation.
- **Files over 2000 lines are named ranges only.** Read the regions the plan
  cites, not the file.
- **Read what the work needs, inside the plan's files.** The whole function
  you are changing, the regions the plan cites, a caller in another file
  when behavior depends on it, the test file — reading is how you avoid
  coding against a guess. No repo-wide searching for context.
- You are a throwaway subagent: if your context fills up, stop and report
  to the supervisor so it can start a fresh coder for the remaining steps.
  A replaced coder loses nothing — its finished edits stay in the working
  tree, and the next coder continues from them.

## The supervisor reads little

The supervisor delegates reading, not just writing. It does not read diffs,
logs, or code to check the work — the reviewer's ACCEPT is how it knows.
It does no research, no diagnosis, and no verification: it never opens a
file to investigate a failure, never forms a diagnosis, and never hands a
cause or a fix to a coder. When a failure needs investigating, that is the
coder's job; the supervisor relays where the evidence lives — as a location,
phrased as a question to confirm or refute — and only investigates itself
when the user directly asks it to. The supervisor never runs the project's
tests to verify work; verification belongs to the coder and the reviewer
alone.

## If a step's tests fail

If tests fail during a step, the work goes back to the coder — always, with
no exceptions. The re-dispatch brief contains only: the failing observable
behavior, where the evidence lives (paths), and the acceptance criteria that
must hold. The supervisor decides nothing about the cause and prescribes
nothing about the fix; a coder who cannot find the cause stops and reports,
and the supervisor escalates to the user rather than filling the gap itself.
A coder whose context goes bad mid-step stops and a
fresh coder takes over for the next step — the stalled coder's finished
edits stay in the working tree, and the fresh one continues from them.

## The placement rules, in one screen

The plan skill's "Placement decision" is authoritative. The coder's working
form:

- New function, module, struct, callback, constant table → **new
  `*_rambla.ex` file.** Any size. A new file cannot conflict, ever.
- Replacing most of an upstream function → our version in a
  `*_rambla.ex` module, under a different name, called from the upstream
  site. Their signature and call sites stay untouched.
- Changing some of upstream's logic → put the logic in a `*_rambla.ex`
  helper module, call it in **one line**.
- Changing a few lines where extracting would be sillier than the
  edit → edit in place, minimally. At most 5 changed lines.

Plus:

- **Keep our edits in one contiguous block per file.** Scattered one-line
  edits multiply the chances of colliding with upstream.
- **New aliases go at the END of the alias block, after a blank line.**
- **Every block of code we add or change gets a fork tag on the line
  above — one line, exactly this format. The comment token is `#` —
  this repo is Elixir:**

  ```
  # RAMBLA-FORK: <category>: <plan file name>: <what it does>.
  ```

  `<category>` is `feature` or `fix` — matching the plan's title (`feat:` →
  `feature`, `fix:` → `fix`). `<plan file name>` is the plan's exact file
  name, e.g. `2026-09-22-fix-load-client-diagnostics.md` — it points any
  future reader (a merge-conflict resolver, an auditor) to the plan that
  commissioned this code. `<what it does>` is one brief clause. One line,
  never more — the comment is a pointer, not an essay. Example:

  ```
  # RAMBLA-FORK: fix: 2026-09-22-fix-load-client-diagnostics.md: adds WebSocket error status reporting to the load client.
  ```

  This tag goes on every block in upstream files, in our own
  `*_rambla_*` files, and in test files alike — it is the code's audit
  trail. Never invent a category; the plan is where any question about
  category belongs — if a situation seems to need a category the plan did
  not name, stop and ask.

- **Never reformat, reorder, rename, or tidy upstream code you aren't
  fixing.** Keep their lines in their order.
- **Never rename or move upstream code.** A move is a delete plus an insert,
  and the delete conflicts forever.

## Before you touch any upstream file

```
git diff HEAD upstream-rebrand -- <path>
git log upstream-rebrand -- <path>      # any history = upstream's
```

**Always `upstream-rebrand`, never `upstream/main`** — it is unrebranded, so
the diff is noise or empty (see the plan skill, "How git decides conflicts").

If the plan names an upstream fix, **port it verbatim.** Do not invent a
parallel solution — an invented fix conflicts with theirs on the next merge
and we get the worst of both. If you find an upstream fix the plan didn't
name, stop and report to the supervisor.

## Write the minimum code that works

- No extra abstraction, no configuration nobody asked for, no error handling
  for cases that can't happen, no "while I'm here" cleanups.
- If the fix is three lines, it's three lines. Do not grow it into a module
  because a module feels tidier.
- This applies to production code only. Tests are ours, in our own
  `*_rambla_test.exs` files,
  and can be as thorough as you like.

## Tests

**Test-driven development is mandatory.** Write the failing test first, then
the code that makes it pass. A step's tests must assert that step's
**acceptance criteria** from the plan — each criterion traceable to at least
one test assertion. A step whose tests do not test its acceptance criteria is
not done, and a reviewer must REJECT it for that alone. This includes
end-to-end criteria: if a step's acceptance criteria are behavioral (a
client connects, a frame is relayed), the test reproduces that behavior
through the real WebSocket interface, not by calling internals. `TDD.md`
governs the details. Each step also records its red/green evidence in
`TDD.md`, in the format of the existing entries — `AGENTS.md` requires this
for every behavior change.

- `*_rambla_test.exs` files are ours, always — never upstream's. Every test
  file the work creates or extends has its own row in the table, marked
  `new` or `existing`. Tests never go inside upstream test files.
- **Never add tests to upstream test files, and never edit, delete, or skip
  an upstream test.** Not to make your change
  pass, not because the assertion looks outdated. When one fails:
  1. **If your code caused it** — a bug in your change, a wrong assumption
     about existing behavior — fix your code. Do not report it; it is yours.
  2. **If your feature or fix genuinely conflicts with the test** — the
     behavior the change requires is not what the test asserts — **stop all
     work**, and report to the supervisor: the test name, the failure
     output, and why you believe the change conflicts. The supervisor shows
     the failure to the user and asks what to do. Work stops until the user
     decides. Never edit, delete, or skip the test — not on your judgment,
     only on the user's explicit decision.
- A `@tag :skip` that carries a `RAMBLA-FORK: skip-test:` comment is an
  approved divergence the user already made. Leave it.

### Which tests to run

The toolchain is mise-pinned (`.tool-versions`); `eval "$(mise env -s bash)"`
first, or use the `just` recipes. Tests open hundreds of sockets, so the
open-files limit must be raised first or the load tests fail with `:emfile`:

```bash
ulimit -Sn 100000        # only if the current soft limit is lower
mix test test/<your_test_file>.exs
```

Run only the tests that intersect what you changed, plus your own. The fd
raise is required for any run that includes the load or backpressure suites;
plain unit tests do not need it.

**Never run the full suite.** No bare `mix test` at the repo
level. This binds the coder AND the reviewer. Several agents may be running at
once; full verification happens in CI (`scripts/ci.sh`), not here.

## When you're done

```
mix format --check-formatted
mix compile --warnings-as-errors
```

**A verification command that fails on a file in the table:
fix it and rerun. It fails on any other file: stop and report —
that is not yours to fix.**

Then:

- `git grep "RAMBLA-FORK:" -- <each upstream file you edited>` — every one
  must show a tag. An untagged divergence is one we lose at the next merge.
- Branch: decided at the starting gates — every plan works on its own new
  `fix/<slug>` or `feat/<slug>` branch. Never main.
- **Always run `just trial-merge` after the review passes** —
  every job, branched or not. It rehearses the upstream merge in a
  throwaway copy and never touches the real repo; `just trial-merge drop`
  cleans up. If it reports conflicts: do not resolve them in place, do not
  move our code, do not create modules the plan never named. Study the
  conflict, propose the resolution, and report it to the supervisor for
  the user — work stops until the user decides.
- **Commit each step as the reviewer accepts it**, on the plan's `feat/`
  or `fix/` branch — never to main. There is no one-step-on-main
  exception. Stage only files in the table — never another agent's
  files. The final step's commit is the final commit the changelog cites.
- **Every plan has its own branch: push it once the final code passes
  review**, so CI runs, and tell the user the branch name.
- **Parallel work on a shared branch — never push without the user's
  approval.**
- **Append the changelog entry.** Under `## Unreleased` in
  `RAMBLA-CHANGELOG.md`, add one bullet — under `### Added` for a
  `feature`, `### Fixed` for a `fix`. Together with the step's red/green
  evidence entry in `TDD.md` (see Tests), this is the only write allowed
  outside the table, ever. Format:

  ```
  - <YYYY-MM-DD> - [<short hash>](<commit URL>) - [<plan file name>](<plan file>) - <one user-visible sentence>.
  ```

  A filled example:

  ```
  - 2026-09-23 - [a1b2c3d](https://github.com/getrambla/rambla-relay/commit/a1b2c3d) - [2026-09-22-fix-load-client-diagnostics.md](plans/2026-09-22-fix-load-client-diagnostics.md) - Added WebSocket error status reporting to the load client.
  ```

  All entries share that shape, so dates, hashes, and plan links line up
  down the page. Field by field:
  - `<short hash>` — the 7-character git short hash of the final commit,
    linked to `https://github.com/getrambla/rambla-relay/commit/<hash>`. If the
    entry is written before that commit exists, the link text and URL are
    exactly 7 underscores `_______` (grep `_______` later to find unfilled
    entries). Changes that follow — a fix after review, another commit
    — amend the entry to the new final commit.
  - `<plan file name>` — the plan's file name as the link text, linking to
    the plan's relative path (`plans/<file>`). If the work had no plan
    file, this field is the plain text `(no plan)`.
  - `<one user-visible sentence>` — short, plain English, no links; start
    with the verb (`Added…`, `Fixed…`, `Renamed…`) and drop filler
    articles when the sentence stays clear (`Added WebSocket error status
reporting`, not `Added a toggle for the enabling of notifications`).
    Create either `###` heading if it is not there yet. The fork tag in the
    code and this line are the whole audit trail. Last step.

## Stop and ask

- **The plan's step has no acceptance criteria, or criteria too vague to
  test** (e.g. "works correctly", no observable check). A step that cannot
  state how it will be verified cannot be executed on trust: stop and report
  to the supervisor — "this step has no acceptance criteria I can code
  against" — and the supervisor takes it to the user. Do not invent criteria
  silently and proceed; do not translate instructions into your own idea of
  done.
- **The plan turns out to be wrong, incomplete, or inconsistent with the
  code.** Stop and report to the supervisor, who takes it to the user with
  your reasons in a handoff. Only the user edits a plan, ever — through a
  separate planning session. Do not re-decide placement mid-edit, do not
  work around it.
- **An upstream test fails and the change conflicts with what it asserts** —
  stop all
  work and report to the supervisor: the test name, the failure output, why
  the change conflicts. The supervisor shows the failure to the user and
  asks. Work stops until the user decides. (A failure your own code caused
  is not this: fix your code.) Never edit, delete, or skip an upstream test
  on your own judgment.
- Upstream already fixed this a different way (say in plain English what
  they did and how it differs).
- The change needs an identifier rename that upstream also names.
- **Git identity is the user's, always.** Never run
  `git config` (user.email, user.name, or anything else), even for a
  temporary clone or worktree. Git is already configured globally and
  inherits everywhere. If identity is ever missing, that is a stop-and-ask,
  not a default to pick.
- **Anything else this skill doesn't clearly cover.** Ask rather than pick.

## The scope is the plan's scope

Do exactly what the plan says. Not more, not less. Not the obvious
improvement next to it, not the half of it that seems sufficient.

**The mitigation table is the complete list of files that may be
created or edited — tests included, every one with a row.** No other file
gets created or edited — not a config line, not a one-line
import fix somewhere else, not a rename that "has to happen anyway". If the
work appears to need a file that isn't listed, stop and report to the
supervisor. That is a hole in an approved plan, and only the user can widen
it. The reviewer rejects on any file outside the table, whatever the reason.

**Other agents work in this checkout at the same time.** Before writing
anything, check every file in the table with `git status --porcelain`:
if any of them carries an uncommitted change you didn't make, stop and
report to the supervisor — begin only when the table's files are clean.
After that, uncommitted changes and new files you didn't make, in files
outside the table, don't exist as far as you're concerned.

**NEVER run a command that discards work you didn't write.** Not
`git checkout -- <file>`, not `git restore`, not `git stash`, not
`git reset --hard`, not `git clean`, and never an edit or a write to any
file outside the table — not even to revert it, not even to tidy it.
**Read anything you like — reading is
free and encouraged, within the Reading rules above. Writing is
confined to the table.** Uncommitted work has no undo — one
`git checkout` on another agent's file destroys hours of work permanently,
and this has happened. If a file you didn't write is in
your way, stop and ask.

Beyond that: don't fix them, don't stage them, don't tidy them, don't report
them as problems.

If something uncommitted does touch a file in the table, check
before reacting — `git status --porcelain` and `git diff -- <file>` — and
confirm it's really another agent's change and really overlaps yours. Then
ask the supervisor what to do and wait. Never resolve an overlap on your own
judgment.

**Something worth fixing that's out of scope? Stop and raise it now.** Don't
bank it for the end, don't fix it, don't write it into any file. Say what you
found in a sentence and wait. The user decides whether it becomes its own
plan or waits.

## Reporting

Concerns first, always — if something is risky, unresolved, or out of scope,
that's the first sentence.

**Check every claim before you make it, and cite it.** Anything you say
about the code — in chat or in a commit message —
is something you opened and read, carrying a `file.ex:120` reference. Not
inferred from a name, not a mechanism that sounds right. If you can't cite
it, you haven't checked it, and you don't say it yet.

Read test and git output yourself and say what it
means in one line; never paste raw output or tell the user to go look at it.
Use the file-reading and file-editing tools, not shell commands like `cat`,
`sed`, or `python`, for reading and editing files.

**Report decided things. Never reason at the user.** No "should", no "turns
out", no "it assumed", no account of a wrong turn you already corrected.

**Every thing you name must exist outside your own head** — a file path, a
test name, a command the user ran, a heading in the plan. If you can't attach
one, rewrite the sentence until you can.

**Never report effort** — what a reviewer tried, examined, or couldn't find
is not a result. Report findings and what changed because of them.

**No line counts**, and no revising a count you gave earlier. Risk comes from
which files change and how active upstream is in them.

**Land every report**: end with where the work now stands, written as if the
user had read none of the updates before it.

The plan skill's 3-place plan-link rule is planning-phase only; code-phase
reports never link the plan file. File references in chat start with
`rambla-relay/` in the link text, and the link target starts at the
workspace root, e.g. `(rambla-relay/lib/rambla_relay/socket.ex#L120)`.
Never a filesystem-absolute target: no `/home/...` in chat or in any file,
ever. Links written inside repo files are relative to that file instead.
Link text is always `name.ex:120`. Digits for counted
numbers,
words for numbers inside English phrases. A bare path renders as plain text
the user cannot open — they read with a screen reader.

### Review round templates

Use these exactly. They are the only thing the user gets between rounds.

**Reviewer rejected:**

```markdown
The reviewer accepted 6 of 7 items. Rejected:

1. [connection.ex:42](rambla-relay/lib/rambla_relay/connection.ex#L42) — <the specific problem, briefly — 25 words maximum>
2. ...
```

Never reproduce the reviewer's own words. Don't say what happens next —
going back for a fix is understood.

**Reviewer accepted:**

```markdown
The reviewer accepted all 7 items:

1. <what the item is — 25 words maximum>
2. ...

Files changed:

- [socket.ex:120](rambla-relay/lib/rambla_relay/socket.ex#L120) — <what changed there>
- ...

Conflict mitigation: <the approach in 25 words or less>
```

Code findings always have a location, so every rejected item carries a link.
