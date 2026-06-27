USE [DATACORE];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH(N'Maintenance.MaintenanceCategory', N'IdaraId') IS NOT NULL
AND COL_LENGTH(N'Maintenance.MaintenanceCategory', N'IdaraId_FK') IS NULL
    EXEC sp_rename N'[Maintenance].[MaintenanceCategory].[IdaraId]', N'IdaraId_FK', N'COLUMN';
GO

IF COL_LENGTH(N'Maintenance.MaintenanceCategoryRouting', N'IdaraId') IS NOT NULL
AND COL_LENGTH(N'Maintenance.MaintenanceCategoryRouting', N'IdaraId_FK') IS NULL
    EXEC sp_rename N'[Maintenance].[MaintenanceCategoryRouting].[IdaraId]', N'IdaraId_FK', N'COLUMN';
GO

IF COL_LENGTH(N'Maintenance.BuildingMaintenanceRequest', N'IdaraId') IS NOT NULL
AND COL_LENGTH(N'Maintenance.BuildingMaintenanceRequest', N'IdaraId_FK') IS NULL
    EXEC sp_rename N'[Maintenance].[BuildingMaintenanceRequest].[IdaraId]', N'IdaraId_FK', N'COLUMN';
GO

IF COL_LENGTH(N'Maintenance.MaintenanceDisputeRule', N'IdaraId') IS NOT NULL
AND COL_LENGTH(N'Maintenance.MaintenanceDisputeRule', N'IdaraId_FK') IS NULL
    EXEC sp_rename N'[Maintenance].[MaintenanceDisputeRule].[IdaraId]', N'IdaraId_FK', N'COLUMN';
GO

IF COL_LENGTH(N'Maintenance.MaintenanceSLA', N'IdaraId') IS NOT NULL
AND COL_LENGTH(N'Maintenance.MaintenanceSLA', N'IdaraId_FK') IS NULL
    EXEC sp_rename N'[Maintenance].[MaintenanceSLA].[IdaraId]', N'IdaraId_FK', N'COLUMN';
GO

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql + N'
IF COL_LENGTH(N''Maintenance.' + REPLACE(t.name, '''', '''''') + N''', N''IdaraId_FK'') IS NULL
    ALTER TABLE [Maintenance].' + QUOTENAME(t.name) + N' ADD [IdaraId_FK] BIGINT NULL;

IF COL_LENGTH(N''Maintenance.' + REPLACE(t.name, '''', '''''') + N''', N''entryDate'') IS NULL
    ALTER TABLE [Maintenance].' + QUOTENAME(t.name) + N' ADD [entryDate] DATETIME NULL CONSTRAINT ' + QUOTENAME(N'DF_' + t.name + N'_entryDate') + N' DEFAULT (GETDATE());

IF COL_LENGTH(N''Maintenance.' + REPLACE(t.name, '''', '''''') + N''', N''entryDate'') IS NOT NULL
AND NOT EXISTS
(
    SELECT 1
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c
        ON c.object_id = dc.parent_object_id
        AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N''Maintenance.' + REPLACE(t.name, '''', '''''') + N''')
      AND c.name = N''entryDate''
)
    ALTER TABLE [Maintenance].' + QUOTENAME(t.name) + N' ADD CONSTRAINT ' + QUOTENAME(N'DF_' + t.name + N'_entryDate') + N' DEFAULT (GETDATE()) FOR [entryDate];

IF COL_LENGTH(N''Maintenance.' + REPLACE(t.name, '''', '''''') + N''', N''entryData'') IS NULL
    ALTER TABLE [Maintenance].' + QUOTENAME(t.name) + N' ADD [entryData] NVARCHAR(20) NULL;

IF COL_LENGTH(N''Maintenance.' + REPLACE(t.name, '''', '''''') + N''', N''hostName'') IS NULL
    ALTER TABLE [Maintenance].' + QUOTENAME(t.name) + N' ADD [hostName] NVARCHAR(200) NULL;
'
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE s.name = N'Maintenance';

EXEC sp_executesql @sql;
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



