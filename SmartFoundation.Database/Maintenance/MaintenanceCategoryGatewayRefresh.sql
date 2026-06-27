USE [DATACORE];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @NewLine NCHAR(1) = NCHAR(10);

DECLARE @CrudDefinition NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'[dbo].[Masters_CRUD]'));
DECLARE @CrudBlock NVARCHAR(MAX) = N'
-- نظام طلبات صيانة المباني
-- Maintenance Requests System
------------------------------

----------------------------------------------------------------
-- MaintenanceCategory
----------------------------------------------------------------
ELSE IF @pageName_ = ''MaintenanceCategory''
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

    IF @ActionType = ''INSERTMAINTENANCECATEGORY''
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [Maintenance].[MaintenanceCategorySP]
              @Action                = @ActionType
            , @MaintenanceCategoryID = NULL
            , @ParentID              = @parameter_01
            , @CategoryName_A        = @parameter_02
            , @CategoryName_E        = @parameter_03
            , @Description_A         = @parameter_04
            , @DisplayOrder          = @parameter_05
            , @idaraID_FK            = @idaraID
            , @entryData             = @entrydata
            , @hostName              = @hostName;
    END
    ELSE IF @ActionType = ''UPDATEMAINTENANCECATEGORY''
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [Maintenance].[MaintenanceCategorySP]
              @Action                = @ActionType
            , @MaintenanceCategoryID = @parameter_01
            , @ParentID              = @parameter_02
            , @CategoryName_A        = @parameter_03
            , @CategoryName_E        = @parameter_04
            , @Description_A         = @parameter_05
            , @DisplayOrder          = @parameter_06
            , @idaraID_FK            = @idaraID
            , @entryData             = @entrydata
            , @hostName              = @hostName;
    END
    ELSE IF @ActionType = ''DELETEMAINTENANCECATEGORY''
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [Maintenance].[MaintenanceCategorySP]
              @Action                = @ActionType
            , @MaintenanceCategoryID = @parameter_01
            , @idaraID_FK            = @idaraID
            , @entryData             = @entrydata
            , @hostName              = @hostName;
    END
    ELSE IF @ActionType = ''ROUTEMAINTENANCECATEGORY''
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [Maintenance].[MaintenanceCategorySP]
              @Action                = @ActionType
            , @MaintenanceCategoryID = @parameter_01
            , @ResponsibleDSDID      = @parameter_02
            , @Notes                 = @parameter_03
            , @idaraID_FK            = @idaraID
            , @entryData             = @entrydata
            , @hostName              = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N''نوع العملية المطلوبة غير معروف. ActionType'';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END';

IF @CrudDefinition IS NULL
    THROW 50002, N'dbo.Masters_CRUD was not found.', 1;

SET @CrudDefinition = REPLACE
(
    @CrudDefinition,
    N'-- ظ†ط¸ط§ظ… ط·ظ„ط¨ط§طھ طµظٹط§ظ†ط© ط§ظ„ظ…ط¨ط§ظ†ظٹ',
    N'-- نظام طلبات صيانة المباني'
);

DECLARE @CrudBlockStart INT = CHARINDEX(N'-- نظام طلبات صيانة المباني' + @NewLine + N'-- Maintenance Requests System', @CrudDefinition);

IF @CrudBlockStart = 0
    THROW 50002, N'MaintenanceCategory block start was not found in dbo.Masters_CRUD.', 1;

DECLARE @CrudIf INT = CHARINDEX(N'ELSE IF @pageName_ = ''MaintenanceCategory''', @CrudDefinition, @CrudBlockStart);
DECLARE @CrudGoto INT = CHARINDEX(N'GOTO Finish;', @CrudDefinition, @CrudIf);
DECLARE @CrudEnd INT = CHARINDEX(@NewLine + N'END', @CrudDefinition, @CrudGoto);

IF @CrudIf = 0 OR @CrudGoto = 0 OR @CrudEnd = 0
    THROW 50002, N'MaintenanceCategory block end was not found in dbo.Masters_CRUD.', 1;

SET @CrudEnd = @CrudEnd + LEN(@NewLine + N'END');
SET @CrudDefinition = STUFF(@CrudDefinition, @CrudBlockStart, @CrudEnd - @CrudBlockStart, @CrudBlock);
SET @CrudDefinition = STUFF
(
      @CrudDefinition
    , CHARINDEX(N'CREATE PROCEDURE', @CrudDefinition)
    , LEN(N'CREATE PROCEDURE')
    , N'ALTER PROCEDURE'
);

EXEC sp_executesql @CrudDefinition;
GO

DECLARE @NewLine NCHAR(1) = NCHAR(10);

DECLARE @DataLoadDefinition NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'[dbo].[Masters_DataLoad]'));
DECLARE @DataLoadBlock NVARCHAR(MAX) = N'
-- نظام طلبات صيانة المباني
-- Maintenance Requests System
------------------------------

-------------------------------------------------------------------
--                    MaintenanceCategory
-------------------------------------------------------------------
ELSE IF @pageName_ = ''MaintenanceCategory''
BEGIN
    EXEC [Maintenance].[MaintenanceCategoryDL]
          @pageName_ = @pageName_
        , @idaraID   = @idaraID
        , @entryData = @entrydata
        , @hostName  = @hostName;
END';

IF @DataLoadDefinition IS NULL
    THROW 50002, N'dbo.Masters_DataLoad was not found.', 1;

SET @DataLoadDefinition = REPLACE
(
    @DataLoadDefinition,
    N'-- ظ†ط¸ط§ظ… ط·ظ„ط¨ط§طھ طµظٹط§ظ†ط© ط§ظ„ظ…ط¨ط§ظ†ظٹ',
    N'-- نظام طلبات صيانة المباني'
);

DECLARE @DataLoadBlockStart INT = CHARINDEX(N'-- نظام طلبات صيانة المباني' + @NewLine + N'-- Maintenance Requests System', @DataLoadDefinition);

IF @DataLoadBlockStart = 0
    THROW 50002, N'MaintenanceCategory block start was not found in dbo.Masters_DataLoad.', 1;

DECLARE @DataLoadIf INT = CHARINDEX(N'ELSE IF @pageName_ = ''MaintenanceCategory''', @DataLoadDefinition, @DataLoadBlockStart);
DECLARE @DataLoadExec INT = CHARINDEX(N'EXEC [Maintenance].[MaintenanceCategoryDL]', @DataLoadDefinition, @DataLoadIf);
DECLARE @DataLoadEnd INT = CHARINDEX(@NewLine + N'END', @DataLoadDefinition, @DataLoadExec);

IF @DataLoadIf = 0 OR @DataLoadExec = 0 OR @DataLoadEnd = 0
    THROW 50002, N'MaintenanceCategory block end was not found in dbo.Masters_DataLoad.', 1;

SET @DataLoadEnd = @DataLoadEnd + LEN(@NewLine + N'END');
SET @DataLoadDefinition = STUFF(@DataLoadDefinition, @DataLoadBlockStart, @DataLoadEnd - @DataLoadBlockStart, @DataLoadBlock);
SET @DataLoadDefinition = STUFF
(
      @DataLoadDefinition
    , CHARINDEX(N'CREATE PROCEDURE', @DataLoadDefinition)
    , LEN(N'CREATE PROCEDURE')
    , N'ALTER PROCEDURE'
);

EXEC sp_executesql @DataLoadDefinition;
GO
