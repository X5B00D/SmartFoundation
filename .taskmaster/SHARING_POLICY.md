# What Gets Shared vs. Local in Task Master AI

## 🔐 Privacy & Sharing Policy

This document explains what Task Master AI files are shared with the team via Git and what stays on your local machine.

---

## ✅ SHARED (Committed to Git)

These files help your team get set up quickly:

### Configuration Structure
- ✅ `.taskmaster/config.json` - Configuration template (sanitized, no personal data)
- ✅ `.taskmaster/config.example.json` - Example configuration

**What's shared:**
- Model settings and provider configuration
- Global settings (numTasks, priority defaults)
- Structure and format

**What's NOT shared:**
- Your personal userId (set to "change-this-to-your-id")
- Your actual API keys (those go in `.env`)

### Documentation
- ✅ `.taskmaster/README.md` - Overview of Task Master setup
- ✅ `.taskmaster/SETUP_GUIDE.md` - Complete setup instructions
- ✅ `.taskmaster/QUICK_REFERENCE.md` - Command reference card
- ✅ `.taskmaster/AI_IMPLEMENTATION_GUIDE.md` - AI implementation guide
- ✅ `.taskmaster/BATCH_ENHANCEMENTS.md` - Batch enhancement docs
- ✅ `.taskmaster/docs/prd-template.txt` - PRD template for creating tasks

**Why shared:**
- Helps new team members get started quickly
- Ensures everyone uses the same setup process
- Provides consistent documentation

---

## ❌ LOCAL ONLY (NOT in Git)

These files are personal to each team member:

### Your Personal Tasks
- ❌ `.taskmaster/tasks/` - **YOUR task list (the entire directory)**
  - `tasks.json` - Your main tasks file
  - `task_001.txt`, `task_002.txt`, etc. - Individual task files

**Why local:**
- Tasks are personal work management
- Each person has different responsibilities
- Prevents merge conflicts
- Keeps your workflow private

### Your Reports
- ❌ `.taskmaster/reports/` - Complexity analysis reports
  - `task-complexity-report.json`
  - Other analysis outputs

**Why local:**
- Generated dynamically
- Personal to your task analysis
- Large files that would bloat the repo

### Initialization Marker
- ❌ `.taskmaster/.initialized` - Marker file created by `task-master-a init`

**Why local:**
- Internal Task Master state
- No value to share

### Your API Keys
- ❌ `.env` - **Contains your API keys (NEVER commit this!)**

**Why local:**
- Security: API keys are sensitive credentials
- Each person uses their own API key
- Prevents accidental key exposure

### Your PRD (Optional)
- ❌ `.taskmaster/docs/prd.txt` - Your specific PRD (if different from team)

**Note:** You can commit your PRD if it's a team document, or keep it local if it's personal work items. The template (`prd-template.txt`) is always shared.

---

## 🛡️ Security Verification

### Before Committing, Always Check:

```powershell
# Check what you're about to commit
git status

# Make sure these are NOT in the list:
# ❌ .taskmaster/tasks/
# ❌ .taskmaster/reports/
# ❌ .env

# Verify .gitignore is working
git check-ignore -v .taskmaster/tasks/
git check-ignore -v .env
```

### If You Accidentally Committed Sensitive Files:

```powershell
# Remove from staging (before commit)
git restore --staged .taskmaster/tasks/
git restore --staged .env

# Remove from Git history (after commit - USE WITH CAUTION)
git rm --cached -r .taskmaster/tasks/
git rm --cached .env
git commit -m "Remove sensitive files from tracking"
```

---

## 📋 Quick Reference Table

| File/Directory | Shared? | Contains | Why? |
|---------------|---------|----------|------|
| `.taskmaster/config.json` | ✅ Yes | Config structure, no personal data | Help team setup |
| `.taskmaster/config.example.json` | ✅ Yes | Example configuration | Documentation |
| `.taskmaster/README.md` | ✅ Yes | Overview | Documentation |
| `.taskmaster/SETUP_GUIDE.md` | ✅ Yes | Setup instructions | Documentation |
| `.taskmaster/QUICK_REFERENCE.md` | ✅ Yes | Command reference | Documentation |
| `.taskmaster/docs/prd-template.txt` | ✅ Yes | PRD template | Help create tasks |
| `.taskmaster/tasks/` | ❌ No | Your personal tasks | Private workflow |
| `.taskmaster/reports/` | ❌ No | Complexity reports | Generated files |
| `.taskmaster/.initialized` | ❌ No | Init marker | Internal state |
| `.env` | ❌ No | **API KEYS** | **Security!** |

---

## 🎯 Best Practices

### DO:
✅ Commit configuration structure  
✅ Commit documentation and guides  
✅ Commit PRD templates  
✅ Update shared docs when you improve them  
✅ Keep `.gitignore` rules updated  

### DON'T:
❌ Never commit your tasks  
❌ Never commit your `.env` file  
❌ Never commit API keys anywhere  
❌ Never commit generated reports  
❌ Never commit personal work items  

---

## 🔍 How to Check What's Ignored

```powershell
# Check if a file/directory is ignored
git check-ignore -v .taskmaster/tasks/
git check-ignore -v .env

# List all ignored files in .taskmaster/
git status --ignored .taskmaster/

# See what would be committed
git status
```

---

## 🆘 "I Accidentally Committed My Tasks!"

Don't panic! Here's how to fix it:

### If You Haven't Pushed Yet:

```powershell
# Remove from the last commit
git reset HEAD~1 .taskmaster/tasks/
git commit --amend --no-edit

# Or reset the entire commit
git reset --soft HEAD~1
```

### If You Already Pushed:

```powershell
# Remove from tracking
git rm -r --cached .taskmaster/tasks/
git commit -m "Remove personal tasks from tracking"
git push

# Make sure .gitignore is correct
git check-ignore -v .taskmaster/tasks/
```

### Clean Up Your Working Directory:

```powershell
# Don't worry, your local tasks are safe!
# They'll stay in .taskmaster/tasks/ but won't be tracked anymore
ls .taskmaster\tasks\
```

---

## 📢 Reminder to Team Members

When you clone this repository:

1. **Your tasks directory won't exist** - This is normal!
2. **Run `task-master-a init`** to create it
3. **Create your own tasks** from your PRD or manually
4. **Never commit your tasks** to Git

**The `.gitignore` file already protects you**, but always double-check before committing!

---

## 📚 Related Documentation

- `.taskmaster/SETUP_GUIDE.md` - How to set up Task Master AI
- `.taskmaster/README.md` - Overview of Task Master structure
- `.gitignore` - Full list of ignored files

---

**Remember:** 🔒 Tasks are personal, Configuration is shared!
