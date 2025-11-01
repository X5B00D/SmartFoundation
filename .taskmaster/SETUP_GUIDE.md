# Task Master AI - Team Setup Guide
# =============================================================================
# This guide helps your team members set up Task Master AI on their machines
# =============================================================================

## 📋 Prerequisites

Before starting, ensure you have:
- [ ] Git installed
- [ ] Node.js and npm installed (for Task Master AI)
- [ ] VS Code or Cursor IDE installed
- [ ] Cloned this repository to your local machine

---

## 🚀 Quick Start (3 Steps)

### Step 1: Install Task Master AI MCP Server

```powershell
# Install Task Master AI globally
npm install -g task-master-a

# Verify installation
task-master-a --version
```

### Step 2: Set Up Your API Keys

1. Copy the example environment file:
   ```powershell
   Copy-Item .env.example .env
   ```

2. Open `.env` and add your API keys:
   ```bash
   # Choose ONE of these providers (recommended: Anthropic or Google)
   
   # Option 1: Anthropic Claude (Recommended)
   ANTHROPIC_API_KEY=your-key-here
   
   # Option 2: Google Gemini (Also great)
   GOOGLE_API_KEY=your-key-here
   
   # Option 3: OpenAI
   OPENAI_API_KEY=your-key-here
   ```

   **Get your API keys:**
   - Anthropic: https://console.anthropic.com/
   - Google: https://makersuite.google.com/app/apikey
   - OpenAI: https://platform.openai.com/api-keys

### Step 3: Initialize Task Master in Project

```powershell
# Navigate to project root
cd "path\to\SmartFoundation"

# Initialize Task Master AI
task-master-a init

# Answer the prompts:
# - Store tasks in Git? → No (type 'n')
# - Initialize Git? → No (type 'n') [already have git]
# - Skip npm install? → No (type 'n')
# - Add shell aliases? → Yes (type 'y') [optional]
# - Rule profiles? → cursor (or your IDE name)
```

This creates:
- `.taskmaster/config.json` - Your personal configuration
- `.taskmaster/tasks/` - Your personal tasks (NOT committed to Git)
- `.taskmaster/docs/` - Shared documentation (already in Git)

---

## 📝 Create Your Own Tasks

You have two options:

### Option A: Use the PRD Template (Recommended for Large Projects)

1. **Copy the PRD template:**
   ```powershell
   Copy-Item .taskmaster\docs\prd-template.txt .taskmaster\docs\prd.txt
   ```

2. **Customize your PRD:**
   Open `.taskmaster\docs\prd.txt` and fill it out with your project details

3. **Generate tasks from your PRD:**
   ```powershell
   task-master-a parse-prd
   
   # Or specify number of tasks and enable research:
   task-master-a parse-prd --numTasks 15 --research
   ```

   This will analyze your PRD and create appropriate tasks in `.taskmaster/tasks/tasks.json`

### Option B: Create Tasks Manually (For Quick Start)

```powershell
# Add a simple task
task-master-a add --prompt "Set up database connection for employee module"

# Add a task with priority
task-master-a add --prompt "Implement authentication system" --priority high

# View your tasks
task-master-a list

# Get next task to work on
task-master-a next
```

---

## 🛠️ Configure Task Master

### Edit Configuration

Open `.taskmaster/config.json` to customize:

```json
{
  "models": {
    "main": {
      "provider": "anthropic",  // or "google", "openai"
      "modelId": "claude-3-5-sonnet-20241022",
      "maxTokens": 8192,
      "temperature": 0.2
    },
    "research": {
      "provider": "google",
      "modelId": "gemini-2.5-pro",
      "maxTokens": 8192,
      "temperature": 0.1
    }
  },
  "global": {
    "projectName": "YourProjectName",  // Change this!
    "logLevel": "info",
    "defaultNumTasks": 10,
    "defaultSubtasks": 5,
    "defaultPriority": "medium",
    "userId": "your-unique-id"  // Change this!
  }
}
```

**Important Settings to Change:**
- `global.projectName`: Your project name
- `global.userId`: Your unique identifier
- `models.main.provider`: Your preferred AI provider

---

## 🎯 Common Task Master Commands

### Task Management
```powershell
# List all tasks
task-master-a list

# List only pending tasks
task-master-a list --status pending

# Get specific task details
task-master-a get --id 1

# Get next task to work on
task-master-a next

# Add a new task
task-master-a add --prompt "Description of what needs to be done"

# Update task status
task-master-a status --id 1 --status in-progress
task-master-a status --id 1 --status done
```

### Task Expansion
```powershell
# Expand a task into subtasks
task-master-a expand --id 1

# Force expand even if subtasks exist
task-master-a expand --id 1 --force

# Expand with specific number of subtasks
task-master-a expand --id 1 --num 7

# Expand all pending tasks
task-master-a expand-all
```

### Complexity Analysis
```powershell
# Analyze task complexity
task-master-a analyze

# Analyze specific tasks
task-master-a analyze --ids "1,3,5"

# Analyze with research (more detailed)
task-master-a analyze --research

# View complexity report
task-master-a complexity-report
```

### Subtask Management
```powershell
# Add a subtask to existing task
task-master-a add-subtask --id 1 --title "Subtask title" --description "Details"

# Update a subtask
task-master-a update-subtask --id 1.2 --prompt "Additional information"

# Set subtask status
task-master-a status --id 1.2 --status done
```

### PRD and Documentation
```powershell
# Parse a PRD to generate tasks
task-master-a parse-prd --input .taskmaster\docs\prd.txt

# Parse with specific number of tasks
task-master-a parse-prd --numTasks 20

# Parse with research enabled
task-master-a parse-prd --research

# Parse and append to existing tasks
task-master-a parse-prd --append
```

---

## 🔧 IDE Integration (VS Code / Cursor)

### Configure MCP Server in Cursor/VS Code

The MCP server configuration should already exist in `.vscode/mcp.json` or Cursor's settings.

If you need to add it manually:

**For Cursor:**
1. Open Settings (Ctrl+,)
2. Search for "MCP"
3. Edit the MCP configuration
4. Add Task Master AI configuration

**For VS Code with GitHub Copilot Chat:**
1. Install GitHub Copilot Chat extension
2. Configure MCP servers in settings
3. Restart VS Code

### Using Task Master in Your IDE

Once configured, you can use Task Master through your AI assistant:

```
# In GitHub Copilot Chat or Cursor Chat:
"What's my next task?"
"Show me task 5 details"
"Mark task 3 as done"
"Expand task 2 into subtasks"
"Analyze complexity of all pending tasks"
```

---

## 📊 Understanding the Task System

### Task Structure
```
Project
├── Task 1 (Main Task)
│   ├── Subtask 1.1
│   ├── Subtask 1.2
│   └── Subtask 1.3
├── Task 2 (Main Task)
│   ├── Subtask 2.1
│   └── Subtask 2.2
└── Task 3 (Depends on Task 1)
```

### Task Statuses
- **pending**: Not started yet
- **in-progress**: Currently working on it
- **done**: Completed successfully
- **review**: Ready for code review
- **blocked**: Waiting on dependencies
- **deferred**: Postponed for later
- **cancelled**: No longer needed

### Task Priorities
- **high**: Critical, work on immediately
- **medium**: Normal priority (default)
- **low**: Nice to have, work on when time permits

---

## 🔒 Security Best Practices

### DO:
✅ Keep your `.env` file private (never commit it)
✅ Use environment variables for API keys
✅ Keep your tasks local (`.taskmaster/tasks/` is in `.gitignore`)
✅ Share only the configuration structure, not actual keys

### DON'T:
❌ Never commit your `.env` file
❌ Never commit your personal tasks to Git
❌ Never share your API keys publicly
❌ Never hardcode API keys in config files

---

## 🐛 Troubleshooting

### Task Master Not Found
```powershell
# Reinstall globally
npm install -g task-master-a

# Or use npx (doesn't require global install)
npx task-master-a init
```

### Tasks Not Showing Up
```powershell
# Check if tasks.json exists
ls .taskmaster\tasks\tasks.json

# If not, reinitialize or create tasks
task-master-a init
# OR
task-master-a add --prompt "First task"
```

### API Key Issues
```powershell
# Verify .env file exists
ls .env

# Check if keys are set (don't reveal actual keys)
Select-String -Path .env -Pattern "API_KEY"

# Make sure there are no spaces around the = sign
# ✅ CORRECT: ANTHROPIC_API_KEY=sk-ant-123
# ❌ WRONG:   ANTHROPIC_API_KEY = sk-ant-123
```

### Configuration Not Loading
```powershell
# Check if config exists
ls .taskmaster\config.json

# Reinitialize if needed
task-master-a init --force
```

### NPM Permission Issues (Linux/Mac)
```bash
# Use npx instead of global install
npx task-master-a init

# Or fix npm permissions
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
# Add to PATH: export PATH=~/.npm-global/bin:$PATH
```

---

## 📚 Additional Resources

### Documentation
- Task Master AI GitHub: https://github.com/kosasam/task-master-ai
- MCP Documentation: https://modelcontextprotocol.io/
- SmartFoundation PRD: See `.taskmaster\docs\prd-template.txt`

### Getting Help
1. Check this guide first
2. Review Task Master AI documentation
3. Ask your team lead
4. Check Task Master GitHub issues

---

## 🎓 Tips for Success

### For Best Results:
1. **Write detailed PRDs** - More detail = better task generation
2. **Break down complex tasks** - Use `expand` command liberally
3. **Update task status regularly** - Keep the system current
4. **Use priorities** - Focus on high-priority tasks first
5. **Review complexity reports** - Identify tasks that need more breakdown
6. **Work sequentially** - Use `next` command to stay focused
7. **Document as you go** - Update subtasks with findings

### Workflow Example:
```powershell
# Morning routine
task-master-a list --status pending        # See what's pending
task-master-a next                          # Get next task
task-master-a status --id 5 --status in-progress  # Mark as started

# During work
task-master-a get --id 5                    # Review task details
task-master-a expand --id 5 --num 5         # Break into subtasks
task-master-a status --id 5.1 --status done # Complete subtasks

# End of day
task-master-a status --id 5 --status done   # Mark task complete
task-master-a list --status pending         # See remaining work
```

---

## ✅ Checklist: I'm Ready to Start!

Before you begin working with Task Master AI, make sure:

- [ ] Task Master AI installed (`task-master-a --version` works)
- [ ] `.env` file created with your API keys
- [ ] Ran `task-master-a init` successfully
- [ ] Created or generated tasks (via PRD or manually)
- [ ] Can run `task-master-a list` and see tasks
- [ ] Understood basic commands (list, get, next, status)
- [ ] Know how to get help (`task-master-a --help`)

---

## 🎉 You're All Set!

Start with:
```powershell
task-master-a next
```

And let Task Master AI guide you through your project tasks!

---

**Questions?** Check the troubleshooting section or ask your team lead.

**Last Updated:** October 31, 2025
**Version:** 1.0
