CREATE PROCEDURE [Housing].[WaitingListMoveListSP]
(
      @Action                     NVARCHAR(200)
    , @ActionID                   BIGINT         = NULL
    , @residentInfoID_FK          NVARCHAR(100)  = NULL
    , @NationalID                 NVARCHAR(100)  = NULL
    , @GeneralNo                  NVARCHAR(100)  = NULL
    , @buildingActionDecisionNo   NVARCHAR(1000) = NULL
    , @buildingActionDecisionDate NVARCHAR(1000) = NULL
    , @Notes                      NVARCHAR(1000) = NULL
    , @idaraID_FK                 NVARCHAR(10)   = NULL
    , @entryData                  NVARCHAR(20)   = NULL
    , @hostName                   NVARCHAR(200)  = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @tc INT = @@TRANCOUNT;
    DECLARE @NewID BIGINT = NULL;
    DECLARE @Note NVARCHAR(MAX) = NULL;
    DECLARE @IdaraID_INT INT = TRY_CONVERT(INT, NULLIF(@idaraID_FK, ''));

    BEGIN TRY
        IF @tc = 0
        BEGIN
            BEGIN TRANSACTION;
        END

        IF NULLIF(LTRIM(RTRIM(@Action)), N'') IS NULL
        BEGIN
            ;THROW 50001, N'العملية مطلوبة', 1;
        END

        IF @ActionID IS NULL
        BEGIN
            ;THROW 50001, N'يوجد خطأ بجلب بيانات سجل الانتظار - Action ID', 1;
        END

        IF NULLIF(LTRIM(RTRIM(@residentInfoID_FK)), N'') IS NULL
        BEGIN
            ;THROW 50001, N'يوجد خطأ بجلب بيانات المستفيد - resident ID', 1;
        END

        IF NULLIF(LTRIM(RTRIM(@GeneralNo)), N'') IS NULL
        BEGIN
            ;THROW 50001, N'يوجد خطأ بجلب بيانات المستفيد - GN', 1;
        END

        IF NULLIF(LTRIM(RTRIM(@NationalID)), N'') IS NULL
        BEGIN
            ;THROW 50001, N'يوجد خطأ بجلب بيانات المستفيد - @NationalID', 1;
        END

        IF NULLIF(LTRIM(RTRIM(@buildingActionDecisionNo)), N'') IS NULL
        BEGIN
            ;THROW 50001, N'رقم القرار مطلوب', 1;
        END

        IF NULLIF(LTRIM(RTRIM(@buildingActionDecisionDate)), N'') IS NULL
        BEGIN
            ;THROW 50001, N'تاريخ القرار مطلوب', 1;
        END

        ----------------------------------------------------------------
        -- MOVEWAITINGLISTREJECT
        ----------------------------------------------------------------
        IF @Action = N'MOVEWAITINGLISTREJECT'
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1
                FROM [Housing].[V_MoveWaitingList] AS mwl
                WHERE mwl.ActionID = @ActionID
            )
            BEGIN
                ;THROW 50001, N'السجل غير موجود', 1;
            END

            IF NOT EXISTS
            (
                SELECT 1
                FROM [Housing].[V_MoveWaitingList] AS mwl
                WHERE mwl.ActionID = @ActionID
                  AND mwl.LastActionID IS NULL
                  AND mwl.ToIdaraID = @idaraID_FK
            )
            BEGIN
                ;THROW 50001, N'تم اتخاذ اجراء للطلب مسبقا', 1;
            END

            INSERT INTO [Housing].[BuildingAction]
            (
                  buildingActionTypeID_FK
                , residentInfoID_FK
                , generalNo_FK
                , buildingActionDecisionNo
                , buildingActionDecisionDate
                , buildingActionActive
                , buildingActionNote
                , buildingActionParentID
                , IdaraId_FK
                , entryData
                , hostName
            )
            VALUES
            (
                  34
                , @residentInfoID_FK
                , @GeneralNo
                , @buildingActionDecisionNo
                , @buildingActionDecisionDate
                , 1
                , @Notes
                , @ActionID
                , @IdaraID_INT
                , @entryData
                , @hostName
            );

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في رفض الطلب', 1;
            END

            SET @NewID = SCOPE_IDENTITY();

            IF @NewID IS NULL OR @NewID <= 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في رفض الطلب - Identity', 1;
            END

            SET @Note = N'{'
                + N'"buildingActionID": "' + ISNULL(CONVERT(NVARCHAR(MAX), @NewID), '') + N'"'
                + N',"buildingActionTypeID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), 34), '') + N'"'
                + N',"residentInfoID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentInfoID_FK), '') + N'"'
                + N',"generalNo_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @GeneralNo), '') + N'"'
                + N',"buildingActionDecisionNo": "' + ISNULL(CONVERT(NVARCHAR(MAX), @buildingActionDecisionNo), '') + N'"'
                + N',"buildingActionDecisionDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @buildingActionDecisionDate), '') + N'"'
                + N',"buildingActionActive": "' + ISNULL(CONVERT(NVARCHAR(MAX), '1'), '') + N'"'
                + N',"buildingActionNote": "' + ISNULL(CONVERT(NVARCHAR(MAX), @Notes), '') + N'"'
                + N',"buildingActionParentID": "' + ISNULL(CONVERT(NVARCHAR(MAX), @ActionID), '') + N'"'
                + N',"entryData": "' + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + N'"'
                + N',"hostName": "' + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + N'"'
                + N'}';

            INSERT INTO [dbo].[AuditLog]
            (
                  TableName
                , ActionType
                , RecordID
                , PerformedBy
                , Notes
            )
            VALUES
            (
                  N'[Housing].[BuildingAction]'
                , N'REJECTWAITINGLIST'
                , @ActionID
                , @entryData
                , @Note
            );

            IF @tc = 0 AND XACT_STATE() = 1
            BEGIN
                COMMIT TRANSACTION;
            END

            SELECT 1 AS IsSuccessful, N'تم حذف البيانات بنجاح' AS Message_;
            RETURN;
        END

        ----------------------------------------------------------------
        -- MOVEWAITINGLISTAPPROVE
        ----------------------------------------------------------------
        IF @Action = N'MOVEWAITINGLISTAPPROVE'
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1
                FROM [Housing].[V_MoveWaitingList] AS mwl
                WHERE mwl.ActionID = @ActionID
            )
            BEGIN
                ;THROW 50001, N'السجل غير موجود', 1;
            END

            IF NOT EXISTS
            (
                SELECT 1
                FROM [Housing].[V_MoveWaitingList] AS mwl
                WHERE mwl.ActionID = @ActionID
                  AND mwl.LastActionID IS NULL
                  AND mwl.ToIdaraID = @idaraID_FK
            )
            BEGIN
                ;THROW 50001, N'تم اتخاذ اجراء للطلب مسبقا', 1;
            END

            INSERT INTO [Housing].[BuildingAction]
            (
                  buildingActionTypeID_FK
                , residentInfoID_FK
                , generalNo_FK
                , buildingActionDecisionNo
                , buildingActionDecisionDate
                , buildingActionActive
                , buildingActionNote
                , buildingActionParentID
                , IdaraId_FK
                , entryData
                , hostName
            )
            VALUES
            (
                  33
                , @residentInfoID_FK
                , @GeneralNo
                , @buildingActionDecisionNo
                , @buildingActionDecisionDate
                , 1
                , @Notes
                , @ActionID
                , @IdaraID_INT
                , @entryData
                , @hostName
            );

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في قبول الطلب', 1;
            END

            SET @NewID = SCOPE_IDENTITY();

            INSERT INTO [Housing].[BuildingAction]
            (
                  buildingActionTypeID_FK
                , residentInfoID_FK
                , generalNo_FK
                , buildingActionDecisionNo
                , buildingActionDecisionDate
                , buildingActionExtraType1
                , buildingActionExtraType2
                , buildingActionActive
                , buildingActionNote
                , buildingActionParentID
                , IdaraId_FK
                , entryData
                , hostName
            )
            SELECT
                  w.ActionTypeID
                , w.residentInfoID
                , w.GeneralNo
                , w.ActionDecisionNo
                , w.ActionDecisionDate
                , w.WaitingClassID
                , w.WaitingOrderTypeID
                , 1
                , @Notes
                , w.ActionID
                , @IdaraID_INT
                , @entryData
                , @hostName
            FROM [Housing].[V_WaitingList] AS w
            WHERE w.residentInfoID = @residentInfoID_FK
              AND w.LastActionTypeID IS NULL
              AND w.WaitingClassID IN (1, 2, 3, 4, 11);

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في قبول الطلب ونقل السجلات 1', 1;
            END

            INSERT INTO [Housing].[BuildingAction]
            (
                  buildingActionTypeID_FK
                , residentInfoID_FK
                , generalNo_FK
                , buildingActionDecisionNo
                , buildingActionDecisionDate
                , buildingActionExtraType1
                , buildingActionExtraType2
                , buildingActionActive
                , buildingActionNote
                , buildingActionParentID
                , IdaraId_FK
                , entryData
                , hostName
            )
            SELECT
                  36
                , w.residentInfoID
                , w.GeneralNo
                , w.ActionDecisionNo
                , w.ActionDecisionDate
                , w.WaitingClassID
                , w.WaitingOrderTypeID
                , 1
                , @Notes
                , w.ActionID
                , @IdaraID_INT
                , @entryData
                , @hostName
            FROM [Housing].[V_WaitingList] AS w
            WHERE w.residentInfoID = @residentInfoID_FK
              AND w.LastActionTypeID IS NULL
              AND w.WaitingClassID NOT IN (1, 2, 3, 4, 11);

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في قبول الطلب ونقل السجلات 2', 1;
            END

            IF EXISTS
            (
                SELECT 1
                FROM [Housing].[V_WaitingListByLetter]
                WHERE residentInfoID = @residentInfoID_FK
            )
            BEGIN
                INSERT INTO [Housing].[BuildingAction]
                (
                      buildingActionTypeID_FK
                    , residentInfoID_FK
                    , generalNo_FK
                    , buildingActionActive
                    , buildingActionNote
                    , buildingActionParentID
                    , IdaraId_FK
                    , entryData
                    , hostName
                )
                SELECT
                      37
                    , residentInfoID
                    , GeneralNo
                    , 1
                    , @Notes
                    , ActionID
                    , IdaraId
                    , @entryData
                    , @hostName
                FROM [Housing].[V_WaitingListByLetter]
                WHERE residentInfoID = @residentInfoID_FK;

                IF @@ROWCOUNT = 0
                BEGIN
                    ;THROW 50002, N'حصل خطأ في قبول الطلب ونقل السجلات 3', 1;
                END
            END

            DECLARE @rd BIGINT;

            SET @rd =
            (
                SELECT TOP (1) rdd.residentDetailsID
                FROM [Housing].[ResidentDetails] AS rdd
                WHERE rdd.residentInfoID_FK = @residentInfoID_FK
                  AND rdd.residentDetailsActive = 1
                ORDER BY rdd.residentDetailsID DESC
            );

            UPDATE [Housing].[ResidentDetails]
            SET
                  residentDetailsActive = 0
                , residentDetailsEndDate = GETDATE()
            WHERE residentInfoID_FK = @residentInfoID_FK
              AND residentDetailsActive = 1;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في قبول الطلب ونقل السجلات 4', 1;
            END

            INSERT INTO [Housing].[ResidentDetails]
            (
                  [residentInfoID_FK]
                , [generalNo_FK]
                , [rankID_FK]
                , [militaryUnitID_FK]
                , [martialStatusID_FK]
                , [dependinceCounter]
                , [nationalityID_FK]
                , [genderID_FK]
                , [firstName_A]
                , [secondName_A]
                , [thirdName_A]
                , [lastName_A]
                , [firstName_E]
                , [secondName_E]
                , [thirdName_E]
                , [lastName_E]
                , [note]
                , [birthdate]
                , [residentDetailsStartDate]
                , [IdaraId_FK]
                , [residentDetailsActive]
                , [entryData]
                , [hostName]
            )
            SELECT
                  [residentInfoID_FK]
                , [generalNo_FK]
                , [rankID_FK]
                , [militaryUnitID_FK]
                , [martialStatusID_FK]
                , [dependinceCounter]
                , [nationalityID_FK]
                , [genderID_FK]
                , [firstName_A]
                , [secondName_A]
                , [thirdName_A]
                , [lastName_A]
                , [firstName_E]
                , [secondName_E]
                , [thirdName_E]
                , [lastName_E]
                , [note]
                , [birthdate]
                , GETDATE()
                , @IdaraID_INT
                , 1
                , @entryData
                , @hostName
            FROM [Housing].[ResidentDetails] AS rd
            WHERE rd.residentDetailsID = @rd;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في قبول الطلب ونقل السجلات 5', 1;
            END

            IF @NewID IS NULL OR @NewID <= 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في قبول الطلب ونقل السجلات - Identity', 1;
            END

            SET @Note = N'{'
                + N'"buildingActionID": "' + ISNULL(CONVERT(NVARCHAR(MAX), @NewID), '') + N'"'
                + N',"buildingActionTypeID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), 33), '') + N'"'
                + N',"residentInfoID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentInfoID_FK), '') + N'"'
                + N',"generalNo_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @GeneralNo), '') + N'"'
                + N',"buildingActionDecisionNo": "' + ISNULL(CONVERT(NVARCHAR(MAX), @buildingActionDecisionNo), '') + N'"'
                + N',"buildingActionDecisionDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @buildingActionDecisionDate), '') + N'"'
                + N',"buildingActionActive": "' + ISNULL(CONVERT(NVARCHAR(MAX), '1'), '') + N'"'
                + N',"buildingActionNote": "' + ISNULL(CONVERT(NVARCHAR(MAX), @Notes), '') + N'"'
                + N',"buildingActionParentID": "' + ISNULL(CONVERT(NVARCHAR(MAX), @ActionID), '') + N'"'
                + N',"entryData": "' + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + N'"'
                + N',"hostName": "' + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + N'"'
                + N'}';

            INSERT INTO [dbo].[AuditLog]
            (
                  TableName
                , ActionType
                , RecordID
                , PerformedBy
                , Notes
            )
            VALUES
            (
                  N'[Housing].[BuildingAction]'
                , N'APPROVEWAITINGLIST'
                , @ActionID
                , @entryData
                , @Note
            );

            IF @tc = 0 AND XACT_STATE() = 1
            BEGIN
                COMMIT TRANSACTION;
            END

            SELECT 1 AS IsSuccessful, N'تم قبول الطلب بنجاح' AS Message_;
            RETURN;
        END

        ;THROW 50001, N'العملية غير مسجلة', 1;
    END TRY
    BEGIN CATCH
        IF @tc = 0 AND XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        ;THROW;
    END CATCH
END