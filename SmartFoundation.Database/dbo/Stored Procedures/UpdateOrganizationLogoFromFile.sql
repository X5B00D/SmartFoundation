CREATE   PROCEDURE dbo.UpdateOrganizationLogoFromFile
(
    @OrganizationID BIGINT,
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
        UPDATE dbo.Organization
        SET 
            OrganizationLogo = (
                SELECT BulkColumn
                FROM OPENROWSET(
                    BULK ''' + @FilePath + N''',
                    SINGLE_BLOB
                ) AS LogoFile
            ),
            entryDate = GETDATE()
        WHERE OrganizationID = ' + CAST(@OrganizationID AS NVARCHAR(20)) + N';
    ';

    BEGIN TRY
        EXEC sp_executesql @SQL;
        PRINT N'Organization logo updated successfully for Organization ID: ' + CAST(@OrganizationID AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        PRINT N'Failed for Organization ID: ' + CAST(@OrganizationID AS NVARCHAR(20));
        PRINT N'File: ' + @FilePath;
        PRINT ERROR_MESSAGE();
    END CATCH
END
