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

CREATE OR ALTER PROCEDURE [Maintenance].[MaintenanceCategoryDL]
      @pageName_ NVARCHAR(400)
    , @idaraID BIGINT
    , @entryData NVARCHAR(20)
    , @hostName NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    --                    MaintenanceCategory

    SELECT
          t.[IdaraId]
        , t.[MaintenanceCategoryID]
        , t.[ParentID]
        , t.[CategoryName_A]
        , t.[CategoryName_E]
        , t.[FullPath_A]
        , CASE
              WHEN t.[LevelNo] = 0 THEN N'مستوى رئيسي'
              ELSE N'مستوى فرعي ' + CAST(t.[LevelNo] AS NVARCHAR)
          END AS [LevelNo]
        , t.[LevelNo] AS [levelInt]
        , t.[DisplayOrder]
        , t.[IsActive]
        , t.[HasChildren]
        , ISNULL(routing.[ResponsibleDSDID], 0) AS [ResponsibleDSDID]
        , ISNULL
          (
              COALESCE
              (
                  NULLIF
                  (
                      LTRIM(RTRIM
                      (
                          CONCAT
                          (
                              ISNULL(dept.[deptName_A], N''),
                              CASE WHEN sec.[secName_A] IS NOT NULL THEN N' / ' + sec.[secName_A] ELSE N'' END,
                              CASE WHEN div.[divName_A] IS NOT NULL THEN N' / ' + div.[divName_A] ELSE N'' END
                          )
                      )),
                      N''
                  ),
                  N'جهة رقم ' + CONVERT(NVARCHAR(30), dsd.[DSDID])
              ),
              N'لايوجد جهة مسؤولة'
          ) AS [DSDName_A]
    FROM [Maintenance].[V_MaintenanceCategoryTree] AS t
    LEFT JOIN [Maintenance].[MaintenanceCategoryRouting] AS routing
        ON routing.[MaintenanceCategoryID] = t.[MaintenanceCategoryID]
        AND routing.[IdaraId_FK] = t.[IdaraId]
        AND routing.[IsActive] = 1
        AND routing.[IsDefault] = 1
    LEFT JOIN [dbo].[DeptSecDiv] AS dsd
        ON dsd.[DSDID] = routing.[ResponsibleDSDID]
    LEFT JOIN [dbo].[Department] AS dept
        ON dept.[deptID] = dsd.[deptID_FK]
    LEFT JOIN [dbo].[Section] AS sec
        ON sec.[secID] = dsd.[secID_FK]
    LEFT JOIN [dbo].[Divison] AS div
        ON div.[divID] = dsd.[divID_FK]
    WHERE t.[IdaraId] = @idaraID
      AND t.[IsActive] = 1
    ORDER BY t.[DisplayOrder], t.[MaintenanceCategoryID];

    SELECT
          [MaintenanceCategoryID]
        , [FullPath_A]
    FROM [Maintenance].[V_MaintenanceCategoryTree]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
    ORDER BY [MaintenanceCategoryID];

    SELECT
          dsd.[DSDID]
        , COALESCE
          (
              NULLIF
              (
                  LTRIM(RTRIM
                  (
                      CONCAT
                      (
                          ISNULL(dept.[deptName_A], N''),
                          CASE WHEN sec.[secName_A] IS NOT NULL THEN N' / ' + sec.[secName_A] ELSE N'' END,
                          CASE WHEN div.[divName_A] IS NOT NULL THEN N' / ' + div.[divName_A] ELSE N'' END
                      )
                  )),
                  N''
              ),
              N'جهة رقم ' + CONVERT(NVARCHAR(30), dsd.[DSDID])
          ) AS [DSDName_A]
        , dept.[deptName_A]
        , sec.[secName_A]
        , div.[divName_A]
    FROM [dbo].[DeptSecDiv] AS dsd
    LEFT JOIN [dbo].[Department] AS dept
        ON dept.[deptID] = dsd.[deptID_FK]
    LEFT JOIN [dbo].[Section] AS sec
        ON sec.[secID] = dsd.[secID_FK]
    LEFT JOIN [dbo].[Divison] AS div
        ON div.[divID] = dsd.[divID_FK]
    WHERE dsd.[idaraID_FK] = @idaraID
    ORDER BY [DSDName_A], dsd.[DSDID];

    SELECT
          routing.[MaintenanceCategoryRoutingID]
        , routing.[IdaraId_FK]
        , routing.[MaintenanceCategoryID]
        , category.[CategoryName_A] AS [MaintenanceCategoryName_A]
        , category.[FullPath_A] AS [MaintenanceCategoryFullPath_A]
        , routing.[ResponsibleDSDID]
        , COALESCE
          (
              NULLIF
              (
                  LTRIM(RTRIM
                  (
                      CONCAT
                      (
                          ISNULL(dept.[deptName_A], N''),
                          CASE WHEN sec.[secName_A] IS NOT NULL THEN N' / ' + sec.[secName_A] ELSE N'' END,
                          CASE WHEN div.[divName_A] IS NOT NULL THEN N' / ' + div.[divName_A] ELSE N'' END
                      )
                  )),
                  N''
              ),
              N'جهة رقم ' + CONVERT(NVARCHAR(30), routing.[ResponsibleDSDID])
          ) AS [ResponsibleDSDName_A]
        , routing.[IsDefault]
        , routing.[Notes]
        , routing.[IsActive]
    FROM [Maintenance].[MaintenanceCategoryRouting] AS routing
    LEFT JOIN [Maintenance].[V_MaintenanceCategoryTree] AS category
        ON category.[IdaraId] = routing.[IdaraId_FK]
        AND category.[MaintenanceCategoryID] = routing.[MaintenanceCategoryID]
    LEFT JOIN [dbo].[DeptSecDiv] AS dsd
        ON dsd.[DSDID] = routing.[ResponsibleDSDID]
    LEFT JOIN [dbo].[Department] AS dept
        ON dept.[deptID] = dsd.[deptID_FK]
    LEFT JOIN [dbo].[Section] AS sec
        ON sec.[secID] = dsd.[secID_FK]
    LEFT JOIN [dbo].[Divison] AS div
        ON div.[divID] = dsd.[divID_FK]
    WHERE routing.[IdaraId_FK] = @idaraID
    ORDER BY category.[FullPath_A], routing.[MaintenanceCategoryRoutingID];
END
GO

DECLARE @Definition NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'[Maintenance].[MaintenanceCategorySP]'));
DECLARE @RouteStart INT = CHARINDEX(N'ELSE IF @Action = N''ROUTEMAINTENANCECATEGORY''', @Definition);
DECLARE @UpdateStart INT = CHARINDEX(N'            UPDATE  Maintenance.MaintenanceCategoryRouting', @Definition, @RouteStart);
DECLARE @Insert NVARCHAR(MAX) = N'
            IF EXISTS
            (
                SELECT 1
                FROM  Maintenance.MaintenanceCategory
                WHERE ParentID = @MaintenanceCategoryID_BIGINT
                  AND IdaraId_FK = @IdaraID_INT
                  AND IsActive = 1
            )
            BEGIN
                ;THROW 50001, N''لا يمكن ربط الجهة المسؤولة بتصنيف يحتوي على أبناء، اختر آخر مستوى'', 1;
            END

';

IF @Definition IS NULL
BEGIN
    ;THROW 50002, N'Maintenance.MaintenanceCategorySP was not found.', 1;
END;

IF @Definition NOT LIKE N'%لا يمكن ربط الجهة المسؤولة بتصنيف يحتوي على أبناء%'
BEGIN
    IF @RouteStart = 0 OR @UpdateStart = 0
    BEGIN
        ;THROW 50002, N'Could not locate ROUTEMAINTENANCECATEGORY update block.', 1;
    END;

    SET @Definition = STUFF(@Definition, @UpdateStart, 0, @Insert);
    SET @Definition = STUFF(@Definition, CHARINDEX(N'CREATE', @Definition), LEN(N'CREATE'), N'CREATE OR ALTER');

    EXEC sys.sp_executesql @Definition;
END
GO
