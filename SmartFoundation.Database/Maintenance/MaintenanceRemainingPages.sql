USE [DATACORE];
GO

CREATE OR ALTER PROCEDURE [Maintenance].[MaintenanceApprovalDL]
      @pageName_ NVARCHAR(400)
    , @idaraID INT
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
          list.[RequestID]
        , list.[RequestNo]
        , list.[RequestDate]
        , list.[BuildingID]
        , list.[ResidentID]
        , list.[MaintenanceCategoryID]
        , list.[MaintenanceCategoryFullPath_A]
        , list.[PriorityName_A]
        , list.[StatusName_A]
        , list.[CurrentDSDID]
        , list.[LastActionDate]
        , list.[LastActionTypeName_A]
        , list.[LastActionNote]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList] AS list
    WHERE list.[IdaraId] = @idaraID
      AND list.[IsActive] = 1
      AND list.[StatusCode] = N'WAITING_APPROVAL'
    ORDER BY list.[RequestDate] DESC, list.[RequestID] DESC;
END;
GO

CREATE OR ALTER PROCEDURE [Maintenance].[MaintenanceApprovalSP]
      @Action NVARCHAR(200)
    , @RequestID NVARCHAR(100) = NULL
    , @Notes NVARCHAR(MAX) = NULL
    , @idaraID_FK NVARCHAR(10) = NULL
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
          @tc INT = @@TRANCOUNT
        , @RequestID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@RequestID)), N''))
        , @IdaraID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@idaraID_FK)), N''))
        , @EntryUser_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@entryData)), N''))
        , @CurrentStatusID INT = NULL
        , @CurrentStatusCode NVARCHAR(100) = NULL
        , @NewStatusID INT = NULL
        , @ActionTypeID INT = NULL
        , @CurrentDSDID BIGINT = NULL
        , @NewID BIGINT = NULL
        , @Note NVARCHAR(MAX) = NULL
        , @Message NVARCHAR(400) = NULL;

    SET @Action = UPPER(LTRIM(RTRIM(ISNULL(@Action, N''))));

    BEGIN TRY
        IF @tc = 0
            BEGIN TRAN;

        IF @IdaraID_BIGINT IS NULL
        BEGIN
            ;THROW 50001, N'الإدارة مطلوبة', 1;
        END

        IF @RequestID_BIGINT IS NULL
        BEGIN
            ;THROW 50001, N'طلب الصيانة مطلوب', 1;
        END

        IF @Action NOT IN (N'APPROVEMAINTENANCEAPPROVAL', N'REJECTMAINTENANCEAPPROVAL')
        BEGIN
            ;THROW 50001, N'نوع العملية غير معروف', 1;
        END

        IF @Action = N'REJECTMAINTENANCEAPPROVAL' AND NULLIF(LTRIM(RTRIM(ISNULL(@Notes, N''))), N'') IS NULL
        BEGIN
            ;THROW 50001, N'ملاحظة الرفض مطلوبة', 1;
        END

        SELECT
              @CurrentStatusID = request.[StatusID]
            , @CurrentStatusCode = status.[StatusCode]
            , @CurrentDSDID = request.[CurrentDSDID]
        FROM [Maintenance].[BuildingMaintenanceRequest] AS request WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN [Maintenance].[MaintenanceRequestStatus] AS status
            ON status.[StatusID] = request.[StatusID]
        WHERE request.[RequestID] = @RequestID_BIGINT
          AND request.[IdaraId_FK] = @IdaraID_BIGINT
          AND request.[IsActive] = 1;

        IF @CurrentStatusID IS NULL
        BEGIN
            ;THROW 50001, N'طلب الصيانة غير موجود أو غير نشط', 1;
        END

        IF ISNULL(@CurrentStatusCode, N'') <> N'WAITING_APPROVAL'
        BEGIN
            ;THROW 50001, N'لا يمكن تنفيذ الموافقة إلا على طلب بانتظار الموافقة', 1;
        END

        SELECT @NewStatusID = [StatusID]
        FROM [Maintenance].[MaintenanceRequestStatus]
        WHERE [StatusCode] = CASE WHEN @Action = N'APPROVEMAINTENANCEAPPROVAL' THEN N'IN_PROGRESS' ELSE N'REJECTED' END
          AND [IsActive] = 1;

        IF @NewStatusID IS NULL
        BEGIN
            ;THROW 50002, N'حالة الطلب المستهدفة غير معرفة', 1;
        END

        SELECT @ActionTypeID = [ActionTypeID]
        FROM [Maintenance].[MaintenanceActionType]
        WHERE [ActionTypeCode] = CASE WHEN @Action = N'APPROVEMAINTENANCEAPPROVAL' THEN N'APPROVE' ELSE N'REJECT' END
          AND [IsActive] = 1;

        IF @ActionTypeID IS NULL
        BEGIN
            ;THROW 50002, N'نوع إجراء الموافقة غير معرف', 1;
        END

        UPDATE [Maintenance].[BuildingMaintenanceRequest]
        SET
              [StatusID] = @NewStatusID
            , [updateUser] = @EntryUser_BIGINT
            , [updateDate] = GETDATE()
            , [entryData] = ISNULL(ISNULL([entryData], N'') + N',' + @entryData, [entryData])
            , [hostName] = ISNULL(ISNULL([hostName], N'') + N',' + @hostName, [hostName])
        WHERE [RequestID] = @RequestID_BIGINT
          AND [IdaraId_FK] = @IdaraID_BIGINT
          AND [IsActive] = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            ;THROW 50002, N'حصل خطأ أثناء تحديث حالة طلب الصيانة', 1;
        END

        UPDATE [Maintenance].[BuildingMaintenanceRequestApproval]
        SET
              [ApprovalStatusID] = @NewStatusID
            , [ApprovalUserID] = @EntryUser_BIGINT
            , [DecisionNote] = @Notes
            , [DecisionDate] = GETDATE()
            , [updateUser] = @EntryUser_BIGINT
            , [updateDate] = GETDATE()
            , [entryData] = ISNULL(ISNULL([entryData], N'') + N',' + @entryData, [entryData])
            , [hostName] = ISNULL(ISNULL([hostName], N'') + N',' + @hostName, [hostName])
        WHERE [RequestID] = @RequestID_BIGINT
          AND ([IdaraId_FK] = @IdaraID_BIGINT OR [IdaraId_FK] IS NULL)
          AND [IsActive] = 1;

        INSERT INTO [Maintenance].[BuildingMaintenanceRequestAction]
        (
              [RequestID]
            , [ActionTypeID]
            , [FromDSDID]
            , [ToDSDID]
            , [FromUserID]
            , [OldStatusID]
            , [NewStatusID]
            , [ActionNote]
            , [ActionDate]
            , [entryUser]
            , [IdaraId_FK]
            , [entryData]
            , [hostName]
        )
        VALUES
        (
              @RequestID_BIGINT
            , @ActionTypeID
            , @CurrentDSDID
            , @CurrentDSDID
            , @EntryUser_BIGINT
            , @CurrentStatusID
            , @NewStatusID
            , @Notes
            , GETDATE()
            , @EntryUser_BIGINT
            , @IdaraID_BIGINT
            , @entryData
            , @hostName
        );

        IF @@ROWCOUNT = 0
        BEGIN
            ;THROW 50002, N'حصل خطأ أثناء تسجيل حركة الموافقة', 1;
        END

        SET @NewID = @RequestID_BIGINT;
        SET @Note = N'{"RequestID":"' + CONVERT(NVARCHAR(30), @RequestID_BIGINT) + N'","Action":"' + @Action + N'"}';

        INSERT INTO [dbo].[AuditLog]
        (
              [TableName]
            , [ActionType]
            , [RecordID]
            , [PerformedBy]
            , [Notes]
        )
        VALUES
        (
              N'[Maintenance].[BuildingMaintenanceRequest]'
            , @Action
            , @NewID
            , @entryData
            , @Note
        );

        SET @Message = CASE
            WHEN @Action = N'APPROVEMAINTENANCEAPPROVAL' THEN N'تمت الموافقة على طلب الصيانة بنجاح'
            ELSE N'تم رفض طلب الصيانة بنجاح'
        END;

        IF @tc = 0
            COMMIT;

        SELECT 1 AS [IsSuccessful], @Message AS [Message_];
        RETURN;
    END TRY
    BEGIN CATCH
        IF @tc = 0 AND XACT_STATE() <> 0
            ROLLBACK;

        ;THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE [Maintenance].[MaintenanceSubRequestDL]
      @pageName_ NVARCHAR(400)
    , @idaraID INT
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
          list.[RequestID]
        , list.[TransactionID_FK]
        , list.[RequestNo]
        , list.[RequestDate]
        , list.[ParentRequestID]
        , list.[RootRequestID]
        , list.[RequestLevel]
        , list.[BuildingID]
        , list.[ResidentID]
        , list.[MaintenanceCategoryID]
        , list.[MaintenanceCategoryFullPath_A]
        , list.[CurrentDSDID]
        , list.[StatusID]
        , list.[StatusName_A]
        , list.[StatusCode]
        , list.[PriorityID]
        , list.[PriorityName_A]
        , list.[PriorityCode]
        , list.[LastActionDate]
        , list.[LastActionTypeName_A]
        , list.[LastActionNote]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList] AS list
    WHERE list.[IdaraId] = @idaraID
      AND list.[IsActive] = 1
      AND list.[IsSubRequest] = 1
    ORDER BY list.[RequestDate] DESC, list.[RequestID] DESC;

    SELECT
          list.[RequestID]
        , list.[RequestNo]
        , list.[RequestDate]
        , list.[BuildingID]
        , list.[ResidentID]
        , list.[MaintenanceCategoryFullPath_A]
        , list.[StatusName_A]
        , list.[StatusCode]
        , list.[PriorityName_A]
        , list.[CurrentDSDID]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList] AS list
    WHERE list.[IdaraId] = @idaraID
      AND list.[IsActive] = 1
      AND list.[IsSubRequest] = 0
      AND ISNULL(list.[StatusCode], N'') NOT IN (N'CLOSED', N'CANCELLED', N'COMPLETED')
    ORDER BY list.[RequestDate] DESC, list.[RequestID] DESC;

    SELECT
          tree.[MaintenanceCategoryID]
        , tree.[FullPath_A]
        , routing.[ResponsibleDSDID]
    FROM [Maintenance].[V_MaintenanceCategoryTree] AS tree
    INNER JOIN [Maintenance].[MaintenanceCategoryRouting] AS routing
        ON routing.[IdaraId_FK] = tree.[IdaraId]
       AND routing.[MaintenanceCategoryID] = tree.[MaintenanceCategoryID]
       AND routing.[IsActive] = 1
       AND routing.[IsDefault] = 1
    WHERE tree.[IdaraId] = @idaraID
      AND tree.[IsActive] = 1
      AND tree.[HasChildren] = 0
    ORDER BY tree.[FullPath_A], tree.[MaintenanceCategoryID];

    SELECT
          dsd.[DSDID]
        , COALESCE
          (
              NULLIF(LTRIM(RTRIM(CONCAT(dept.[deptName_A], N' ', sec.[secName_A], N' ', div.[divName_A]))), N''),
              N'جهة رقم ' + CONVERT(NVARCHAR(30), dsd.[DSDID])
          ) AS [DSDName_A]
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
          [PriorityID]
        , [PriorityName_A]
        , [PriorityCode]
    FROM [Maintenance].[MaintenancePriority]
    WHERE [IsActive] = 1
      AND ([IdaraId_FK] IS NULL OR [IdaraId_FK] = @idaraID)
    ORDER BY [DisplayOrder], [PriorityID];

    SELECT
          [StatusID]
        , [StatusName_A]
        , [StatusCode]
    FROM [Maintenance].[MaintenanceRequestStatus]
    WHERE [IsActive] = 1
      AND ([IdaraId_FK] IS NULL OR [IdaraId_FK] = @idaraID)
    ORDER BY [DisplayOrder], [StatusID];
END;
GO

CREATE OR ALTER PROCEDURE [Maintenance].[MaintenanceSubRequestSP]
      @Action NVARCHAR(200)
    , @ParentRequestID NVARCHAR(100) = NULL
    , @RequestID NVARCHAR(100) = NULL
    , @MaintenanceCategoryID NVARCHAR(100) = NULL
    , @ToDSDID NVARCHAR(100) = NULL
    , @Description_A NVARCHAR(MAX) = NULL
    , @PriorityID NVARCHAR(100) = NULL
    , @Notes NVARCHAR(MAX) = NULL
    , @idaraID_FK NVARCHAR(10) = NULL
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
          @tc INT = @@TRANCOUNT
        , @ParentRequestID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@ParentRequestID)), N''))
        , @RequestID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@RequestID)), N''))
        , @MaintenanceCategoryID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@MaintenanceCategoryID)), N''))
        , @ToDSDID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@ToDSDID)), N''))
        , @PriorityID_INT INT = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(@PriorityID)), N''))
        , @IdaraID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@idaraID_FK)), N''))
        , @EntryUser_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@entryData)), N''))
        , @ParentStatusID INT = NULL
        , @ParentStatusCode NVARCHAR(100) = NULL
        , @ParentRootRequestID BIGINT = NULL
        , @ParentRequestLevel INT = NULL
        , @ParentBuildingID BIGINT = NULL
        , @ParentUnitID BIGINT = NULL
        , @ParentResidentID BIGINT = NULL
        , @ParentPriorityID INT = NULL
        , @ParentCurrentDSDID BIGINT = NULL
        , @NewStatusID INT = NULL
        , @WaitingSubRequestStatusID INT = NULL
        , @InProgressStatusID INT = NULL
        , @CancelledStatusID INT = NULL
        , @CompletedStatusID INT = NULL
        , @ActionTypeID INT = NULL
        , @ParentActionTypeID INT = NULL
        , @NewID BIGINT = NULL
        , @RequestNo NVARCHAR(50) = NULL
        , @NextNo INT = NULL
        , @Note NVARCHAR(MAX) = NULL
        , @Message NVARCHAR(400) = NULL;

    SET @Action = UPPER(LTRIM(RTRIM(ISNULL(@Action, N''))));

    BEGIN TRY
        IF @tc = 0
            BEGIN TRAN;

        IF @IdaraID_BIGINT IS NULL
        BEGIN
            ;THROW 50001, N'الإدارة مطلوبة', 1;
        END

        IF @Action = N'CREATEMAINTENANCESUBREQUEST'
        BEGIN
            IF @ParentRequestID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'الطلب الرئيسي مطلوب', 1;
            END

            IF @MaintenanceCategoryID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'نوع الصيانة مطلوب', 1;
            END

            SELECT
                  @ParentStatusID = parent.[StatusID]
                , @ParentStatusCode = status.[StatusCode]
                , @ParentRootRequestID = parent.[RootRequestID]
                , @ParentRequestLevel = parent.[RequestLevel]
                , @ParentBuildingID = parent.[BuildingID]
                , @ParentUnitID = parent.[UnitID]
                , @ParentResidentID = parent.[ResidentID]
                , @ParentPriorityID = parent.[PriorityID]
                , @ParentCurrentDSDID = parent.[CurrentDSDID]
            FROM [Maintenance].[BuildingMaintenanceRequest] AS parent WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN [Maintenance].[MaintenanceRequestStatus] AS status
                ON status.[StatusID] = parent.[StatusID]
            WHERE parent.[RequestID] = @ParentRequestID_BIGINT
              AND parent.[IdaraId_FK] = @IdaraID_BIGINT
              AND parent.[IsActive] = 1;

            IF @ParentStatusID IS NULL
            BEGIN
                ;THROW 50001, N'الطلب الرئيسي غير موجود أو غير نشط', 1;
            END

            IF ISNULL(@ParentStatusCode, N'') IN (N'CLOSED', N'CANCELLED')
            BEGIN
                ;THROW 50001, N'لا يمكن إنشاء طلب فرعي لطلب مغلق أو ملغي', 1;
            END

            IF NOT EXISTS
            (
                SELECT 1
                FROM [Maintenance].[MaintenanceCategory]
                WHERE [MaintenanceCategoryID] = @MaintenanceCategoryID_BIGINT
                  AND [IdaraId_FK] = @IdaraID_BIGINT
                  AND [IsActive] = 1
            )
            BEGIN
                ;THROW 50001, N'نوع الصيانة غير موجود أو غير فعال', 1;
            END

            IF @ToDSDID_BIGINT IS NULL
            BEGIN
                SELECT TOP 1 @ToDSDID_BIGINT = [ResponsibleDSDID]
                FROM [Maintenance].[MaintenanceCategoryRouting]
                WHERE [MaintenanceCategoryID] = @MaintenanceCategoryID_BIGINT
                  AND [IdaraId_FK] = @IdaraID_BIGINT
                  AND [IsActive] = 1
                  AND [IsDefault] = 1
                ORDER BY [MaintenanceCategoryRoutingID] DESC;
            END

            IF @ToDSDID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'لا يمكن إنشاء طلب فرعي بدون جهة مسؤولة', 1;
            END

            SELECT @NewStatusID = [StatusID]
            FROM [Maintenance].[MaintenanceRequestStatus]
            WHERE [StatusCode] = N'NEW'
              AND [IsActive] = 1;

            SELECT @WaitingSubRequestStatusID = [StatusID]
            FROM [Maintenance].[MaintenanceRequestStatus]
            WHERE [StatusCode] = N'WAITING_SUB_REQUEST'
              AND [IsActive] = 1;

            SELECT @ActionTypeID = [ActionTypeID]
            FROM [Maintenance].[MaintenanceActionType]
            WHERE [ActionTypeCode] = N'CREATE'
              AND [IsActive] = 1;

            SELECT @ParentActionTypeID = [ActionTypeID]
            FROM [Maintenance].[MaintenanceActionType]
            WHERE [ActionTypeCode] = N'CREATE_SUB_REQUEST'
              AND [IsActive] = 1;

            IF @NewStatusID IS NULL OR @WaitingSubRequestStatusID IS NULL OR @ActionTypeID IS NULL OR @ParentActionTypeID IS NULL
            BEGIN
                ;THROW 50002, N'تعريفات الحالات أو الإجراءات الخاصة بالطلب الفرعي غير مكتملة', 1;
            END

            SELECT @NextNo = ISNULL(MAX(TRY_CONVERT(INT, RIGHT([RequestNo], 6))), 0) + 1
            FROM [Maintenance].[BuildingMaintenanceRequest] WITH (UPDLOCK, HOLDLOCK)
            WHERE [IdaraId_FK] = @IdaraID_BIGINT
              AND [RequestNo] LIKE N'MR-' + CONVERT(NVARCHAR(4), YEAR(GETDATE())) + N'-%';

            SET @RequestNo = N'MR-' + CONVERT(NVARCHAR(4), YEAR(GETDATE())) + N'-' + RIGHT(N'000000' + CONVERT(NVARCHAR(20), @NextNo), 6);

            INSERT INTO [Maintenance].[BuildingMaintenanceRequest]
            (
                  [IdaraId_FK]
                , [RequestNo]
                , [ParentRequestID]
                , [RootRequestID]
                , [RequestLevel]
                , [IsSubRequest]
                , [IsBlockingParent]
                , [BuildingID]
                , [UnitID]
                , [ResidentID]
                , [MaintenanceCategoryID]
                , [CurrentDSDID]
                , [OriginalDSDID]
                , [StatusID]
                , [PriorityID]
                , [Description_A]
                , [HasDispute]
                , [EscalationLevel]
                , [IsLockedByDecision]
                , [RequestDate]
                , [entryUser]
                , [entryData]
                , [hostName]
            )
            VALUES
            (
                  @IdaraID_BIGINT
                , @RequestNo
                , @ParentRequestID_BIGINT
                , ISNULL(@ParentRootRequestID, @ParentRequestID_BIGINT)
                , ISNULL(@ParentRequestLevel, 0) + 1
                , 1
                , 1
                , @ParentBuildingID
                , @ParentUnitID
                , @ParentResidentID
                , @MaintenanceCategoryID_BIGINT
                , @ToDSDID_BIGINT
                , @ToDSDID_BIGINT
                , @NewStatusID
                , ISNULL(@PriorityID_INT, @ParentPriorityID)
                , ISNULL(NULLIF(LTRIM(RTRIM(@Description_A)), N''), N'طلب فرعي')
                , 0
                , 0
                , 0
                , GETDATE()
                , @EntryUser_BIGINT
                , @entryData
                , @hostName
            );

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ أثناء إنشاء الطلب الفرعي', 1;
            END

            SET @NewID = SCOPE_IDENTITY();
            IF @NewID IS NULL OR @NewID <= 0
            BEGIN
                ;THROW 50002, N'حصل خطأ أثناء إنشاء الطلب الفرعي - Identity', 1;
            END

            UPDATE [Maintenance].[BuildingMaintenanceRequest]
            SET
                  [StatusID] = @WaitingSubRequestStatusID
                , [updateUser] = @EntryUser_BIGINT
                , [updateDate] = GETDATE()
                , [entryData] = ISNULL(ISNULL([entryData], N'') + N',' + @entryData, [entryData])
                , [hostName] = ISNULL(ISNULL([hostName], N'') + N',' + @hostName, [hostName])
            WHERE [RequestID] = @ParentRequestID_BIGINT
              AND [IdaraId_FK] = @IdaraID_BIGINT
              AND [IsActive] = 1;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ أثناء تحديث حالة الطلب الرئيسي', 1;
            END

            INSERT INTO [Maintenance].[BuildingMaintenanceRequestAction]
            ([RequestID], [ActionTypeID], [FromDSDID], [ToDSDID], [FromUserID], [OldStatusID], [NewStatusID], [ActionNote], [ActionDate], [entryUser], [IdaraId_FK], [entryData], [hostName])
            VALUES
            (@ParentRequestID_BIGINT, @ParentActionTypeID, @ParentCurrentDSDID, @ParentCurrentDSDID, @EntryUser_BIGINT, @ParentStatusID, @WaitingSubRequestStatusID, @Description_A, GETDATE(), @EntryUser_BIGINT, @IdaraID_BIGINT, @entryData, @hostName),
            (@NewID, @ActionTypeID, @ToDSDID_BIGINT, @ToDSDID_BIGINT, @EntryUser_BIGINT, NULL, @NewStatusID, @Description_A, GETDATE(), @EntryUser_BIGINT, @IdaraID_BIGINT, @entryData, @hostName);

            SET @Message = N'تم إنشاء الطلب الفرعي بنجاح';
            SET @Note = N'{"ParentRequestID":"' + CONVERT(NVARCHAR(30), @ParentRequestID_BIGINT) + N'","SubRequestID":"' + CONVERT(NVARCHAR(30), @NewID) + N'"}';
        END
        ELSE IF @Action IN (N'COMPLETEMAINTENANCESUBREQUEST', N'RETURNTOPARENTREQUEST', N'CANCELMAINTENANCESUBREQUEST')
        BEGIN
            IF @RequestID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'الطلب الفرعي مطلوب', 1;
            END

            SELECT
                  @ParentRequestID_BIGINT = request.[ParentRequestID]
                , @ParentStatusID = request.[StatusID]
                , @ParentStatusCode = status.[StatusCode]
                , @ParentCurrentDSDID = request.[CurrentDSDID]
            FROM [Maintenance].[BuildingMaintenanceRequest] AS request WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN [Maintenance].[MaintenanceRequestStatus] AS status
                ON status.[StatusID] = request.[StatusID]
            WHERE request.[RequestID] = @RequestID_BIGINT
              AND request.[IdaraId_FK] = @IdaraID_BIGINT
              AND request.[IsSubRequest] = 1
              AND request.[IsActive] = 1;

            IF @ParentRequestID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'الطلب الفرعي غير موجود أو غير نشط', 1;
            END

            IF ISNULL(@ParentStatusCode, N'') IN (N'CLOSED', N'CANCELLED')
            BEGIN
                ;THROW 50001, N'لا يمكن تنفيذ الإجراء على طلب فرعي مغلق أو ملغي', 1;
            END

            SELECT @CompletedStatusID = [StatusID]
            FROM [Maintenance].[MaintenanceRequestStatus]
            WHERE [StatusCode] = N'COMPLETED'
              AND [IsActive] = 1;

            SELECT @CancelledStatusID = [StatusID]
            FROM [Maintenance].[MaintenanceRequestStatus]
            WHERE [StatusCode] = N'CANCELLED'
              AND [IsActive] = 1;

            SELECT @InProgressStatusID = [StatusID]
            FROM [Maintenance].[MaintenanceRequestStatus]
            WHERE [StatusCode] = N'IN_PROGRESS'
              AND [IsActive] = 1;

            SELECT @ActionTypeID = [ActionTypeID]
            FROM [Maintenance].[MaintenanceActionType]
            WHERE [ActionTypeCode] = CASE WHEN @Action = N'CANCELMAINTENANCESUBREQUEST' THEN N'CANCEL' ELSE N'COMPLETE_WORK' END
              AND [IsActive] = 1;

            SELECT @ParentActionTypeID = [ActionTypeID]
            FROM [Maintenance].[MaintenanceActionType]
            WHERE [ActionTypeCode] = N'RETURN_TO_PARENT'
              AND [IsActive] = 1;

            IF @CompletedStatusID IS NULL OR @CancelledStatusID IS NULL OR @InProgressStatusID IS NULL OR @ActionTypeID IS NULL
            BEGIN
                ;THROW 50002, N'تعريفات الحالات أو الإجراءات الخاصة بالطلب الفرعي غير مكتملة', 1;
            END

            SET @NewStatusID = CASE WHEN @Action = N'CANCELMAINTENANCESUBREQUEST' THEN @CancelledStatusID ELSE @CompletedStatusID END;

            UPDATE [Maintenance].[BuildingMaintenanceRequest]
            SET
                  [StatusID] = @NewStatusID
                , [ClosedDate] = CASE WHEN @Action = N'CANCELMAINTENANCESUBREQUEST' THEN [ClosedDate] ELSE ISNULL([ClosedDate], GETDATE()) END
                , [updateUser] = @EntryUser_BIGINT
                , [updateDate] = GETDATE()
                , [entryData] = ISNULL(ISNULL([entryData], N'') + N',' + @entryData, [entryData])
                , [hostName] = ISNULL(ISNULL([hostName], N'') + N',' + @hostName, [hostName])
            WHERE [RequestID] = @RequestID_BIGINT
              AND [IdaraId_FK] = @IdaraID_BIGINT
              AND [IsActive] = 1;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ أثناء تحديث الطلب الفرعي', 1;
            END

            INSERT INTO [Maintenance].[BuildingMaintenanceRequestAction]
            ([RequestID], [ActionTypeID], [FromDSDID], [ToDSDID], [FromUserID], [OldStatusID], [NewStatusID], [ActionNote], [ActionDate], [entryUser], [IdaraId_FK], [entryData], [hostName])
            VALUES
            (@RequestID_BIGINT, @ActionTypeID, @ParentCurrentDSDID, @ParentCurrentDSDID, @EntryUser_BIGINT, @ParentStatusID, @NewStatusID, @Notes, GETDATE(), @EntryUser_BIGINT, @IdaraID_BIGINT, @entryData, @hostName);

            IF @Action <> N'CANCELMAINTENANCESUBREQUEST'
               AND NOT EXISTS
               (
                   SELECT 1
                   FROM [Maintenance].[BuildingMaintenanceRequest] AS child
                   INNER JOIN [Maintenance].[MaintenanceRequestStatus] AS childStatus
                       ON childStatus.[StatusID] = child.[StatusID]
                   WHERE child.[ParentRequestID] = @ParentRequestID_BIGINT
                     AND child.[IdaraId_FK] = @IdaraID_BIGINT
                     AND child.[IsSubRequest] = 1
                     AND child.[IsBlockingParent] = 1
                     AND child.[IsActive] = 1
                     AND ISNULL(childStatus.[StatusCode], N'') NOT IN (N'COMPLETED', N'CLOSED', N'CANCELLED')
               )
            BEGIN
                UPDATE [Maintenance].[BuildingMaintenanceRequest]
                SET
                      [StatusID] = @InProgressStatusID
                    , [updateUser] = @EntryUser_BIGINT
                    , [updateDate] = GETDATE()
                    , [entryData] = ISNULL(ISNULL([entryData], N'') + N',' + @entryData, [entryData])
                    , [hostName] = ISNULL(ISNULL([hostName], N'') + N',' + @hostName, [hostName])
                WHERE [RequestID] = @ParentRequestID_BIGINT
                  AND [IdaraId_FK] = @IdaraID_BIGINT
                  AND [IsActive] = 1;

                INSERT INTO [Maintenance].[BuildingMaintenanceRequestAction]
                ([RequestID], [ActionTypeID], [FromUserID], [OldStatusID], [NewStatusID], [ActionNote], [ActionDate], [entryUser], [IdaraId_FK], [entryData], [hostName])
                VALUES
                (@ParentRequestID_BIGINT, @ParentActionTypeID, @EntryUser_BIGINT, NULL, @InProgressStatusID, @Notes, GETDATE(), @EntryUser_BIGINT, @IdaraID_BIGINT, @entryData, @hostName);
            END

            SET @NewID = @RequestID_BIGINT;
            SET @Message = CASE WHEN @Action = N'CANCELMAINTENANCESUBREQUEST' THEN N'تم إلغاء الطلب الفرعي بنجاح' ELSE N'تم إنهاء الطلب الفرعي بنجاح' END;
            SET @Note = N'{"SubRequestID":"' + CONVERT(NVARCHAR(30), @RequestID_BIGINT) + N'","Action":"' + @Action + N'"}';
        END
        ELSE
        BEGIN
            ;THROW 50001, N'نوع العملية غير معروف', 1;
        END

        INSERT INTO [dbo].[AuditLog] ([TableName], [ActionType], [RecordID], [PerformedBy], [Notes])
        VALUES (N'[Maintenance].[BuildingMaintenanceRequest]', @Action, ISNULL(@NewID, 0), @entryData, @Note);

        IF @tc = 0
            COMMIT;

        SELECT 1 AS [IsSuccessful], @Message AS [Message_];
        RETURN;
    END TRY
    BEGIN CATCH
        IF @tc = 0 AND XACT_STATE() <> 0
            ROLLBACK;

        ;THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE [Maintenance].[MaintenanceDisputeDL]
      @pageName_ NVARCHAR(400)
    , @idaraID INT
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
          dispute.[DisputeID]
        , dispute.[RequestID]
        , list.[RequestNo]
        , list.[RequestDate]
        , list.[MaintenanceCategoryFullPath_A]
        , list.[StatusName_A]
        , list.[StatusCode]
        , dispute.[RaisedByDSDID]
        , dispute.[AgainstDSDID]
        , dispute.[RaisedByUserID]
        , dispute.[Reason]
        , dispute.[ArbitrationDSDID]
        , dispute.[DecisionByUserID]
        , dispute.[DecisionNote]
        , dispute.[IsBindingDecision]
        , dispute.[DecisionDate]
        , dispute.[DisputeStatusID]
        , dispute.[IsActive]
    FROM [Maintenance].[BuildingMaintenanceRequestDispute] AS dispute
    INNER JOIN [Maintenance].[V_BuildingMaintenanceRequestList] AS list
        ON list.[RequestID] = dispute.[RequestID]
    WHERE list.[IdaraId] = @idaraID
      AND dispute.[IsActive] = 1
      AND dispute.[DecisionDate] IS NULL
    ORDER BY dispute.[entryDate] DESC, dispute.[DisputeID] DESC;

    SELECT
          list.[RequestID]
        , list.[RequestNo]
        , list.[RequestDate]
        , list.[MaintenanceCategoryFullPath_A]
        , list.[CurrentDSDID]
        , list.[StatusName_A]
        , list.[StatusCode]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList] AS list
    WHERE list.[IdaraId] = @idaraID
      AND list.[IsActive] = 1
      AND ISNULL(list.[StatusCode], N'') NOT IN (N'CLOSED', N'CANCELLED')
    ORDER BY list.[RequestDate] DESC, list.[RequestID] DESC;

    SELECT
          dsd.[DSDID]
        , COALESCE
          (
              NULLIF(LTRIM(RTRIM(CONCAT(dept.[deptName_A], N' ', sec.[secName_A], N' ', div.[divName_A]))), N''),
              N'جهة رقم ' + CONVERT(NVARCHAR(30), dsd.[DSDID])
          ) AS [DSDName_A]
    FROM [dbo].[DeptSecDiv] AS dsd
    LEFT JOIN [dbo].[Department] AS dept
        ON dept.[deptID] = dsd.[deptID_FK]
    LEFT JOIN [dbo].[Section] AS sec
        ON sec.[secID] = dsd.[secID_FK]
    LEFT JOIN [dbo].[Divison] AS div
        ON div.[divID] = dsd.[divID_FK]
    WHERE dsd.[idaraID_FK] = @idaraID
    ORDER BY [DSDName_A], dsd.[DSDID];

    SELECT TOP (100)
          timeline.[ActionID]
        , timeline.[RequestID]
        , list.[RequestNo]
        , timeline.[ActionDate]
        , timeline.[ActionTypeName_A]
        , timeline.[ActionTypeCode]
        , timeline.[ReasonName_A]
        , timeline.[ActionNote]
    FROM [Maintenance].[V_BuildingMaintenanceRequestTimeline] AS timeline
    INNER JOIN [Maintenance].[V_BuildingMaintenanceRequestList] AS list
        ON list.[RequestID] = timeline.[RequestID]
    WHERE list.[IdaraId] = @idaraID
    ORDER BY timeline.[ActionDate] DESC, timeline.[ActionID] DESC;
END;
GO

CREATE OR ALTER PROCEDURE [Maintenance].[MaintenanceDisputeSP]
      @Action NVARCHAR(200)
    , @RequestID NVARCHAR(100) = NULL
    , @DisputeID NVARCHAR(100) = NULL
    , @AgainstDSDID NVARCHAR(100) = NULL
    , @DecisionDSDID NVARCHAR(100) = NULL
    , @Reason NVARCHAR(MAX) = NULL
    , @DecisionNote NVARCHAR(MAX) = NULL
    , @idaraID_FK NVARCHAR(10) = NULL
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
          @tc INT = @@TRANCOUNT
        , @RequestID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@RequestID)), N''))
        , @DisputeID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@DisputeID)), N''))
        , @AgainstDSDID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@AgainstDSDID)), N''))
        , @DecisionDSDID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@DecisionDSDID)), N''))
        , @IdaraID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@idaraID_FK)), N''))
        , @EntryUser_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@entryData)), N''))
        , @CurrentStatusID INT = NULL
        , @CurrentStatusCode NVARCHAR(100) = NULL
        , @NewStatusID INT = NULL
        , @ActionTypeID INT = NULL
        , @CurrentDSDID BIGINT = NULL
        , @NewID BIGINT = NULL
        , @Note NVARCHAR(MAX) = NULL
        , @Message NVARCHAR(400) = NULL;

    SET @Action = UPPER(LTRIM(RTRIM(ISNULL(@Action, N''))));

    BEGIN TRY
        IF @tc = 0
            BEGIN TRAN;

        IF @IdaraID_BIGINT IS NULL
        BEGIN
            ;THROW 50001, N'الإدارة مطلوبة', 1;
        END

        IF @Action = N'RAISEMAINTENANCEDISPUTE'
        BEGIN
            IF @RequestID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'طلب الصيانة مطلوب', 1;
            END

            IF NULLIF(LTRIM(RTRIM(ISNULL(@Reason, N''))), N'') IS NULL
            BEGIN
                ;THROW 50001, N'سبب النزاع مطلوب', 1;
            END

            SELECT
                  @CurrentStatusID = request.[StatusID]
                , @CurrentStatusCode = status.[StatusCode]
                , @CurrentDSDID = request.[CurrentDSDID]
            FROM [Maintenance].[BuildingMaintenanceRequest] AS request WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN [Maintenance].[MaintenanceRequestStatus] AS status
                ON status.[StatusID] = request.[StatusID]
            WHERE request.[RequestID] = @RequestID_BIGINT
              AND request.[IdaraId_FK] = @IdaraID_BIGINT
              AND request.[IsActive] = 1;

            IF @CurrentStatusID IS NULL
            BEGIN
                ;THROW 50001, N'طلب الصيانة غير موجود أو غير نشط', 1;
            END

            IF ISNULL(@CurrentStatusCode, N'') IN (N'CLOSED', N'CANCELLED')
            BEGIN
                ;THROW 50001, N'لا يمكن تسجيل نزاع على طلب مغلق أو ملغي', 1;
            END

            IF EXISTS
            (
                SELECT 1
                FROM [Maintenance].[BuildingMaintenanceRequestDispute]
                WHERE [RequestID] = @RequestID_BIGINT
                  AND [IsActive] = 1
                  AND [DecisionDate] IS NULL
            )
            BEGIN
                ;THROW 50001, N'يوجد نزاع نشط مفتوح لنفس الطلب', 1;
            END

            SELECT @NewStatusID = [StatusID]
            FROM [Maintenance].[MaintenanceRequestStatus]
            WHERE [StatusCode] = N'DISPUTE'
              AND [IsActive] = 1;

            SELECT @ActionTypeID = [ActionTypeID]
            FROM [Maintenance].[MaintenanceActionType]
            WHERE [ActionTypeCode] = N'RAISE_DISPUTE'
              AND [IsActive] = 1;

            IF @NewStatusID IS NULL OR @ActionTypeID IS NULL
            BEGIN
                ;THROW 50002, N'تعريفات النزاع غير مكتملة', 1;
            END

            INSERT INTO [Maintenance].[BuildingMaintenanceRequestDispute]
            (
                  [RequestID]
                , [RaisedByDSDID]
                , [AgainstDSDID]
                , [RaisedByUserID]
                , [Reason]
                , [DisputeStatusID]
                , [entryUser]
                , [IdaraId_FK]
                , [entryData]
                , [hostName]
            )
            VALUES
            (
                  @RequestID_BIGINT
                , @CurrentDSDID
                , @AgainstDSDID_BIGINT
                , @EntryUser_BIGINT
                , @Reason
                , @NewStatusID
                , @EntryUser_BIGINT
                , @IdaraID_BIGINT
                , @entryData
                , @hostName
            );

            SET @NewID = SCOPE_IDENTITY();
            IF @NewID IS NULL OR @NewID <= 0
            BEGIN
                ;THROW 50002, N'حصل خطأ أثناء تسجيل النزاع - Identity', 1;
            END

            UPDATE [Maintenance].[BuildingMaintenanceRequest]
            SET
                  [HasDispute] = 1
                , [DisputeStatusID] = @NewStatusID
                , [StatusID] = @NewStatusID
                , [updateUser] = @EntryUser_BIGINT
                , [updateDate] = GETDATE()
                , [entryData] = ISNULL(ISNULL([entryData], N'') + N',' + @entryData, [entryData])
                , [hostName] = ISNULL(ISNULL([hostName], N'') + N',' + @hostName, [hostName])
            WHERE [RequestID] = @RequestID_BIGINT
              AND [IdaraId_FK] = @IdaraID_BIGINT
              AND [IsActive] = 1;

            INSERT INTO [Maintenance].[BuildingMaintenanceRequestAction]
            ([RequestID], [ActionTypeID], [FromDSDID], [ToDSDID], [FromUserID], [OldStatusID], [NewStatusID], [ActionNote], [ActionDate], [entryUser], [IdaraId_FK], [entryData], [hostName])
            VALUES
            (@RequestID_BIGINT, @ActionTypeID, @CurrentDSDID, @AgainstDSDID_BIGINT, @EntryUser_BIGINT, @CurrentStatusID, @NewStatusID, @Reason, GETDATE(), @EntryUser_BIGINT, @IdaraID_BIGINT, @entryData, @hostName);

            SET @Message = N'تم تسجيل نزاع الاختصاص بنجاح';
            SET @Note = N'{"RequestID":"' + CONVERT(NVARCHAR(30), @RequestID_BIGINT) + N'","DisputeID":"' + CONVERT(NVARCHAR(30), @NewID) + N'"}';
        END
        ELSE IF @Action = N'DECIDEMAINTENANCEDISPUTE'
        BEGIN
            IF @DisputeID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'النزاع مطلوب', 1;
            END

            IF @DecisionDSDID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'جهة القرار مطلوبة', 1;
            END

            IF NULLIF(LTRIM(RTRIM(ISNULL(@DecisionNote, N''))), N'') IS NULL
            BEGIN
                ;THROW 50001, N'قرار التحكيم مطلوب', 1;
            END

            SELECT
                  @RequestID_BIGINT = dispute.[RequestID]
                , @CurrentStatusID = request.[StatusID]
                , @CurrentDSDID = request.[CurrentDSDID]
            FROM [Maintenance].[BuildingMaintenanceRequestDispute] AS dispute WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN [Maintenance].[BuildingMaintenanceRequest] AS request
                ON request.[RequestID] = dispute.[RequestID]
            WHERE dispute.[DisputeID] = @DisputeID_BIGINT
              AND (dispute.[IdaraId_FK] = @IdaraID_BIGINT OR dispute.[IdaraId_FK] IS NULL)
              AND dispute.[IsActive] = 1
              AND dispute.[DecisionDate] IS NULL;

            IF @RequestID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'النزاع غير موجود أو غير نشط', 1;
            END

            SELECT @NewStatusID = [StatusID]
            FROM [Maintenance].[MaintenanceRequestStatus]
            WHERE [StatusCode] = N'UNDER_INSPECTION'
              AND [IsActive] = 1;

            SELECT @ActionTypeID = [ActionTypeID]
            FROM [Maintenance].[MaintenanceActionType]
            WHERE [ActionTypeCode] = N'ARBITRATION_DECISION'
              AND [IsActive] = 1;

            IF @NewStatusID IS NULL OR @ActionTypeID IS NULL
            BEGIN
                ;THROW 50002, N'تعريفات قرار التحكيم غير مكتملة', 1;
            END

            UPDATE [Maintenance].[BuildingMaintenanceRequestDispute]
            SET
                  [ArbitrationDSDID] = @DecisionDSDID_BIGINT
                , [DecisionByUserID] = @EntryUser_BIGINT
                , [DecisionNote] = @DecisionNote
                , [IsBindingDecision] = 1
                , [DecisionDate] = GETDATE()
                , [DisputeStatusID] = @NewStatusID
                , [updateUser] = @EntryUser_BIGINT
                , [updateDate] = GETDATE()
                , [entryData] = ISNULL(ISNULL([entryData], N'') + N',' + @entryData, [entryData])
                , [hostName] = ISNULL(ISNULL([hostName], N'') + N',' + @hostName, [hostName])
            WHERE [DisputeID] = @DisputeID_BIGINT;

            UPDATE [Maintenance].[BuildingMaintenanceRequest]
            SET
                  [CurrentDSDID] = @DecisionDSDID_BIGINT
                , [HasDispute] = 0
                , [StatusID] = @NewStatusID
                , [IsLockedByDecision] = 1
                , [EscalationLevel] = ISNULL([EscalationLevel], 0) + 1
                , [updateUser] = @EntryUser_BIGINT
                , [updateDate] = GETDATE()
                , [entryData] = ISNULL(ISNULL([entryData], N'') + N',' + @entryData, [entryData])
                , [hostName] = ISNULL(ISNULL([hostName], N'') + N',' + @hostName, [hostName])
            WHERE [RequestID] = @RequestID_BIGINT
              AND [IdaraId_FK] = @IdaraID_BIGINT
              AND [IsActive] = 1;

            INSERT INTO [Maintenance].[BuildingMaintenanceRequestAction]
            ([RequestID], [ActionTypeID], [FromDSDID], [ToDSDID], [FromUserID], [OldStatusID], [NewStatusID], [ActionNote], [ActionDate], [entryUser], [IdaraId_FK], [entryData], [hostName])
            VALUES
            (@RequestID_BIGINT, @ActionTypeID, @CurrentDSDID, @DecisionDSDID_BIGINT, @EntryUser_BIGINT, @CurrentStatusID, @NewStatusID, @DecisionNote, GETDATE(), @EntryUser_BIGINT, @IdaraID_BIGINT, @entryData, @hostName);

            SET @NewID = @DisputeID_BIGINT;
            SET @Message = N'تم تسجيل قرار التحكيم بنجاح';
            SET @Note = N'{"DisputeID":"' + CONVERT(NVARCHAR(30), @DisputeID_BIGINT) + N'","RequestID":"' + CONVERT(NVARCHAR(30), @RequestID_BIGINT) + N'"}';
        END
        ELSE IF @Action = N'CLOSEMAINTENANCEDISPUTE'
        BEGIN
            IF @DisputeID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'النزاع مطلوب', 1;
            END

            UPDATE [Maintenance].[BuildingMaintenanceRequestDispute]
            SET
                  [IsActive] = 0
                , [DecisionDate] = ISNULL([DecisionDate], GETDATE())
                , [updateUser] = @EntryUser_BIGINT
                , [updateDate] = GETDATE()
                , [entryData] = ISNULL(ISNULL([entryData], N'') + N',' + @entryData, [entryData])
                , [hostName] = ISNULL(ISNULL([hostName], N'') + N',' + @hostName, [hostName])
            WHERE [DisputeID] = @DisputeID_BIGINT
              AND ([IdaraId_FK] = @IdaraID_BIGINT OR [IdaraId_FK] IS NULL)
              AND [IsActive] = 1;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50001, N'النزاع غير موجود أو مغلق مسبقاً', 1;
            END

            SET @NewID = @DisputeID_BIGINT;
            SET @Message = N'تم إغلاق النزاع بنجاح';
            SET @Note = N'{"DisputeID":"' + CONVERT(NVARCHAR(30), @DisputeID_BIGINT) + N'"}';
        END
        ELSE
        BEGIN
            ;THROW 50001, N'نوع العملية غير معروف', 1;
        END

        INSERT INTO [dbo].[AuditLog] ([TableName], [ActionType], [RecordID], [PerformedBy], [Notes])
        VALUES (N'[Maintenance].[BuildingMaintenanceRequestDispute]', @Action, ISNULL(@NewID, 0), @entryData, @Note);

        IF @tc = 0
            COMMIT;

        SELECT 1 AS [IsSuccessful], @Message AS [Message_];
        RETURN;
    END TRY
    BEGIN CATCH
        IF @tc = 0 AND XACT_STATE() <> 0
            ROLLBACK;

        ;THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE [Maintenance].[MaintenanceDashboardDL]
      @pageName_ NVARCHAR(400)
    , @idaraID INT
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [StatusID], [StatusName_A], [StatusCode], COUNT(1) AS [RequestsCount]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
    GROUP BY [StatusID], [StatusName_A], [StatusCode]
    ORDER BY [StatusName_A];

    SELECT COUNT(1) AS [OpenRequestsCount]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
      AND ISNULL([StatusCode], N'') NOT IN (N'CLOSED', N'CANCELLED', N'COMPLETED');

    SELECT COUNT(1) AS [ClosedRequestsCount]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
      AND ISNULL([StatusCode], N'') IN (N'CLOSED', N'COMPLETED');

    SELECT COUNT(1) AS [LateRequestsCount]
    FROM [Maintenance].[V_BuildingMaintenanceRequestSLAStatus]
    WHERE [IdaraId] = @idaraID
      AND [IsAnyLate] = 1;

    SELECT [MaintenanceCategoryID], [MaintenanceCategoryFullPath_A], COUNT(1) AS [RequestsCount]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
    GROUP BY [MaintenanceCategoryID], [MaintenanceCategoryFullPath_A]
    ORDER BY [RequestsCount] DESC, [MaintenanceCategoryFullPath_A];

    SELECT [CurrentDSDID], COUNT(1) AS [RequestsCount]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
    GROUP BY [CurrentDSDID]
    ORDER BY [RequestsCount] DESC, [CurrentDSDID];

    SELECT [PriorityID], [PriorityName_A], [PriorityCode], COUNT(1) AS [RequestsCount]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
    GROUP BY [PriorityID], [PriorityName_A], [PriorityCode]
    ORDER BY [RequestsCount] DESC, [PriorityName_A];

    SELECT TOP (20)
          [RequestID]
        , [RequestNo]
        , [RequestDate]
        , [MaintenanceCategoryFullPath_A]
        , [StatusName_A]
        , [StatusCode]
        , [PriorityName_A]
        , [CurrentDSDID]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
    ORDER BY [RequestDate] DESC, [RequestID] DESC;

    SELECT TOP (20) [MaintenanceCategoryID], [MaintenanceCategoryFullPath_A], COUNT(1) AS [RequestsCount]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
    GROUP BY [MaintenanceCategoryID], [MaintenanceCategoryFullPath_A]
    ORDER BY [RequestsCount] DESC, [MaintenanceCategoryFullPath_A];

    SELECT COUNT(1) AS [OpenDisputesCount]
    FROM [Maintenance].[BuildingMaintenanceRequestDispute] AS dispute
    INNER JOIN [Maintenance].[BuildingMaintenanceRequest] AS request
        ON request.[RequestID] = dispute.[RequestID]
    WHERE request.[IdaraId_FK] = @idaraID
      AND dispute.[IsActive] = 1
      AND dispute.[DecisionDate] IS NULL;

    SELECT COUNT(1) AS [WaitingApprovalRequestsCount]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
      AND [StatusCode] = N'WAITING_APPROVAL';

    SELECT COUNT(1) AS [OpenSubRequestsCount]
    FROM [Maintenance].[V_BuildingMaintenanceRequestList]
    WHERE [IdaraId] = @idaraID
      AND [IsActive] = 1
      AND [IsSubRequest] = 1
      AND ISNULL([StatusCode], N'') NOT IN (N'CLOSED', N'CANCELLED', N'COMPLETED');
END;
GO

CREATE OR ALTER PROCEDURE [Maintenance].[MaintenanceDashboardSP]
      @Action NVARCHAR(200)
    , @idaraID_FK NVARCHAR(10) = NULL
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    ;THROW 50001, N'لا توجد عمليات حفظ في لوحة مؤشرات الصيانة حالياً', 1;
END;
GO
