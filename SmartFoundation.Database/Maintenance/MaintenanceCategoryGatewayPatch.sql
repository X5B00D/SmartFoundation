USE [DATACORE];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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

IF @CrudDefinition NOT LIKE N'%@pageName_ = ''MaintenanceCategory''%'
BEGIN
    DECLARE @CrudStart INT = CHARINDEX(N'-- Violation_Upsert', @CrudDefinition);

    IF @CrudStart = 0
        THROW 50002, N'Violation_Upsert block was not found in dbo.Masters_CRUD.', 1;

    DECLARE @CrudGoto INT = CHARINDEX(N'GOTO Finish;', @CrudDefinition, @CrudStart);

    IF @CrudGoto = 0
        THROW 50002, N'Violation_Upsert GOTO Finish was not found in dbo.Masters_CRUD.', 1;

    DECLARE @CrudEnd INT = CHARINDEX(NCHAR(10) + N'END', @CrudDefinition, @CrudGoto);

    IF @CrudEnd = 0
        THROW 50002, N'Violation_Upsert END was not found in dbo.Masters_CRUD.', 1;

    SET @CrudEnd = @CrudEnd + LEN(NCHAR(10) + N'END');

    SET @CrudDefinition = STUFF(@CrudDefinition, @CrudEnd, 0, @CrudBlock);
    SET @CrudDefinition = STUFF
    (
          @CrudDefinition
        , CHARINDEX(N'CREATE PROCEDURE', @CrudDefinition)
        , LEN(N'CREATE PROCEDURE')
        , N'ALTER PROCEDURE'
    );

    EXEC sp_executesql @CrudDefinition;
END
GO

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

IF @DataLoadDefinition NOT LIKE N'%@pageName_ = ''MaintenanceCategory''%'
BEGIN
    DECLARE @DataLoadStart INT = CHARINDEX(N'--                    Violation_Get', @DataLoadDefinition);

    IF @DataLoadStart = 0
        THROW 50002, N'Violation_Get block was not found in dbo.Masters_DataLoad.', 1;

    DECLARE @DataLoadExec INT = CHARINDEX(N'EXEC [VIC].[Violation_Get_DL]', @DataLoadDefinition, @DataLoadStart);

    IF @DataLoadExec = 0
        THROW 50002, N'Violation_Get EXEC was not found in dbo.Masters_DataLoad.', 1;

    DECLARE @DataLoadEnd INT = CHARINDEX(NCHAR(10) + N'END', @DataLoadDefinition, @DataLoadExec);

    IF @DataLoadEnd = 0
        THROW 50002, N'Violation_Get END was not found in dbo.Masters_DataLoad.', 1;

    SET @DataLoadEnd = @DataLoadEnd + LEN(NCHAR(10) + N'END');

    SET @DataLoadDefinition = STUFF(@DataLoadDefinition, @DataLoadEnd, 0, @DataLoadBlock);
    SET @DataLoadDefinition = STUFF
    (
          @DataLoadDefinition
        , CHARINDEX(N'CREATE PROCEDURE', @DataLoadDefinition)
        , LEN(N'CREATE PROCEDURE')
        , N'ALTER PROCEDURE'
    );

    EXEC sp_executesql @DataLoadDefinition;
END
GO
