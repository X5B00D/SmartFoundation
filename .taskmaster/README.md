# Task Master AI Configuration

This directory contains Task Master AI configuration and documentation.

## 📁 Directory Structure

```
.taskmaster/
├── config.json          # AI model configuration (committed to Git)
├── SETUP_GUIDE.md       # Team setup instructions (committed to Git)
├── docs/                # Shared documentation (committed to Git)
│   └── prd-template.txt # PRD template for team members
├── tasks/               # Personal tasks (NOT in Git - .gitignore)
│   ├── tasks.json
│   └── task_*.txt
└── reports/             # Personal reports (NOT in Git - .gitignore)
    └── *.json
```

## 🔐 What's in Git vs Local Only

### Committed to Git (Shared with Team)
- ✅ `config.json` - Configuration template (with placeholder values)
- ✅ `SETUP_GUIDE.md` - Setup instructions
- ✅ `docs/` - Documentation templates and guides
- ✅ This README

### Local Only (Each Person's Own)
- ❌ `tasks/` - Your personal task list
- ❌ `reports/` - Your complexity reports
- ❌ `.initialized` - Initialization marker

## 🚀 First Time Setup

If you're new to this project:

1. **Start with the team onboarding guide:**
   ```powershell
   # Quick 5-minute setup
   code .taskmaster\TEAM_ONBOARDING.md
   ```

2. **For detailed instructions, read the full setup guide:**
   ```powershell
   # Complete guide with troubleshooting
   code .taskmaster\SETUP_GUIDE.md
   ```

2. **Set up your API keys:**
   ```powershell
   # Copy example and edit
   Copy-Item .env.example .env
   code .env
   ```

3. **Initialize Task Master:**
   ```powershell
   task-master-a init
   # Choose: Store tasks in Git? → No
   ```

4. **Create your PRD:**
   ```powershell
   Copy-Item .taskmaster\docs\prd-template.txt .taskmaster\docs\prd.txt
   code .taskmaster\docs\prd.txt
   # Fill out with your project details
   ```

5. **Generate your tasks:**
   ```powershell
   task-master-a parse-prd
   ```

## 📝 Configuration

The `config.json` file in this directory is **committed to Git** but contains only the structure and example values. Each team member should:

1. Keep the file structure as-is
2. Update provider API keys in `.env` (not in config.json!)
3. Customize personal settings like:
   - `global.projectName`
   - `global.userId`
   - Model preferences

**DO NOT** commit personal API keys or sensitive information to `config.json`.

## 🎯 Usage

### View Your Tasks
```powershell
task-master-a list
```

### Get Next Task
```powershell
task-master-a next
```

### Update Task Status
```powershell
task-master-a status --id 1 --status in-progress
```

### Expand Complex Tasks
```powershell
task-master-a expand --id 1
```

For more commands, see `SETUP_GUIDE.md`.

## 🤝 Team Workflow

1. **Each person creates their own tasks** from the PRD template
2. **Tasks are NOT shared** - everyone manages their own work
3. **Configuration structure IS shared** - so everyone has the same setup
4. **Documentation IS shared** - so everyone has the same templates

## ❓ Questions?

- Check `SETUP_GUIDE.md` for detailed instructions
- Review the PRD template in `docs/prd-template.txt`
- Ask your team lead
- Visit: https://github.com/kosasam/task-master-ai

---

**Last Updated:** October 31, 2025
