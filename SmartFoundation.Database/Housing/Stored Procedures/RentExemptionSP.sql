
CREATE PROCEDURE [Housing].[RentExemptionSP] 
(
      @Action                               NVARCHAR(200)
    , @residentRentExemptionID              BIGINT          = NULL
    , @residentRentExemptionTypeID_FK       BIGINT   = NULL
    , @residentInfoID_FK                    NVARCHAR(100)   = NULL
    , @residentRentExemptionStartDate       NVARCHAR(1000)  = NULL
    , @residentRentExemptionEndDate         NVARCHAR(1000)  = NULL
    , @residentRentExemptionDescription     NVARCHAR(1000)  = NULL
    , @residentRentExemptionLetterNo        NVARCHAR(1000)  = NULL
    , @residentRentExemptionLetterDate      NVARCHAR(1000)  = NULL
    , @buildingDetailsID_FK                 NVARCHAR(1000)  = NULL
    , @buildingDetailsNo                    NVARCHAR(1000)  = NULL
    , @idaraID_FK                           NVARCHAR(10)    = NULL
    , @entryData                            NVARCHAR(20)    = NULL
    , @hostName                             NVARCHAR(200)   = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @tc INT = @@TRANCOUNT;

    DECLARE 
          @NewID BIGINT = NULL
        , @Note  NVARCHAR(MAX) = NULL;

    -- تحويلات رقمية آمنة
    DECLARE @IdaraID_INT INT = TRY_CONVERT(INT, NULLIF(@idaraID_FK, ''));

    BEGIN TRY
        -- Transaction-safe
        IF @tc = 0
            BEGIN TRAN;

        ----------------------------------------------------------------
        -- Business validations => THROW 50001
        ----------------------------------------------------------------
        IF NULLIF(LTRIM(RTRIM(@Action)), N'') IS NULL
        BEGIN
            ;THROW 50001, N'العملية مطلوبة', 1;
        END
                   IF NULLIF(LTRIM(RTRIM(@residentRentExemptionTypeID_FK)), N'') IS NULL
            BEGIN
                ;THROW 50001, N'نوع الاعفاء مطلوب', 1;
            END
            
            IF NULLIF(LTRIM(RTRIM(@residentInfoID_FK)), N'') IS NULL
            BEGIN
                ;THROW 50001, N'الرقم المرجعي للمستفيد مطلوب', 1;
            END
            
            IF NULLIF(LTRIM(RTRIM(@residentRentExemptionStartDate)), N'') IS NULL
            BEGIN
                ;THROW 50001, N'تاريخ بداية الاعفاء مطلوب', 1;
            END
            
            
            IF NULLIF(LTRIM(RTRIM(@residentRentExemptionLetterNo)), N'') IS NULL
            BEGIN
                ;THROW 50001, N'رقم الخطاب مطلوب', 1;
            END
            
            IF NULLIF(LTRIM(RTRIM(@residentRentExemptionLetterDate)), N'') IS NULL
            BEGIN
                ;THROW 50001, N'تاريخ الخطاب مطلوب', 1;
            END
            
            IF NULLIF(LTRIM(RTRIM(@idaraID_FK)), N'') IS NULL
            BEGIN
                ;THROW 50001, N'الإدارة مطلوبة', 1;
            END

            IF NULLIF(LTRIM(RTRIM(@buildingDetailsNo)), N'') IS NULL
            BEGIN
                ;THROW 50001, N'رقم المنزل مطلوب', 1;
            END

            IF NULLIF(LTRIM(RTRIM(@buildingDetailsID_FK)), N'') IS NULL
            BEGIN
                ;THROW 50001, N'رقم المنزل مطلوب', 1;
            END
            IF(cast(@residentRentExemptionEndDate as date) <= cast(@residentRentExemptionStartDate as date))
            BEGIN
                ;THROW 50001, N'تاريخ نهاية الاعفاء يجب أن يكون اكبر من تاريخ بداية الاعفاء', 1;
            END

        ----------------------------------------------------------------
        -- INSERT
        ----------------------------------------------------------------
        IF @Action = N'ADDRENTEXEMPTION'
        BEGIN

         IF (SELECT COUNT(*) FROM Housing.V_Occupant e WHERE e.residentInfoID = @residentInfoID_FK) = 0
            
            BEGIN
                ;THROW 50001, N'المستفيد غير ساكن حاليا', 1;
            END
            

            IF EXISTS
            (
                SELECT 1
                FROM  Housing.ResidentRentExemption c
                WHERE C.residentInfoID_FK = @residentInfoID_FK
                  AND c.residentRentExemptionActive = 1
                  AND (c.residentRentExemptionEndDate > TRY_CONVERT(DATE, GETDATE()) OR c.residentRentExemptionEndDate IS NULL)
                  AND (c.IdaraId_FK = @IdaraID_INT OR @IdaraID_INT IS NULL)
                  and c.buildingDetailsID_FK = @buildingDetailsID_FK
            )
            BEGIN
                ;THROW 50001, N'يوجد اعفاء نشط للمستفيد مسبقا', 1;
            END


            INSERT INTO  Housing.ResidentRentExemption
            (
                  [residentRentExemptionTypeID_FK]
                 ,[residentInfoID_FK]
                 ,[buildingDetailsID_FK]
                 ,[residentRentExemptionActive]
                 ,[residentRentExemptionLetterNo]
                 ,[residentRentExemptionLetterDate]
                 ,[residentRentExemptionStartDate]
                 ,[residentRentExemptionEndDate]
                 ,[residentRentExemptionDescription]
                 ,[idaraID_FK]
                 ,[entryData]
                 ,[entryDate]
                 ,[hostName]
            )
            VALUES
            (
                  @residentRentExemptionTypeID_FK
                , @residentInfoID_FK
                , @buildingDetailsID_FK
                , 1
                , @residentRentExemptionLetterNo
                , @residentRentExemptionLetterDate
                , @residentRentExemptionStartDate
                , @residentRentExemptionEndDate
                , @residentRentExemptionDescription
                , @IdaraID_INT
                , @entryData
                , GETDATE()
                , @hostName
            );

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في اضافة الاعفاء', 1; -- برمجي
            END
            SET @NewID = SCOPE_IDENTITY();
            IF @NewID IS NULL OR @NewID <= 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في اضافة الاعفاء - Identity', 1; -- برمجي
            END
            SET @Note = N'{'
                + N'"residentRentExemptionID": "'           + ISNULL(CONVERT(NVARCHAR(MAX), @NewID), '') + N'"'
                + N',"residentRentExemptionTypeID_FK": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionTypeID_FK), '') + N'"'
                + N',"residentInfoID_FK": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentInfoID_FK), '') + N'"'
                + N',"buildingDetailsID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @buildingDetailsID_FK), '') + N'"'
                + N',"residentRentExemptionActive": "1"'
                + N',"residentRentExemptionLetterNo": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionLetterNo), '') + N'"'
                + N',"residentRentExemptionLetterDate": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionLetterDate), '') + N'"'
                + N',"residentRentExemptionStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionStartDate), '') + N'"' 
                + N',"residentRentExemptionEndDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionEndDate), '') + N'"'
                + N',"residentRentExemptionDescription": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionDescription), '') + N'"'
                + N',"IdaraId_FK": "'               + ISNULL(CONVERT(NVARCHAR(MAX), @idaraID_FK), '') + N'"'
                + N',"entryData": "'                + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + N'"'
                + N',"hostName": "'                 + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + N'"'
                + N'}';

            INSERT INTO  dbo.AuditLog
            (
                  TableName
                , ActionType
                , RecordID
                , PerformedBy
                , Notes
            )
            VALUES
            (
                  N'[Housing].[ResidentRentExemption]'
                , N'ADDRENTEXEMPTION'
                , ISNULL(@NewID, 0)
                , @entryData
                , @Note
            );

            SELECT 1 AS IsSuccessful, N'تم اضافة الاعفاء بنجاح' AS Message_;
            RETURN;
        END

        ----------------------------------------------------------------
        -- EDITRENTEXEMPTION
        ----------------------------------------------------------------
        ELSE IF @Action = N'EDITRENTEXEMPTION'
        BEGIN
            IF @residentRentExemptionID IS NULL
            BEGIN
                ;THROW 50001, N'رقم السجل مطلوب للتحديث', 1;
            END

            IF NOT EXISTS
            (
                SELECT 1
                FROM  Housing.ResidentRentExemption c
                WHERE C.residentRentExemptionID = @residentRentExemptionID
                  AND c.residentRentExemptionActive = 1
                  AND (c.IdaraId_FK = @IdaraID_INT OR @IdaraID_INT IS NULL)
            )
            BEGIN
                ;THROW 50001, N'الاعفاء غير موجود', 1;
            END

            IF (SELECT COUNT(*) FROM Housing.ResidentRentExemption e WHERE e.residentRentExemptionID = @residentRentExemptionID and e.residentRentExemptionEndDate is not null ) > 0
            BEGIN
                UPDATE  Housing.ResidentRentExemption
            SET residentRentExemptionActive = 0
            WHERE residentRentExemptionID = @residentRentExemptionID;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'لم يتم تحديث أي سجل', 1; -- برمجي/غير متوقع
            END
            END

            IF (SELECT COUNT(*) FROM Housing.ResidentRentExemption e WHERE e.residentRentExemptionID = @residentRentExemptionID and e.residentRentExemptionEndDate is null ) > 0
            BEGIN
                UPDATE  Housing.ResidentRentExemption
            SET residentRentExemptionActive = 0, residentRentExemptionEndDate = GETDATE()
            WHERE residentRentExemptionID = @residentRentExemptionID;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'لم يتم تحديث أي سجل', 1; -- برمجي/غير متوقع
            END
            END


            
            INSERT INTO  Housing.ResidentRentExemption
            (
                  [residentRentExemptionTypeID_FK]
                 ,[residentInfoID_FK]
                 ,[buildingDetailsID_FK]
                 ,[residentRentExemptionActive]
                 ,[residentRentExemptionLetterNo]
                 ,[residentRentExemptionLetterDate]
                 ,[residentRentExemptionStartDate]
                 ,[residentRentExemptionEndDate]
                 ,[residentRentExemptionDescription]
                 ,[idaraID_FK]
                 ,[entryData]
                 ,[entryDate]
                 ,[hostName]
            )
            VALUES
            (
                  @residentRentExemptionTypeID_FK
                , @residentInfoID_FK
                , @buildingDetailsID_FK
                , 1
                , @residentRentExemptionLetterNo
                , @residentRentExemptionLetterDate
                , @residentRentExemptionStartDate
                , @residentRentExemptionEndDate
                , @residentRentExemptionDescription
                , @IdaraID_INT
                , @entryData
                , GETDATE()
                , @hostName
            );

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في اضافة الاعفاء', 1; -- برمجي
            END
            SET @NewID = SCOPE_IDENTITY();
            IF @NewID IS NULL OR @NewID <= 0
            BEGIN
                ;THROW 50002, N'حصل خطأ في اضافة الاعفاء - Identity', 1; -- برمجي
            END




            SET @Note = N'{'
                + N'"residentRentExemptionID": "'           + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionID), '') + N'"'
                + N',"residentRentExemptionTypeID_FK": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionTypeID_FK), '') + N'"'
                + N',"residentInfoID_FK": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentInfoID_FK), '') + N'"'
                + N',"buildingDetailsID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @buildingDetailsID_FK), '') + N'"'
                + N',"residentRentExemptionActive": "1"'
                + N',"residentRentExemptionLetterNo": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionLetterNo), '') + N'"'
                + N',"residentRentExemptionLetterDate": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionLetterDate), '') + N'"'
                + N',"residentRentExemptionStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionStartDate), '') + N'"' 
                + N',"residentRentExemptionEndDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionEndDate), '') + N'"'
                + N',"residentRentExemptionDescription": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionDescription), '') + N'"'
                + N',"IdaraId_FK": "'               + ISNULL(CONVERT(NVARCHAR(MAX), @idaraID_FK), '') + N'"'
                + N',"entryData": "'                + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + N'"'
                + N',"hostName": "'                 + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + N'"'
                + N'}';

            INSERT INTO  dbo.AuditLog
            (
                  TableName
                , ActionType
                , RecordID
                , PerformedBy
                , Notes
            )
            VALUES
            (
                  N'[Housing].[ResidentRentExemption]'
                , N'EDITRENTEXEMPTION'
                , ISNULL(@NewID, 0)
                , @entryData
                , @Note
            );

            SELECT 1 AS IsSuccessful, N'تم تحديث الاعفاء بنجاح' AS Message_;
            RETURN;
        END

        ----------------------------------------------------------------
        -- DELETE (Soft Delete)
        ----------------------------------------------------------------
        ELSE IF @Action = N'DELETERENTEXEMPTION'
        BEGIN
           IF @residentRentExemptionID IS NULL
            BEGIN
                ;THROW 50001, N'رقم السجل مطلوب للتحديث', 1;
            END

            IF NOT EXISTS
            (
                SELECT 1
                FROM  Housing.ResidentRentExemption c
                WHERE C.residentRentExemptionID = @residentRentExemptionID
                  AND c.residentRentExemptionActive = 1
                  AND (c.IdaraId_FK = @IdaraID_INT OR @IdaraID_INT IS NULL)
            )
            BEGIN
                ;THROW 50001, N'الاعفاء غير موجود', 1;
            END

            IF (SELECT COUNT(*) FROM Housing.ResidentRentExemption e WHERE e.residentRentExemptionID = @residentRentExemptionID and e.residentRentExemptionEndDate is not null ) > 0
            BEGIN
                UPDATE  Housing.ResidentRentExemption
            SET residentRentExemptionActive = 0,CanceldBy = @entryData, CanceldDate = GETDATE(),CanceldWhy=@residentRentExemptionDescription
            WHERE residentRentExemptionID = @residentRentExemptionID;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'لم يتم الغاء الاعفاء', 1; -- برمجي/غير متوقع
            END
            END

            IF (SELECT COUNT(*) FROM Housing.ResidentRentExemption e WHERE e.residentRentExemptionID = @residentRentExemptionID and e.residentRentExemptionEndDate is null ) > 0
            BEGIN
                UPDATE  Housing.ResidentRentExemption
            SET residentRentExemptionActive = 0, residentRentExemptionEndDate = GETDATE(),CanceldBy = @entryData, CanceldDate = GETDATE(),CanceldWhy=@residentRentExemptionDescription
            WHERE residentRentExemptionID = @residentRentExemptionID;

            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50002, N'لم يتم الغاء الاعفاء', 1; -- برمجي/غير متوقع
            END
            END


            SET @Note = N'{'
                + N'"residentRentExemptionID": "'           + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionID), '') + N'"'
                + N',"residentRentExemptionTypeID_FK": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionTypeID_FK), '') + N'"'
                + N',"residentInfoID_FK": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentInfoID_FK), '') + N'"'
                + N',"buildingDetailsID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @buildingDetailsID_FK), '') + N'"'
                + N',"residentRentExemptionActive": "1"'
                + N',"residentRentExemptionLetterNo": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionLetterNo), '') + N'"'
                + N',"residentRentExemptionLetterDate": "'      + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionLetterDate), '') + N'"'
                + N',"residentRentExemptionStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionStartDate), '') + N'"' 
                + N',"residentRentExemptionEndDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionEndDate), '') + N'"'
                + N',"residentRentExemptionDescription": "' + ISNULL(CONVERT(NVARCHAR(MAX), @residentRentExemptionDescription), '') + N'"'
                + N',"IdaraId_FK": "'               + ISNULL(CONVERT(NVARCHAR(MAX), @idaraID_FK), '') + N'"'
                + N',"entryData": "'                + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + N'"'
                + N',"hostName": "'                 + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + N'"'
                + N'}';

            INSERT INTO  dbo.AuditLog
            (
                  TableName
                , ActionType
                , RecordID
                , PerformedBy
                , Notes
            )
            VALUES
            (
                  N'[Housing].[ResidentRentExemption]'
                , N'DELETERENTEXEMPTION'
                , ISNULL(@NewID, 0)
                , @entryData
                , @Note
            );

            SELECT 1 AS IsSuccessful, N'تم الغاء الاعفاء بنجاح' AS Message_;
            RETURN;
        END


        ----------------------------------------------------------------
        -- Unknown Action
        ----------------------------------------------------------------
        ELSE
        BEGIN
            ;THROW 50001, N'العملية غير مسجلة', 1;
        END

    END TRY
    BEGIN CATCH
        IF @tc = 0 AND XACT_STATE() <> 0
            ROLLBACK;

        ;THROW;
    END CATCH
END
