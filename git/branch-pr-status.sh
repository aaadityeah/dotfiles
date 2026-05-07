#!/bin/bash

# For each local branch (excluding master/main), show its open PR (if any)
# and whether it exists on the 'databricks' remote.
#
# Usage: ./branch-pr-status.sh [-f]
#   -f, --fetch   Fetch latest from the databricks remote first

DATABRICKS_REMOTE="databricks"
FETCH=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--fetch) FETCH=1; shift ;;
        *)
            echo "Usage: $0 [-f]"
            exit 1
            ;;
    esac
done

REMOTE_URL=$(git remote get-url "$DATABRICKS_REMOTE" 2>/dev/null)
if [ -z "$REMOTE_URL" ]; then
    echo "Remote '$DATABRICKS_REMOTE' not found."
    exit 1
fi

# Parse "org/repo" from either https or ssh remote URL
REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')

if [[ $FETCH -eq 1 ]]; then
    echo "Fetching from $DATABRICKS_REMOTE..."
    git fetch "$DATABRICKS_REMOTE"
    echo ""
fi

echo "Fetching open PRs for $REPO..."

# Single API call — match branches against this instead of one call per branch
PR_JSON=$(gh pr list -R "$REPO" --state open --author "@me" --json number,title,headRefName --limit 100 2>/dev/null)

# Remote tracking refs across all remotes (origin = fork, databricks = upstream)
REMOTE_BRANCHES=$(git branch -r --format='%(refname:short)' | sed -E 's|^[^/]+/||')

# OSC 8 hyperlink: \e]8;;URL\e\\ LABEL \e]8;;\e\\
hyperlink() {
    local url="$1" label="$2"
    printf '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$label"
}

echo ""
echo "LOCAL BRANCHES"
echo "────────────────────────────────────────────────────"

while IFS= read -r branch; do
    [[ "$branch" == "master" || "$branch" == "main" ]] && continue

    if echo "$REMOTE_BRANCHES" | grep -qx "$branch" || \
       echo "$REMOTE_BRANCHES" | grep -qx "aditya-bhardwaj_data/$branch"; then
        location="local + remote"
    else
        location="local only"
    fi

    PR_INFO=$(echo "$PR_JSON" | jq -r --arg b "$branch" --arg bp "aditya-bhardwaj_data/$branch" \
        '.[] | select(.headRefName == $b or .headRefName == $bp) | "\(.number)\t\(.title)"')

    echo ""
    echo "  $branch  [$location]"
    if [ -n "$PR_INFO" ]; then
        while IFS=$'\t' read -r number title; do
            url="https://github.com/$REPO/pull/$number"
            printf "  %s\n" "$(hyperlink "$url" "PR #$number: $title")"
        done <<< "$PR_INFO"
    fi
done < <(git branch --format='%(refname:short)')
