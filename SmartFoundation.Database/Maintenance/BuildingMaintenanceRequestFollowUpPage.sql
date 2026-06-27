USE [DATACORE]
GO

CREATE OR ALTER PROCEDURE [Maintenance].[BuildingMaintenanceRequestFollowUpSP]
      @Action NVARCHAR(200)
    , @RequestID NVARCHAR(100) = NULL
    , @AssignedToUserID NVARCHAR(100) = NULL
    , @AssignmentID NVARCHAR(100) = NULL
    , @ReportText NVARCHAR(MAX) = NULL
    , @ReasonID NVARCHAR(100) = NULL
    , @NeedsApproval NVARCHAR(20) = NULL
    , @NeedsSubRequest NVARCHAR(20) = NULL
    , @Notes NVARCHAR(MAX) = NULL
    , @idaraID_FK NVARCHAR(10) = NULL
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    ----------------------------------------------------------------
    --                    BuildingMaintenanceRequestFollowUp
    ----------------------------------------------------------------

    DECLARE @tc INT = @@TRANCOUNT;

    DECLARE
          @NewID BIGINT = NULL
        , @Note NVARCHAR(MAX) = NULL
        , @IdaraID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@idaraID_FK)), N''))
        , @RequestID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@RequestID)), N''))
        , @AssignedToUserID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@AssignedToUserID)), N''))
        , @AssignmentID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@AssignmentID)), N''))
        , @ReasonID_INT INT = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(@ReasonID)), N''))
        , @NeedsApproval_BIT BIT = CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(@NeedsApproval, N'')))) IN (N'1', N'TRUE', N'YES', N'ON') THEN 1 ELSE 0 END
        , @NeedsSubRequest_BIT BIT = CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(@NeedsSubRequest, N'')))) IN (N'1', N'TRUE', N'YES', N'ON') THEN 1 ELSE 0 END
        , @EntryUser_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@entryData)), N''))
        , @CurrentStatusID INT = NULL
        , @CurrentStatusCode NVARCHAR(100) = NULL
        , @NewStatusID INT = NULL
        , @ActionTypeID INT = NULL
        , @CurrentDSDID BIGINT = NULL
        , @LastActionTypeCode NVARCHAR(100) = NULL
        , @LastInspectionActionID BIGINT = NULL
        , @LastInspectionActionDate DATETIME = NULL
        , @SuccessMessage NVARCHAR(4000) = N'تم تنفيذ الإجراء بنجاح'
        , @ReasonCode NVARCHAR(100) = NULL;

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
            ;THROW 50001, N'رقم الطلب مطلوب', 1;
        END

        SELECT
              @CurrentStatusID = request.StatusID
            , @CurrentStatusCode = status.StatusCode
            , @CurrentDSDID = request.CurrentDSDID
        FROM Maintenance.BuildingMaintenanceRequest AS request
        INNER JOIN Maintenance.MaintenanceRequestStatus AS status
            ON status.StatusID = request.StatusID
        WHERE request.RequestID = @RequestID_BIGINT
          AND request.IdaraId_FK = @IdaraID_BIGINT
          AND request.IsActive = 1;

        IF @CurrentStatusID IS NULL
        BEGIN
            ;THROW 50001, N'طلب الصيانة غير موجود', 1;
        END

        IF ISNULL(@CurrentStatusCode, N'') IN (N'CLOSED', N'CANCELLED')
        BEGIN
            ;THROW 50001, N'لا يمكن تنفيذ إجراء على طلب مغلق أو ملغي', 1;
        END

        SELECT TOP 1
              @LastActionTypeCode = actionType.ActionTypeCode
        FROM Maintenance.BuildingMaintenanceRequestAction AS action
        INNER JOIN Maintenance.MaintenanceActionType AS actionType
            ON actionType.ActionTypeID = action.ActionTypeID
        WHERE action.RequestID = @RequestID_BIGINT
          AND action.IdaraId_FK = @IdaraID_BIGINT
          AND action.IsActive = 1
        ORDER BY action.ActionDate DESC, action.ActionID DESC;

        SELECT TOP 1
              @LastInspectionActionID = action.ActionID
            , @LastInspectionActionDate = action.ActionDate
        FROM Maintenance.BuildingMaintenanceRequestAction AS action
        INNER JOIN Maintenance.MaintenanceActionType AS actionType
            ON actionType.ActionTypeID = action.ActionTypeID
        WHERE action.RequestID = @RequestID_BIGINT
          AND action.IdaraId_FK = @IdaraID_BIGINT
          AND action.IsActive = 1
          AND actionType.ActionTypeCode = N'INSPECTION_REPORT'
        ORDER BY action.ActionDate DESC, action.ActionID DESC;

        SELECT TOP 1 @ActionTypeID = ActionTypeID
        FROM Maintenance.MaintenanceActionType
        WHERE ActionTypeCode =
            CASE @Action
                WHEN N'ASSIGNMAINTENANCETECHNICIAN' THEN N'ASSIGN_TECHNICIAN'
                WHEN N'ADDINSPECTIONREPORT' THEN N'INSPECTION_REPORT'
                WHEN N'STARTMAINTENANCEWORK' THEN N'START_WORK'
                WHEN N'COMPLETEMAINTENANCEWORK' THEN N'COMPLETE_WORK'
                WHEN N'CLOSEMAINTENANCEREQUEST' THEN N'CLOSE'
                ELSE N''
            END
          AND IsActive = 1
          AND (IdaraId_FK IS NULL OR IdaraId_FK = @IdaraID_BIGINT)
        ORDER BY CASE WHEN IdaraId_FK = @IdaraID_BIGINT THEN 0 ELSE 1 END, ActionTypeID;

        IF @ActionTypeID IS NULL
        BEGIN
            ;THROW 50001, N'نوع الإجراء غير معرف', 1;
        END

        IF @Action = N'ASSIGNMAINTENANCETECHNICIAN'
        BEGIN
            IF ISNULL(@CurrentStatusCode, N'') = N'COMPLETED'
            BEGIN
                ;THROW 50001, N'لا يمكن تنفيذ إجراء على طلب مغلق أو ملغي', 1;
            END

            IF @AssignedToUserID_BIGINT IS NULL
            BEGIN
                ;THROW 50001, N'الفني مطلوب', 1;
            END

            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.V_GetFullSystemUsersDetails
                WHERE usersID = @AssignedToUserID_BIGINT
                  AND userActive = 1
                  AND (IdaraID IS NULL OR IdaraID = @IdaraID_BIGINT)
            )
            BEGIN
                ;THROW 50001, N'الفني غير موجود أو غير فعال', 1;
            END

            IF EXISTS
            (
                SELECT 1
                FROM Maintenance.BuildingMaintenanceRequestAssignment
                WHERE RequestID = @RequestID_BIGINT
                  AND AssignedToUserID = @AssignedToUserID_BIGINT
                  AND IdaraId_FK = @IdaraID_BIGINT
                  AND IsActive = 1
            )
            BEGIN
                ;THROW 50001, N'تم إسناد هذا الفني مسبقاً لنفس الطلب', 1;
            END

            IF ISNULL(@CurrentStatusCode, N'') = N'NEW'
            BEGIN
                SELECT TOP 1 @NewStatusID = StatusID
                FROM Maintenance.MaintenanceRequestStatus
                WHERE StatusCode = N'UNDER_INSPECTION'
                  AND IsActive = 1
                  AND (IdaraId_FK IS NULL OR IdaraId_FK = @IdaraID_BIGINT)
                ORDER BY CASE WHEN IdaraId_FK = @IdaraID_BIGINT THEN 0 ELSE 1 END, StatusID;

                IF @NewStatusID IS NULL
                BEGIN
                    ;THROW 50002, N'حالة UNDER_INSPECTION غير معرفة', 1;
                END
            END
            ELSE
            BEGIN
                SET @NewStatusID = @CurrentStatusID;
            END

            INSERT INTO Maintenance.BuildingMaintenanceRequestAssignment
            (
                  RequestID
                , AssignedToUserID
                , AssignedByUserID
                , AssignedDSDID
                , AssignedDate
                , NeedsApproval
                , NeedsSubRequest
                , entryUser
                , IdaraId_FK
                , entryData
                , hostName
            )
            VALUES
            (
                  @RequestID_BIGINT
                , @AssignedToUserID_BIGINT
                , @EntryUser_BIGINT
                , @CurrentDSDID
                , GETDATE()
                , 0
                , 0
                , @EntryUser_BIGINT
                , @IdaraID_BIGINT
                , @entryData
                , @hostName
            );

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ أثناء إسناد الفني', 1;
            END

            SET @NewID = SCOPE_IDENTITY();

            IF ISNULL(@CurrentStatusCode, N'') = N'NEW'
            BEGIN
                UPDATE Maintenance.BuildingMaintenanceRequest
                SET
                      StatusID = @NewStatusID
                    , updateUser = @EntryUser_BIGINT
                    , updateDate = GETDATE()
                    , entryData = ISNULL(ISNULL(entryData, N'') + N',' + @entryData, entryData)
                    , hostName = ISNULL(ISNULL(@hostName, N'') + N',' + @hostName, hostName)
                WHERE RequestID = @RequestID_BIGINT
                  AND IdaraId_FK = @IdaraID_BIGINT
                  AND IsActive = 1;

                IF @@ROWCOUNT = 0
                BEGIN
                    ;THROW 50002, N'حصل خطأ أثناء تحديث حالة الطلب', 1;
                END
            END

            INSERT INTO Maintenance.BuildingMaintenanceRequestAction
            (
                  RequestID
                , ActionTypeID
                , FromDSDID
                , ToDSDID
                , FromUserID
                , ToUserID
                , OldStatusID
                , NewStatusID
                , ActionNote
                , ActionDate
                , entryUser
                , IdaraId_FK
                , entryData
                , hostName
            )
            VALUES
            (
                  @RequestID_BIGINT
                , @ActionTypeID
                , @CurrentDSDID
                , @CurrentDSDID
                , @EntryUser_BIGINT
                , @AssignedToUserID_BIGINT
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
                ;THROW 50002, N'حصل خطأ أثناء تسجيل حركة الإسناد', 1;
            END

            SET @Note = N'{"RequestID":"' + ISNULL(CONVERT(NVARCHAR(MAX), @RequestID_BIGINT), N'') + N'","AssignmentID":"' + ISNULL(CONVERT(NVARCHAR(MAX), @NewID), N'') + N'"}';
            SET @SuccessMessage = N'تم إسناد الفني للطلب بنجاح';
        END

        ELSE IF @Action = N'ADDINSPECTIONREPORT'
        BEGIN
            IF ISNULL(@CurrentStatusCode, N'') <> N'UNDER_INSPECTION'
            BEGIN
                ;THROW 50001, N'لا يمكن تسجيل تقرير المعاينة قبل إسناد فني للطلب', 1;
            END

            IF NOT EXISTS
            (
                SELECT 1
                FROM Maintenance.BuildingMaintenanceRequestAssignment
                WHERE RequestID = @RequestID_BIGINT
                  AND IdaraId_FK = @IdaraID_BIGINT
                  AND IsActive = 1
            )
            BEGIN
                ;THROW 50001, N'لا يمكن تسجيل تقرير المعاينة قبل إسناد فني للطلب', 1;
            END

            IF @ReasonID_INT IS NULL
            BEGIN
                ;THROW 50001, N'سبب تقرير المعاينة مطلوب', 1;
            END

            IF NULLIF(LTRIM(RTRIM(@ReportText)), N'') IS NULL
            BEGIN
                ;THROW 50001, N'تقرير المعاينة مطلوب', 1;
            END

            SELECT TOP 1 @ReasonCode = ReasonCode
            FROM Maintenance.MaintenanceActionReason
            WHERE ReasonID = @ReasonID_INT
              AND IsActive = 1
              AND (IdaraId_FK IS NULL OR IdaraId_FK = @IdaraID_BIGINT)
            ORDER BY CASE WHEN IdaraId_FK = @IdaraID_BIGINT THEN 0 ELSE 1 END, ReasonID;

            IF @ReasonCode IS NULL
            BEGIN
                ;THROW 50001, N'سبب تقرير المعاينة غير موجود أو غير فعال', 1;
            END

            SET @NeedsApproval_BIT = CASE WHEN @ReasonCode = N'NEEDS_APPROVAL' THEN 1 ELSE 0 END;
            SET @NeedsSubRequest_BIT = CASE WHEN @ReasonCode = N'NEEDS_SUB_REQUEST' THEN 1 ELSE 0 END;
            SET @NewStatusID = @CurrentStatusID;

            UPDATE Maintenance.BuildingMaintenanceRequestAssignment
            SET
                  InspectionDate = GETDATE()
                , ReportText = @ReportText
                , NeedsApproval = @NeedsApproval_BIT
                , NeedsSubRequest = @NeedsSubRequest_BIT
                , updateUser = @EntryUser_BIGINT
                , updateDate = GETDATE()
                , entryData = ISNULL(ISNULL(entryData, N'') + N',' + @entryData, entryData)
                , hostName = ISNULL(ISNULL(@hostName, N'') + N',' + @hostName, hostName)
            WHERE RequestID = @RequestID_BIGINT
              AND IdaraId_FK = @IdaraID_BIGINT
              AND IsActive = 1;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ أثناء تحديث تقرير المعاينة', 1;
            END

            UPDATE Maintenance.BuildingMaintenanceRequest
            SET
                  StatusID = @NewStatusID
                , updateUser = @EntryUser_BIGINT
                , updateDate = GETDATE()
                , entryData = ISNULL(ISNULL(entryData, N'') + N',' + @entryData, entryData)
                , hostName = ISNULL(ISNULL(@hostName, N'') + N',' + @hostName, hostName)
            WHERE RequestID = @RequestID_BIGINT
              AND IdaraId_FK = @IdaraID_BIGINT
              AND IsActive = 1;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ أثناء تحديث حالة الطلب', 1;
            END

            INSERT INTO Maintenance.BuildingMaintenanceRequestAction
            (
                  RequestID
                , ActionTypeID
                , ReasonID
                , FromDSDID
                , ToDSDID
                , FromUserID
                , OldStatusID
                , NewStatusID
                , ActionNote
                , ActionDate
                , entryUser
                , IdaraId_FK
                , entryData
                , hostName
            )
            VALUES
            (
                  @RequestID_BIGINT
                , @ActionTypeID
                , @ReasonID_INT
                , @CurrentDSDID
                , @CurrentDSDID
                , @EntryUser_BIGINT
                , @CurrentStatusID
                , @NewStatusID
                , @ReportText
                , GETDATE()
                , @EntryUser_BIGINT
                , @IdaraID_BIGINT
                , @entryData
                , @hostName
            );

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ أثناء تسجيل حركة المعاينة', 1;
            END

            SET @NewID = @RequestID_BIGINT;
            SET @Note = N'{"RequestID":"' + ISNULL(CONVERT(NVARCHAR(MAX), @RequestID_BIGINT), N'')
                + N'","ReasonID":"' + ISNULL(CONVERT(NVARCHAR(MAX), @ReasonID_INT), N'')
                + N'","ReasonCode":"' + ISNULL(CONVERT(NVARCHAR(MAX), @ReasonCode), N'') + N'"}';
        END

        ELSE IF @Action IN (N'STARTMAINTENANCEWORK', N'COMPLETEMAINTENANCEWORK', N'CLOSEMAINTENANCEREQUEST')
        BEGIN
            IF @Action = N'STARTMAINTENANCEWORK'
            BEGIN
                IF ISNULL(@LastActionTypeCode, N'') <> N'INSPECTION_REPORT'
                BEGIN
                    ;THROW 50001, N'لا يمكن بدء التنفيذ قبل تسجيل تقرير المعاينة', 1;
                END

                IF ISNULL(@CurrentStatusCode, N'') IN (N'CLOSED', N'CANCELLED', N'COMPLETED')
                BEGIN
                    ;THROW 50001, N'لا يمكن بدء التنفيذ قبل تسجيل تقرير المعاينة', 1;
                END
            END

            IF @Action = N'COMPLETEMAINTENANCEWORK'
            BEGIN
                IF ISNULL(@CurrentStatusCode, N'') <> N'IN_PROGRESS'
                BEGIN
                    ;THROW 50001, N'لا يمكن إنهاء التنفيذ قبل بدء العمل', 1;
                END

                IF NOT EXISTS
                (
                    SELECT 1
                    FROM Maintenance.BuildingMaintenanceRequestAction AS action
                    INNER JOIN Maintenance.MaintenanceActionType AS actionType
                        ON actionType.ActionTypeID = action.ActionTypeID
                    WHERE action.RequestID = @RequestID_BIGINT
                      AND action.IdaraId_FK = @IdaraID_BIGINT
                      AND action.IsActive = 1
                      AND actionType.ActionTypeCode = N'START_WORK'
                )
                BEGIN
                    ;THROW 50001, N'لا يمكن إنهاء التنفيذ قبل بدء العمل', 1;
                END
            END

            IF @Action = N'CLOSEMAINTENANCEREQUEST'
            BEGIN
                IF @LastInspectionActionID IS NULL
                BEGIN
                    ;THROW 50001, N'لا يمكن إغلاق الطلب قبل تسجيل تقرير المعاينة', 1;
                END

                IF ISNULL(@CurrentStatusCode, N'') = N'COMPLETED'
                   AND NOT EXISTS
                   (
                       SELECT 1
                       FROM Maintenance.BuildingMaintenanceRequestAction AS action
                       INNER JOIN Maintenance.MaintenanceActionType AS actionType
                           ON actionType.ActionTypeID = action.ActionTypeID
                       WHERE action.RequestID = @RequestID_BIGINT
                         AND action.IdaraId_FK = @IdaraID_BIGINT
                         AND action.IsActive = 1
                         AND actionType.ActionTypeCode = N'COMPLETE_WORK'
                   )
                BEGIN
                    ;THROW 50001, N'لا يمكن إغلاق الطلب قبل تسجيل تقرير المعاينة', 1;
                END

                IF ISNULL(@CurrentStatusCode, N'') <> N'COMPLETED'
                   AND
                   (
                       ISNULL(@LastActionTypeCode, N'') <> N'INSPECTION_REPORT'
                       OR EXISTS
                       (
                           SELECT 1
                           FROM Maintenance.BuildingMaintenanceRequestAction AS action
                           INNER JOIN Maintenance.MaintenanceActionType AS actionType
                               ON actionType.ActionTypeID = action.ActionTypeID
                           WHERE action.RequestID = @RequestID_BIGINT
                             AND action.IdaraId_FK = @IdaraID_BIGINT
                             AND action.IsActive = 1
                             AND action.ActionDate >= @LastInspectionActionDate
                             AND action.ActionID > @LastInspectionActionID
                             AND actionType.ActionTypeCode IN (N'START_WORK', N'COMPLETE_WORK')
                       )
                   )
                BEGIN
                    ;THROW 50001, N'لا يمكن إغلاق الطلب قبل تسجيل تقرير المعاينة', 1;
                END
            END

            IF @Action = N'STARTMAINTENANCEWORK' AND ISNULL(@CurrentStatusCode, N'') IN (N'COMPLETED')
            BEGIN
                ;THROW 50001, N'لا يمكن بدء تنفيذ طلب مكتمل', 1;
            END

            IF @Action = N'CLOSEMAINTENANCEREQUEST'
               AND ISNULL(@CurrentStatusCode, N'') <> N'COMPLETED'
               AND ISNULL(@LastActionTypeCode, N'') <> N'INSPECTION_REPORT'
            BEGIN
                ;THROW 50001, N'لا يمكن إغلاق الطلب إلا بعد اكتماله', 1;
            END

            SELECT TOP 1 @NewStatusID = StatusID
            FROM Maintenance.MaintenanceRequestStatus
            WHERE StatusCode =
                CASE @Action
                    WHEN N'STARTMAINTENANCEWORK' THEN N'IN_PROGRESS'
                    WHEN N'COMPLETEMAINTENANCEWORK' THEN N'COMPLETED'
                    WHEN N'CLOSEMAINTENANCEREQUEST' THEN N'CLOSED'
                END
              AND IsActive = 1
              AND (IdaraId_FK IS NULL OR IdaraId_FK = @IdaraID_BIGINT)
            ORDER BY CASE WHEN IdaraId_FK = @IdaraID_BIGINT THEN 0 ELSE 1 END, StatusID;

            IF @NewStatusID IS NULL
            BEGIN
                ;THROW 50002, N'حالة الطلب المطلوبة غير معرفة', 1;
            END

            UPDATE Maintenance.BuildingMaintenanceRequest
            SET
                  StatusID = @NewStatusID
                , ClosedDate = CASE WHEN @Action = N'CLOSEMAINTENANCEREQUEST' THEN GETDATE() ELSE ClosedDate END
                , updateUser = @EntryUser_BIGINT
                , updateDate = GETDATE()
                , entryData = ISNULL(ISNULL(entryData, N'') + N',' + @entryData, entryData)
                , hostName = ISNULL(ISNULL(@hostName, N'') + N',' + @hostName, hostName)
            WHERE RequestID = @RequestID_BIGINT
              AND IdaraId_FK = @IdaraID_BIGINT
              AND IsActive = 1;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ أثناء تحديث حالة الطلب', 1;
            END

            IF @Action = N'COMPLETEMAINTENANCEWORK'
            BEGIN
                UPDATE Maintenance.BuildingMaintenanceRequestAssignment
                SET
                      CompletionDate = ISNULL(CompletionDate, GETDATE())
                    , updateUser = @EntryUser_BIGINT
                    , updateDate = GETDATE()
                    , entryData = ISNULL(ISNULL(entryData, N'') + N',' + @entryData, entryData)
                    , hostName = ISNULL(ISNULL(@hostName, N'') + N',' + @hostName, hostName)
                WHERE RequestID = @RequestID_BIGINT
                  AND IdaraId_FK = @IdaraID_BIGINT
                  AND IsActive = 1;
            END

            INSERT INTO Maintenance.BuildingMaintenanceRequestAction
            (
                  RequestID
                , ActionTypeID
                , FromDSDID
                , ToDSDID
                , FromUserID
                , OldStatusID
                , NewStatusID
                , ActionNote
                , ActionDate
                , entryUser
                , IdaraId_FK
                , entryData
                , hostName
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
                ;THROW 50002, N'حصل خطأ أثناء تسجيل حركة الطلب', 1;
            END

            SET @NewID = @RequestID_BIGINT;
            SET @Note = N'{"RequestID":"' + ISNULL(CONVERT(NVARCHAR(MAX), @RequestID_BIGINT), N'') + N'","Action":"' + ISNULL(CONVERT(NVARCHAR(MAX), @Action), N'') + N'"}';
        END

        ELSE
        BEGIN
            ;THROW 50001, N'العملية غير مسجلة', 1;
        END

        INSERT INTO dbo.AuditLog
        (
              TableName
            , ActionType
            , RecordID
            , PerformedBy
            , Notes
        )
        VALUES
        (
              N'[Maintenance].[BuildingMaintenanceRequestFollowUp]'
            , @Action
            , ISNULL(@NewID, @RequestID_BIGINT)
            , @entryData
            , @Note
        );

        IF @tc = 0
            COMMIT;

        SELECT 1 AS IsSuccessful, @SuccessMessage AS Message_;
        RETURN;
    END TRY
    BEGIN CATCH
        IF @tc = 0 AND XACT_STATE() <> 0
            ROLLBACK;

        ;THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE [Maintenance].[BuildingMaintenanceRequestFollowUpDL]
      @pageName_ NVARCHAR(200) = NULL
    , @idaraID NVARCHAR(10) = NULL
    , @entryData NVARCHAR(20) = NULL
    , @hostName NVARCHAR(200) = NULL
    , @RequestID NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ----------------------------------------------------------------
    --                    BuildingMaintenanceRequestFollowUp
    ----------------------------------------------------------------

    DECLARE @IdaraID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@idaraID)), N''));
    DECLARE @RequestID_BIGINT BIGINT = TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(@RequestID)), N''));

    SELECT
          details.RequestID
        , details.RequestNo
        , details.IdaraId
        , details.RequestDate
        , details.BuildingID
        , details.ResidentID
        , details.MaintenanceCategoryID
        , details.MaintenanceCategoryName_A
        , details.MaintenanceCategoryFullPath_A
        , details.StatusID
        , details.StatusName_A
        , details.StatusCode
        , details.PriorityID
        , details.PriorityName_A
        , details.PriorityCode
        , details.CurrentDSDID
        , details.OriginalDSDID
        , details.Description_A
        , lastAction.LastActionDate
        , lastAction.LastActionTypeName_A
        , lastAction.LastActionTypeCode
        , lastAction.LastActionNote
        , CASE
            WHEN details.StatusCode = N'COMPLETED' OR lastAction.LastActionTypeCode = N'INSPECTION_REPORT'
                THEN 1
            ELSE 0
          END AS CanCloseMaintenanceRequest
        , details.ClosedDate
        , details.IsActive
    FROM Maintenance.V_BuildingMaintenanceRequestDetails AS details
    OUTER APPLY
    (
        SELECT TOP 1
              timeline.ActionDate AS LastActionDate
            , timeline.ActionTypeName_A AS LastActionTypeName_A
            , timeline.ActionTypeCode AS LastActionTypeCode
            , timeline.ActionNote AS LastActionNote
        FROM Maintenance.V_BuildingMaintenanceRequestTimeline AS timeline
        WHERE timeline.RequestID = details.RequestID
        ORDER BY timeline.ActionDate DESC, timeline.ActionID DESC
    ) AS lastAction
    WHERE details.IdaraId = @IdaraID_BIGINT
      AND details.IsActive = 1
      AND (@RequestID_BIGINT IS NULL OR details.RequestID = @RequestID_BIGINT)
      AND (@RequestID_BIGINT IS NOT NULL OR ISNULL(details.StatusCode, N'') NOT IN (N'CLOSED', N'CANCELLED'))
    ORDER BY details.RequestDate DESC, details.RequestID DESC;

    SELECT
          timeline.ActionID
        , timeline.RequestID
        , timeline.ActionDate
        , timeline.ActionTypeID
        , timeline.ActionTypeName_A
        , timeline.ActionTypeCode
        , timeline.ReasonID
        , timeline.ReasonName_A
        , timeline.FromDSDID
        , timeline.ToDSDID
        , timeline.FromUserID
        , timeline.ToUserID
        , timeline.OldStatusID
        , timeline.OldStatusName_A
        , timeline.NewStatusID
        , timeline.NewStatusName_A
        , timeline.ActionNote
        , timeline.entryUser
        , timeline.entryDate
    FROM Maintenance.V_BuildingMaintenanceRequestTimeline AS timeline
    INNER JOIN Maintenance.BuildingMaintenanceRequest AS request
        ON request.RequestID = timeline.RequestID
       AND request.IdaraId_FK = @IdaraID_BIGINT
    WHERE (@RequestID_BIGINT IS NULL OR timeline.RequestID = @RequestID_BIGINT)
    ORDER BY timeline.ActionDate DESC, timeline.ActionID DESC;

    SELECT
          assignments.AssignmentID
        , assignments.RequestID
        , assignments.AssignedToUserID
        , assignments.AssignedByUserID
        , assignments.AssignedDSDID
        , assignments.AssignedDate
        , assignments.InspectionDate
        , assignments.CompletionDate
        , assignments.AssignmentStatusID
        , assignments.NeedsApproval
        , assignments.NeedsSubRequest
        , assignments.TransactionID_FK
        , assignments.ReportText
        , assignments.IsActive
        , CONVERT(NVARCHAR(50), assignments.AssignmentID) + N' - ' + ISNULL(users.FullName, N'') AS AssignmentDisplayName
    FROM Maintenance.V_BuildingMaintenanceRequestAssignments AS assignments
    INNER JOIN Maintenance.BuildingMaintenanceRequest AS request
        ON request.RequestID = assignments.RequestID
       AND request.IdaraId_FK = @IdaraID_BIGINT
    LEFT JOIN dbo.V_GetFullSystemUsersDetails AS users
        ON users.usersID = assignments.AssignedToUserID
    WHERE assignments.IsActive = 1
      AND (@RequestID_BIGINT IS NULL OR assignments.RequestID = @RequestID_BIGINT)
    ORDER BY assignments.AssignedDate DESC, assignments.AssignmentID DESC;

    SELECT
          ReasonID
        , ReasonName_A
        , ReasonCode
        , IsActive
        , IdaraId_FK
    FROM Maintenance.MaintenanceActionReason
    WHERE IsActive = 1
      AND (IdaraId_FK IS NULL OR IdaraId_FK = @IdaraID_BIGINT)
    ORDER BY ReasonID;

    SELECT
          usersID
        , nationalID
        , GeneralNo
        , FullName
        , userActive
        , IdaraID
        , CONCAT(ISNULL(CONVERT(NVARCHAR(50), GeneralNo), N''), N' - ', ISNULL(FullName, N'')) AS UserDisplayName
    FROM dbo.V_GetFullSystemUsersDetails
    WHERE userActive = 1
      AND (IdaraID IS NULL OR IdaraID = @IdaraID_BIGINT)
    ORDER BY FullName;
END
GO

DECLARE @CrudDefinition NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.Masters_CRUD'));
DECLARE @CrudMarker NVARCHAR(MAX) = N'-- DO NOT TOUCH BELOW THIS LINE';
DECLARE @CrudPosition INT;
DECLARE @CrudBlock NVARCHAR(MAX) = N'

----------------------------------------------------------------
-- BuildingMaintenanceRequestFollowUp
----------------------------------------------------------------
ELSE IF @pageName_ = ''BuildingMaintenanceRequestFollowUp''
BEGIN
    IF (
        SELECT COUNT(*)
        FROM DATACORE.dbo.V_GetListUserPermission v
        WHERE v.userID = @entrydata
          AND v.menuName_E = @pageName_
          AND v.permissionTypeName_E = @ActionType
    ) <= 0
    BEGIN
        SET @ok = 0;
        SET @msg = N''عفوا لاتملك صلاحية لهذه العملية'';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = ''ASSIGNMAINTENANCETECHNICIAN''
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [Maintenance].[BuildingMaintenanceRequestFollowUpSP]
              @Action           = @ActionType
            , @RequestID        = @parameter_01
            , @AssignedToUserID = @parameter_02
            , @Notes            = @parameter_03
            , @idaraID_FK       = @idaraID
            , @entryData        = @entrydata
            , @hostName         = @hostName;
    END
    ELSE IF @ActionType = ''ADDINSPECTIONREPORT''
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [Maintenance].[BuildingMaintenanceRequestFollowUpSP]
              @Action          = @ActionType
            , @RequestID       = @parameter_01
            , @ReportText      = @parameter_02
            , @ReasonID        = @parameter_03
            , @idaraID_FK      = @idaraID
            , @entryData       = @entrydata
            , @hostName        = @hostName;
    END
    ELSE IF @ActionType IN (''STARTMAINTENANCEWORK'', ''COMPLETEMAINTENANCEWORK'', ''CLOSEMAINTENANCEREQUEST'')
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [Maintenance].[BuildingMaintenanceRequestFollowUpSP]
              @Action     = @ActionType
            , @RequestID  = @parameter_01
            , @Notes      = @parameter_02
            , @idaraID_FK = @idaraID
            , @entryData  = @entrydata
            , @hostName   = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N''نوع العملية المطلوبة غير معروف. ActionType'';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END
';

IF @CrudDefinition IS NOT NULL AND CHARINDEX(N'BuildingMaintenanceRequestFollowUp', @CrudDefinition) = 0
BEGIN
    SET @CrudPosition = CHARINDEX(@CrudMarker, @CrudDefinition);

    IF @CrudPosition <= 0
    BEGIN
        ;THROW 50002, N'لم يتم العثور على موضع إضافة BuildingMaintenanceRequestFollowUp في Masters_CRUD', 1;
    END

    SET @CrudDefinition = STUFF(@CrudDefinition, @CrudPosition, 0, @CrudBlock + CHAR(13) + CHAR(10));
    SET @CrudDefinition = STUFF(@CrudDefinition, 1, CHARINDEX(N'PROCEDURE', @CrudDefinition) - 1, N'CREATE OR ALTER ');
    EXEC sys.sp_executesql @CrudDefinition;
END
GO

DECLARE @DataLoadDefinition NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.Masters_DataLoad'));
DECLARE @DataLoadMarker NVARCHAR(MAX) = N'--                     PAGE NOT FOUND';
DECLARE @DataLoadPosition INT;
DECLARE @DataLoadBlock NVARCHAR(MAX) = N'

-------------------------------------------------------------------
--                    BuildingMaintenanceRequestFollowUp
-------------------------------------------------------------------
ELSE IF @pageName_ = ''BuildingMaintenanceRequestFollowUp''
BEGIN
    EXEC [Maintenance].[BuildingMaintenanceRequestFollowUpDL]
          @pageName_ = @pageName_
        , @idaraID   = @idaraID
        , @entryData = @entrydata
        , @hostName  = @hostName
        , @RequestID = @parameter_01;
END
';

IF @DataLoadDefinition IS NOT NULL AND CHARINDEX(N'BuildingMaintenanceRequestFollowUp', @DataLoadDefinition) = 0
BEGIN
    SET @DataLoadPosition = CHARINDEX(@DataLoadMarker, @DataLoadDefinition);

    IF @DataLoadPosition <= 0
    BEGIN
        ;THROW 50002, N'لم يتم العثور على موضع إضافة BuildingMaintenanceRequestFollowUp في Masters_DataLoad', 1;
    END

    SET @DataLoadDefinition = STUFF(@DataLoadDefinition, @DataLoadPosition, 0, @DataLoadBlock + CHAR(13) + CHAR(10));
    SET @DataLoadDefinition = STUFF(@DataLoadDefinition, 1, CHARINDEX(N'PROCEDURE', @DataLoadDefinition) - 1, N'CREATE OR ALTER ');
    EXEC sys.sp_executesql @DataLoadDefinition;
END
GO
