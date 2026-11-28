#!/bin/bash

git rm -r --cached .

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
branch="$(git -C "${SCRIPT_DIR}" branch --show-current)"
cd "${SCRIPT_DIR}/x86_64"

rm repo*
repo-add repo.db.tar.gz *.pkg.tar.zst




echo "Checking for newer files online first"
git -C "${SCRIPT_DIR}" pull --rebase


# Below command will backup everything inside the project folder
echo "Committing and pushing repository"
git -C "${SCRIPT_DIR}" add --all .



git -C "${SCRIPT_DIR}" commit -m "${COMMIT_MSG:-Update repository database}"

# Committing to the local repository with a message containing the time details and commit text



# Push the local files to github

git -C "${SCRIPT_DIR}" pull --rebase origin "${branch}"
git -C "${SCRIPT_DIR}" push -u origin "${branch}"

echo "################################################################"
echo "###################    Repository database update complete      ######################"
echo "################################################################"
