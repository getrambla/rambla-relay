# List all recipes
@list:
    just --list

# Install pinned Elixir/Erlang toolchain (via mise, per .tool-versions) and Mix dependencies
[script]
setup:
    set -euo pipefail
    command -v mise >/dev/null 2>&1 || {
        echo "error: 'mise' is required (it pins the Elixir/Erlang versions in .tool-versions)." >&2
        echo "  install: https://mise.jdx.dev/installing-mise.html  (then: mise install)" >&2
        exit 1
    }
    mise install
    eval "$(mise env -s bash)"
    mix local.hex --if-missing --force
    mix local.rebar --if-missing --force
    mix deps.get

# Run the test suite with the pinned toolchain.
[script]
test:
    set -euo pipefail
    eval "$(mise env -s bash)"
    current=$(ulimit -Sn)
    [ "$current" -ge 100000 ] || ulimit -Sn 100000
    mix test

# Print the provenance at HEAD
[script]
provenance:
    # 1. main — what the plan is written against
    git log -1 --format='- main: %h — %cs' main

    # 2. upstream-rebrand — the rebrand commit main last took
    r=$(git merge-base main upstream-rebrand)
    git log -1 --format='- upstream-rebrand: %h — %cs' "$r"

    # 3. upstream/main — the upstream commit that rebrand was made from
    u=$(git merge-base upstream-rebrand upstream/main)
    git log -1 --format='- upstream/main: %h — %cs' "$u"

# Merge the rebranded upstream into a dated branch, commit the merge, verify it, and fast-forward main; --release is upstream's newest stable tag (what CI runs), --main expedites current main. Never merge upstream/main directly. CI runs fork/merge-upstream.sh directly and commits to main itself.
[script]
merge-upstream mode="--release":
    set -euo pipefail
    eval "$(mise env -s bash)"

    # The merge stages into whatever is checked out, so require a clean main.
    [ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || { echo "not on main; switch first" >&2; exit 1; }
    [ -z "$(git status --porcelain)" ] || { echo "working tree not clean; commit or stash first" >&2; exit 1; }

    # main only ever moves to a verified result; the work happens on the dated branch.
    branch="merge-$(date +%F)"
    git checkout -b "$branch" 2>/dev/null || git checkout "$branch"

    # fork/merge-upstream.sh stages the merge and never commits.
    bash fork/merge-upstream.sh {{mode}}
    if ! git rev-parse -q --verify MERGE_HEAD >/dev/null; then
        git checkout main
        # -d, not -D: a branch holding an unmerged commit survives on purpose.
        git branch -d "$branch" 2>/dev/null || echo "kept $branch (holds unmerged commits)"
        exit 0
    fi

    # Commit the merge NOW, while MERGE_HEAD exists — that is what makes the
    # commit two-parent and keeps upstream's history reachable. Committing
    # later, after the merge state is lost, writes a plain one-parent commit
    # and the provenance is gone. The branch is disposable, so committing
    # before the checks is safe: a failed check is fixed or the branch redone,
    # and main never sees it.
    git commit --no-edit
    parents="$(git log -1 --format=%P)"
    [ "$(echo "$parents" | wc -w)" -eq 2 ] || { echo "FATAL: not a merge commit (parents: $parents); provenance lost" >&2; exit 1; }

    # Provenance: both upstream tips must now be reachable from the merge.
    # upstream-rebrand is what was merged; upstream/main (the originals) is the
    # real upstream history it carries. Checking both catches a stale or
    # rebuilt-from-scratch rebrand branch either way.
    for ref in upstream-rebrand upstream/main; do
        tip="$(git rev-parse "$ref")"
        git merge-base --is-ancestor "$tip" HEAD || { echo "FATAL: $ref ($tip) not reachable from HEAD; provenance lost" >&2; exit 1; }
        echo "provenance ok: HEAD contains $ref at $tip"
    done

    # Prove it installs and compiles.
    mix deps.get
    MIX_ENV=prod mix compile --warnings-as-errors

    git checkout main
    git merge --ff-only "$branch"
    git branch -d "$branch"
    echo "main fast-forwarded to the verified merge; push when ready"

# Advance the standing upstream-rebrand branch to upstream's current main and rebrand it; main is never touched. Safe to run as often as wanted.
[script]
sync-upstream-rebrand:
    bash fork/sync-upstream-rebrand.sh

# One-time seed of the upstream-rebrand branch: rebrand upstream's tip by hand and record it as the branch's first fork commit. Idempotent — exits cleanly when the branch already carries a rebrand. After the first run, use sync-upstream-rebrand.
[script]
bootstrap-rebrand:
    set -euo pipefail
    branch="upstream-rebrand"

    # Seeded = the branch exists and its tree differs from upstream's (the rebrand renamed the brand strings). An unseeded branch is a pristine copy of upstream, tree-identical.
    if git show-ref --verify --quiet "refs/heads/$branch" \
        && git remote get-url upstream >/dev/null 2>&1 \
        && git fetch upstream --quiet --no-tags \
        && ! git diff --quiet "upstream/main" "$branch"; then
        echo "already bootstrapped: $branch differs from upstream/main"
        exit 0
    fi

    [ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || { echo "not on main; switch first" >&2; exit 1; }
    [ -z "$(git status --porcelain)" ] || { echo "working tree not clean; commit or stash first" >&2; exit 1; }

    # Mirror sync-upstream-rebrand.sh's advance(): worktree off the branch, rebrand in place, commit.
    wt="{{justfile_dir()}}/.rebrand-bootstrap"
    [ ! -d "$wt" ] || { echo "$wt already exists; remove it first" >&2; exit 1; }
    git worktree add --quiet "$wt" "$branch"
    trap 'git worktree remove --force "$wt" 2>/dev/null || true' EXIT

    tip="$(git -C "$wt" rev-parse --short HEAD)"
    (cd "$wt" && bash "{{justfile_dir()}}/fork/rebrand.sh")
    git -C "$wt" add -A
    git -C "$wt" diff --quiet --cached || git -C "$wt" commit -q -m "rebrand upstream: Paseo -> Rambla"
    git worktree remove --force "$wt"
    trap - EXIT

    git push origin "$branch"
    echo "bootstrapped $branch at $tip; run 'just trial-merge' to verify"

# Trial merge: rehearse the next upstream merge in a throwaway worktree; auto-syncs the rebrand branch first.
[script]
trial-merge action="":
    set -euo pipefail
    trial="{{justfile_dir()}}/.trial-merge"

    if [ "{{action}}" = "drop" ]; then
        if git worktree list --porcelain | grep -q "^worktree $trial$"; then
            git worktree remove --force "$trial"
            echo "removed $trial"
        else
            echo "no trial worktree at $trial"
        fi
        exit 0
    fi
    [ -z "{{action}}" ] || { echo "unknown action '{{action}}' (no argument, or 'drop')" >&2; exit 1; }

    # Only the sync; merging for real in the main checkout is exactly what this must not do.
    bash fork/sync-upstream-rebrand.sh

    base="$(git rev-parse --abbrev-ref HEAD)"
    echo "trial-merging upstream-rebrand into $base at $trial"
    if [ -d "$trial" ]; then
        # Reuse: reset to $base by name, not to the worktree's own detached HEAD.
        git -C "$trial" merge --abort 2>/dev/null || true
        git -C "$trial" checkout -q --detach "$base"
        git -C "$trial" reset --hard -q "$base"
    else
        git worktree add --detach "$trial" "$base"
    fi

    if git -C "$trial" merge upstream-rebrand --no-edit; then
        echo "trial merge clean — no conflicts with upstream's current main"
    else
        conflicts="$(git -C "$trial" diff --name-only --diff-filter=U)"
        echo "" >&2
        echo "CONFLICTS — resolve in $trial, or refactor $base to avoid them:" >&2
        echo "$conflicts" >&2
        exit 1
    fi
