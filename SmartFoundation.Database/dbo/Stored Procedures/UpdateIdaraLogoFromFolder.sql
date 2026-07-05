CREATE PROCEDURE dbo.UpdateIdaraLogoFromFolder
(
    @idaraID BIGINT,
    @ImageName NVARCHAR(255) -- example: logo1.jpg
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @FilePath NVARCHAR(500),
        @SQL NVARCHAR(MAX);

    SET @FilePath = N'D:\IdaraLogo\' + @ImageName;

    SET @SQL = N'
        UPDATE dbo.Idara
        SET 
            idaraLogo = (
                SELECT BulkColumn
                FROM OPENROWSET(
                    BULK ''' + @FilePath + N''',
                    SINGLE_BLOB
                ) AS LogoFile
            ),
            entryDate = GETDATE()
        WHERE idaraID = ' + CAST(@idaraID AS NVARCHAR(20)) + N';
    ';

    BEGIN TRY
        EXEC sp_executesql @SQL;
        PRINT N'Logo updated successfully for IDARA ID: ' + CAST(@idaraID AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        PRINT N'Failed for IDARA ID: ' + CAST(@idaraID AS NVARCHAR(20));
        PRINT N'File: ' + @FilePath;
        PRINT ERROR_MESSAGE();
    END CATCH
END
