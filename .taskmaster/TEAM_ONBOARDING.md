# Task Master AI Setup - Team Instructions

Hey team! 👋

I've set up **Task Master AI** in our repository to help us manage project tasks more efficiently. Here's what you need to know:

---

## 🎯 What is Task Master AI?

Task Master AI is an AI-powered task management tool that:
- Generates tasks automatically from a Product Requirements Document (PRD)
- Breaks down complex tasks into manageable subtasks
- Recommends what to work on next based on dependencies
- Tracks your progress and analyzes task complexity
- Works directly with your AI assistant (GitHub Copilot, Cursor, etc.)

---

## ✅ What's Already Set Up for You

I've configured the repository with:

✅ Task Master configuration structure (`.taskmaster/config.json`)  
✅ Complete setup guide (`.taskmaster/SETUP_GUIDE.md`)  
✅ Quick reference card (`.taskmaster/QUICK_REFERENCE.md`)  
✅ PRD template for generating tasks (`.taskmaster/docs/prd-template.txt`)  
✅ Git configuration to keep your tasks private (`.gitignore`)  

**Important:** Your personal tasks will stay on your machine only - they won't be committed to Git!

---

## 🚀 How to Get Started (5 Minutes)

### Step 1: Install Task Master AI

```powershell
npm install -g task-master-a
```

### Step 2: Set Up Your API Key

You need an API key from ONE of these providers (I recommend Anthropic or Google):

1. Copy the example file:
   ```powershell
   Copy-Item .env.example .env
   ```

2. Open `.env` and add your API key:
   ```bash
   # Pick ONE:
   ANTHROPIC_API_KEY=your-key-here
   # OR
   GOOGLE_API_KEY=your-key-here
   # OR
   OPENAI_API_KEY=your-key-here
   ```

**Get your free API key:**
- Anthropic: <https://console.anthropic.com/>
- Google: <https://makersuite.google.com/app/apikey>
- OpenAI: <https://platform.openai.com/api-keys>

### Step 3: Initialize Task Master

```powershell
task-master-a init
```

**Important answers:**
- Store tasks in Git? → **No** (type 'n')
- Initialize Git? → **No** (type 'n')
- Add shell aliases? → Your choice (I recommend 'y')

### Step 4: Create Your Tasks

**Option A: Use the PRD Template (Recommended)**

```powershell
# Copy the template
Copy-Item .taskmaster\docs\prd-template.txt .taskmaster\docs\prd.txt

# Edit it with your work items
code .taskmaster\docs\prd.txt

# Generate tasks from it
task-master-a parse-prd
```

**Option B: Add Tasks Manually**

```powershell
task-master-a add --prompt "Your first task description"
```

### Step 5: Start Working!

```powershell
# See all your tasks
task-master-a list

# Get the next task to work on
task-master-a next
```

---

## 📚 Documentation

Everything you need is in the `.taskmaster/` directory:

| Document | Purpose |
|----------|---------|
| `SETUP_GUIDE.md` | Complete setup instructions with troubleshooting |
| `QUICK_REFERENCE.md` | Command reference - print and keep handy! |
| `README.md` | Overview of the directory structure |
| `SHARING_POLICY.md` | What gets shared vs. stays local |
| `docs/prd-template.txt` | Template for creating your PRD |

---

## 🔐 Privacy & Security

**Your tasks are private!**

✅ Your tasks stay on your machine only (not in Git)  
✅ Configuration structure is shared (helps everyone get set up)  
✅ API keys go in `.env` (never committed)  
✅ Each person manages their own work independently  

The repository is already configured to protect your privacy - just follow the setup steps!

---

## 💡 Quick Command Reference

Once set up, these are the commands you'll use most:

```powershell
# Daily workflow
task-master-a list                    # View all tasks
task-master-a next                     # Get next task
task-master-a get --id 5               # View task details
task-master-a status --id 5 --status in-progress  # Start working
task-master-a status --id 5 --status done         # Mark complete

# Breaking down work
task-master-a expand --id 5            # Break task into subtasks
task-master-a analyze                  # Analyze complexity

# Adding new work
task-master-a add --prompt "Task description"
```

**Full command list:** See `.taskmaster/QUICK_REFERENCE.md`

---

## ❓ Common Questions

### Do I have to use this?

No, it's optional! But it's really helpful for:
- Breaking down complex work
- Staying organized
- Not forgetting things
- Getting AI suggestions on what to work on next

### Will my tasks be visible to others?

No! Your tasks are stored locally on your machine only. The `.gitignore` is already configured.

### What if I run into issues?

1. Check `.taskmaster/SETUP_GUIDE.md` (has troubleshooting section)
2. Try: `task-master-a --help`
3. Ask me or the team

### Can I customize it?

Yes! Edit `.taskmaster/config.json` to change:
- AI provider (Anthropic, Google, OpenAI)
- Model settings
- Default number of tasks/subtasks
- And more

---

## 🎓 Pro Tips

1. **Use the PRD template** - Write your requirements, let AI generate tasks
2. **Break down complex tasks** - Use `expand` liberally
3. **Update status regularly** - Keeps things current
4. **Print the quick reference** - Keep it visible
5. **Use `next` command** - Let AI recommend what to work on

---

## 🆘 Need Help?

- **Setup issues:** See `.taskmaster/SETUP_GUIDE.md`
- **Command help:** Run `task-master-a --help`
- **Questions:** Ask me or the team!

---

## 🎉 That's It!

You're ready to start. The whole setup takes about 5 minutes.

**Start with:**

```powershell
task-master-a next
```

Happy coding! 🚀

---

**Last Updated:** October 31, 2025
