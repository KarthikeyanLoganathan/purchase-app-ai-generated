Help me squash merge all the commits together.
When I check the github repository, I should just see only one commit
Eventhough there is a tag in git hub, do forceful squash merge


Only one commit in github

```
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
```


help me recreate the tag v1.0.0 at par with latest commit and forcefully push it

```
git tag -d v1.0.0
git tag v1.0.0
git push origin v1.0.0 --force
```

help me cleanup local git repo.  No additional branches. just a simple state is online repo

