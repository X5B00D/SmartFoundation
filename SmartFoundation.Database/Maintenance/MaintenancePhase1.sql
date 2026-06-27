USE [DATACORE];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'Maintenance')
BEGIN
    EXEC(N'CREATE SCHEMA [Maintenance]');
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceCategory]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[MaintenanceCategory]
    (
        [MaintenanceCategoryID] BIGINT IDENTITY(1,1) NOT NULL,
        [IdaraId_FK] BIGINT NOT NULL,
        [ParentID] BIGINT NULL,
        [CategoryName_A] NVARCHAR(250) NOT NULL,
        [CategoryName_E] NVARCHAR(250) NULL,
        [Description_A] NVARCHAR(1000) NULL,
        [DisplayOrder] INT NOT NULL CONSTRAINT [DF_MaintenanceCategory_DisplayOrder] DEFAULT (0),
        [entryUser] BIGINT NULL,
        [entryDate] DATETIME NOT NULL CONSTRAINT [DF_MaintenanceCategory_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [updateUser] BIGINT NULL,
        [updateDate] DATETIME NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_MaintenanceCategory_IsActive] DEFAULT (1),
        CONSTRAINT [PK_MaintenanceCategory] PRIMARY KEY CLUSTERED ([MaintenanceCategoryID] ASC),
        CONSTRAINT [UQ_MaintenanceCategory_Idara_Category] UNIQUE NONCLUSTERED ([IdaraId_FK] ASC, [MaintenanceCategoryID] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceCategoryRouting]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[MaintenanceCategoryRouting]
    (
        [MaintenanceCategoryRoutingID] BIGINT IDENTITY(1,1) NOT NULL,
        [IdaraId_FK] BIGINT NOT NULL,
        [MaintenanceCategoryID] BIGINT NOT NULL,
        [ResponsibleDSDID] BIGINT NOT NULL,
        [IsDefault] BIT NOT NULL CONSTRAINT [DF_MaintenanceCategoryRouting_IsDefault] DEFAULT (1),
        [Notes] NVARCHAR(1000) NULL,
        [entryUser] BIGINT NULL,
        [entryDate] DATETIME NOT NULL CONSTRAINT [DF_MaintenanceCategoryRouting_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [updateUser] BIGINT NULL,
        [updateDate] DATETIME NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_MaintenanceCategoryRouting_IsActive] DEFAULT (1),
        CONSTRAINT [PK_MaintenanceCategoryRouting] PRIMARY KEY CLUSTERED ([MaintenanceCategoryRoutingID] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceRequestStatus]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[MaintenanceRequestStatus]
    (
        [StatusID] INT NOT NULL,
        [StatusName_A] NVARCHAR(100) NOT NULL,
        [StatusCode] NVARCHAR(50) NOT NULL,
        [DisplayOrder] INT NOT NULL,
        [IdaraId_FK] BIGINT NULL,
        [entryDate] DATETIME NULL CONSTRAINT [DF_MaintenanceRequestStatus_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [IsClosed] BIT NOT NULL CONSTRAINT [DF_MaintenanceRequestStatus_IsClosed] DEFAULT (0),
        [IsActive] BIT NOT NULL CONSTRAINT [DF_MaintenanceRequestStatus_IsActive] DEFAULT (1),
        CONSTRAINT [PK_MaintenanceRequestStatus] PRIMARY KEY CLUSTERED ([StatusID] ASC),
        CONSTRAINT [UQ_MaintenanceRequestStatus_StatusCode] UNIQUE NONCLUSTERED ([StatusCode] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenancePriority]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[MaintenancePriority]
    (
        [PriorityID] INT NOT NULL,
        [PriorityName_A] NVARCHAR(100) NOT NULL,
        [PriorityCode] NVARCHAR(50) NOT NULL,
        [DisplayOrder] INT NOT NULL,
        [IdaraId_FK] BIGINT NULL,
        [entryDate] DATETIME NULL CONSTRAINT [DF_MaintenancePriority_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_MaintenancePriority_IsActive] DEFAULT (1),
        CONSTRAINT [PK_MaintenancePriority] PRIMARY KEY CLUSTERED ([PriorityID] ASC),
        CONSTRAINT [UQ_MaintenancePriority_PriorityCode] UNIQUE NONCLUSTERED ([PriorityCode] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceActionType]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[MaintenanceActionType]
    (
        [ActionTypeID] INT NOT NULL,
        [ActionTypeName_A] NVARCHAR(150) NOT NULL,
        [ActionTypeCode] NVARCHAR(80) NOT NULL,
        [DisplayOrder] INT NOT NULL,
        [IdaraId_FK] BIGINT NULL,
        [entryDate] DATETIME NULL CONSTRAINT [DF_MaintenanceActionType_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_MaintenanceActionType_IsActive] DEFAULT (1),
        CONSTRAINT [PK_MaintenanceActionType] PRIMARY KEY CLUSTERED ([ActionTypeID] ASC),
        CONSTRAINT [UQ_MaintenanceActionType_ActionTypeCode] UNIQUE NONCLUSTERED ([ActionTypeCode] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceActionReason]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[MaintenanceActionReason]
    (
        [ReasonID] INT IDENTITY(1,1) NOT NULL,
        [ReasonName_A] NVARCHAR(200) NOT NULL,
        [ReasonCode] NVARCHAR(80) NULL,
        [IdaraId_FK] BIGINT NULL,
        [entryDate] DATETIME NULL CONSTRAINT [DF_MaintenanceActionReason_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_MaintenanceActionReason_IsActive] DEFAULT (1),
        CONSTRAINT [PK_MaintenanceActionReason] PRIMARY KEY CLUSTERED ([ReasonID] ASC),
        CONSTRAINT [UQ_MaintenanceActionReason_ReasonName_A] UNIQUE NONCLUSTERED ([ReasonName_A] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[BuildingMaintenanceRequest]
    (
        [RequestID] BIGINT IDENTITY(1,1) NOT NULL,
        [IdaraId_FK] BIGINT NOT NULL,
        [RequestNo] NVARCHAR(50) NULL,
        [TransactionID_FK] BIGINT NULL,
        [ParentRequestID] BIGINT NULL,
        [RootRequestID] BIGINT NULL,
        [RequestLevel] INT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequest_RequestLevel] DEFAULT (0),
        [IsSubRequest] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequest_IsSubRequest] DEFAULT (0),
        [IsBlockingParent] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequest_IsBlockingParent] DEFAULT (1),
        [BuildingID] BIGINT NULL,
        [UnitID] BIGINT NULL,
        [ResidentID] BIGINT NULL,
        [MaintenanceCategoryID] BIGINT NOT NULL,
        [CurrentDSDID] BIGINT NULL,
        [OriginalDSDID] BIGINT NULL,
        [StatusID] INT NOT NULL,
        [PriorityID] INT NOT NULL,
        [Description_A] NVARCHAR(MAX) NOT NULL,
        [HasDispute] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequest_HasDispute] DEFAULT (0),
        [DisputeStatusID] INT NULL,
        [EscalationLevel] INT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequest_EscalationLevel] DEFAULT (0),
        [IsLockedByDecision] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequest_IsLockedByDecision] DEFAULT (0),
        [RequestDate] DATETIME NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequest_RequestDate] DEFAULT (GETDATE()),
        [ClosedDate] DATETIME NULL,
        [entryUser] BIGINT NULL,
        [entryDate] DATETIME NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequest_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [updateUser] BIGINT NULL,
        [updateDate] DATETIME NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequest_IsActive] DEFAULT (1),
        CONSTRAINT [PK_BuildingMaintenanceRequest] PRIMARY KEY CLUSTERED ([RequestID] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAssignment]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[BuildingMaintenanceRequestAssignment]
    (
        [AssignmentID] BIGINT IDENTITY(1,1) NOT NULL,
        [IdaraId_FK] BIGINT NULL,
        [RequestID] BIGINT NOT NULL,
        [AssignedToUserID] BIGINT NOT NULL,
        [AssignedByUserID] BIGINT NULL,
        [AssignedDSDID] BIGINT NULL,
        [AssignedDate] DATETIME NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestAssignment_AssignedDate] DEFAULT (GETDATE()),
        [InspectionDate] DATETIME NULL,
        [CompletionDate] DATETIME NULL,
        [AssignmentStatusID] INT NULL,
        [ReportText] NVARCHAR(MAX) NULL,
        [NeedsApproval] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestAssignment_NeedsApproval] DEFAULT (0),
        [NeedsSubRequest] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestAssignment_NeedsSubRequest] DEFAULT (0),
        [entryUser] BIGINT NULL,
        [entryDate] DATETIME NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestAssignment_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [updateUser] BIGINT NULL,
        [updateDate] DATETIME NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestAssignment_IsActive] DEFAULT (1),
        CONSTRAINT [PK_BuildingMaintenanceRequestAssignment] PRIMARY KEY CLUSTERED ([AssignmentID] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAction]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[BuildingMaintenanceRequestAction]
    (
        [ActionID] BIGINT IDENTITY(1,1) NOT NULL,
        [IdaraId_FK] BIGINT NULL,
        [RequestID] BIGINT NOT NULL,
        [ActionTypeID] INT NOT NULL,
        [ReasonID] INT NULL,
        [FromDSDID] BIGINT NULL,
        [ToDSDID] BIGINT NULL,
        [FromUserID] BIGINT NULL,
        [ToUserID] BIGINT NULL,
        [OldStatusID] INT NULL,
        [NewStatusID] INT NULL,
        [ActionNote] NVARCHAR(MAX) NULL,
        [ActionDate] DATETIME NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestAction_ActionDate] DEFAULT (GETDATE()),
        [entryUser] BIGINT NULL,
        [entryDate] DATETIME NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestAction_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [updateUser] BIGINT NULL,
        [updateDate] DATETIME NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestAction_IsActive] DEFAULT (1),
        CONSTRAINT [PK_BuildingMaintenanceRequestAction] PRIMARY KEY CLUSTERED ([ActionID] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestApproval]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[BuildingMaintenanceRequestApproval]
    (
        [ApprovalID] BIGINT IDENTITY(1,1) NOT NULL,
        [IdaraId_FK] BIGINT NULL,
        [RequestID] BIGINT NOT NULL,
        [RequestedByUserID] BIGINT NULL,
        [RequestedDate] DATETIME NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestApproval_RequestedDate] DEFAULT (GETDATE()),
        [ApprovalLevel] INT NULL,
        [ApprovalDSDID] BIGINT NULL,
        [ApprovalUserID] BIGINT NULL,
        [ApprovalStatusID] INT NULL,
        [Reason] NVARCHAR(MAX) NULL,
        [EstimatedCost] DECIMAL(18,2) NULL,
        [DecisionNote] NVARCHAR(MAX) NULL,
        [DecisionDate] DATETIME NULL,
        [entryUser] BIGINT NULL,
        [entryDate] DATETIME NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestApproval_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [updateUser] BIGINT NULL,
        [updateDate] DATETIME NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestApproval_IsActive] DEFAULT (1),
        CONSTRAINT [PK_BuildingMaintenanceRequestApproval] PRIMARY KEY CLUSTERED ([ApprovalID] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestDispute]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[BuildingMaintenanceRequestDispute]
    (
        [DisputeID] BIGINT IDENTITY(1,1) NOT NULL,
        [IdaraId_FK] BIGINT NULL,
        [RequestID] BIGINT NOT NULL,
        [RaisedByDSDID] BIGINT NULL,
        [AgainstDSDID] BIGINT NULL,
        [RaisedByUserID] BIGINT NULL,
        [Reason] NVARCHAR(MAX) NOT NULL,
        [ArbitrationDSDID] BIGINT NULL,
        [DecisionByUserID] BIGINT NULL,
        [DecisionNote] NVARCHAR(MAX) NULL,
        [IsBindingDecision] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestDispute_IsBindingDecision] DEFAULT (1),
        [DecisionDate] DATETIME NULL,
        [DisputeStatusID] INT NULL,
        [entryUser] BIGINT NULL,
        [entryDate] DATETIME NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestDispute_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [updateUser] BIGINT NULL,
        [updateDate] DATETIME NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestDispute_IsActive] DEFAULT (1),
        CONSTRAINT [PK_BuildingMaintenanceRequestDispute] PRIMARY KEY CLUSTERED ([DisputeID] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceDisputeRule]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[MaintenanceDisputeRule]
    (
        [DisputeRuleID] BIGINT IDENTITY(1,1) NOT NULL,
        [IdaraId_FK] BIGINT NOT NULL,
        [FromDSDID] BIGINT NULL,
        [ToDSDID] BIGINT NULL,
        [ArbitrationDSDID] BIGINT NOT NULL,
        [RuleDescription] NVARCHAR(1000) NULL,
        [entryUser] BIGINT NULL,
        [entryDate] DATETIME NOT NULL CONSTRAINT [DF_MaintenanceDisputeRule_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [updateUser] BIGINT NULL,
        [updateDate] DATETIME NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_MaintenanceDisputeRule_IsActive] DEFAULT (1),
        CONSTRAINT [PK_MaintenanceDisputeRule] PRIMARY KEY CLUSTERED ([DisputeRuleID] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceSLA]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[MaintenanceSLA]
    (
        [SLAID] BIGINT IDENTITY(1,1) NOT NULL,
        [IdaraId_FK] BIGINT NOT NULL,
        [MaintenanceCategoryID] BIGINT NULL,
        [PriorityID] INT NULL,
        [InspectionHours] INT NULL,
        [ExecutionHours] INT NULL,
        [ApprovalHours] INT NULL,
        [TransferResponseHours] INT NULL,
        [entryUser] BIGINT NULL,
        [entryDate] DATETIME NOT NULL CONSTRAINT [DF_MaintenanceSLA_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [updateUser] BIGINT NULL,
        [updateDate] DATETIME NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_MaintenanceSLA_IsActive] DEFAULT (1),
        CONSTRAINT [PK_MaintenanceSLA] PRIMARY KEY CLUSTERED ([SLAID] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestSLA]', N'U') IS NULL
BEGIN
    CREATE TABLE [Maintenance].[BuildingMaintenanceRequestSLA]
    (
        [RequestSLAID] BIGINT IDENTITY(1,1) NOT NULL,
        [IdaraId_FK] BIGINT NULL,
        [RequestID] BIGINT NOT NULL,
        [InspectionDueDate] DATETIME NULL,
        [ExecutionDueDate] DATETIME NULL,
        [ApprovalDueDate] DATETIME NULL,
        [IsInspectionLate] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestSLA_IsInspectionLate] DEFAULT (0),
        [IsExecutionLate] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestSLA_IsExecutionLate] DEFAULT (0),
        [IsApprovalLate] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestSLA_IsApprovalLate] DEFAULT (0),
        [entryUser] BIGINT NULL,
        [entryDate] DATETIME NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestSLA_entryDate] DEFAULT (GETDATE()),
        [entryData] NVARCHAR(20) NULL,
        [hostName] NVARCHAR(200) NULL,
        [updateUser] BIGINT NULL,
        [updateDate] DATETIME NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_BuildingMaintenanceRequestSLA_IsActive] DEFAULT (1),
        CONSTRAINT [PK_BuildingMaintenanceRequestSLA] PRIMARY KEY CLUSTERED ([RequestSLAID] ASC)
    );
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceCategory]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceCategory_Parent')
BEGIN
    ALTER TABLE [Maintenance].[MaintenanceCategory] WITH CHECK
    ADD CONSTRAINT [FK_MaintenanceCategory_Parent]
    FOREIGN KEY ([IdaraId_FK], [ParentID])
    REFERENCES [Maintenance].[MaintenanceCategory] ([IdaraId_FK], [MaintenanceCategoryID]);

    ALTER TABLE [Maintenance].[MaintenanceCategory] CHECK CONSTRAINT [FK_MaintenanceCategory_Parent];
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceCategoryRouting]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceCategoryRouting_MaintenanceCategory')
BEGIN
    ALTER TABLE [Maintenance].[MaintenanceCategoryRouting] WITH CHECK
    ADD CONSTRAINT [FK_MaintenanceCategoryRouting_MaintenanceCategory]
    FOREIGN KEY ([IdaraId_FK], [MaintenanceCategoryID])
    REFERENCES [Maintenance].[MaintenanceCategory] ([IdaraId_FK], [MaintenanceCategoryID]);

    ALTER TABLE [Maintenance].[MaintenanceCategoryRouting] CHECK CONSTRAINT [FK_MaintenanceCategoryRouting_MaintenanceCategory];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[MaintenanceCategoryRouting]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceCategoryRouting_DeptSecDiv_Responsible')
BEGIN
    ALTER TABLE [Maintenance].[MaintenanceCategoryRouting] WITH CHECK
    ADD CONSTRAINT [FK_MaintenanceCategoryRouting_DeptSecDiv_Responsible]
    FOREIGN KEY ([ResponsibleDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[MaintenanceCategoryRouting] CHECK CONSTRAINT [FK_MaintenanceCategoryRouting_DeptSecDiv_Responsible];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND OBJECT_ID(N'[dbo].[Transactions]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequest_Transactions')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequest_Transactions]
    FOREIGN KEY ([TransactionID_FK])
    REFERENCES [dbo].[Transactions] ([transactionID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] CHECK CONSTRAINT [FK_BuildingMaintenanceRequest_Transactions];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequest_MaintenanceCategory')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequest_MaintenanceCategory]
    FOREIGN KEY ([IdaraId_FK], [MaintenanceCategoryID])
    REFERENCES [Maintenance].[MaintenanceCategory] ([IdaraId_FK], [MaintenanceCategoryID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] CHECK CONSTRAINT [FK_BuildingMaintenanceRequest_MaintenanceCategory];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequest_ParentRequest')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequest_ParentRequest]
    FOREIGN KEY ([ParentRequestID])
    REFERENCES [Maintenance].[BuildingMaintenanceRequest] ([RequestID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] CHECK CONSTRAINT [FK_BuildingMaintenanceRequest_ParentRequest];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequest_RootRequest')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequest_RootRequest]
    FOREIGN KEY ([RootRequestID])
    REFERENCES [Maintenance].[BuildingMaintenanceRequest] ([RequestID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] CHECK CONSTRAINT [FK_BuildingMaintenanceRequest_RootRequest];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequest_Status')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequest_Status]
    FOREIGN KEY ([StatusID])
    REFERENCES [Maintenance].[MaintenanceRequestStatus] ([StatusID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] CHECK CONSTRAINT [FK_BuildingMaintenanceRequest_Status];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequest_DisputeStatus')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequest_DisputeStatus]
    FOREIGN KEY ([DisputeStatusID])
    REFERENCES [Maintenance].[MaintenanceRequestStatus] ([StatusID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] CHECK CONSTRAINT [FK_BuildingMaintenanceRequest_DisputeStatus];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequest_Priority')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequest_Priority]
    FOREIGN KEY ([PriorityID])
    REFERENCES [Maintenance].[MaintenancePriority] ([PriorityID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] CHECK CONSTRAINT [FK_BuildingMaintenanceRequest_Priority];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequest_DeptSecDiv_Current')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequest_DeptSecDiv_Current]
    FOREIGN KEY ([CurrentDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] CHECK CONSTRAINT [FK_BuildingMaintenanceRequest_DeptSecDiv_Current];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequest_DeptSecDiv_Original')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequest_DeptSecDiv_Original]
    FOREIGN KEY ([OriginalDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequest] CHECK CONSTRAINT [FK_BuildingMaintenanceRequest_DeptSecDiv_Original];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAssignment]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAssignment_Request')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAssignment] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestAssignment_Request]
    FOREIGN KEY ([RequestID])
    REFERENCES [Maintenance].[BuildingMaintenanceRequest] ([RequestID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAssignment] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestAssignment_Request];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAssignment]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAssignment_DeptSecDiv_Assigned')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAssignment] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestAssignment_DeptSecDiv_Assigned]
    FOREIGN KEY ([AssignedDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAssignment] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestAssignment_DeptSecDiv_Assigned];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAction]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAction_Request')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestAction_Request]
    FOREIGN KEY ([RequestID])
    REFERENCES [Maintenance].[BuildingMaintenanceRequest] ([RequestID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestAction_Request];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAction]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAction_ActionType')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestAction_ActionType]
    FOREIGN KEY ([ActionTypeID])
    REFERENCES [Maintenance].[MaintenanceActionType] ([ActionTypeID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestAction_ActionType];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAction]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAction_Reason')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestAction_Reason]
    FOREIGN KEY ([ReasonID])
    REFERENCES [Maintenance].[MaintenanceActionReason] ([ReasonID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestAction_Reason];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAction]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAction_OldStatus')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestAction_OldStatus]
    FOREIGN KEY ([OldStatusID])
    REFERENCES [Maintenance].[MaintenanceRequestStatus] ([StatusID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestAction_OldStatus];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAction]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAction_NewStatus')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestAction_NewStatus]
    FOREIGN KEY ([NewStatusID])
    REFERENCES [Maintenance].[MaintenanceRequestStatus] ([StatusID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestAction_NewStatus];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAction]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAction_DeptSecDiv_From')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestAction_DeptSecDiv_From]
    FOREIGN KEY ([FromDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestAction_DeptSecDiv_From];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAction]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestAction_DeptSecDiv_To')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestAction_DeptSecDiv_To]
    FOREIGN KEY ([ToDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestAction] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestAction_DeptSecDiv_To];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestApproval]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestApproval_Request')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestApproval] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestApproval_Request]
    FOREIGN KEY ([RequestID])
    REFERENCES [Maintenance].[BuildingMaintenanceRequest] ([RequestID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestApproval] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestApproval_Request];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestApproval]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestApproval_Status')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestApproval] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestApproval_Status]
    FOREIGN KEY ([ApprovalStatusID])
    REFERENCES [Maintenance].[MaintenanceRequestStatus] ([StatusID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestApproval] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestApproval_Status];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestApproval]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestApproval_DeptSecDiv')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestApproval] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestApproval_DeptSecDiv]
    FOREIGN KEY ([ApprovalDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestApproval] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestApproval_DeptSecDiv];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestDispute]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestDispute_Request')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestDispute] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestDispute_Request]
    FOREIGN KEY ([RequestID])
    REFERENCES [Maintenance].[BuildingMaintenanceRequest] ([RequestID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestDispute] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestDispute_Request];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestDispute]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestDispute_Status')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestDispute] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestDispute_Status]
    FOREIGN KEY ([DisputeStatusID])
    REFERENCES [Maintenance].[MaintenanceRequestStatus] ([StatusID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestDispute] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestDispute_Status];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestDispute]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestDispute_DeptSecDiv_RaisedBy')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestDispute] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestDispute_DeptSecDiv_RaisedBy]
    FOREIGN KEY ([RaisedByDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestDispute] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestDispute_DeptSecDiv_RaisedBy];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestDispute]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestDispute_DeptSecDiv_Against')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestDispute] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestDispute_DeptSecDiv_Against]
    FOREIGN KEY ([AgainstDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestDispute] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestDispute_DeptSecDiv_Against];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestDispute]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestDispute_DeptSecDiv_Arbitration')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestDispute] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestDispute_DeptSecDiv_Arbitration]
    FOREIGN KEY ([ArbitrationDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestDispute] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestDispute_DeptSecDiv_Arbitration];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[MaintenanceDisputeRule]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceDisputeRule_DeptSecDiv_From')
BEGIN
    ALTER TABLE [Maintenance].[MaintenanceDisputeRule] WITH CHECK
    ADD CONSTRAINT [FK_MaintenanceDisputeRule_DeptSecDiv_From]
    FOREIGN KEY ([FromDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[MaintenanceDisputeRule] CHECK CONSTRAINT [FK_MaintenanceDisputeRule_DeptSecDiv_From];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[MaintenanceDisputeRule]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceDisputeRule_DeptSecDiv_To')
BEGIN
    ALTER TABLE [Maintenance].[MaintenanceDisputeRule] WITH CHECK
    ADD CONSTRAINT [FK_MaintenanceDisputeRule_DeptSecDiv_To]
    FOREIGN KEY ([ToDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[MaintenanceDisputeRule] CHECK CONSTRAINT [FK_MaintenanceDisputeRule_DeptSecDiv_To];
END
GO

IF OBJECT_ID(N'[dbo].[DeptSecDiv]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Maintenance].[MaintenanceDisputeRule]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceDisputeRule_DeptSecDiv_Arbitration')
BEGIN
    ALTER TABLE [Maintenance].[MaintenanceDisputeRule] WITH CHECK
    ADD CONSTRAINT [FK_MaintenanceDisputeRule_DeptSecDiv_Arbitration]
    FOREIGN KEY ([ArbitrationDSDID])
    REFERENCES [dbo].[DeptSecDiv] ([DSDID]);

    ALTER TABLE [Maintenance].[MaintenanceDisputeRule] CHECK CONSTRAINT [FK_MaintenanceDisputeRule_DeptSecDiv_Arbitration];
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceSLA]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceSLA_MaintenanceCategory')
BEGIN
    ALTER TABLE [Maintenance].[MaintenanceSLA] WITH CHECK
    ADD CONSTRAINT [FK_MaintenanceSLA_MaintenanceCategory]
    FOREIGN KEY ([IdaraId_FK], [MaintenanceCategoryID])
    REFERENCES [Maintenance].[MaintenanceCategory] ([IdaraId_FK], [MaintenanceCategoryID]);

    ALTER TABLE [Maintenance].[MaintenanceSLA] CHECK CONSTRAINT [FK_MaintenanceSLA_MaintenanceCategory];
END
GO

IF OBJECT_ID(N'[Maintenance].[MaintenanceSLA]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceSLA_Priority')
BEGIN
    ALTER TABLE [Maintenance].[MaintenanceSLA] WITH CHECK
    ADD CONSTRAINT [FK_MaintenanceSLA_Priority]
    FOREIGN KEY ([PriorityID])
    REFERENCES [Maintenance].[MaintenancePriority] ([PriorityID]);

    ALTER TABLE [Maintenance].[MaintenanceSLA] CHECK CONSTRAINT [FK_MaintenanceSLA_Priority];
END
GO

IF OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestSLA]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuildingMaintenanceRequestSLA_Request')
BEGIN
    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestSLA] WITH CHECK
    ADD CONSTRAINT [FK_BuildingMaintenanceRequestSLA_Request]
    FOREIGN KEY ([RequestID])
    REFERENCES [Maintenance].[BuildingMaintenanceRequest] ([RequestID]);

    ALTER TABLE [Maintenance].[BuildingMaintenanceRequestSLA] CHECK CONSTRAINT [FK_BuildingMaintenanceRequestSLA_Request];
END
GO

MERGE [Maintenance].[MaintenanceRequestStatus] AS target
USING
(
    VALUES
        (1, N'جديد', N'NEW', 1, 0),
        (2, N'تحت المعاينة', N'UNDER_INSPECTION', 2, 0),
        (3, N'جاري التنفيذ', N'IN_PROGRESS', 3, 0),
        (4, N'بانتظار الموافقة', N'WAITING_APPROVAL', 4, 0),
        (5, N'معلق بانتظار طلب فرعي', N'WAITING_SUB_REQUEST', 5, 0),
        (6, N'مكتمل', N'COMPLETED', 6, 1),
        (7, N'مغلق', N'CLOSED', 7, 1),
        (8, N'ملغي', N'CANCELLED', 8, 1),
        (9, N'مرفوض', N'REJECTED', 9, 1),
        (10, N'تحت النزاع', N'DISPUTE', 10, 0)
) AS source ([StatusID], [StatusName_A], [StatusCode], [DisplayOrder], [IsClosed])
ON target.[StatusID] = source.[StatusID]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([StatusID], [StatusName_A], [StatusCode], [DisplayOrder], [IsClosed], [IsActive])
    VALUES (source.[StatusID], source.[StatusName_A], source.[StatusCode], source.[DisplayOrder], source.[IsClosed], 1);
GO

MERGE [Maintenance].[MaintenancePriority] AS target
USING
(
    VALUES
        (1, N'منخفضة', N'LOW', 1),
        (2, N'عادية', N'NORMAL', 2),
        (3, N'عالية', N'HIGH', 3),
        (4, N'طارئة', N'URGENT', 4)
) AS source ([PriorityID], [PriorityName_A], [PriorityCode], [DisplayOrder])
ON target.[PriorityID] = source.[PriorityID]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([PriorityID], [PriorityName_A], [PriorityCode], [DisplayOrder], [IsActive])
    VALUES (source.[PriorityID], source.[PriorityName_A], source.[PriorityCode], source.[DisplayOrder], 1);
GO

MERGE [Maintenance].[MaintenanceActionType] AS target
USING
(
    VALUES
        (1, N'إنشاء الطلب', N'CREATE', 1),
        (2, N'إسناد لفني', N'ASSIGN_TECHNICIAN', 2),
        (3, N'تقرير معاينة', N'INSPECTION_REPORT', 3),
        (4, N'بدء التنفيذ', N'START_WORK', 4),
        (5, N'إنهاء التنفيذ', N'COMPLETE_WORK', 5),
        (6, N'طلب موافقة', N'REQUEST_APPROVAL', 6),
        (7, N'موافقة', N'APPROVE', 7),
        (8, N'رفض', N'REJECT', 8),
        (9, N'إحالة لجهة أخرى', N'TRANSFER_DSD', 9),
        (10, N'إنشاء طلب فرعي', N'CREATE_SUB_REQUEST', 10),
        (11, N'إعادة للطلب الرئيسي', N'RETURN_TO_PARENT', 11),
        (12, N'تسجيل نزاع', N'RAISE_DISPUTE', 12),
        (13, N'قرار تحكيم', N'ARBITRATION_DECISION', 13),
        (14, N'إغلاق', N'CLOSE', 14),
        (15, N'إلغاء', N'CANCEL', 15),
        (16, N'إضافة ملاحظة', N'ADD_NOTE', 16)
) AS source ([ActionTypeID], [ActionTypeName_A], [ActionTypeCode], [DisplayOrder])
ON target.[ActionTypeID] = source.[ActionTypeID]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([ActionTypeID], [ActionTypeName_A], [ActionTypeCode], [DisplayOrder], [IsActive])
    VALUES (source.[ActionTypeID], source.[ActionTypeName_A], source.[ActionTypeCode], source.[DisplayOrder], 1);
GO

MERGE [Maintenance].[MaintenanceActionReason] AS target
USING
(
    VALUES
        (N'ليس من الاختصاص', N'NOT_RESPONSIBLE'),
        (N'يتطلب موافقة', N'NEEDS_APPROVAL'),
        (N'يتطلب مواد', N'NEEDS_MATERIALS'),
        (N'يتطلب مقاول', N'NEEDS_CONTRACTOR'),
        (N'يتطلب فصل كهرباء', N'NEEDS_POWER_CUTOFF'),
        (N'يتطلب كشف إضافي', N'NEEDS_EXTRA_INSPECTION'),
        (N'تعذر الوصول للوحدة', N'UNIT_ACCESS_FAILED'),
        (N'إجراء بسيط تم تنفيذه', N'SIMPLE_ACTION_COMPLETED'),
        (N'يحتاج طلب فرعي', N'NEEDS_SUB_REQUEST'),
        (N'نزاع اختصاص', N'RESPONSIBILITY_DISPUTE')
) AS source ([ReasonName_A], [ReasonCode])
ON target.[ReasonName_A] = source.[ReasonName_A]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([ReasonName_A], [ReasonCode], [IsActive])
    VALUES (source.[ReasonName_A], source.[ReasonCode], 1);
GO

CREATE OR ALTER VIEW [Maintenance].[V_MaintenanceCategoryTree]
AS
WITH CategoryTree AS
(
    SELECT
        [IdaraId_FK] AS [IdaraId],
        [MaintenanceCategoryID],
        [ParentID],
        [CategoryName_A],
        [CategoryName_E],
        CAST(0 AS INT) AS [LevelNo],
        CAST([CategoryName_A] AS NVARCHAR(MAX)) AS [FullPath_A],
        [DisplayOrder],
        [IsActive]
    FROM [Maintenance].[MaintenanceCategory]
    WHERE [ParentID] IS NULL

    UNION ALL

    SELECT
        child.[IdaraId_FK] AS [IdaraId],
        child.[MaintenanceCategoryID],
        child.[ParentID],
        child.[CategoryName_A],
        child.[CategoryName_E],
        parent.[LevelNo] + 1 AS [LevelNo],
        CAST(parent.[FullPath_A] + N' / ' + child.[CategoryName_A] AS NVARCHAR(MAX)) AS [FullPath_A],
        child.[DisplayOrder],
        child.[IsActive]
    FROM [Maintenance].[MaintenanceCategory] AS child
    INNER JOIN CategoryTree AS parent
        ON parent.[IdaraId] = child.[IdaraId_FK]
        AND parent.[MaintenanceCategoryID] = child.[ParentID]
)
SELECT
    [IdaraId],
    [MaintenanceCategoryID],
    [ParentID],
    [CategoryName_A],
    [CategoryName_E],
    [LevelNo],
    [FullPath_A],
    [DisplayOrder],
    [IsActive],
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Maintenance].[MaintenanceCategory] AS child
            WHERE child.[IdaraId_FK] = CategoryTree.[IdaraId]
              AND child.[ParentID] = CategoryTree.[MaintenanceCategoryID]
              AND child.[IsActive] = 1
        )
        THEN 1
        ELSE 0
    END AS [HasChildren]
FROM CategoryTree;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceCategory_IdaraId' AND object_id = OBJECT_ID(N'[Maintenance].[MaintenanceCategory]'))
    CREATE INDEX [IX_MaintenanceCategory_IdaraId] ON [Maintenance].[MaintenanceCategory] ([IdaraId_FK]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceCategory_ParentID' AND object_id = OBJECT_ID(N'[Maintenance].[MaintenanceCategory]'))
    CREATE INDEX [IX_MaintenanceCategory_ParentID] ON [Maintenance].[MaintenanceCategory] ([ParentID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceCategoryRouting_IdaraId' AND object_id = OBJECT_ID(N'[Maintenance].[MaintenanceCategoryRouting]'))
    CREATE INDEX [IX_MaintenanceCategoryRouting_IdaraId] ON [Maintenance].[MaintenanceCategoryRouting] ([IdaraId_FK]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceCategoryRouting_MaintenanceCategoryID' AND object_id = OBJECT_ID(N'[Maintenance].[MaintenanceCategoryRouting]'))
    CREATE INDEX [IX_MaintenanceCategoryRouting_MaintenanceCategoryID] ON [Maintenance].[MaintenanceCategoryRouting] ([MaintenanceCategoryID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceCategoryRouting_ResponsibleDSDID' AND object_id = OBJECT_ID(N'[Maintenance].[MaintenanceCategoryRouting]'))
    CREATE INDEX [IX_MaintenanceCategoryRouting_ResponsibleDSDID] ON [Maintenance].[MaintenanceCategoryRouting] ([ResponsibleDSDID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequest_IdaraId' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]'))
    CREATE INDEX [IX_BuildingMaintenanceRequest_IdaraId] ON [Maintenance].[BuildingMaintenanceRequest] ([IdaraId_FK]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequest_ParentRequestID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]'))
    CREATE INDEX [IX_BuildingMaintenanceRequest_ParentRequestID] ON [Maintenance].[BuildingMaintenanceRequest] ([ParentRequestID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequest_RootRequestID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]'))
    CREATE INDEX [IX_BuildingMaintenanceRequest_RootRequestID] ON [Maintenance].[BuildingMaintenanceRequest] ([RootRequestID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequest_CurrentDSDID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]'))
    CREATE INDEX [IX_BuildingMaintenanceRequest_CurrentDSDID] ON [Maintenance].[BuildingMaintenanceRequest] ([CurrentDSDID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequest_StatusID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]'))
    CREATE INDEX [IX_BuildingMaintenanceRequest_StatusID] ON [Maintenance].[BuildingMaintenanceRequest] ([StatusID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequest_MaintenanceCategoryID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]'))
    CREATE INDEX [IX_BuildingMaintenanceRequest_MaintenanceCategoryID] ON [Maintenance].[BuildingMaintenanceRequest] ([MaintenanceCategoryID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequest_TransactionID_FK' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequest]'))
    CREATE INDEX [IX_BuildingMaintenanceRequest_TransactionID_FK] ON [Maintenance].[BuildingMaintenanceRequest] ([TransactionID_FK]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequestAssignment_RequestID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAssignment]'))
    CREATE INDEX [IX_BuildingMaintenanceRequestAssignment_RequestID] ON [Maintenance].[BuildingMaintenanceRequestAssignment] ([RequestID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequestAssignment_AssignedDSDID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAssignment]'))
    CREATE INDEX [IX_BuildingMaintenanceRequestAssignment_AssignedDSDID] ON [Maintenance].[BuildingMaintenanceRequestAssignment] ([AssignedDSDID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequestAction_RequestID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAction]'))
    CREATE INDEX [IX_BuildingMaintenanceRequestAction_RequestID] ON [Maintenance].[BuildingMaintenanceRequestAction] ([RequestID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequestAction_ActionTypeID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestAction]'))
    CREATE INDEX [IX_BuildingMaintenanceRequestAction_ActionTypeID] ON [Maintenance].[BuildingMaintenanceRequestAction] ([ActionTypeID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequestApproval_RequestID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestApproval]'))
    CREATE INDEX [IX_BuildingMaintenanceRequestApproval_RequestID] ON [Maintenance].[BuildingMaintenanceRequestApproval] ([RequestID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequestDispute_RequestID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestDispute]'))
    CREATE INDEX [IX_BuildingMaintenanceRequestDispute_RequestID] ON [Maintenance].[BuildingMaintenanceRequestDispute] ([RequestID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceDisputeRule_IdaraId' AND object_id = OBJECT_ID(N'[Maintenance].[MaintenanceDisputeRule]'))
    CREATE INDEX [IX_MaintenanceDisputeRule_IdaraId] ON [Maintenance].[MaintenanceDisputeRule] ([IdaraId_FK]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceSLA_IdaraId' AND object_id = OBJECT_ID(N'[Maintenance].[MaintenanceSLA]'))
    CREATE INDEX [IX_MaintenanceSLA_IdaraId] ON [Maintenance].[MaintenanceSLA] ([IdaraId_FK]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceSLA_MaintenanceCategoryID' AND object_id = OBJECT_ID(N'[Maintenance].[MaintenanceSLA]'))
    CREATE INDEX [IX_MaintenanceSLA_MaintenanceCategoryID] ON [Maintenance].[MaintenanceSLA] ([MaintenanceCategoryID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceSLA_PriorityID' AND object_id = OBJECT_ID(N'[Maintenance].[MaintenanceSLA]'))
    CREATE INDEX [IX_MaintenanceSLA_PriorityID] ON [Maintenance].[MaintenanceSLA] ([PriorityID]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BuildingMaintenanceRequestSLA_RequestID' AND object_id = OBJECT_ID(N'[Maintenance].[BuildingMaintenanceRequestSLA]'))
    CREATE INDEX [IX_BuildingMaintenanceRequestSLA_RequestID] ON [Maintenance].[BuildingMaintenanceRequestSLA] ([RequestID]);
GO



