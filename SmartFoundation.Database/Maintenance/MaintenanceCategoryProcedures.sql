USE [DATACORE];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [Maintenance].[MaintenanceCategorySP]
      @Action NVARCHAR(200)
    , @MaintenanceCategoryID NVARCHAR(100) = NULL
    , @ParentID NVARCHAR(100) = NULL
    , @CategoryName_A NVARCHAR(250) = NULL
    , @CategoryName_E NVARCHAR(250) = NULL
    , @Description_A NVARCHAR(1000) = NULL
    , @DisplayOrder NVARCHAR(100) = NULL
    , @ResponsibleDSDID NVARCHAR(100) = NULL
    , @Notes NVARCHAR(1000) = NULL
    , @idaraID_FK NVARCHAR(10) = NULL
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    --                    MaintenanceCategory

    DECLARE @tc INT = @@TRANCOUNT;

    BEGIN TRY
        DECLARE @ActionNormalized NVARCHAR(200) = UPPER(LTRIM(RTRIM(ISNULL(@Action, N''))));
        DECLARE @IdaraID BIGINT = TRY_CONVERT(BIGINT, NULLIF(@idaraID_FK, N''));
        DECLARE @EntryUser BIGINT = TRY_CONVERT(BIGINT, NULLIF(@entryData, N''));
        DECLARE @CategoryID BIGINT = TRY_CONVERT(BIGINT, NULLIF(@MaintenanceCategoryID, N''));
        DECLARE @ParentIDValue BIGINT = TRY_CONVERT(BIGINT, NULLIF(@ParentID, N''));
        DECLARE @DisplayOrderValue INT = ISNULL(TRY_CONVERT(INT, NULLIF(@DisplayOrder, N'')), 0);
        DECLARE @ResponsibleDSDIDValue BIGINT = TRY_CONVERT(BIGINT, NULLIF(@ResponsibleDSDID, N''));
        DECLARE @CategoryNameAValue NVARCHAR(250) = NULLIF(LTRIM(RTRIM(@CategoryName_A)), N'');
        DECLARE @CategoryNameEValue NVARCHAR(250) = NULLIF(LTRIM(RTRIM(@CategoryName_E)), N'');
        DECLARE @DescriptionAValue NVARCHAR(1000) = NULLIF(LTRIM(RTRIM(@Description_A)), N'');
        DECLARE @NotesValue NVARCHAR(1000) = NULLIF(LTRIM(RTRIM(COALESCE(@Notes, @Description_A))), N'');
        DECLARE @RecordID BIGINT = NULL;

        IF @ActionNormalized = N''
            THROW 50001, N'نوع العملية مطلوب', 1;

        IF @IdaraID IS NULL
            THROW 50001, N'الإدارة مطلوبة', 1;

        IF @tc = 0
            BEGIN TRAN;

        IF @ActionNormalized = N'INSERTMAINTENANCECATEGORY'
        BEGIN
            IF @CategoryNameAValue IS NULL
                THROW 50001, N'اسم نوع الصيانة بالعربي مطلوب', 1;

            IF @ParentIDValue IS NOT NULL
            AND NOT EXISTS
            (
                SELECT 1
                FROM [Maintenance].[MaintenanceCategory]
                WHERE [MaintenanceCategoryID] = @ParentIDValue
                  AND [IdaraId_FK] = @IdaraID
                  AND [IsActive] = 1
            )
                THROW 50001, N'التصنيف الأب غير موجود ضمن نفس الإدارة', 1;

            INSERT INTO [Maintenance].[MaintenanceCategory]
            (
                  [IdaraId_FK]
                , [ParentID]
                , [CategoryName_A]
                , [CategoryName_E]
                , [Description_A]
                , [DisplayOrder]
                , [entryUser]
                , [entryData]
                , [hostName]
            )
            VALUES
            (
                  @IdaraID
                , @ParentIDValue
                , @CategoryNameAValue
                , @CategoryNameEValue
                , @DescriptionAValue
                , @DisplayOrderValue
                , @EntryUser
                , @entryData
                , @hostName
            );

            SET @RecordID = CONVERT(BIGINT, SCOPE_IDENTITY());

            INSERT INTO [dbo].[AuditLog] ([TableName], [ActionType], [RecordID], [PerformedBy], [Notes], [PerformedAt])
            VALUES (N'Maintenance.MaintenanceCategory', @ActionNormalized, @RecordID, @entryData, N'إضافة نوع صيانة', GETDATE());

            IF @tc = 0
                COMMIT;

            SELECT 1 AS [IsSuccessful], N'تمت إضافة نوع الصيانة بنجاح' AS [Message_];
            RETURN;
        END

        ELSE IF @ActionNormalized = N'UPDATEMAINTENANCECATEGORY'
        BEGIN
            IF @CategoryID IS NULL
                THROW 50001, N'معرف نوع الصيانة مطلوب', 1;

            IF @CategoryNameAValue IS NULL
                THROW 50001, N'اسم نوع الصيانة بالعربي مطلوب', 1;

            IF NOT EXISTS
            (
                SELECT 1
                FROM [Maintenance].[MaintenanceCategory]
                WHERE [MaintenanceCategoryID] = @CategoryID
                  AND [IdaraId_FK] = @IdaraID
                  AND [IsActive] = 1
            )
                THROW 50001, N'نوع الصيانة غير موجود ضمن نفس الإدارة', 1;

            IF @ParentIDValue = @CategoryID
                THROW 50001, N'لا يمكن جعل التصنيف أباً لنفسه', 1;

            IF @ParentIDValue IS NOT NULL
            AND NOT EXISTS
            (
                SELECT 1
                FROM [Maintenance].[MaintenanceCategory]
                WHERE [MaintenanceCategoryID] = @ParentIDValue
                  AND [IdaraId_FK] = @IdaraID
                  AND [IsActive] = 1
            )
                THROW 50001, N'التصنيف الأب غير موجود ضمن نفس الإدارة', 1;

            IF @ParentIDValue IS NOT NULL
            BEGIN
                DECLARE @DescendantMatchCount INT = 0;

                ;WITH CategoryChildren AS
                (
                    SELECT [MaintenanceCategoryID]
                    FROM [Maintenance].[MaintenanceCategory]
                    WHERE [ParentID] = @CategoryID
                      AND [IdaraId_FK] = @IdaraID
                      AND [IsActive] = 1

                    UNION ALL

                    SELECT child.[MaintenanceCategoryID]
                    FROM [Maintenance].[MaintenanceCategory] AS child
                    INNER JOIN CategoryChildren AS parent
                        ON parent.[MaintenanceCategoryID] = child.[ParentID]
                    WHERE child.[IdaraId_FK] = @IdaraID
                      AND child.[IsActive] = 1
                )
                SELECT @DescendantMatchCount = COUNT(1)
                FROM CategoryChildren
                WHERE [MaintenanceCategoryID] = @ParentIDValue;

                IF @DescendantMatchCount > 0
                    THROW 50001, N'لا يمكن نقل التصنيف تحت أحد أبنائه', 1;
            END

            UPDATE [Maintenance].[MaintenanceCategory]
            SET [ParentID] = @ParentIDValue
              , [CategoryName_A] = @CategoryNameAValue
              , [CategoryName_E] = @CategoryNameEValue
              , [Description_A] = @DescriptionAValue
              , [DisplayOrder] = @DisplayOrderValue
              , [updateUser] = @EntryUser
              , [updateDate] = GETDATE()
              , [entryData] = @entryData
              , [hostName] = @hostName
            WHERE [MaintenanceCategoryID] = @CategoryID
              AND [IdaraId_FK] = @IdaraID;

            INSERT INTO [dbo].[AuditLog] ([TableName], [ActionType], [RecordID], [PerformedBy], [Notes], [PerformedAt])
            VALUES (N'Maintenance.MaintenanceCategory', @ActionNormalized, @CategoryID, @entryData, N'تعديل نوع صيانة', GETDATE());

            IF @tc = 0
                COMMIT;

            SELECT 1 AS [IsSuccessful], N'تم تعديل نوع الصيانة بنجاح' AS [Message_];
            RETURN;
        END

        ELSE IF @ActionNormalized = N'DELETEMAINTENANCECATEGORY'
        BEGIN
            IF @CategoryID IS NULL
                THROW 50001, N'معرف نوع الصيانة مطلوب', 1;

            IF NOT EXISTS
            (
                SELECT 1
                FROM [Maintenance].[MaintenanceCategory]
                WHERE [MaintenanceCategoryID] = @CategoryID
                  AND [IdaraId_FK] = @IdaraID
                  AND [IsActive] = 1
            )
                THROW 50001, N'نوع الصيانة غير موجود ضمن نفس الإدارة', 1;

            IF EXISTS
            (
                SELECT 1
                FROM [Maintenance].[MaintenanceCategory]
                WHERE [ParentID] = @CategoryID
                  AND [IdaraId_FK] = @IdaraID
                  AND [IsActive] = 1
            )
                THROW 50001, N'لا يمكن تعطيل نوع الصيانة لوجود تصنيفات فرعية نشطة', 1;

            IF EXISTS
            (
                SELECT 1
                FROM [Maintenance].[BuildingMaintenanceRequest]
                WHERE [MaintenanceCategoryID] = @CategoryID
                  AND [IdaraId_FK] = @IdaraID
                  AND [IsActive] = 1
            )
                THROW 50001, N'لا يمكن تعطيل نوع الصيانة لأنه مستخدم في طلبات صيانة نشطة', 1;

            UPDATE [Maintenance].[MaintenanceCategory]
            SET [IsActive] = 0
              , [updateUser] = @EntryUser
              , [updateDate] = GETDATE()
              , [entryData] = @entryData
              , [hostName] = @hostName
            WHERE [MaintenanceCategoryID] = @CategoryID
              AND [IdaraId_FK] = @IdaraID;

            UPDATE [Maintenance].[MaintenanceCategoryRouting]
            SET [IsActive] = 0
              , [IsDefault] = 0
              , [updateUser] = @EntryUser
              , [updateDate] = GETDATE()
              , [entryData] = @entryData
              , [hostName] = @hostName
            WHERE [MaintenanceCategoryID] = @CategoryID
              AND [IdaraId_FK] = @IdaraID
              AND [IsActive] = 1;

            INSERT INTO [dbo].[AuditLog] ([TableName], [ActionType], [RecordID], [PerformedBy], [Notes], [PerformedAt])
            VALUES (N'Maintenance.MaintenanceCategory', @ActionNormalized, @CategoryID, @entryData, N'تعطيل نوع صيانة', GETDATE());

            IF @tc = 0
                COMMIT;

            SELECT 1 AS [IsSuccessful], N'تم تعطيل نوع الصيانة بنجاح' AS [Message_];
            RETURN;
        END

        ELSE IF @ActionNormalized = N'ROUTEMAINTENANCECATEGORY'
        BEGIN
            IF @CategoryID IS NULL
                THROW 50001, N'معرف نوع الصيانة مطلوب', 1;

            IF @ResponsibleDSDIDValue IS NULL
                THROW 50001, N'الجهة المسؤولة مطلوبة', 1;

            IF NOT EXISTS
            (
                SELECT 1
                FROM [Maintenance].[MaintenanceCategory]
                WHERE [MaintenanceCategoryID] = @CategoryID
                  AND [IdaraId_FK] = @IdaraID
                  AND [IsActive] = 1
            )
                THROW 50001, N'نوع الصيانة غير موجود ضمن نفس الإدارة', 1;

            IF NOT EXISTS
            (
                SELECT 1
                FROM [dbo].[DeptSecDiv]
                WHERE [DSDID] = @ResponsibleDSDIDValue
                  AND [idaraID_FK] = @IdaraID
            )
                THROW 50001, N'الجهة المسؤولة غير موجودة ضمن نفس الإدارة', 1;

                        IF EXISTS
            (
                SELECT 1
                FROM [Maintenance].[MaintenanceCategory]
                WHERE [ParentID] = @CategoryID
                  AND [IdaraId_FK] = @IdaraID
                  AND [IsActive] = 1
            )
                THROW 50001, N'لا يمكن ربط الجهة المسؤولة بتصنيف يحتوي على أبناء، اختر آخر مستوى', 1;

            UPDATE [Maintenance].[MaintenanceCategoryRouting]
            SET [IsActive] = 0
              , [IsDefault] = 0
              , [updateUser] = @EntryUser
              , [updateDate] = GETDATE()
              , [entryData] = @entryData
              , [hostName] = @hostName
            WHERE [MaintenanceCategoryID] = @CategoryID
              AND [IdaraId_FK] = @IdaraID
              AND [IsDefault] = 1
              AND [IsActive] = 1;

            INSERT INTO [Maintenance].[MaintenanceCategoryRouting]
            (
                  [IdaraId_FK]
                , [MaintenanceCategoryID]
                , [ResponsibleDSDID]
                , [IsDefault]
                , [Notes]
                , [entryUser]
                , [entryData]
                , [hostName]
            )
            VALUES
            (
                  @IdaraID
                , @CategoryID
                , @ResponsibleDSDIDValue
                , 1
                , @NotesValue
                , @EntryUser
                , @entryData
                , @hostName
            );

            SET @RecordID = CONVERT(BIGINT, SCOPE_IDENTITY());

            INSERT INTO [dbo].[AuditLog] ([TableName], [ActionType], [RecordID], [PerformedBy], [Notes], [PerformedAt])
            VALUES (N'Maintenance.MaintenanceCategoryRouting', @ActionNormalized, @RecordID, @entryData, N'ربط نوع صيانة بجهة مسؤولة', GETDATE());

            IF @tc = 0
                COMMIT;

            SELECT 1 AS [IsSuccessful], N'تم ربط نوع الصيانة بالجهة المسؤولة بنجاح' AS [Message_];
            RETURN;
        END

        ELSE
        BEGIN
            THROW 50001, N'نوع العملية المطلوبة غير معروف. ActionType', 1;
        END
    END TRY
    BEGIN CATCH
        IF @tc = 0 AND XACT_STATE() <> 0
            ROLLBACK;

        IF ERROR_NUMBER() BETWEEN 50001 AND 50999
            THROW;

        DECLARE @ErrorMessage NVARCHAR(2048) = ERROR_MESSAGE();
        THROW 50002, @ErrorMessage, 1;
    END CATCH
END
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
          [IdaraId]
        , [MaintenanceCategoryID]
        , [ParentID]
        , [CategoryName_A]
        , [CategoryName_E]
        , [LevelNo]
        , [FullPath_A]
        , [DisplayOrder]
        , [IsActive]
        , [HasChildren]
    FROM [Maintenance].[V_MaintenanceCategoryTree]
    WHERE [IdaraId] = @idaraID
    ORDER BY [FullPath_A], [DisplayOrder], [MaintenanceCategoryID];

    SELECT
          [MaintenanceCategoryID]
        , [FullPath_A]
    FROM [Maintenance].[V_MaintenanceCategoryTree]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
    ORDER BY [FullPath_A], [MaintenanceCategoryID];

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




