CREATE   PROCEDURE dbo._DeleteTableAndResetIdentity
(
    @TableName NVARCHAR(517)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SchemaName SYSNAME;
    DECLARE @ObjectName SYSNAME;
    DECLARE @FullTableName NVARCHAR(517);
    DECLARE @ObjectID INT;
    DECLARE @SQL NVARCHAR(MAX);

    DECLARE @HasIdentity BIT = 0;
    DECLARE @RowsDeleted BIGINT = 0;

    BEGIN TRY

        ------------------------------------------------------------
        -- التحقق من اسم الجدول
        ------------------------------------------------------------
        SET @TableName =
            NULLIF(LTRIM(RTRIM(@TableName)), N'');

        IF @TableName IS NULL
        BEGIN
            ;THROW 50001, N'يجب إدخال اسم الجدول', 1;
        END;

        ------------------------------------------------------------
        -- المسموح فقط Schema.Table
        ------------------------------------------------------------
        IF PARSENAME(@TableName, 3) IS NOT NULL
           OR PARSENAME(@TableName, 4) IS NOT NULL
        BEGIN
            ;THROW 50001,
                N'يجب إدخال اسم الجدول بالشكل Schema.Table فقط',
                1;
        END;

        ------------------------------------------------------------
        -- استخراج اسم السكيما والجدول
        ------------------------------------------------------------
        SET @ObjectName = PARSENAME(@TableName, 1);
        SET @SchemaName = PARSENAME(@TableName, 2);

        IF @ObjectName IS NULL
        BEGIN
            ;THROW 50001, N'اسم الجدول غير صحيح', 1;
        END;

        SET @SchemaName =
            ISNULL(@SchemaName, N'dbo');

        ------------------------------------------------------------
        -- التأكد من وجود الجدول
        ------------------------------------------------------------
        SELECT
            @ObjectID = t.object_id
        FROM sys.tables t
        INNER JOIN sys.schemas s
            ON s.schema_id = t.schema_id
        WHERE t.name = @ObjectName
          AND s.name = @SchemaName;

        IF @ObjectID IS NULL
        BEGIN
            ;THROW 50001, N'الجدول المحدد غير موجود', 1;
        END;

        SET @FullTableName =
              QUOTENAME(@SchemaName)
            + N'.'
            + QUOTENAME(@ObjectName);

        ------------------------------------------------------------
        -- التحقق من وجود Identity
        ------------------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM sys.identity_columns
            WHERE object_id = @ObjectID
        )
        BEGIN
            SET @HasIdentity = 1;
        END;

        ------------------------------------------------------------
        -- بدء المعاملة
        ------------------------------------------------------------
        BEGIN TRANSACTION;

        ------------------------------------------------------------
        -- حذف جميع البيانات وجلب عدد السجلات المحذوفة
        ------------------------------------------------------------
        SET @SQL =
            N'DELETE FROM ' + @FullTableName + N';
              SET @DeletedRows = @@ROWCOUNT;';

        EXEC sys.sp_executesql
              @SQL
            , N'@DeletedRows BIGINT OUTPUT'
            , @DeletedRows = @RowsDeleted OUTPUT;

        ------------------------------------------------------------
        -- إعادة ضبط Identity ليبدأ السجل القادم من 1
        ------------------------------------------------------------
        IF @HasIdentity = 1
        BEGIN
            SET @SQL =
                N'DBCC CHECKIDENT
                (
                    N'''
                    + REPLACE
                      (
                          @FullTableName,
                          N'''',
                          N''''''
                      )
                    + N''',
                    RESEED,
                    0
                ) WITH NO_INFOMSGS;';

            EXEC sys.sp_executesql @SQL;
        END;

        COMMIT TRANSACTION;

        ------------------------------------------------------------
        -- نتيجة النجاح
        ------------------------------------------------------------
        SELECT
              CAST(1 AS BIT) AS Success
            , 0 AS ErrorNumber
            , @FullTableName AS TableName
            , @RowsDeleted AS RowsDeleted
            , @HasIdentity AS HasIdentity
            , CASE
                  WHEN @HasIdentity = 1
                  THEN N'تم حذف البيانات وإعادة ضبط الترقيم ليبدأ السجل القادم من 1'
                  ELSE N'تم حذف البيانات بنجاح، ولكن الجدول لا يحتوي على عمود ترقيم تلقائي'
              END AS Message
            , CAST(NULL AS NVARCHAR(4000)) AS ErrorMessage
            , CAST(NULL AS NVARCHAR(128)) AS ErrorProcedure
            , CAST(NULL AS INT) AS ErrorLine;

    END TRY
    BEGIN CATCH

        ------------------------------------------------------------
        -- التراجع عند حدوث خطأ
        ------------------------------------------------------------
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        ------------------------------------------------------------
        -- إرجاع تفاصيل الخطأ
        ------------------------------------------------------------
        SELECT
              CAST(0 AS BIT) AS Success
            , ERROR_NUMBER() AS ErrorNumber
            , ISNULL(@FullTableName, @TableName) AS TableName
            , CAST(0 AS BIGINT) AS RowsDeleted
            , @HasIdentity AS HasIdentity
            , N'فشلت عملية حذف بيانات الجدول' AS Message
            , ERROR_MESSAGE() AS ErrorMessage
            , ERROR_PROCEDURE() AS ErrorProcedure
            , ERROR_LINE() AS ErrorLine;

        RETURN;
    END CATCH;
END;