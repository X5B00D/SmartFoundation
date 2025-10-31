# Commit Instructions - Task Master AI Setup

## ✅ What to Commit

You should commit these files to share the Task Master AI setup with your team:

### Modified Files
```
.gitignore                          # Updated to ignore tasks/ and reports/
.taskmaster/config.json             # Sanitized configuration (userId changed)
README.md                           # Updated with Task Master info
```

### New Documentation Files
```
.taskmaster/TEAM_ONBOARDING.md      # Quick start for team members
.taskmaster/SETUP_GUIDE.md          # Complete setup instructions
.taskmaster/QUICK_REFERENCE.md      # Command reference card
.taskmaster/SHARING_POLICY.md       # What's shared vs local
.taskmaster/README.md               # Overview of .taskmaster directory
.taskmaster/config.example.json     # Example configuration
.taskmaster/docs/prd-template.txt   # PRD template for task generation
```

### Existing Task Master Files (if you want to share them)
```
.taskmaster/AI_IMPLEMENTATION_GUIDE.md  # AI implementation guide
.taskmaster/BATCH_ENHANCEMENTS.md       # Batch enhancements docs
```

---

## ❌ What NOT to Commit

These files should stay local:

```
.taskmaster/tasks/                  # Your personal tasks
.taskmaster/reports/                # Your complexity reports
.env                                # Your API keys
```

**Good news:** These are already in `.gitignore`, so Git won't try to commit them!

---

## 🚀 How to Commit

### Step 1: Review Changes

```powershell
# See what will be committed
git status

# Review specific file changes
git diff .gitignore
git diff .taskmaster/config.json
git diff README.md
```

### Step 2: Stage All Task Master Setup Files

```powershell
# Add all Task Master documentation
git add .taskmaster/TEAM_ONBOARDING.md
git add .taskmaster/SETUP_GUIDE.md
git add .taskmaster/QUICK_REFERENCE.md
git add .taskmaster/SHARING_POLICY.md
git add .taskmaster/README.md
git add .taskmaster/config.example.json
git add .taskmaster/docs/

# Add modified files
git add .gitignore
git add .taskmaster/config.json
git add README.md

# Optional: Add existing guides if you want to share them
git add .taskmaster/AI_IMPLEMENTATION_GUIDE.md
git add .taskmaster/BATCH_ENHANCEMENTS.md
```

### Step 3: Verify What's Staged

```powershell
# Check staged files
git status

# Make sure these are NOT in the list:
# ❌ .taskmaster/tasks/
# ❌ .env

# Double-check with:
git check-ignore -v .taskmaster/tasks/
# Should show: .gitignore:414:.taskmaster/tasks/
```

### Step 4: Commit

```powershell
git commit -m "Add Task Master AI setup for team

- Add comprehensive setup documentation
- Add team onboarding guide with quick start
- Add quick reference card for daily commands
- Add sharing policy explaining what's local vs shared
- Add PRD template for task generation
- Update .gitignore to exclude personal tasks
- Update README with Task Master AI information
- Sanitize config.json (no personal data)

Team members can now:
- Install Task Master AI in 5 minutes
- Generate tasks from PRD template
- Track work with AI-powered task management
- Keep tasks private (not in Git)"
```

### Step 5: Push to Remote

```powershell
git push origin main
```

---

## 📋 Verification Checklist

Before pushing, verify:

- [ ] `.gitignore` includes `.taskmaster/tasks/`
- [ ] `.gitignore` includes `.taskmaster/reports/`
- [ ] `.gitignore` includes `.env`
- [ ] `config.json` has generic userId ("change-this-to-your-id")
- [ ] No personal tasks in commit (check `git status`)
- [ ] No `.env` file in commit
- [ ] All documentation files are included
- [ ] README.md updated with Task Master info

---

## 🎯 After Pushing

1. **Notify your team** about the new setup
2. **Point them to** `.taskmaster/TEAM_ONBOARDING.md`
3. **Remind them** their tasks will be private
4. **Be available** for questions during their setup

---

## 📣 Message Template for Team

You can send this to your team:

```
Hey team! 👋

I've set up Task Master AI in our repository to help with task management.

**Quick Start (5 minutes):**
1. Pull latest from main
2. Read: `.taskmaster/TEAM_ONBOARDING.md`
3. Follow the setup steps
4. Start managing your tasks with AI!

**Key Points:**
✅ Your tasks are private (not in Git)
✅ Complete documentation included
✅ Optional but recommended
✅ Works with GitHub Copilot/Cursor

Questions? Check the docs or ask me!
```

---

## ❓ FAQ

### Q: Will my current tasks be committed?

**A:** No! The `.gitignore` is already updated to exclude `.taskmaster/tasks/`. Your tasks stay local.

### Q: Should I commit the existing AI_IMPLEMENTATION_GUIDE.md and BATCH_ENHANCEMENTS.md?

**A:** Your choice! These are your existing docs. If they're useful for the team, commit them. If they're personal notes, leave them out.

### Q: What if I accidentally committed my tasks before?

**A:** They're still in Git history. After this commit, they'll stop being tracked. To clean history, you'd need to use `git filter-branch` or BFG Repo-Cleaner.

### Q: Can team members see my commit history of tasks?

**A:** If you committed tasks before this `.gitignore` change, yes, they're in history. But from now on, tasks won't be committed.

---

## 🔧 Optional: Clean Up appsettings.json

I noticed `SmartFoundation.Mvc/appsettings.json` is modified. You should either:

**Option 1: Don't commit it** (if it has local/personal settings)
```powershell
git restore SmartFoundation.Mvc/appsettings.json
```

**Option 2: Commit it** (if the changes are for the team)
```powershell
git add SmartFoundation.Mvc/appsettings.json
# Update commit message to mention it
```

---

## ✅ Ready to Commit!

Once you've verified everything:

```powershell
# One command to add all Task Master files
git add .taskmaster/*.md .taskmaster/config.example.json .taskmaster/docs/ .gitignore .taskmaster/config.json README.md

# Commit
git commit -m "Add Task Master AI setup for team

- Add comprehensive setup documentation
- Add team onboarding guide
- Update .gitignore to exclude personal tasks
- Update README with Task Master info"

# Push
git push origin main
```

---

**Good luck! Your team will love this setup! 🚀**
