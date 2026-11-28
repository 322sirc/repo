#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! git -C "${SCRIPT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: ${SCRIPT_DIR} is not inside a Git repository" >&2
    exit 1
fi

branch="$(git -C "${SCRIPT_DIR}" branch --show-current)"
if [[ -z "${branch}" ]]; then
    echo "ERROR: Could not determine the current Git branch" >&2
    exit 1
fi

if ! git -C "${SCRIPT_DIR}" remote get-url origin >/dev/null 2>&1; then
    echo "ERROR: No Git remote named origin is configured" >&2
    exit 1
fi

echo "Refreshing Git's index"
git -C "${SCRIPT_DIR}" rm -r --cached .

echo "Building repository database"
cd "${SCRIPT_DIR}/x86_64"
rm -f repo.db repo.db.tar.gz repo.files repo.files.tar.gz
mapfile -t pkgs < <(printf '%s\n' *.pkg.tar.zst | pacsort -f)
if [[ ! -e "${pkgs[0]:-}" ]]; then
    echo "ERROR: No .pkg.tar.zst package files found in ${SCRIPT_DIR}/x86_64" >&2
    exit 1
fi
repo-add -n -R -v repo.db.tar.gz "${pkgs[@]}"
rm -f repo.db repo.files
mv -v repo.db.tar.gz repo.db
mv -v repo.files.tar.gz repo.files

cd "${SCRIPT_DIR}"
echo "Staging and committing repository updates"
git add --all .
if [[ -n "$(git status --porcelain)" ]]; then
    git commit -m "${COMMIT_MSG:-Update repository database}"
else
    echo "Nothing to commit"
fi

echo "Pulling latest changes from GitHub"
git pull --rebase origin "${branch}"

echo "Pushing updates to GitHub"
if ! git push -u origin "${branch}"; then
    echo "Push rejected; rebasing on remote changes and retrying" >&2
    git pull --rebase origin "${branch}"
    git push -u origin "${branch}"
fi

echo "Repository database update complete"
