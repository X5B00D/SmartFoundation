USE [DATACORE];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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

CREATE OR ALTER VIEW [Maintenance].[V_BuildingMaintenanceRequestList]
AS
SELECT
    request.[RequestID],
    request.[TransactionID_FK],
    request.[RequestNo],
    request.[IdaraId_FK] AS [IdaraId],
    request.[RequestDate],
    request.[BuildingID],
    request.[UnitID],
    request.[ResidentID],
    request.[MaintenanceCategoryID],
    category.[CategoryName_A] AS [MaintenanceCategoryName_A],
    categoryTree.[FullPath_A] AS [MaintenanceCategoryFullPath_A],
    request.[CurrentDSDID],
    request.[OriginalDSDID],
    request.[StatusID],
    status.[StatusName_A],
    status.[StatusCode],
    request.[PriorityID],
    priority.[PriorityName_A],
    priority.[PriorityCode],
    request.[ParentRequestID],
    request.[RootRequestID],
    request.[RequestLevel],
    request.[IsSubRequest],
    request.[HasDispute],
    request.[EscalationLevel],
    request.[IsLockedByDecision],
    ISNULL(subRequests.[SubRequestsCount], 0) AS [SubRequestsCount],
    ISNULL(subRequests.[OpenSubRequestsCount], 0) AS [OpenSubRequestsCount],
    lastAction.[ActionDate] AS [LastActionDate],
    lastAction.[ActionTypeName_A] AS [LastActionTypeName_A],
    lastAction.[ActionNote] AS [LastActionNote],
    request.[ClosedDate],
    request.[IsActive]
FROM [Maintenance].[BuildingMaintenanceRequest] AS request
LEFT JOIN [Maintenance].[MaintenanceCategory] AS category
    ON category.[MaintenanceCategoryID] = request.[MaintenanceCategoryID]
LEFT JOIN [Maintenance].[V_MaintenanceCategoryTree] AS categoryTree
    ON categoryTree.[IdaraId] = request.[IdaraId_FK]
    AND categoryTree.[MaintenanceCategoryID] = request.[MaintenanceCategoryID]
LEFT JOIN [Maintenance].[MaintenanceRequestStatus] AS status
    ON status.[StatusID] = request.[StatusID]
LEFT JOIN [Maintenance].[MaintenancePriority] AS priority
    ON priority.[PriorityID] = request.[PriorityID]
OUTER APPLY
(
    SELECT
        COUNT(1) AS [SubRequestsCount],
        SUM(CASE WHEN ISNULL(childStatus.[IsClosed], 0) = 0 THEN 1 ELSE 0 END) AS [OpenSubRequestsCount]
    FROM [Maintenance].[BuildingMaintenanceRequest] AS child
    LEFT JOIN [Maintenance].[MaintenanceRequestStatus] AS childStatus
        ON childStatus.[StatusID] = child.[StatusID]
    WHERE child.[ParentRequestID] = request.[RequestID]
      AND child.[IsActive] = 1
) AS subRequests
OUTER APPLY
(
    SELECT TOP (1)
        action.[ActionDate],
        actionType.[ActionTypeName_A],
        action.[ActionNote]
    FROM [Maintenance].[BuildingMaintenanceRequestAction] AS action
    LEFT JOIN [Maintenance].[MaintenanceActionType] AS actionType
        ON actionType.[ActionTypeID] = action.[ActionTypeID]
    WHERE action.[RequestID] = request.[RequestID]
      AND action.[IsActive] = 1
    ORDER BY action.[ActionDate] DESC, action.[ActionID] DESC
) AS lastAction;
GO

CREATE OR ALTER VIEW [Maintenance].[V_BuildingMaintenanceRequestDetails]
AS
SELECT
    request.[RequestID],
    request.[IdaraId_FK] AS [IdaraId],
    request.[RequestNo],
    request.[TransactionID_FK],
    request.[ParentRequestID],
    request.[RootRequestID],
    request.[RequestLevel],
    request.[IsSubRequest],
    request.[IsBlockingParent],
    request.[BuildingID],
    request.[UnitID],
    request.[ResidentID],
    request.[MaintenanceCategoryID],
    request.[CurrentDSDID],
    request.[OriginalDSDID],
    request.[StatusID],
    request.[PriorityID],
    request.[Description_A],
    request.[HasDispute],
    request.[DisputeStatusID],
    request.[EscalationLevel],
    request.[IsLockedByDecision],
    request.[RequestDate],
    request.[ClosedDate],
    request.[entryUser],
    request.[entryDate],
    request.[entryData],
    request.[hostName],
    request.[updateUser],
    request.[updateDate],
    request.[IsActive],
    category.[CategoryName_A] AS [MaintenanceCategoryName_A],
    categoryTree.[FullPath_A] AS [MaintenanceCategoryFullPath_A],
    status.[StatusName_A],
    status.[StatusCode],
    priority.[PriorityName_A],
    priority.[PriorityCode],
    parentRequest.[RequestNo] AS [ParentRequestNo],
    rootRequest.[RequestNo] AS [RootRequestNo]
FROM [Maintenance].[BuildingMaintenanceRequest] AS request
LEFT JOIN [Maintenance].[MaintenanceCategory] AS category
    ON category.[MaintenanceCategoryID] = request.[MaintenanceCategoryID]
LEFT JOIN [Maintenance].[V_MaintenanceCategoryTree] AS categoryTree
    ON categoryTree.[IdaraId] = request.[IdaraId_FK]
    AND categoryTree.[MaintenanceCategoryID] = request.[MaintenanceCategoryID]
LEFT JOIN [Maintenance].[MaintenanceRequestStatus] AS status
    ON status.[StatusID] = request.[StatusID]
LEFT JOIN [Maintenance].[MaintenancePriority] AS priority
    ON priority.[PriorityID] = request.[PriorityID]
LEFT JOIN [Maintenance].[BuildingMaintenanceRequest] AS parentRequest
    ON parentRequest.[RequestID] = request.[ParentRequestID]
LEFT JOIN [Maintenance].[BuildingMaintenanceRequest] AS rootRequest
    ON rootRequest.[RequestID] = request.[RootRequestID];
GO

CREATE OR ALTER VIEW [Maintenance].[V_BuildingMaintenanceRequestTimeline]
AS
SELECT
    action.[ActionID],
    action.[RequestID],
    action.[ActionDate],
    action.[ActionTypeID],
    actionType.[ActionTypeName_A],
    actionType.[ActionTypeCode],
    action.[ReasonID],
    reason.[ReasonName_A],
    reason.[ReasonCode],
    action.[FromDSDID],
    action.[ToDSDID],
    action.[FromUserID],
    action.[ToUserID],
    action.[OldStatusID],
    oldStatus.[StatusName_A] AS [OldStatusName_A],
    oldStatus.[StatusCode] AS [OldStatusCode],
    action.[NewStatusID],
    newStatus.[StatusName_A] AS [NewStatusName_A],
    newStatus.[StatusCode] AS [NewStatusCode],
    action.[ActionNote],
    action.[entryUser],
    action.[entryDate]
FROM [Maintenance].[BuildingMaintenanceRequestAction] AS action
LEFT JOIN [Maintenance].[MaintenanceActionType] AS actionType
    ON actionType.[ActionTypeID] = action.[ActionTypeID]
LEFT JOIN [Maintenance].[MaintenanceActionReason] AS reason
    ON reason.[ReasonID] = action.[ReasonID]
LEFT JOIN [Maintenance].[MaintenanceRequestStatus] AS oldStatus
    ON oldStatus.[StatusID] = action.[OldStatusID]
LEFT JOIN [Maintenance].[MaintenanceRequestStatus] AS newStatus
    ON newStatus.[StatusID] = action.[NewStatusID];
GO

CREATE OR ALTER VIEW [Maintenance].[V_BuildingMaintenanceRequestAssignments]
AS
SELECT
    assignment.[AssignmentID],
    assignment.[RequestID],
    assignment.[AssignedToUserID],
    assignment.[AssignedByUserID],
    assignment.[AssignedDSDID],
    assignment.[AssignedDate],
    assignment.[InspectionDate],
    assignment.[CompletionDate],
    assignment.[AssignmentStatusID],
    assignment.[NeedsApproval],
    assignment.[NeedsSubRequest],
    request.[TransactionID_FK],
    assignment.[ReportText],
    assignment.[IsActive]
FROM [Maintenance].[BuildingMaintenanceRequestAssignment] AS assignment
INNER JOIN [Maintenance].[BuildingMaintenanceRequest] AS request
    ON request.[RequestID] = assignment.[RequestID];
GO

CREATE OR ALTER VIEW [Maintenance].[V_BuildingMaintenanceRequestApprovals]
AS
SELECT
    approval.[ApprovalID],
    approval.[RequestID],
    approval.[RequestedByUserID],
    approval.[RequestedDate],
    approval.[ApprovalLevel],
    approval.[ApprovalDSDID],
    approval.[ApprovalUserID],
    approval.[ApprovalStatusID],
    approval.[Reason],
    approval.[EstimatedCost],
    approval.[DecisionNote],
    approval.[DecisionDate],
    approval.[IsActive]
FROM [Maintenance].[BuildingMaintenanceRequestApproval] AS approval;
GO

CREATE OR ALTER VIEW [Maintenance].[V_BuildingMaintenanceRequestDisputes]
AS
SELECT
    dispute.[DisputeID],
    dispute.[RequestID],
    dispute.[RaisedByDSDID],
    dispute.[AgainstDSDID],
    dispute.[RaisedByUserID],
    dispute.[Reason],
    dispute.[ArbitrationDSDID],
    dispute.[DecisionByUserID],
    dispute.[DecisionNote],
    dispute.[IsBindingDecision],
    dispute.[DecisionDate],
    dispute.[DisputeStatusID],
    dispute.[IsActive]
FROM [Maintenance].[BuildingMaintenanceRequestDispute] AS dispute;
GO

CREATE OR ALTER VIEW [Maintenance].[V_BuildingMaintenanceRequestSLAStatus]
AS
SELECT
    request.[RequestID],
    request.[RequestNo],
    request.[IdaraId_FK] AS [IdaraId],
    request.[StatusID],
    status.[StatusName_A],
    status.[StatusCode],
    request.[PriorityID],
    priority.[PriorityName_A],
    requestSla.[InspectionDueDate],
    requestSla.[ExecutionDueDate],
    requestSla.[ApprovalDueDate],
    requestSla.[IsInspectionLate],
    requestSla.[IsExecutionLate],
    requestSla.[IsApprovalLate],
    CAST(
        CASE
            WHEN requestSla.[IsInspectionLate] = 1
              OR requestSla.[IsExecutionLate] = 1
              OR requestSla.[IsApprovalLate] = 1
            THEN 1
            ELSE 0
        END AS BIT
    ) AS [IsAnyLate],
    request.[RequestDate],
    request.[ClosedDate]
FROM [Maintenance].[BuildingMaintenanceRequest] AS request
LEFT JOIN [Maintenance].[BuildingMaintenanceRequestSLA] AS requestSla
    ON requestSla.[RequestID] = request.[RequestID]
LEFT JOIN [Maintenance].[MaintenanceRequestStatus] AS status
    ON status.[StatusID] = request.[StatusID]
LEFT JOIN [Maintenance].[MaintenancePriority] AS priority
    ON priority.[PriorityID] = request.[PriorityID];
GO

CREATE OR ALTER VIEW [Maintenance].[V_BuildingMaintenanceRequestDocuments]
AS
SELECT
    request.[RequestID],
    request.[TransactionID_FK],
    document.[documentID] AS [DocumentID],
    document.[documentTitle] AS [DocumentTitle],
    document.[documentTypeID_FK] AS [DocumentTypeID_FK],
    document.[documentStateID_FK] AS [DocumentStateID_FK],
    attachment.[attachmentID] AS [AttachmentID],
    attachment.[attachmentName] AS [AttachmentName],
    attachment.[attachmentPath] AS [AttachmentPath],
    attachment.[attachmentExtintion] AS [AttachmentExtintion],
    attachment.[attachmentSize] AS [AttachmentSize],
    document.[documentDate] AS [DocumentDate],
    document.[documentDescription] AS [DocumentDescription]
FROM [Maintenance].[BuildingMaintenanceRequest] AS request
INNER JOIN [dbo].[Document] AS document
    ON document.[transactionID_FK] = request.[TransactionID_FK]
LEFT JOIN [dbo].[Attachment] AS attachment
    ON attachment.[DocumentID_FK] = document.[documentID]
    AND attachment.[transactionID_FK] = document.[transactionID_FK];
GO



