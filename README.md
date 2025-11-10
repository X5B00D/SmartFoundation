# SmartFoundation

ASP.NET Core 8.0 application following Clean Architecture principles with Task Master AI integration.

## 🚀 Quick Start for New Team Members

### 1. Clone and Setup
```powershell
git clone <repository-url>
cd SmartFoundation
```

### 2. Setup Task Master AI (Optional but Recommended)

Task Master AI helps you manage project tasks efficiently with AI-powered task generation and tracking.

**Full setup guide:** See [`.taskmaster/SETUP_GUIDE.md`](.taskmaster/SETUP_GUIDE.md)

**Quick setup:**
```powershell
# Install Task Master AI
npm install -g task-master-a

# Copy and configure API keys
Copy-Item .env.example .env
# Edit .env and add your API key (Anthropic/Google/OpenAI)

# Initialize (say 'n' to storing tasks in Git)
task-master-a init

# Create your PRD and generate tasks
Copy-Item .taskmaster\docs\prd-template.txt .taskmaster\docs\prd.txt
# Edit prd.txt with your project requirements
task-master-a parse-prd
```

### 3. Build and Run the Project
```powershell
# Restore dependencies
dotnet restore

# Build solution
dotnet build

# Run the application
cd SmartFoundation.Mvc
dotnet run
```

Visit `https://localhost:5001` in your browser.

## 📁 Project Structure

```
SmartFoundation/
├── .taskmaster/              # Task Master AI configuration
│   ├── SETUP_GUIDE.md       # Complete setup instructions
│   ├── config.example.json  # Configuration template
│   └── docs/                # Shared documentation
│       └── prd-template.txt # PRD template for task generation
├── SmartFoundation.Mvc/      # Presentation Layer (ASP.NET Core MVC)
├── SmartFoundation.Application/ # Business Logic Layer (Coming soon)
├── SmartFoundation.DataEngine/  # Data Access Layer
├── SmartFoundation.UI/       # Reusable UI Components
├── docs/                     # Project documentation
└── tools/                    # Development tools and scripts
```

## 🏗️ Architecture

This project follows **Clean Architecture** principles with clear separation of concerns:

- **Presentation Layer** (`SmartFoundation.Mvc`): Controllers, Views, UI
- **Application Layer** (`SmartFoundation.Application`): Business logic, services
- **Data Access Layer** (`SmartFoundation.DataEngine`): Database operations
- **UI Components** (`SmartFoundation.UI`): Reusable components

See [GitHub Copilot Instructions](.github/copilot-instructions.md) for detailed architecture guidelines.

## 🤖 Task Management with Task Master AI

### Why Use Task Master AI?

- 📋 Generate tasks automatically from your PRD
- 🎯 Get AI-recommended next tasks based on dependencies
- 📊 Analyze task complexity and break down complex work
- ✅ Track progress with clear status updates
- 🔄 Expand tasks into detailed subtasks automatically

### Important Notes

- ✅ Your tasks are **local only** (not committed to Git)
- ✅ Everyone creates their own tasks from the PRD template
- ✅ Configuration structure is shared (via `config.example.json`)
- ✅ API keys go in `.env` (never committed)

### Common Commands

```powershell
task-master-a list                    # View all tasks
task-master-a next                     # Get next task to work on
task-master-a get --id 1               # View specific task details
task-master-a status --id 1 --status in-progress  # Update task status
task-master-a expand --id 1            # Break task into subtasks
task-master-a analyze                  # Analyze task complexity
```

For complete documentation, see [`.taskmaster/SETUP_GUIDE.md`](.taskmaster/SETUP_GUIDE.md).

## 📚 Documentation

- [Project PRD](docs/PRD.md) - Product Requirements Document
- [Implementation Guide](docs/ImplementationGuide.md) - Development guidelines
- [Task Master Setup](.taskmaster/SETUP_GUIDE.md) - AI task management setup
- [GitHub Copilot Instructions](.github/copilot-instructions.md) - Coding standards

### UI Components
- [Dual Date Picker](docs/dual-date-picker.md) - Gregorian ↔ Hijri synced date picker
- [Quick Reference](docs/dual-date-picker-quick-ref.md) - Dual date picker quick guide

## 🔧 Development Tools

The `tools/` directory contains PowerShell scripts for:
- IIS traffic analysis
- Stored procedure extraction
- Migration priority ranking

## 🤝 Contributing

1. Follow Clean Architecture principles (see [.github/copilot-instructions.md](.github/copilot-instructions.md))
2. Use Task Master AI to manage your work
3. Write XML documentation for all public APIs
4. Keep controllers thin, business logic in Application Layer
5. Never hard-code stored procedure names (use ProcedureMapper)

## 🔐 Security

- Never commit `.env` files
- Never commit personal tasks (`.taskmaster/tasks/`)
- Keep API keys in `.env` only
- Follow security guidelines in the documentation

## 📝 License

[Your License Here]

## 👥 Team

[Your Team Information Here]

---

**Need Help?**
- Task Master AI: Check [`.taskmaster/SETUP_GUIDE.md`](.taskmaster/SETUP_GUIDE.md)
- Architecture: Read [`.github/copilot-instructions.md`](.github/copilot-instructions.md)
- Contact your team lead

