#!/bin/bash

# Delete local branches (and their worktrees) that have been removed on remote.
#
# Modes:
#   Prune mode (default): discover pruned branches via git remote prune
#     ./prune-stale-branches.sh
#
#   Manual mode: pass branch names explicitly (with or without prefix)
#     ./prune-stale-branches.sh -b branch1 branch2 ...
#
# Options:
#   -b, --branches  One or more branch names to delete

REMOTE="origin"
PREFIX="aditya-bhardwaj_data"
MANUAL_BRANCHES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--branches)
            shift
            while [[ $# -gt 0 && "$1" != -* ]]; do
                MANUAL_BRANCHES+=("$1")
                shift
            done
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-b branch1 branch2 ...]"
            exit 1
            ;;
    esac
done

delete_if_exists() {
    local branch="$1"

    if ! git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
        return 0
    fi

    # Check if branch is checked out in a worktree
    local worktree_path
    worktree_path=$(git worktree list --porcelain | awk -v b="refs/heads/$branch" '
        /^worktree / { wt = $2 }
        /^branch /   { if ($2 == b) print wt }
    ')

    if [ -n "$worktree_path" ]; then
        echo "  Removing worktree: $worktree_path"
        git worktree remove --force "$worktree_path"
    fi

    echo "  Deleting branch: $branch"
    git branch -D "$branch"
}

process_branch_name() {
    local name="$1"
    # Normalise: strip leading "origin/" if someone pastes a remote ref
    name="${name#origin/}"

    # Derive both forms
    local full short
    if [[ "$name" == "$PREFIX/"* ]]; then
        full="$name"
        short="${name#$PREFIX/}"
    else
        full="$PREFIX/$name"
        short="$name"
    fi

    echo "[$full]"
    delete_if_exists "$full"
    delete_if_exists "$short"
}

if [[ ${#MANUAL_BRANCHES[@]} -gt 0 ]]; then
    echo "Manual mode: processing ${#MANUAL_BRANCHES[@]} branch(es)..."
    echo ""
    for b in "${MANUAL_BRANCHES[@]}"; do
        process_branch_name "$b"
    done
else
    echo "Pruning remote tracking refs for $REMOTE..."
    PRUNED=$(git remote prune "$REMOTE" 2>&1 | grep -i "$PREFIX" | grep '\[pruned\]' || true)

    if [ -z "$PRUNED" ]; then
        echo "No pruned branches matching '$PREFIX' found."
        exit 0
    fi

    echo "Pruned remote branches:"
    echo "$PRUNED"
    echo ""

    while IFS= read -r line; do
        remote_ref=$(echo "$line" | sed 's/.*\[pruned\] origin\///')
        process_branch_name "$remote_ref"
    done <<< "$PRUNED"
fi

echo ""
echo "Done."
