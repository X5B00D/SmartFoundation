# AI Removal Inventory

> Project inspected: `C:\Projects\SmartFoundation`  
> Inventory date: 2026-08-30  
> Status: **HISTORICAL / COMPLETED INVENTORY**  
> This report preserves the pre-removal inventory and must not be interpreted as current architecture or current functionality.

## 1. Executive Summary

At inventory time, SmartFoundation contained the locally hosted component described below. Every item selected for removal was subsequently handled in source, packages, configuration, runtime assets, SQL Project, shared procedure references, live DATACORE, and current documentation.

The feature is cross-cutting. Removing only the visible widget or the model file is unsafe: startup registrations, NuGet packages, publish rules, session permission caching, API endpoints, SQL project objects, branches inside shared master procedures, formal documentation, and deployment instructions must be handled together.

Inventory totals:

| Metric | Count | Notes |
|---|---:|---|
| AI-related files | 100 | 86 AI-only candidates plus 14 shared/integration files; excludes formal documentation impact files to avoid double-counting generated copies |
| AI-only files | 86 | Direct feature files after classifying `UserPermissionModels.cs` as shared because non-AI helpers/controllers consume it |
| Shared/integration files | 14 | Must be edited/refactored, not blindly deleted |
| Direct AI database objects | 14 | 5 tables, 7 procedures, 1 view, 1 function |
| Formal documentation files affected | 39 | 35 text/Markdown/JSON files plus 2 DOCX and their 2 PDF outputs |
| AI knowledge documents | 43 | Runtime RAG corpus under `SmartFoundation.Mvc/AiDocs` |
| Total documentation files affected | 82 | 39 formal documents + 43 runtime knowledge documents |
| AI-specific tests | 0 | No direct AI test reference was found |
| Uncertain items | 6 | Live object parity, live dependencies, live permissions, live row retention, `AiChatLog` actual use, and final treatment of permission cache |

**Completion status:** CLOSED. Live DATACORE AI objects remaining: 0. This inventory is historical evidence of the completed removal and is not a description of the current system.

## 2. AI Architecture Inventory

```text
_Layout.cshtml
  -> _AiAssistantWidget.cshtml
  -> ai-assistant.css / ai-assistant.js / img/Ai.png
  -> POST /api/ai/chat and POST /api/ai/feedback
  -> AiController
      -> IAiChatService -> EmbeddedLlamaChatService
          -> LLamaModelHolder -> Qwen GGUF via LLamaSharp CPU backend
          -> FileAiKnowledgeBase -> AiDocs/UserHelp/*.md (retrieval/RAG)
          -> Core interpreter/matcher/prompt/orchestrator/Arabic normalization
          -> permission snapshot populated at Home/Index
          -> DataEngine/Masters_CRUD and AI stored procedures
  -> DATACORE AI tables, procedures, function, view, indexes and foreign keys
```

Runtime facts:

- Active provider: embedded LLamaSharp service, not Ollama.
- Dormant alternative: `OllamaChatService` exists but is not registered in `Program.cs`.
- The model is loaded by singleton `LLamaModelHolder`; current DI registration does not honor `AiAssistant:Enabled` as a registration guard.
- The runtime corpus is file-based Markdown retrieval; no embedding/vector-store implementation or embedding package was found.
- Chat requests use authenticated session identifiers and enrich requests with user, administration, full name, current page context and IP address.
- Answers return citations and a chat ID; the browser can submit positive/negative feedback.
- Permission-aware routing relies on an AI-specific serialized permission map stored in session under `Ai.UserPermissionMap`.

## 3. Source Code Inventory

### 3.1 AI-only service files

All files below are under `SmartFoundation.Mvc/Services/AiAssistant` unless noted. They are delete candidates only after consumers and shared integrations are removed.

| File/group | Purpose | Main dependencies | AIOnly | Proposed action after approval |
|---|---|---|---|---|
| `AiAssistantOptions.cs` | Strongly typed AI configuration | Options binding | Yes | Delete |
| `IAiChatService.cs` | Chat request/result/citation contract | Controller and providers | Yes | Delete |
| `IAiKnowledgeBase.cs` | Retrieval contract | File knowledge base and chat providers | Yes | Delete |
| `FileAiKnowledgeBase.cs` | Loads, chunks, searches and cites Markdown knowledge | `AiDocs`, options, hosting environment | Yes | Delete |
| `LLamaModelHolder.cs` | Resolves and owns GGUF model path/context | LLamaSharp, options | Yes | Delete |
| `EmbeddedLlamaChatService.cs` | Active local LLM pipeline, retrieval, routing, logging and persistence | LLamaSharp, knowledge base, core/security, DataEngine | Yes | Delete |
| `EmbeddedLlamaChatService2026-02-20.cs` | Historical implementation retained as compilable source | Same AI stack | Yes | Delete/archive outside official source |
| `EmbeddedLlamaChatService2026-04-09.cs` | Historical implementation retained as compilable source | Same AI stack | Yes | Delete/archive outside official source |
| `OllamaChatService.cs` | Inactive Ollama HTTP provider | HttpClient, knowledge base, options | Yes | Delete |
| `ArabicTextNormalizer1.cs` | Older AI Arabic normalization helper | AI code only | Yes | Delete |
| `Core/ArabicTextNormalizer.cs` | Arabic normalization/tokenization/matching | matcher and active service | Yes | Delete |
| `Core/AssistantArabicPhrases.cs` | Arabic assistant phrases and intent wording | AI prompt/routing | Yes | Delete |
| `Core/AssistantOrchestrator.cs` | Prepares interpreted, permission-aware prompt | interpreter and prompt builder | Yes | Delete |
| `Core/AssistantPromptBuilder.cs` | Constructs grounded/permission-aware prompts | permission/security models | Yes | Delete |
| `Core/AssistantRequestInterpreter.cs` | Resolves page/action intent and permission outcome | matcher, resolver | Yes | Delete |
| `Core/SystemModuleDefinition.cs` | AI module/page/action metadata | registry/matcher | Yes | Delete |
| `Core/SystemModuleMatcher.cs` | Matches Arabic questions to system modules/pages/actions | registry and normalizer | Yes | Delete |
| `Core/SystemModuleRegistry.cs` | Large registry describing operational pages/actions | matcher/service | Yes | Delete |
| `Security/PermissionResolver.cs` | Converts cached permissions into AI answer/action constraints | session helper, registry | Yes | Delete |
| `Security/UserPermissionModels.cs` | Permission row/map models | AI resolver **and non-AI helper/Home code** | **No (shared at present)** | Refactor, then delete only if no non-AI need remains |

### 3.2 Controller and integration points

| File | Lines/section | Purpose | Dependency | Action |
|---|---|---|---|---|
| `SmartFoundation.Mvc/Controllers/Api/AiController.cs` | routes and actions | `POST /api/ai/chat`, `POST /api/ai/feedback` | `IAiChatService`, session, DataEngine, `sp_AiChat_SaveFeedback` | Delete after UI is removed |
| `SmartFoundation.Mvc/Program.cs` | using at 15; DI at 118-130; accessor setup near 135 | Binds options, registers KB/model/chat singleton and configures permission accessor | AI service tree and helpers | Refactor; keep file |
| `SmartFoundation.Mvc/Helpers/UserPermissionSessionHelper.cs` | whole file | Serializes AI permission map to `Ai.UserPermissionMap` | `UserPermissionModels.cs`, session | Likely delete after Home references are removed; confirm no future non-AI use |
| `SmartFoundation.Mvc/Helpers/UserPermissionSessionAccessor.cs` | whole file | Static current-request accessor for AI singleton | HttpContextAccessor and session helper | Delete after AI service removal |
| `SmartFoundation.Mvc/Controllers/Home/HomeController.Index.cs` | around 45-47 | Populates and reads the AI permission cache after login/home load | session helper | Remove only these calls; keep controller |

No AI middleware, hosted/background service, embedding service, vector database, or AI-specific test was found. Logging uses normal ASP.NET logging from AI classes; no dedicated AI log sink/file was found.

## 4. Frontend Inventory

| File | Lines/section | Purpose | Dependency | SafeToRemoveAfterBackendRemoval |
|---|---|---|---|---|
| `Views/Shared/_Layout.cshtml` | 27, 172-173 | Global stylesheet, widget partial and script inclusion | widget/CSS/JS | No: edit shared layout, do not delete it |
| `Views/Shared/_AiAssistantWidget.cshtml` | 32-59 | Launcher, assistant image/title, hidden user/session fields, panel, messages, input and send/close controls | session keys, CSS, JS, `Ai.png` | Yes |
| `wwwroot/js/ai-assistant.js` | whole file; chat near 541; feedback near 589 | Panel behavior, avatar lookup, Markdown rendering, citations, thinking timer, stop/cancel, fetch and feedback | `/api/ai/chat`, `/api/ai/feedback`, DOM IDs, `Ai.png` | Yes |
| `wwwroot/css/ai-assistant.css` | whole file | All `.sf-ai-*` panel, button, message, feedback, thinking and responsive styles | widget class names | Yes |
| `wwwroot/img/Ai.png` | binary asset | Assistant launcher/bot avatar | widget and JavaScript | Yes |

Frontend removal order: remove global layout references first in the same change as widget/JS/CSS/API removal, then confirm no `.sf-ai-*`, `/api/ai/*`, `window.aiAssistant`, assistant labels, or `Ai.png` references remain.

The JavaScript includes its own lightweight Markdown rendering (`parseMarkdown`); no separate Markdown NPM dependency was identified for this feature.

## 5. Configuration Inventory

No secret values, passwords, or connection strings are reproduced here.

| File | Section/Key | Purpose | CanRemoveAfterAI |
|---|---|---|---|
| `appsettings.Development.json` | `AiAssistant.Enabled` | Feature intent flag; not used to guard DI startup | Yes |
| same | `AiAssistant.Provider` | Provider label | Yes |
| same | `AiAssistant.ModelPath` | GGUF location | Yes |
| same | `AiAssistant.ContextSize` | LLM context window | Yes |
| same | `AiAssistant.Threads` | CPU inference threads | Yes |
| same | `AiAssistant.MaxParallelRequests` | inference pool/parallelism | Yes |
| same | `AiAssistant.KnowledgeBasePath` | RAG Markdown root | Yes |
| same | `AiAssistant.RetrievalTopK` | retrieval result count | Yes |
| same | `AiAssistant.MaxTokens` | generation limit | Yes |
| same | `AiAssistant.Temperature` | generation randomness | Yes |
| `appsettings.Production.json` | same ten keys | Production AI runtime values | Yes |
| `Services/AiAssistant/AiAssistantOptions.cs` | defaults including `BaseUrl` and `Model` | Default Ollama/local options | Yes, with class |
| `Program.cs` | `GetSection("AiAssistant")` | Options binding and DI | Yes, remove registrations only |
| `Properties/launchSettings.json` | none found | No AI-specific environment variable names detected | No AI change required |

`appsettings.json` has no `AiAssistant` section. No environment-variable reference specific to AI was found. Configuration files may contain other sensitive settings; those values were deliberately not included.

## 6. NuGet / Dependency Inventory

Direct AI packages in `SmartFoundation.Mvc/SmartFoundation.Mvc.csproj`:

| Package | Version | AI use | Used elsewhere | Action after approval |
|---|---:|---|---|---|
| `LLamaSharp` | 0.25.0 | Model loading, context/executor, token inference | No non-AI source use found | Remove |
| `LLamaSharp.Backend.Cpu` | 0.25.0 | Native CPU backend | No non-AI source use found | Remove |

Observed AI-specific transitive dependency in the current assets graph:

- `Microsoft.Extensions.AI.Abstractions` 9.7.1 is brought by LLamaSharp and should disappear if no other package requires it after restore.
- LLamaSharp native/runtime assets supplied by `LLamaSharp.Backend.Cpu` should disappear from restore and publish output.
- Shared `Microsoft.Extensions.*` assemblies must not be manually removed merely because LLamaSharp references them; ASP.NET and other packages also use them.

No `Directory.Build.*` or `packages.lock.json` AI entry was found. Do not edit `obj/project.assets.json`; restore should regenerate it after package removal.

The MVC project also has explicit publish content rules for `AiModels/**/*.*` and `AiDocs/**/*.md`; remove those rules when the folders are removed. `QuestPDF`, ExcelDataReader, Dapper, SqlClient and test packages are not AI-only.

## 7. Database Inventory

### 7.1 Direct AI objects in the SQL project

| Schema | ObjectName | ObjectType | FilePath | Purpose | ReferencedBy | References | AIOnly | RecommendedActionAfterApproval |
|---|---|---|---|---|---|---|---|---|
| dbo | `AiChatHistory` | Table | `dbo/Tables/AiChatHistory.sql` | Main chat request/answer, intent, entity, user, feedback and timestamps | AI procedures, KPI view, `Masters_CRUD`, reset procedure | user identifiers; indexes | Yes | Delete after retention decision |
| dbo | `AiChatCitations` | Table | `dbo/Tables/AiChatCitations.sql` | Sources/snippets/relevance used in answers | dashboard and save-citation procedure | FK to `AiChatHistory` with cascade | Yes | Delete before/with history |
| dbo | `AiChatFeedback` | Table | `dbo/Tables/AiChatFeedback.sql` | Detailed positive/negative feedback | save-feedback procedure | FK named `AiChatLogId` targets `AiChatHistory.ChatId` | Yes | Delete before/with history |
| dbo | `AiChatLog` | Table | `dbo/Tables/AiChatLog.sql` | Alternate/telemetry log structure | No confirmed project reference beyond definition | user-related fields/indexes | Uncertain | NeedsReview; verify live use |
| dbo | `AiFrequentQuestions` | Table | `dbo/Tables/AiFrequentQuestions.sql` | Aggregated normalized questions and improvement backlog | update/dashboard/questions procedures | AI history-derived values | Yes | Delete |
| dbo | `V_AiChat_Kpi_30Days` | View | `dbo/Views/V_AiChat_Kpi_30Days.sql` | 30-day chat KPI | Unknown external/live consumers | `AiChatHistory` | Yes | Delete after dependency check |
| dbo | `ft_UserAllPermissionsForAi` | Function | `dbo/Functions/ft_UserAllPermissionsForAi.sql` | Returns permission data shaped for AI cache/resolver | `Masters_DataLoad` branch | core permission tables/views | Yes | Delete after branch removal |
| dbo | `sp_AiChat_SaveHistory` | Procedure | `dbo/Stored Procedures/sp_AiChat_SaveHistory.sql` | Inserts chat history and updates frequent questions | AI runtime or legacy path | history, update procedure | Yes | Delete |
| dbo | `sp_AiChat_SaveFeedback` | Procedure | `dbo/Stored Procedures/sp_AiChat_SaveFeedback.sql` | Validates and stores feedback | `AiController` | history and feedback | Yes | Delete |
| dbo | `sp_AiChat_SaveCitation` | Procedure | `dbo/Stored Procedures/sp_AiChat_SaveCitation.sql` | Persists citations | AI service/legacy implementation | history and citations | Yes | Delete |
| dbo | `sp_AiChat_UpdateFrequentQuestions` | Procedure | `dbo/Stored Procedures/sp_AiChat_UpdateFrequentQuestions.sql` | Upserts frequency/improvement data | save-history and `Masters_CRUD` | history and frequent questions | Yes | Delete |
| dbo | `sp_AiChat_GetStatistics` | Procedure | `dbo/Stored Procedures/sp_AiChat_GetStatistics.sql` | AI usage/feedback statistics | Unknown external/live consumers | history | Yes | Delete after dependency check |
| dbo | `sp_AiChat_GetQuestionsNeedingImprovement` | Procedure | `dbo/Stored Procedures/sp_AiChat_GetQuestionsNeedingImprovement.sql` | AI quality backlog | Unknown external/live consumers | frequent questions | Yes | Delete after dependency check |
| dbo | `sp_AiChat_Dashboard` | Procedure | `dbo/Stored Procedures/sp_AiChat_Dashboard.sql` | Dashboard result sets for usage, citations and backlog | Unknown external/live consumers | history, citations, frequent questions | Yes | Delete after dependency check |

Indexes, default constraints, PKs and FKs declared inside the five AI table files are part of those table deletion candidates; they are not counted as separate top-level database objects in the total.

### 7.2 Shared SQL files requiring refactor

| File/object | AI section | Required treatment |
|---|---|---|
| `SmartFoundation.Database.sqlproj` | 14 `<Build Include>` entries | Remove entries only in the approved removal change; keep project file |
| `dbo/Stored Procedures/Masters_DataLoad.sql` | branch calling `ft_UserAllPermissionsForAi` around line 553 | Remove/refactor only the AI data-load action; keep all normal branches |
| `dbo/Stored Procedures/Masters_CRUD.sql` | `pageName_ = 'AiChatHistory'` branches around 5716 onward | Remove AI history/feedback branches; keep procedure |
| `MoveData/Stored Procedures/usp_ResetSystemUsers.sql` | deletes AI history for reset users around line 66 | Remove obsolete AI statement after AI tables are retired; keep procedure |

No separate AI sequence, SQL type, trigger, role-membership file, or explicit GRANT/DENY file was found by project search. Live permissions and untracked dependencies remain unverified.

Local non-official copies also exist and must be handled so AI is not accidentally retained in the deliverable:

- `.gap01-rollback/2026-08-24-gap01-before-alter/dbo_sp_AiChat_SaveFeedback.live.sql`
- `.gap01-rollback/2026-08-24-gap01-before-alter/dbo_sp_AiChat_SaveFeedback.rollback.sql`
- `.buildcheck/AiModels/qwen2.5-7b-instruct-q5_k_m.gguf`

## 8. Live DATACORE Verification

Direct live verification was **not completed**. `sqlcmd` and local SQL Server services are present, but Windows-authenticated connection attempts to the default, `SQLEXPRESS`, and `MSSQLSERVER02` instances failed with client encryption/security-package connection errors. No write command was executed.

### Read-Only DATACORE Verification Queries

Run the following in SSMS while connected to `DATACORE`. Every statement is read-only.

```sql
USE [DATACORE];
SET NOCOUNT ON;

-- 1) Candidate objects by validated AI naming terms.
SELECT s.name AS SchemaName, o.name AS ObjectName, o.type_desc,
       o.create_date, o.modify_date
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND (o.name LIKE '%AiChat%'
       OR o.name LIKE '%AiFrequent%'
       OR o.name LIKE '%Assistant%'
       OR o.name LIKE '%Embedding%'
       OR o.name LIKE '%LLM%')
ORDER BY s.name, o.type_desc, o.name;

-- 2) Exact expected project objects and project/live presence basis.
WITH Expected(ObjectType, SchemaName, ObjectName) AS (
    SELECT * FROM (VALUES
      ('TABLE','dbo','AiChatHistory'),
      ('TABLE','dbo','AiChatCitations'),
      ('TABLE','dbo','AiChatFeedback'),
      ('TABLE','dbo','AiChatLog'),
      ('TABLE','dbo','AiFrequentQuestions'),
      ('VIEW','dbo','V_AiChat_Kpi_30Days'),
      ('FUNCTION','dbo','ft_UserAllPermissionsForAi'),
      ('PROCEDURE','dbo','sp_AiChat_SaveHistory'),
      ('PROCEDURE','dbo','sp_AiChat_SaveFeedback'),
      ('PROCEDURE','dbo','sp_AiChat_SaveCitation'),
      ('PROCEDURE','dbo','sp_AiChat_UpdateFrequentQuestions'),
      ('PROCEDURE','dbo','sp_AiChat_GetStatistics'),
      ('PROCEDURE','dbo','sp_AiChat_GetQuestionsNeedingImprovement'),
      ('PROCEDURE','dbo','sp_AiChat_Dashboard')
    ) v(ObjectType, SchemaName, ObjectName)
)
SELECT e.*, CASE WHEN o.object_id IS NULL THEN 'PROJECT_ONLY_OR_MISSING_LIVE' ELSE 'PRESENT_LIVE' END AS LiveStatus,
       o.type_desc, o.modify_date
FROM Expected e
LEFT JOIN sys.schemas s ON s.name = e.SchemaName
LEFT JOIN sys.objects o ON o.schema_id = s.schema_id AND o.name = e.ObjectName
ORDER BY e.ObjectType, e.ObjectName;

-- 3) Dependencies to and from candidate AI objects.
SELECT OBJECT_SCHEMA_NAME(d.referencing_id) AS ReferencingSchema,
       OBJECT_NAME(d.referencing_id) AS ReferencingObject,
       o.type_desc AS ReferencingType,
       d.referenced_schema_name AS ReferencedSchema,
       d.referenced_entity_name AS ReferencedObject
FROM sys.sql_expression_dependencies d
LEFT JOIN sys.objects o ON o.object_id = d.referencing_id
WHERE OBJECT_NAME(d.referencing_id) LIKE '%Ai%'
   OR d.referenced_entity_name LIKE '%Ai%'
   OR OBJECT_NAME(d.referencing_id) LIKE '%Assistant%'
   OR d.referenced_entity_name LIKE '%Assistant%'
ORDER BY ReferencingSchema, ReferencingObject, ReferencedSchema, ReferencedObject;

-- 4) Text references missed by dependency metadata (dynamic SQL included as text search).
SELECT s.name AS SchemaName, o.name AS ObjectName, o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%AiChat%'
   OR m.definition LIKE '%AiFrequentQuestions%'
   OR m.definition LIKE '%ft_UserAllPermissionsForAi%'
   OR m.definition LIKE '%AiAssistant%'
ORDER BY s.name, o.name;

-- 5) Definitions/hashes for manual project-vs-live comparison.
SELECT s.name AS SchemaName, o.name AS ObjectName, o.type_desc,
       HASHBYTES('SHA2_256', CONVERT(varbinary(max), m.definition)) AS DefinitionHash,
       m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.name LIKE '%AiChat%'
   OR o.name LIKE '%AiFrequent%'
   OR o.name = 'ft_UserAllPermissionsForAi'
ORDER BY s.name, o.name;

-- 6) Foreign keys touching AI tables.
SELECT fk.name AS ForeignKeyName,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) AS ChildSchema,
       OBJECT_NAME(fk.parent_object_id) AS ChildTable,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ParentSchema,
       OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
       fk.delete_referential_action_desc, fk.update_referential_action_desc
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.parent_object_id) LIKE 'Ai%'
   OR OBJECT_NAME(fk.referenced_object_id) LIKE 'Ai%'
ORDER BY fk.name;

-- 7) Explicit database permissions on AI objects.
SELECT USER_NAME(p.grantee_principal_id) AS PrincipalName,
       p.permission_name, p.state_desc,
       OBJECT_SCHEMA_NAME(p.major_id) AS SchemaName,
       OBJECT_NAME(p.major_id) AS ObjectName
FROM sys.database_permissions p
WHERE p.class = 1
  AND (OBJECT_NAME(p.major_id) LIKE '%Ai%'
       OR OBJECT_NAME(p.major_id) LIKE '%Assistant%')
ORDER BY PrincipalName, SchemaName, ObjectName, p.permission_name;

-- 8) Row counts without reading chat content.
SELECT s.name AS SchemaName, t.name AS TableName,
       SUM(p.rows) AS ApproximateRowCount
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE t.name IN ('AiChatHistory','AiChatCitations','AiChatFeedback','AiChatLog','AiFrequentQuestions')
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- 9) Indexes and constraints belonging to AI tables.
SELECT s.name AS SchemaName, t.name AS TableName, i.name AS IndexName,
       i.type_desc, i.is_unique, i.is_primary_key, i.is_unique_constraint
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.indexes i ON i.object_id = t.object_id
WHERE t.name IN ('AiChatHistory','AiChatCitations','AiChatFeedback','AiChatLog','AiFrequentQuestions')
ORDER BY s.name, t.name, i.index_id;

-- 10) Possible SQL Agent jobs with AI references.
SELECT j.name AS JobName, s.step_id, s.step_name, s.database_name, s.command
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps s ON s.job_id = j.job_id
WHERE s.command LIKE '%AiChat%'
   OR s.command LIKE '%AiAssistant%'
ORDER BY j.name, s.step_id;
```

Do not execute removal DDL until these results have been reviewed and a retention/export decision is approved.

## 9. Documentation Impact

### 9.1 Runtime AI knowledge corpus

All 43 Markdown files under `SmartFoundation.Mvc/AiDocs/UserHelp` are runtime RAG content and AI-only deployment content. They cover general chat, Housing definitions/procedures/waiting lists, Electronic Bill System, Income System and Control Panel permissions. They are candidates for removal from the official runtime package. If their user-help content remains useful outside AI, copy/adapt it into the official user manual **before** deleting the AI corpus; do not keep it under `AiDocs` in the official runtime.

### 9.2 Formal documentation detected by text search

Strong AI references were found in 35 text documentation files:

- `README.md`
- `docs/ControllerMigrationChecklist.md`
- `docs/dual-date-picker.md`
- `docs/Migration_Effort_Risk_Assessment.md`
- `Documentation/Documentation-Progress.json`
- `Documentation/Diagrams/21-Reports-and-Integrations-Flows.md`
- `Documentation/security-gap-register.md`
- `Documentation/security-gap-status.md`
- `Documentation/Work/01-System-Inventory.md` through affected program/architecture/operations files, including `03-System-Architecture-and-Shared-Components.md`, `04-ControlPanel-Program.md`, `05-Housing-Definitions.md`, `06-Housing-Procedures.md`, `07-Housing-Waiting-Lists-and-Imports.md`, `08-IncomeSystem.md`, `09-ElectronicBillSystem.md`, `10-Home-and-Login.md`, `11-Live-Database-and-ERD.md`, `12-Reports-Integrations-and-Operations.md`, and `13-Final-Coverage-Audit.md`
- `Documentation/Prompts/02` through `15` where AI appears in documentation-generation instructions

The most operationally significant references are in the architecture, reports/integrations/operations, live database/ERD, security, final audit, diagram 21 and README documents.

### 9.3 Generated Word/PDF documents

Read-only extraction found:

| Document | AI term matches | Required action |
|---|---:|---|
| `SmartFoundation_Interim_Documentation.docx` | 17 | Rewrite/regenerate after source documentation update |
| `SmartFoundation_Interim_Documentation.pdf` | 17 | Regenerate from corrected source/DOCX |
| `SmartFoundation_System_Documentation.docx` | 38 | Rewrite/regenerate; currently describes active AI runtime |
| `SmartFoundation_System_Documentation.pdf` | 37 | Regenerate from corrected source/DOCX |
| `errors.docx` / `errors.pdf` | 0 | No AI update required |

## 10. Dependency Analysis

### 10.1 Confirmed dependency chains

| Producer | Consumer(s) | Removal implication |
|---|---|---|
| `AiAssistantOptions` | Program, model holder, KB, providers | Remove binding and all consumers together |
| `LLamaModelHolder` | Embedded service variants | Remove DI singleton before package/model removal |
| `IAiChatService` | `AiController`, providers | Remove controller and DI registration with interface/providers |
| `IAiKnowledgeBase` | active and Ollama providers | Remove providers and KB registration together |
| `AiDocs` | `FileAiKnowledgeBase`, csproj publish rule | Remove publish rule and runtime consumer |
| GGUF model | holder, config, csproj publish rule, `.gitignore` | Remove runtime/config/publish references; decide whether historical artifact remains outside official tree |
| Widget/JS | layout and API endpoints | Remove layout integration and endpoints in same release |
| Permission map models | AI security plus Home/helpers | Shared at present; refactor non-AI files before deletion |
| `ft_UserAllPermissionsForAi` | `Masters_DataLoad` | Remove only AI branch from shared procedure |
| `AiChatHistory` | procedures, view, citations/feedback FKs, `Masters_CRUD`, reset procedure | Resolve dependents and retention before table removal |
| `AiFrequentQuestions` | updater/dashboard/backlog procedure | Remove procedures before table |
| `sp_AiChat_SaveFeedback` | controller | Remove endpoint consumer before procedure |

### 10.2 Components not proven safe for blind deletion

- `Program.cs`, `_Layout.cshtml`, MVC `.csproj`, the two environment appsettings files and `.gitignore` are shared files; edit only AI sections.
- `HomeController.Index.cs` is operational; remove only AI permission-cache calls.
- `Masters_DataLoad`, `Masters_CRUD` and `usp_ResetSystemUsers` contain non-AI operations; edit only isolated AI branches/statements.
- `UserPermissionModels.cs` is in an AI namespace but is consumed by helpers/Home. It becomes deletable only after those consumers are removed or replaced.
- Core permission tables/views used by `ft_UserAllPermissionsForAi` serve the normal authorization system and must remain.
- DataEngine, session infrastructure, HttpContextAccessor and standard logging are shared and must remain.

## 11. Safe Delete Candidates

These are structurally AI-only candidates **after approval and in the ordered removal change**, not authorization to delete now:

- 19 AI-only files under `Services/AiAssistant` excluding shared-at-present `Security/UserPermissionModels.cs`.
- `Controllers/Api/AiController.cs`.
- `_AiAssistantWidget.cshtml`, `ai-assistant.js`, `ai-assistant.css`, `img/Ai.png`.
- All 43 files under `AiDocs` after useful user-help content is migrated if desired.
- Both `AiModels` files, including the 5,444,831,648-byte Qwen GGUF, plus the `.buildcheck` duplicate.
- Two `.gap01-rollback` AI procedure snapshots if rollback retention policy permits; otherwise archive outside official deliverable.
- Two LLamaSharp direct packages after source removal.
- The 14 direct SQL objects only after live verification, dependency review and retention approval.

## 12. Shared Components That Must Remain

| Component | Must remain | AI-specific follow-up |
|---|---|---|
| `Program.cs` | Yes | Remove AI using, options binding, model/KB/chat registrations and accessor setup if unused |
| `_Layout.cshtml` | Yes | Remove three AI includes only |
| `SmartFoundation.Mvc.csproj` | Yes | Remove LLama packages and AiDocs/AiModels content rules only |
| Development/Production appsettings | Yes | Remove `AiAssistant` section only; preserve all other keys/secrets |
| Home controller | Yes | Remove permission snapshot population/read only if AI-only |
| `Masters_DataLoad` | Yes | Remove AI permissions branch only |
| `Masters_CRUD` | Yes | Remove AI history/feedback branches only |
| `usp_ResetSystemUsers` | Yes | Remove obsolete AI-table statement only |
| Core permission schema | Yes | Used by normal authorization; do not remove with AI function |
| DataEngine and `ISmartComponentService` | Yes | Shared across application |
| Session/authentication/login infrastructure | Yes | Remove only AI cache key/helper path |
| Standard Microsoft.Extensions dependencies | Yes | Shared by ASP.NET and other packages |

## 13. Uncertain Items Requiring Review

1. **Live parity:** whether all 14 project objects exist in DATACORE and whether DATACORE has AI-only objects absent from the SQL project.
2. **Live dependencies:** external reports, jobs, ad-hoc scripts or dynamic SQL may consume the AI view/procedures/tables.
3. **Live permissions:** explicit grants or role access on AI objects were not verifiable without connection.
4. **Data retention:** chat history may contain operational/audit/personal data; approve export/retention/disposal before database deletion.
5. **`AiChatLog`:** no active project consumer was confirmed; live use must be checked before classification as safely removable.
6. **Permission cache:** helpers appear created for AI, but Home currently consumes them. Confirm there is no intended non-AI authorization/dashboard use before deleting models/helpers and session key.

## 14. Proposed Documentation Changes

The official documents must describe the post-removal system without presenting AI as active. The single approved historical statement is retained in `AI-Removal-Record.md` only.

| DocumentPath/group | CurrentSection | CurrentAIReference | RequiredUpdate |
|---|---|---|---|
| `README.md` | technology/features/deployment | AI assistant/runtime references | REWRITE; add one historical note |
| `Documentation/Work/01-System-Inventory.md` | packages/components inventory | LLamaSharp/AI inventory | REMOVE active entries; ADD_REMOVAL_NOTE |
| `Documentation/Work/03-System-Architecture-and-Shared-Components.md` | architecture/configuration | `AiAssistant` config and service architecture | REWRITE topology/config sections |
| `Documentation/Work/04-ControlPanel-Program.md` | permissions/integrations | AI permission/mapping references | REWRITE to normal permission flow only |
| `Documentation/Work/05` through `10` | module integration notes | assistant help/page references | REMOVE active assistant references; retain module behavior |
| `Documentation/Work/11-Live-Database-and-ERD.md` | database objects/ERD | AI tables/procedures/function/view | REWRITE after approved DB removal and live compare |
| `Documentation/Work/12-Reports-Integrations-and-Operations.md` | AI/LLama/Ollama, packages, deployment, backup, troubleshooting | active GGUF, AiDocs, startup capacity and publishing | REMOVE operational AI requirements; ADD_REMOVAL_NOTE |
| `Documentation/Work/13-Final-Coverage-Audit.md` | coverage/status | AI described in final system | REWRITE final scope |
| `Documentation/Diagrams/21-Reports-and-Integrations-Flows.md` | integration diagram | AI -> embedded LLamaSharp/GGUF | REMOVE node/edges; regenerate diagram |
| `Documentation/security-gap-register.md` and `security-gap-status.md` | AI feedback/security gap entries | AI procedure/permission risk | KEEP_AS_HISTORICAL_NOTE with closed/removed status |
| `Documentation/Documentation-Progress.json` | coverage/progress metadata | AI deliverable state | REWRITE status after document regeneration |
| `Documentation/Prompts/02` through `15` | generation instructions | instruct generated docs to include AI | REWRITE so regeneration does not reintroduce AI as active |
| affected `docs/*.md` | migration/checklist references | AI or assistant references | Review each match; REMOVE only feature-specific statements |
| `SmartFoundation_Interim_Documentation.docx/.pdf` | architecture/integration/deployment | 17 AI term matches | REGENERATE after sources update; ADD_REMOVAL_NOTE once |
| `SmartFoundation_System_Documentation.docx/.pdf` | multiple operational sections | 37-38 AI term matches | REGENERATE; ensure no active feature claim remains |
| `SmartFoundation.Mvc/AiDocs/**` | whole corpus | runtime knowledge base | REMOVE from official runtime; optionally migrate useful help into User Guide |

## 15. Proposed AI Removal Sequence

1. Obtain explicit approval and choose a branch/backup strategy; record the historical note wording.
2. Run the DATACORE read-only queries; reconcile project/live objects and identify external dependencies/jobs/permissions.
3. Decide retention/export/disposal for chat history, feedback, citations, logs and frequent questions.
4. Add or update tests around login, session, permissions and affected pages before removing the AI permission cache.
5. Remove global frontend includes, widget, JS/CSS/image and AI API controller in one coherent change.
6. Remove AI DI registrations/options and refactor Home/session permission helper/accessor usage.
7. Remove AI services/core/security files after all references are gone.
8. Remove LLamaSharp package references and AiDocs/AiModels publish rules; restore and inspect transitive package removal.
9. Remove AI configuration sections and model/knowledge assets, including ignored/local build copies per retention policy.
10. Refactor shared SQL procedures first, then remove AI procedures/view/function and finally dependent tables/FKs in an approved database deployment.
11. Remove AI entries from the SQL project and verify schema compare shows only the approved changes.
12. Update source documentation and prompts, regenerate DOCX/PDF deliverables, and retain only the historical note.
13. Perform the complete verification checklist below before declaring the official version AI-free.

## 16. Post-Removal Verification Checklist

- [ ] Search the entire project with ignored/untracked files included for `AiAssistant`, `AiChat`, `AiDocs`, `AiModels`, `LLama`, `Ollama`, `Qwen`, `GGUF`, `/api/ai`, `.sf-ai-`, `المساعد الذكي`, `RAG`, `Embedding` and the session key `Ai.UserPermissionMap`.
- [ ] Confirm no AI DI registration, options binding, model singleton or permission accessor setup remains.
- [ ] Confirm no `LLamaSharp` or `LLamaSharp.Backend.Cpu` direct package remains.
- [ ] Restore and confirm AI-only transitive/native assets, including `Microsoft.Extensions.AI.Abstractions` when otherwise unused, disappear.
- [ ] Confirm `AiDocs` and `AiModels` are absent from the official tree and publish output.
- [ ] Confirm the widget partial, layout includes, JS, CSS, image and all `.sf-ai-*` selectors are absent.
- [ ] Confirm `/api/ai/chat` and `/api/ai/feedback` return no application route and no fetch call remains.
- [ ] Confirm no AI controller/service/interface/model/prompt/RAG/retrieval code remains.
- [ ] Confirm no AI-specific session data or permission cache is written during login/home navigation.
- [ ] Run read-only live dependency checks before deployment and verify approved AI database objects are absent afterward.
- [ ] Confirm shared permission objects and non-AI branches of master procedures remain intact.
- [ ] Rebuild the full solution from clean generated outputs.
- [ ] Run all unit tests; add coverage for any refactored permission/session behavior.
- [ ] Start the system and inspect startup logs for missing model/service/config errors.
- [ ] Test Login, logout, session expiry and unauthorized access.
- [ ] Test representative Housing definitions, procedures, waiting lists and imports.
- [ ] Test IncomeSystem flows and reports.
- [ ] Test ElectronicBillSystem meters, readings and services.
- [ ] Inspect browser Console and Network for missing AI assets, 404s, JavaScript errors and obsolete API requests.
- [ ] Publish to a clean directory and search publish output for AI assemblies, native runtimes, GGUF, AiDocs, widget assets and AI config.
- [ ] Verify deployment size and startup memory/time no longer include the 5.44 GB model/runtime cost.
- [ ] Re-run database schema compare and review only expected approved removals.
- [ ] Search all Markdown, prompts, diagrams, DOCX and PDF outputs; ensure official documentation does not describe AI as active.
- [ ] Confirm the historical statement appears once in an appropriate release/history section and not as an operational feature.
- [ ] Do not delete the pre-removal backup until build, tests, runtime, publish, database and documentation verification all pass.

## Final Candidate Register

| ID | Category | Path/Object | Purpose | Dependencies | AIOnly | DeleteCandidate | RiskIfRemoved | RequiredFollowUp |
|---|---|---|---|---|---|---|---|---|
| AI-SRC-001 | AI-SRC | `Services/AiAssistant/*` | Model, retrieval, routing, prompts, Arabic normalization | DI/controller/config/DB | Mostly; one shared model file | Yes after refactor | Compile/startup failure if consumers remain | Remove references and rebuild |
| AI-SRC-002 | AI-SRC | `Controllers/Api/AiController.cs` | Chat and feedback API | service, DataEngine, SP | Yes | Yes | UI requests fail if removed first | Remove UI in same change |
| AI-UI-001 | AI-UI | widget/JS/CSS/layout references | Global chat UI | API/session/image | Partial: layout shared | Yes/edit | Broken layout/404/JS errors | Remove includes and assets together |
| AI-ASSET-001 | AI-ASSET | `AiModels/*`, `.buildcheck/AiModels/*` | Qwen GGUF and local notes | config/model holder/publish | Yes | Yes | Startup failure if DI remains | Remove runtime first; inspect publish |
| AI-ASSET-002 | AI-ASSET | `AiDocs/**` | RAG knowledge corpus | file KB/publish | Yes | Yes | Loss of help content | Migrate useful help first if desired |
| AI-CONFIG-001 | AI-CONFIG | Dev/Production `AiAssistant` sections | Runtime tuning/paths | Options/DI | Yes sections | Yes | Config drift if code remains | Remove binding and verify startup |
| AI-PKG-001 | AI-PKG | LLamaSharp packages | Local inference | AI services | Yes | Yes | Compile failure if types remain | Remove source, restore, inspect assets |
| AI-DB-001 | AI-DB | 14 direct dbo objects | persistence/analytics/permissions | shared SP branches and live consumers | Mostly | Yes after approval | Data loss/dependency break | Live verify and decide retention |
| AI-DB-002 | AI-DB | `Masters_DataLoad`, `Masters_CRUD`, reset SP | Shared gateways/reset | many non-AI flows | No | No | Severe system break if deleted | Refactor AI branches only |
| AI-SECURITY-001 | AI-SECURITY | permission models/helpers/cache | AI-aware authorization | Home/session/core permissions | Shared at present | Conditional | Login/permission regression | Confirm non-AI use; test before removal |
| AI-DOC-001 | AI-DOC | 39 formal docs | Official architecture/operations record | source docs and generated outputs | No | No | Official docs become false/stale | Rewrite/regenerate + historical note |
| AI-TEST-001 | AI-TEST | no AI-specific tests found | Verification gap | removal work | N/A | N/A | Regressions may be missed | Add targeted removal regression tests |
