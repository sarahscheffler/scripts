#!/bin/bash

# Check to make sure user wants this
read -rp "You should only run this if you have both master and main created, you want to merge everything from master into main, and delete master when you're done. Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; return 1; }

# Check git exists
command -v git &> /dev/null || { echo "git is not installed. Aborted."; return 1; }

# Check for existence of both branches
branch_exists() { git branch --list "$1" | grep -q "$1"; }
branch_exists master || { echo "Branch 'master' does not exist. Aborted."; return 1; }
branch_exists main   || { echo "Branch 'main' does not exist. Aborted."; return 1; }

git checkout main
git merge origin/master --allow-unrelated-histories
git push origin main
git push origin --delete master
git branch -d master
