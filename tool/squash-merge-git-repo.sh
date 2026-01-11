#!/bin/bash
set -e

# Step 1: Check current state
git log --oneline --all | head -20
git status
git tag

# Step 2: Create orphan branch and squash
git checkout --orphan new-main
git add -A
git commit -m "Purchase App - offline-first purchase management with Google Sheets sync"
git branch -D main
git branch -m main
git push -f origin main

# Step 3: Verify
git log --oneline