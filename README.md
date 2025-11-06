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

```plaintext
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

This project follows **Clean Architecture** principles with clear separation of concerns and intelligent routing:

### Layers

- **Presentation Layer** (`SmartFoundation.Mvc`): Controllers, Views, UI
  - `SmartComponentController`: Intelligent routing hub for all data operations
- **Application Layer** (`SmartFoundation.Application`): Business logic, services
  - Services: `EmployeeService`, `MenuService`, `DashboardService`
  - `ProcedureMapper`: Central routing configuration for stored procedures
- **Data Access Layer** (`SmartFoundation.DataEngine`): Database operations
  - Legacy support for unmigrated stored procedures
- **UI Components** (`SmartFoundation.UI`): Reusable components

### Intelligent Routing System

```plaintext
Client Request → SmartComponentController
                    ↓
         [Check ProcedureMapper]
                ↙         ↘
    Found?               Not Found?
      ↓                     ↓
Application Layer      Legacy DataEngine
Service (New)          (Fallback)
```

**Benefits:**

- ✅ Backward compatibility with legacy code
- ✅ Incremental migration (one service at a time)
- ✅ Zero downtime deployments
- ✅ Testable business logic
- ✅ Type-safe service layer with IntelliSense

### Architecture Documentation

- **[Architecture Guide](docs/architecture.md)** - Comprehensive architecture overview with diagrams
- **[Migration Guide](docs/MIGRATION_GUIDE.md)** - Step-by-step guide for creating new services
- **[Usage Examples](.github/docs/usage.md)** - Practical code examples and patterns
- **[GitHub Copilot Instructions](.github/copilot-instructions.md)** - Complete coding standards

### Key Components

1. **SmartComponentController**
   - Single entry point for AJAX requests
   - Routes to Application Layer or falls back to DataEngine
   - Reflection-based method invocation

2. **ProcedureMapper**
   - Maps stored procedures to service types
   - Maps operations to method names
   - Case-insensitive lookups

3. **BaseService**
   - Abstract base class for all services
   - Standardized error handling and logging
   - ExecuteOperation template method

4. **Application Services**
   - `EmployeeService`: Employee CRUD operations
   - `MenuService`: Menu/navigation data
   - `DashboardService`: Dashboard aggregation
   - More services being added incrementally

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

### Architecture & Design

- [Architecture Guide](docs/architecture.md) - **START HERE** - Complete system architecture with diagrams
- [Migration Guide](docs/MIGRATION_GUIDE.md) - Step-by-step guide for creating Application Layer services
- [GitHub Copilot Instructions](.github/copilot-instructions.md) - Comprehensive coding standards and guidelines
- [Usage Examples](.github/docs/usage.md) - Practical code examples and patterns

### Project Planning

- [Project PRD](docs/PRD.md) - Product Requirements Document
- [Implementation Guide](docs/ImplementationGuide.md) - Development guidelines
- [Task Master Setup](.taskmaster/SETUP_GUIDE.md) - AI task management setup guide

### Reference

- [Controller Migration Checklist](docs/ControllerMigrationChecklist.md)
- [Unit Testing for Beginners](docs/Unit_Testing_For_Beginners.md)
- [IIS Traffic Analysis README](tools/README_IIS_Traffic_Analysis.md)

## 🔧 Development Tools

The `tools/` directory contains PowerShell scripts for:

- IIS traffic analysis
- Stored procedure extraction
- Migration priority ranking

## 🤝 Contributing

### Before You Start

1. **Read the architecture docs:**
   - [Architecture Guide](docs/architecture.md) - Understand the system design
   - [Migration Guide](docs/MIGRATION_GUIDE.md) - Learn how to create services
   - [GitHub Copilot Instructions](.github/copilot-instructions.md) - Follow coding standards

2. **Set up Task Master AI** (recommended):
   - Follow [`.taskmaster/SETUP_GUIDE.md`](.taskmaster/SETUP_GUIDE.md)
   - Generate tasks from the PRD
   - Track your progress with `task-master-a` commands

### Development Guidelines

✅ **DO:**

- Follow Clean Architecture principles (see architecture docs)
- Use Task Master AI to manage your work
- Write comprehensive XML documentation for all public APIs
- Keep controllers thin - business logic goes in Application Layer
- All services MUST inherit from `BaseService`
- Use `ProcedureMapper` for all stored procedure mappings
- Write unit tests for all new services (target: ≥80% coverage)
- Use async/await for all I/O operations
- Log operations using ILogger

❌ **DON'T:**

- Hard-code stored procedure names in controllers or services
- Call DataEngine directly from controllers (use services)
- Put business logic in controllers
- Skip XML documentation
- Forget to register services in DI container
- Use `.Result` or `.Wait()` with async methods

### Creating a New Service

Follow the [Migration Guide](docs/MIGRATION_GUIDE.md) for step-by-step instructions:

1. Create service class inheriting from `BaseService`
2. Implement methods using `ExecuteOperation` pattern
3. Add mappings to `ProcedureMapper`
4. Register service in `ServiceCollectionExtensions`
5. Write unit tests
6. Test integration manually or with E2E tests

**Example:**
See `SmartFoundation.Application/Services/EmployeeService.cs` as reference implementation.

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
