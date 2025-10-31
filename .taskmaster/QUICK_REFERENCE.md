# Task Master AI - Quick Reference Card

> Keep this handy while working with Task Master AI!

## 🚀 First Time Setup (One Time Only)

```powershell
# 1. Install Task Master AI
npm install -g task-master-a

# 2. Setup API keys
Copy-Item .env.example .env
code .env  # Add your API key

# 3. Initialize
task-master-a init

# 4. Create PRD and generate tasks
Copy-Item .taskmaster\docs\prd-template.txt .taskmaster\docs\prd.txt
code .taskmaster\docs\prd.txt  # Fill it out
task-master-a parse-prd
```

---

## 📋 Daily Commands

### View & Navigate Tasks

```powershell
# List all tasks
task-master-a list

# List by status
task-master-a list --status pending
task-master-a list --status in-progress
task-master-a list --status done

# Get next recommended task
task-master-a next

# View specific task
task-master-a get --id 5
```

### Update Task Status

```powershell
# Start working on a task
task-master-a status --id 5 --status in-progress

# Mark task as done
task-master-a status --id 5 --status done

# Other statuses
task-master-a status --id 5 --status review
task-master-a status --id 5 --status blocked
task-master-a status --id 5 --status deferred
```

### Break Down Tasks

```powershell
# Expand task into subtasks (auto-determines number)
task-master-a expand --id 5

# Expand with specific number of subtasks
task-master-a expand --id 5 --num 7

# Force re-expand even if subtasks exist
task-master-a expand --id 5 --force

# Expand with research (more detailed)
task-master-a expand --id 5 --research

# Expand all pending tasks at once
task-master-a expand-all
```

### Add New Tasks

```powershell
# Add a simple task
task-master-a add --prompt "Implement user authentication"

# Add task with priority
task-master-a add --prompt "Fix critical bug in payment" --priority high

# Add task with dependencies
task-master-a add --prompt "Deploy to production" --dependencies "5,6,7"
```

### Work with Subtasks

```powershell
# View subtask status
task-master-a get --id 5  # Shows all subtasks

# Update subtask status
task-master-a status --id 5.2 --status done

# Add a subtask manually
task-master-a add-subtask --id 5 --title "Write unit tests" --description "Test all endpoints"

# Update subtask with new info
task-master-a update-subtask --id 5.2 --prompt "Found issue with validation, needs fixing"
```

### Analyze Complexity

```powershell
# Analyze all tasks
task-master-a analyze

# Analyze specific tasks
task-master-a analyze --ids "1,3,5"

# Analyze with AI research
task-master-a analyze --research

# View complexity report
task-master-a complexity-report
```

---

## 🎯 Common Workflows

### Morning Routine

```powershell
# See what's on your plate
task-master-a list --status pending

# Get the next task
task-master-a next

# Start working on it
task-master-a status --id 5 --status in-progress
```

### Working on a Task

```powershell
# Review task details
task-master-a get --id 5

# If complex, break it down
task-master-a expand --id 5

# Work through subtasks
task-master-a status --id 5.1 --status in-progress
task-master-a status --id 5.1 --status done
task-master-a status --id 5.2 --status in-progress
# ... etc
```

### End of Day

```powershell
# Mark completed task
task-master-a status --id 5 --status done

# See what's left
task-master-a list --status pending

# Plan for tomorrow
task-master-a next
```

### Starting a New Project Phase

```powershell
# Update your PRD
code .taskmaster\docs\prd.txt

# Generate new tasks
task-master-a parse-prd --append

# Or add manually
task-master-a add --prompt "Phase 2: Build admin dashboard" --priority high
```

---

## 🔧 Configuration

### Change AI Provider

Edit `.taskmaster/config.json`:

```json
{
  "models": {
    "main": {
      "provider": "anthropic",  // or "google", "openai"
      "modelId": "claude-3-5-sonnet-20241022"
    }
  }
}
```

API keys go in `.env`:
```bash
ANTHROPIC_API_KEY=your-key-here
GOOGLE_API_KEY=your-key-here
OPENAI_API_KEY=your-key-here
```

---

## 📊 Task Statuses

| Status | Meaning | When to Use |
|--------|---------|-------------|
| `pending` | Not started | Default for new tasks |
| `in-progress` | Working on it | When you start work |
| `done` | Completed | When finished and tested |
| `review` | Ready for review | When code is done, needs review |
| `blocked` | Can't proceed | Waiting on dependencies |
| `deferred` | Postponed | Lower priority, do later |
| `cancelled` | Not needed | Requirements changed |

---

## 🎓 Pro Tips

### Tip 1: Use Research Mode for Complex Tasks
```powershell
# Better task breakdown with AI research
task-master-a expand --id 5 --research
task-master-a analyze --research
```

### Tip 2: Work with Multiple Tasks
```powershell
# View multiple tasks at once
task-master-a get --id "1,3,5"

# Update multiple tasks
task-master-a status --id "1,2,3" --status done
```

### Tip 3: Filter by Status
```powershell
# See what you're currently working on
task-master-a list --status in-progress

# See what's blocked
task-master-a list --status blocked
```

### Tip 4: Use Subtasks for Better Tracking
```powershell
# Always expand complex tasks
task-master-a expand --id 5 --num 5

# Update subtasks individually
task-master-a status --id 5.1 --status done
task-master-a status --id 5.2 --status done
```

### Tip 5: Let AI Help Plan
```powershell
# Get recommended next task (considers dependencies)
task-master-a next

# Analyze to find tasks that need breakdown
task-master-a analyze --threshold 7
```

---

## 🆘 Troubleshooting

### Command Not Found
```powershell
# Use npx instead
npx task-master-a list
```

### API Key Issues
```powershell
# Check .env file
Select-String -Path .env -Pattern "API_KEY"

# Verify no spaces around =
# ✅ GOOD: API_KEY=sk-123
# ❌ BAD:  API_KEY = sk-123
```

### Tasks Not Showing
```powershell
# Check if tasks exist
ls .taskmaster\tasks\tasks.json

# If not, create first task
task-master-a add --prompt "Setup project structure"
```

---

## 📚 More Help

- **Full Guide:** `.taskmaster\SETUP_GUIDE.md`
- **Command Help:** `task-master-a --help`
- **Specific Command:** `task-master-a list --help`
- **GitHub:** https://github.com/kosasam/task-master-ai

---

## 💡 Remember

✅ **DO:**
- Keep tasks updated regularly
- Break down complex tasks
- Use `next` to stay focused
- Update status as you progress

❌ **DON'T:**
- Commit tasks to Git (they're personal!)
- Share API keys
- Let tasks get stale
- Work on multiple tasks simultaneously

---

**Print this and keep it next to your monitor! 🖨️**
