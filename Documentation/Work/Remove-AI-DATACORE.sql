/*
DO NOT EXECUTE WITHOUT MANUAL APPROVAL

Target: DATACORE
Purpose: remove the retired AI database surface after the application/source release
         has been accepted and the verified full backup is available.

Verified backup: DATACORE_20260830_112952.bak (2026-08-30)
This script intentionally contains no conversation-data export or disclosure.
Review every ALTER and DROP statement manually before execution.
*/

USE [DATACORE];
GO
ALTER PROCEDURE [dbo].[Masters_CRUD]
      @pageName_      NVARCHAR(400)
    , @ActionType     NVARCHAR(100)
    , @idaraID        INT
    , @entrydata      INT
    , @hostName       NVARCHAR(4000) = NULL
    , @parameter_01   NVARCHAR(4000) = NULL
    , @parameter_02   NVARCHAR(4000) = NULL
    , @parameter_03   NVARCHAR(4000) = NULL
    , @parameter_04   NVARCHAR(4000) = NULL
    , @parameter_05   NVARCHAR(4000) = NULL
    , @parameter_06   NVARCHAR(4000) = NULL
    , @parameter_07   NVARCHAR(4000) = NULL
    , @parameter_08   NVARCHAR(4000) = NULL
    , @parameter_09   NVARCHAR(4000) = NULL
    , @parameter_10   NVARCHAR(4000) = NULL
    , @parameter_11   NVARCHAR(4000) = NULL
    , @parameter_12   NVARCHAR(4000) = NULL
    , @parameter_13   NVARCHAR(4000) = NULL
    , @parameter_14   NVARCHAR(4000) = NULL
    , @parameter_15   NVARCHAR(4000) = NULL
    , @parameter_16   NVARCHAR(4000) = NULL
    , @parameter_17   NVARCHAR(4000) = NULL
    , @parameter_18   NVARCHAR(4000) = NULL
    , @parameter_19   NVARCHAR(4000) = NULL
    , @parameter_20   NVARCHAR(4000) = NULL
    , @parameter_21   NVARCHAR(4000) = NULL
    , @parameter_22   NVARCHAR(4000) = NULL
    , @parameter_23   NVARCHAR(4000) = NULL
    , @parameter_24   NVARCHAR(4000) = NULL
    , @parameter_25   NVARCHAR(4000) = NULL
    , @parameter_26   NVARCHAR(4000) = NULL
    , @parameter_27   NVARCHAR(4000) = NULL
    , @parameter_28   NVARCHAR(4000) = NULL
    , @parameter_29   NVARCHAR(4000) = NULL
    , @parameter_30   NVARCHAR(4000) = NULL
    , @parameter_31   NVARCHAR(4000) = NULL
    , @parameter_32   NVARCHAR(4000) = NULL
    , @parameter_33   NVARCHAR(4000) = NULL
    , @parameter_34   NVARCHAR(4000) = NULL
    , @parameter_35   NVARCHAR(4000) = NULL
    , @parameter_36   NVARCHAR(4000) = NULL
    , @parameter_37   NVARCHAR(4000) = NULL
    , @parameter_38   NVARCHAR(4000) = NULL
    , @parameter_39   NVARCHAR(4000) = NULL
    , @parameter_40   NVARCHAR(4000) = NULL
    , @parameter_41   NVARCHAR(4000) = NULL
    , @parameter_42   NVARCHAR(4000) = NULL
    , @parameter_43   NVARCHAR(4000) = NULL
    , @parameter_44   NVARCHAR(4000) = NULL
    , @parameter_45   NVARCHAR(4000) = NULL
    , @parameter_46   NVARCHAR(4000) = NULL
    , @parameter_47   NVARCHAR(4000) = NULL
    , @parameter_48   NVARCHAR(4000) = NULL
    , @parameter_49   NVARCHAR(4000) = NULL
    , @parameter_50   NVARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @tc INT = @@TRANCOUNT;

    DECLARE @Result TABLE (IsSuccessful INT, Message_ NVARCHAR(4000));
    DECLARE @ok  INT = 0;
    DECLARE @msg NVARCHAR(4000) = N'';

    -- Notification Outbox
    DECLARE @SendNotif BIT = 0;
    DECLARE @NotifTitle NVARCHAR(200)  = NULL;
    DECLARE @NotifBody  NVARCHAR(2000) = NULL;
    DECLARE @NotifUrl   NVARCHAR(500)  = NULL;

    DECLARE @NotifUserID        BIGINT = NULL;
    DECLARE @NotifDistributorID BIGINT = NULL;
    DECLARE @NotifRoleID        BIGINT = NULL;
    DECLARE @NotifDsdID         BIGINT = NULL;
    DECLARE @NotifIdaraID       BIGINT = NULL;
    DECLARE @NotifMenuID        BIGINT = NULL;
    DECLARE @NotifPermissionTypeID BIGINT = NULL;
    DECLARE @NotifPermissionTypeIDs NVARCHAR(500) = NULL;

    DECLARE @NotifStartDate NVARCHAR(500) = NULL;
    DECLARE @NotifEndDate   NVARCHAR(500) = NULL;
    DECLARE @entrydataname   NVARCHAR(500) = NULL;
    set @entrydataname = (SELECT u.FullName FROM V_GetListUsersInDSD u WHERE U.usersID =@entrydata)


    BEGIN TRY
        IF @tc = 0
            BEGIN TRAN;

        -- reset outbox
        SET @SendNotif = 0;
        SET @NotifTitle = NULL;
        SET @NotifBody  = NULL;
        SET @NotifUrl   = NULL;
        SET @NotifUserID = NULL;
        SET @NotifDistributorID = NULL;
        SET @NotifRoleID  = NULL;
        SET @NotifDsdID = NULL;
        SET @NotifPermissionTypeID = NULL;
        SET @NotifPermissionTypeIDs = NULL;
        SET @NotifStartDate = NULL;
        SET @NotifEndDate = NULL;
        ----------------------------------------------------------------
        -- Permission
        ----------------------------------------------------------------
        IF @pageName_ = 'Permission'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERTPERMISSION'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PermissionSP]
                      @Action                         = @ActionType
                    , @DistributorPermissionTypeID_FK = @parameter_02
                    , @permissionStartDate            = @parameter_03
                    , @permissionEndDate              = @parameter_04
                    , @permissionNote                 = @parameter_05
                    , @UsersID                        = @parameter_06
                    , @RoleID                         = @parameter_07
                    , @IdaraID                        = @parameter_08
                    , @DeptID                         = @parameter_09
                    , @SectionID                      = @parameter_10
                    , @DivisonID                      = @parameter_11
                    , @distributorID                  = @parameter_12
                    , @searchID                       = @parameter_13
                    , @InIdaraID                      = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName;
            END
            ELSE IF @ActionType = 'INSERTFULLACCESS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PermissionSP]
                      @Action                              = @ActionType
                    , @distributorIDFroGiveAllPermissions   = @parameter_01
                    , @permissionStartDate                  = @parameter_02
                    , @permissionEndDate                    = @parameter_03
                    , @permissionNote                       = @parameter_04
                    , @UsersID                              = @parameter_05
                    , @RoleID                               = @parameter_06
                    , @IdaraID                              = @parameter_07
                    , @DeptID                               = @parameter_08
                    , @SectionID                            = @parameter_09
                    , @DivisonID                            = @parameter_10
                    , @distributorID                        = @parameter_11
                    , @searchID                             = @parameter_12
                    , @InIdaraID                      = @idaraID
                    , @entryData                            = @entrydata
                    , @hostName                             = @hostName;
            END
            ELSE IF @ActionType = 'UPDATEPERMISSION'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PermissionSP]
                      @Action               = @ActionType
                    , @PermissionID         = @parameter_01
                    , @permissionStartDate  = @parameter_04
                    , @permissionEndDate    = @parameter_05
                    , @permissionNote       = @parameter_06
                    , @InIdaraID                      = @idaraID
                    , @entryData            = @entrydata
                    , @hostName             = @hostName;
            END
            ELSE IF @ActionType = 'DELETEPERMISSION'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PermissionSP]
                      @Action                         = @ActionType
                    , @PermissionID                   = @parameter_01
                    , @DistributorPermissionTypeID_FK = @parameter_02
                    , @permissionStartDate            = @parameter_03
                    , @permissionEndDate              = @parameter_04
                    , @permissionNote                 = @parameter_05
                    , @UsersID                        = @parameter_06
                    , @RoleID                         = @parameter_07
                    , @IdaraID                        = @parameter_08
                    , @DeptID                         = @parameter_09
                    , @SectionID                      = @parameter_10
                    , @DivisonID                      = @parameter_11
                    , @distributorID                  = @parameter_12
                    , @searchID                       = @parameter_13
                    , @InIdaraID                      = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName;
            END
            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END


        ----------------------------------------------------------------
        -- PagesManagment
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'PagesManagment'
        BEGIN
            DECLARE @PagesManagmentRequiredAction NVARCHAR(200) =
                CASE
                    WHEN @ActionType IN ('AddProgram') THEN 'ADDPROGRAM'
                    WHEN @ActionType IN ('EditProgram') THEN 'EDITPROGRAM'
                    WHEN @ActionType IN ('DeleteProgram') THEN 'DELETEPROGRAM'
                    WHEN @ActionType IN ('AddMenuList', 'AddPage') THEN 'ADDMENU'
                    WHEN @ActionType IN ('EditMenuList', 'EditPage') THEN 'EDITMENU'
                    WHEN @ActionType IN ('DeleteMenuList', 'DeletePage') THEN 'DELETEMENU'
                    WHEN @ActionType IN ('AddPagePermission') THEN 'ADDPERMISSION'
                    WHEN @ActionType IN ('EditPagePermission') THEN 'EDITPERMISSION'
                    WHEN @ActionType IN ('DeletePagePermission') THEN 'DELETEPERMISSION'
                    ELSE @ActionType
                END;

            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND UPPER(v.permissionTypeName_E) = @PagesManagmentRequiredAction
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'AddProgram'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @programID                       = NULL
                  , @programName_A                   = @parameter_02
                  , @programName_E                   = @parameter_03
                  , @programDescription              = @parameter_04
                  , @programActive                   = NULL
                  , @programLink                     = @parameter_06
                  , @programIcon                     = @parameter_07
                  , @programSerial                   = @parameter_08
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;

            END


            ELSE IF @ActionType = 'EditProgram'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @programID                       = @parameter_01
                  , @programName_A                   = @parameter_02
                  , @programName_E                   = @parameter_03
                  , @programDescription              = @parameter_04
                  , @programActive                   = NULL
                  , @programLink                     = @parameter_06
                  , @programIcon                     = @parameter_07
                  , @programSerial                   = @parameter_08
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END


             ELSE IF @ActionType = 'DeleteProgram'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @programID                       = @parameter_01
                  , @programName_A                   = @parameter_02
                  , @programName_E                   = @parameter_03
                  , @programDescription              = @parameter_04
                  , @programActive                   = @parameter_09
                  , @programLink                     = @parameter_06
                  , @programIcon                     = @parameter_07
                  , @programSerial                   = @parameter_08
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END


               ELSE IF @ActionType = 'AddMenuList'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @programID                       = @parameter_01
                  , @programName_A                   = @parameter_02
                  , @programName_E                   = @parameter_03
                  , @programDescription              = @parameter_04
                  , @programSerial                   = @parameter_05


                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END

            ELSE IF @ActionType = 'EditMenuList'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @programID                       = @parameter_09
                  , @programName_A                   = @parameter_03
                  , @programName_E                   = @parameter_04
                  , @programDescription              = @parameter_07
                  , @programSerial                   = @parameter_10
                  , @menuID                          = @parameter_02
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END

            ELSE IF @ActionType = 'DeleteMenuList'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @programActive                   = @parameter_11
                  , @menuID                          = @parameter_02
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END

            ELSE IF @ActionType = 'AddPage'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @programID                       = @parameter_01
                  , @parentMenuID                    = @parameter_02
                  , @programName_A                   = @parameter_03
                  , @programName_E                   = @parameter_04
                  , @programDescription              = @parameter_05
                  , @programLink                     = @parameter_06
                  , @programSerial                   = @parameter_07
                  , @programActive                   = NULL
                  , @isDashboard                     = NULL
                  , @PageLvl                         = @parameter_10
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END

            ELSE IF @ActionType = 'EditPage'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @menuID                          = @parameter_02
                  , @programName_A                   = @parameter_03
                  , @programName_E                   = @parameter_04
                  , @programDescription              = @parameter_07
                  , @programLink                     = @parameter_06
                  , @parentMenuID                    = @parameter_08
                  , @programID                       = @parameter_09
                  , @programSerial                   = @parameter_10
                  , @isDashboard                     = NULL
                  , @PageLvl                         = @parameter_13
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END

            ELSE IF @ActionType = 'DeletePage'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @menuID                          = @parameter_02
                  , @programActive                   = @parameter_11
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END

            ELSE IF @ActionType = 'AddPagePermission'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @menuID                          = @parameter_02
                  , @permissionTypeName_A            = @parameter_03
                  , @permissionTypeName_E            = @parameter_04
                  , @permissionAuthLvl               = @parameter_05
                  , @programActive                   = NULL
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END

            ELSE IF @ActionType = 'EditPagePermission'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @distributorPermissionTypeID     = @parameter_01
                  , @permissionTypeID                = @parameter_02
                  , @permissionAuthLvl               = @parameter_07
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END

            ELSE IF @ActionType = 'DeletePagePermission'
            BEGIN
               INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PagesManagmentSP]
                    @Action                          = @ActionType
                  , @distributorPermissionTypeID     = @parameter_01
                  , @programActive                   = @parameter_06
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END







            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END



        ----------------------------------------------------------------
        -- Users
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'Users'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERTUSERS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [DBO].[UsersSP]
                    @Action                          = @ActionType
                  , @usersID                         = NULL
                  , @nationalID                      = @parameter_02
                  , @GeneralNo                       = @parameter_03
                  , @firstName_A                     = @parameter_04
                  , @secondName_A                    = @parameter_05
                  , @thirdName_A                     = @parameter_06
                  , @forthName_A                     = @parameter_07
                  , @lastName_A                      = @parameter_08
                  , @firstName_E                     = @parameter_09
                  , @secondName_E                    = @parameter_10
                  , @thirdName_E                     = @parameter_11
                  , @forthName_E                     = @parameter_12
                  , @lastName_E                      = @parameter_13
                  , @UsersAuthTypeID                 = @parameter_14
                  , @userTypeID_FK                   = @parameter_16
                  , @IdaraID                         = @parameter_17
                  , @nationalIDIssueDate             = @parameter_22
                  , @dateOfBirth                     = @parameter_23
                  , @genderID_FK                     = @parameter_24
                  , @nationalityID_FK                = @parameter_25
                  , @religionID_FK                   = @parameter_26
                  , @maritalStatusID_FK              = @parameter_27
                  , @educationID_FK                  = @parameter_28
                  , @userNote                        = @parameter_20
                  , @distributorID                   = @parameter_36
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;

            END


            ELSE IF @ActionType = 'UPDATEUSERS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [DBO].[UsersSP]
                    @Action                          = @ActionType
                  , @usersID                         = @parameter_01
                  , @nationalID                      = @parameter_02
                  , @GeneralNo                       = @parameter_03
                  , @firstName_A                     = @parameter_04
                  , @secondName_A                    = @parameter_05
                  , @thirdName_A                     = @parameter_06
                  , @forthName_A                     = @parameter_07
                  , @lastName_A                      = @parameter_08
                  , @firstName_E                     = @parameter_09
                  , @secondName_E                    = @parameter_10
                  , @thirdName_E                     = @parameter_11
                  , @forthName_E                     = @parameter_12
                  , @lastName_E                      = @parameter_13
                  , @UsersAuthTypeID                 = @parameter_14
                  , @userTypeID_FK                   = @parameter_16
                  , @IdaraID                         = @parameter_17
                  , @nationalIDIssueDate             = @parameter_22
                  , @dateOfBirth                     = @parameter_23
                  , @genderID_FK                     = @parameter_24
                  , @nationalityID_FK                = @parameter_25
                  , @religionID_FK                   = @parameter_26
                  , @maritalStatusID_FK              = @parameter_27
                  , @educationID_FK                  = @parameter_28
                  , @userNote                        = @parameter_35
                  , @distributorID                   = @parameter_36
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;

            END

             

              ELSE IF @ActionType = 'DELETEUSERS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [DBO].[UsersSP]
                    @Action                          = @ActionType
                  , @usersID                         = @parameter_01
                  , @nationalID                      = @parameter_02
                  , @GeneralNo                       = @parameter_03
                  , @firstName_A                     = @parameter_04
                  , @secondName_A                    = @parameter_05
                  , @thirdName_A                     = @parameter_06
                  , @forthName_A                     = @parameter_07
                  , @lastName_A                      = @parameter_08
                  , @firstName_E                     = @parameter_09
                  , @secondName_E                    = @parameter_10
                  , @thirdName_E                     = @parameter_11
                  , @forthName_E                     = @parameter_12
                  , @lastName_E                      = @parameter_13
                  , @UsersAuthTypeID                 = @parameter_14
                  , @userTypeID_FK                   = @parameter_16
                  , @IdaraID                         = @parameter_17
                  , @nationalIDIssueDate             = @parameter_22
                  , @dateOfBirth                     = @parameter_23
                  , @genderID_FK                     = @parameter_24
                  , @nationalityID_FK                = @parameter_25
                  , @religionID_FK                   = @parameter_26
                  , @maritalStatusID_FK              = @parameter_27
                  , @educationID_FK                  = @parameter_28
                  , @userNote                        = @parameter_35
                  , @distributorID                   = @parameter_36
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;

            END

          
              ELSE IF @ActionType = 'RESETUSERPASSWORD'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [DBO].[ReSetUserPassword]
                    @Action                          = @ActionType
                  , @usersID                         = @parameter_01
                  , @NationalID                      = NULL
                  , @PlainPassword                   = NULL
                  , @OldPassword                     = NULL
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;

            END





            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END



        ----------------------------------------------------------------
        -- BuildingType
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'BuildingType'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERTBUILDINGTYPE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingTypeSP]
                      @Action                  = @ActionType
                    , @buildingTypeID          = NULL
                    , @buildingTypeCode        = @parameter_01
                    , @buildingTypeName_A      = @parameter_02
                    , @buildingTypeName_E      = @parameter_03
                    , @buildingTypeDescription = @parameter_04
                    , @idaraID_FK              = @idaraID
                    , @entryData               = @entrydata
                    , @hostName                = @hostName;

               
            END
            ELSE IF @ActionType = 'UPDATEBUILDINGTYPE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingTypeSP]
                      @Action                  = @ActionType
                    , @buildingTypeID          = @parameter_01
                    , @buildingTypeCode        = @parameter_02
                    , @buildingTypeName_A      = @parameter_03
                    , @buildingTypeName_E      = @parameter_04
                    , @buildingTypeDescription = @parameter_10
                    , @idaraID_FK              = @idaraID
                    , @entryData               = @entrydata
                    , @hostName                = @hostName;

             
            END
            ELSE IF @ActionType = 'DELETEBUILDINGTYPE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingTypeSP]
                      @Action         = @ActionType
                    , @buildingTypeID = @parameter_01
                    , @entryData      = @entrydata
                    , @hostName       = @hostName;

                -- (اختياري) إشعار حذف
            END
            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END

        ----------------------------------------------------------------
        -- BuildingClass
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'BuildingClass'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERTBUILDINGCLASS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingClassSP]
                      @Action                   = @ActionType
                    , @BuildingClassName_A      = @parameter_01
                    , @BuildingClassName_E      = @parameter_02
                    , @BuildingClassDescription = @parameter_03
                    , @idaraID_FK               = @idaraID
                    , @entryData                = @entrydata
                    , @hostName                 = @hostName;

               
            END
            ELSE IF @ActionType = 'UPDATEBUILDINGCLASS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingClassSP]
                      @Action                   = @ActionType
                    , @BuildingClassID          = @parameter_01
                    , @BuildingClassName_A      = @parameter_02
                    , @BuildingClassName_E      = @parameter_03
                    , @BuildingClassDescription = @parameter_10
                    , @idaraID_FK               = @idaraID
                    , @entryData                = @entrydata
                    , @hostName                 = @hostName;
            END
            ELSE IF @ActionType = 'DELETEBUILDINGCLASS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingClassSP]
                      @Action          = @ActionType
                    , @BuildingClassID = @parameter_01
                    , @entryData       = @entrydata
                    , @hostName        = @hostName;
            END
            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END

        ----------------------------------------------------------------
        -- BuildingUtilityType
        ----------------------------------------------------------------
      
        ELSE IF @pageName_ = 'BuildingUtilityType'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERTBUILDINGUTILITYTYPE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingUtilityTypeSP]
                      @Action                         = @ActionType
                    , @buildingUtilityTypeName_A      = @parameter_01
                    , @buildingUtilityTypeName_E      = @parameter_02
                    , @buildingUtilityTypeDescription = @parameter_03
                    , @buildingUtilityTypeStartDate   = @parameter_04
                    , @buildingUtilityTypeEndDate     = @parameter_05
                    , @buildingUtilityIsRent          = @parameter_06
                    , @idaraID_FK                     = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName;

                
            END
            ELSE IF @ActionType = 'UPDATEBUILDINGUTILITYTYPE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingUtilityTypeSP]
                      @Action                         = @ActionType
                    , @buildingUtilityTypeID          = @parameter_01
                    , @buildingUtilityTypeName_A      = @parameter_02
                    , @buildingUtilityTypeName_E      = @parameter_03
                    , @buildingUtilityTypeDescription = @parameter_10
                    , @buildingUtilityTypeStartDate   = @parameter_06
                    , @buildingUtilityTypeEndDate     = @parameter_07
                    , @buildingUtilityIsRent          = @parameter_08
                    , @idaraID_FK                     = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName;
            END
            ELSE IF @ActionType = 'DELETEBUILDINGUTILITYTYPE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingUtilityTypeSP]
                      @Action                = @ActionType
                    , @buildingUtilityTypeID = @parameter_01
                    , @entryData             = @entrydata
                    , @hostName              = @hostName;
            END
            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END

        ----------------------------------------------------------------
        -- MilitaryLocation
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'MilitaryLocation'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERTMILITARYLOCATION'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MilitaryLocationSP]
                    @Action                          = @ActionType
                  , @militaryLocationID              = NULL
                  , @militaryLocationCode            = @parameter_01
                  , @militaryAreaCityID_FK           = @parameter_02
                  , @militaryLocationName_A          = @parameter_04
                  , @militaryLocationName_E          = @parameter_05
                  , @militaryLocationCoordinates     = @parameter_06
                  , @militaryLocationDescription     = @parameter_07
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;

               
            END
            ELSE IF @ActionType = 'UPDATEMILITARYLOCATION'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MilitaryLocationSP]
                    @Action                          = @ActionType
                  , @militaryLocationID              = @parameter_01
                  , @militaryLocationCode            = @parameter_02
                  , @militaryAreaCityID_FK           = @parameter_03
                  , @militaryLocationName_A          = @parameter_05
                  , @militaryLocationName_E          = @parameter_06
                  , @militaryLocationCoordinates     = @parameter_07
                  , @militaryLocationDescription     = @parameter_08
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END
            ELSE IF @ActionType = 'DELETEMILITARYLOCATION'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MilitaryLocationSP]
                    @Action                          = @ActionType
                  , @militaryLocationID              = @parameter_01
                  , @militaryLocationCode            = @parameter_02
                  , @militaryAreaCityID_FK           = @parameter_03
                  , @militaryLocationName_A          = @parameter_04
                  , @militaryLocationName_E          = @parameter_05
                  , @militaryLocationCoordinates     = @parameter_06
                  , @militaryLocationDescription     = @parameter_07
                  , @militaryLocationActive          = @parameter_08
                  , @idaraID_FK                      = @idaraID
                  , @entryData                       = @entrydata
                  , @hostName                        = @hostName;
            END
            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END


         ----------------------------------------------------------------
        -- BuildingDetails
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'BuildingDetails'
        BEGIN
          
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERTBUILDINGDETAILS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingDetailsSP]
                    @Action                         = @ActionType
                  , @buildingDetailsNo              = @parameter_02
                  , @buildingDetailsRooms           = @parameter_03
                  , @buildingLevelsCount            = @parameter_04
                  , @buildingDetailsArea            = @parameter_05
                  , @buildingDetailsCoordinates     = @parameter_06
                  , @buildingTypeID_FK              = @parameter_16
                  , @buildingClassID_FK             = @parameter_07
                  , @militaryLocationID_FK          = @parameter_08
                  , @buildingUtilityTypeID_FK       = @parameter_15
                  , @buildingDetailsTel_1           = @parameter_09
                  , @buildingDetailsTel_2           = @parameter_10
                  , @buildingDetailsRemark          = @parameter_14
                  , @buildingDetailsStartDate       = @parameter_13
                  , @buildingDetailsEndDate         = @parameter_18
                  , @buildingRentTypeID_FK          = @parameter_11
                  , @buildingRentAmount             = @parameter_12
                  , @ElectrictyService              = @parameter_19
                  , @WaterService                   = @parameter_20      
                  , @GasService                     = @parameter_21        
                  , @idaraID_FK                     = @idaraID
                  , @entryData                      = @entrydata
                  , @hostName                       = @hostName;
                           
               
            END

              ELSE IF @ActionType = 'UPDATEBUILDINGDETAILS'
            BEGIN
                 INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingDetailsSP]
                    @Action                         = @ActionType
                  , @buildingDetailsID              = @parameter_01
                  , @buildingDetailsNo              = @parameter_02
                  , @buildingDetailsRooms           = @parameter_03
                  , @buildingLevelsCount            = @parameter_04
                  , @buildingDetailsArea            = @parameter_05
                  , @buildingDetailsCoordinates     = @parameter_06
                  , @buildingTypeID_FK              = @parameter_07
                  , @buildingUtilityTypeID_FK       = @parameter_08
                  , @militaryLocationID_FK          = @parameter_09
                  , @buildingClassID_FK             = @parameter_10
                  , @buildingDetailsTel_1           = @parameter_11
                  , @buildingDetailsTel_2           = @parameter_12
                  , @buildingDetailsRemark          = @parameter_16
                  , @buildingDetailsStartDate       = @parameter_15
                  , @buildingDetailsEndDate         = @parameter_18
                  , @buildingRentTypeID_FK          = @parameter_13
                  , @buildingRentAmount             = @parameter_14
                  , @ElectrictyService              = @parameter_19
                  , @WaterService                   = @parameter_20      
                  , @GasService                     = @parameter_21  
                  , @idaraID_FK                     = @idaraID
                  , @entryData                      = @entrydata
                  , @hostName                       = @hostName;

            END

             ELSE IF @ActionType = 'DELETEBUILDINGDETAILS'
            BEGIN
                 INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingDetailsSP]
                    @Action                         = @ActionType
                  , @buildingDetailsID              = @parameter_01
                  , @buildingDetailsNo              = @parameter_02
                  , @buildingDetailsRooms           = @parameter_03
                  , @buildingLevelsCount            = @parameter_04
                  , @buildingDetailsArea            = @parameter_05
                  , @buildingDetailsCoordinates     = @parameter_06
                  , @buildingTypeID_FK              = @parameter_07
                  --, @buildingUtilityTypeID_FK       = @parameter_08
                  , @militaryLocationID_FK          = @parameter_09
                  , @buildingClassID_FK             = @parameter_10
                  , @buildingDetailsTel_1           = @parameter_11
                  , @buildingDetailsTel_2           = @parameter_12
                  , @buildingDetailsRemark          = @parameter_16
                  , @buildingDetailsStartDate       = @parameter_15
                  , @buildingDetailsActive          = @parameter_16
                  , @buildingRentTypeID_FK          = @parameter_13
                  , @buildingRentAmount             = @parameter_14
                  , @ElectrictyService              = @parameter_19
                  , @WaterService                   = @parameter_20      
                  , @GasService                     = @parameter_21  
                  , @idaraID_FK                     = @idaraID
                  , @entryData                      = @entrydata
                  , @hostName                       = @hostName;

            END

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END



        ----------------------------------------------------------------
        -- BuildingDetails
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'Residents'
        BEGIN
          
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERTRESIDENTS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[ResidentsSP]
                    @Action               = @ActionType
                  , @NationalID           = @parameter_01
                  , @generalNo            = @parameter_02
                  , @firstName_A          = @parameter_03
                  , @secondName_A         = @parameter_04
                  , @thirdName_A          = @parameter_05
                  , @lastName_A           = @parameter_06
                  , @firstName_E          = @parameter_07
                  , @secondName_E         = @parameter_08
                  , @thirdName_E          = @parameter_09
                  , @lastName_E           = @parameter_10
                  , @rankID_FK            = @parameter_11
                  , @militaryUnitID_FK    = @parameter_12
                  , @martialStatusID_FK   = @parameter_13
                  , @nationalityID_FK     = @parameter_14
                  , @dependinceCounter    = @parameter_15
                  , @genderID_FK          = @parameter_16
                  , @birthDate            = @parameter_17
                  , @Mobile               = @parameter_18
                  , @notes                = @parameter_19
                  , @idaraID_FK           = @idaraID
                  , @entryData            = @entrydata
                  , @hostName             = @hostName;
                           
               
            END

              ELSE IF @ActionType = 'UPDATERESIDENTS'
            BEGIN
                 INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[ResidentsSP]
                    @Action               = @ActionType
                  , @residentInfoID       = @parameter_01
                  , @NationalID           = @parameter_02
                  , @generalNo            = @parameter_03
                  , @firstName_A          = @parameter_04
                  , @secondName_A         = @parameter_05
                  , @thirdName_A          = @parameter_06
                  , @lastName_A           = @parameter_07
                  , @firstName_E          = @parameter_08
                  , @secondName_E         = @parameter_09
                  , @thirdName_E          = @parameter_10
                  , @lastName_E           = @parameter_11
                  , @rankID_FK            = @parameter_14
                  , @militaryUnitID_FK    = @parameter_16
                  , @martialStatusID_FK   = @parameter_18
                  , @nationalityID_FK     = @parameter_21
                  , @dependinceCounter    = @parameter_20
                  , @genderID_FK          = @parameter_23
                  , @birthDate            = @parameter_25
                  , @Mobile               = @parameter_26
                  , @notes                = @parameter_27
                  , @idaraID_FK           = @idaraID
                  , @entryData            = @entrydata
                  , @hostName             = @hostName;

            END

             ELSE IF @ActionType = 'DELETERESIDENTS'
            BEGIN
                 INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[ResidentsSP]
                    @Action               = @ActionType
                  , @residentInfoID       = @parameter_01
                  , @idaraID_FK           = @idaraID
                  , @entryData            = @entrydata
                  , @hostName             = @hostName;

            END

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END




       ----------------------------------------------------------------
        -- WaitingListByResident
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'WaitingListByResident'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            

            DELETE FROM @Result;

              IF @ActionType = 'INSERTWAITINGLIST'
            BEGIN

           

             IF (
               select count(*) from Housing.V_MoveWaitingList f
               where f.residentInfoID  = @parameter_01 and f.LastActionID is null
            ) > 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا يوجد طلب نقل للمستفيد تحت الاجراء لايمكن عمل اي اجراء الى حين الانتهاء منه';
                GOTO Finish;
            END

                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListByResidentSP]
                    @Action                       = @ActionType
                  , @ActionID                     = NULL
                  , @residentInfoID_FK            = @parameter_01
                  , @NationalID                   = @parameter_02
                  , @GeneralNo                    = @parameter_03
                  , @buildingActionDecisionNo     = @parameter_04
                  , @buildingActionDecisionDate   = @parameter_05
                  , @WaitingClassID               = @parameter_06
                  , @WaitingOrderTypeID           = @parameter_07
                  , @Notes                        = @parameter_08
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                           
               
            END

              ELSE IF @ActionType = 'UPDATEWAITINGLIST'
            BEGIN

          

             IF (
               select count(*) from Housing.V_MoveWaitingList f
               where f.residentInfoID  = @parameter_01 and f.LastActionID is null
            ) > 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا يوجد طلب نقل للمستفيد تحت الاجراء لايمكن عمل اي اجراء الى حين الانتهاء منه';
                GOTO Finish;
            END

                  INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListByResidentSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID_FK            = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingOrderTypeID           = @parameter_08
                  , @Notes                        = @parameter_09
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END

             ELSE IF @ActionType = 'DELETEWAITINGLIST'
            BEGIN

           

             IF (
               select count(*) from Housing.V_MoveWaitingList f
               where f.residentInfoID  = @parameter_01 and f.LastActionID is null
            ) > 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا يوجد طلب نقل للمستفيد تحت الاجراء لايمكن عمل اي اجراء الى حين الانتهاء منه';
                GOTO Finish;
            END

                 INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListByResidentSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID_FK            = @parameter_20
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END



              ELSE IF @ActionType = 'INSERTOCCUBENTLETTER'
            BEGIN


             IF (
               select count(*) from Housing.V_MoveWaitingList f
               where f.residentInfoID  = @parameter_01 and f.LastActionID is null
            ) > 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا يوجد طلب نقل للمستفيد تحت الاجراء لايمكن عمل اي اجراء الى حين الانتهاء منه';
                GOTO Finish;
            END

                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListByResidentSP]
                    @Action                       = @ActionType
                  , @ActionID                     = NULL
                  , @residentInfoID_FK            = @parameter_01
                  , @NationalID                   = @parameter_02
                  , @GeneralNo                    = @parameter_03
                  , @buildingActionDecisionNo     = @parameter_04
                  , @buildingActionDecisionDate   = @parameter_05
                  , @WaitingClassID               = @parameter_06
                  , @WaitingOrderTypeID           = @parameter_07
                  , @Notes                        = @parameter_08
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                           
               
            END

             ELSE IF @ActionType = 'UPDATEOCCUBENTLETTER'
            BEGIN

          

             IF (
               select count(*) from Housing.V_MoveWaitingList f
               where f.residentInfoID  = @parameter_01 and f.LastActionID is null
            ) > 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا يوجد طلب نقل للمستفيد تحت الاجراء لايمكن عمل اي اجراء الى حين الانتهاء منه';
                GOTO Finish;
            END

                  INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListByResidentSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID_FK            = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingOrderTypeID           = @parameter_08
                  , @Notes                        = @parameter_09
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END


             ELSE IF @ActionType = 'DELETEOCCUBENTLETTER'
            BEGIN



             IF (
               select count(*) from Housing.V_MoveWaitingList f
               where f.residentInfoID  = @parameter_01 and f.LastActionID is null
            ) > 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا يوجد طلب نقل للمستفيد تحت الاجراء لايمكن عمل اي اجراء الى حين الانتهاء منه';
                GOTO Finish;
            END

                 INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListByResidentSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID_FK            = @parameter_20
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END

             ELSE IF @ActionType = 'MOVEWAITINGLIST'
            BEGIN


             IF (
               select count(*) from Housing.V_MoveWaitingList f
               where f.residentInfoID  = @parameter_01 and f.LastActionID is null
            ) > 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا يوجد طلب نقل للمستفيد تحت الاجراء لايمكن عمل اي اجراء الى حين الانتهاء منه';
                GOTO Finish;
            END

                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListByResidentSP]
                    @Action                       = @ActionType
                  --, @ActionID                     = @parameter_01
                  , @residentInfoID_FK            = @parameter_01
                  , @NationalID                   = @parameter_02
                  , @GeneralNo                    = @parameter_03
                  , @buildingActionDecisionNo     = @parameter_30
                  , @buildingActionDecisionDate   = @parameter_31
                  --, @WaitingClassID               = @parameter_07
                  --, @WaitingOrderTypeID           = @parameter_08
                  , @Notes                        = @parameter_13
                  , @NewIdaraForMoveWaitingList   = @parameter_12
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;


                   -- إشعار (من الماستر فقط)
                    SET @SendNotif  = 1;
                    SET @NotifTitle = N'طلب نقل سجلات انتظار جديد وارد للادارة 📩';
                    SET @NotifBody  = N'يوجد نقل سجلات انتظار جديد وارد للادارة اضغط هنا للاطلاع عليه';
                    SET @NotifUrl   = N'/Housing/WaitingListMoveList';

                    SET @NotifUserID                 = NULL;
                    SET @NotifDistributorID          = NULL;
                    SET @NotifRoleID                 = NULL;
                    SET @NotifDsdID                  = NULL;
                    SET @NotifPermissionTypeID       = NULL;
                    SET @NotifPermissionTypeIDs      = NULL;
                    SET @NotifIdaraID                = @parameter_12;
                    SET @NotifMenuID                 = 275;
                    SET @NotifStartDate              = NULL;
                    SET @NotifEndDate                = NULL;
                           
            END 


             ELSE IF @ActionType = 'DELETEMOVEWAITINGLIST'
            BEGIN


                 INSERT INTO @Result(IsSuccessful, Message_)
                 EXEC [Housing].[WaitingListByResidentSP]
                      @Action                       = @ActionType
                  , @ActionID                     = @parameter_25
                  , @residentInfoID_FK            = @parameter_01
                  , @NationalID                   = @parameter_02
                  , @GeneralNo                    = @parameter_03
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @Notes                        = @parameter_26
                  , @NewIdaraForMoveWaitingList   = @parameter_10
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

                    SET @SendNotif  = 1;
                    SET @NotifTitle = N'الغاء نقل سجلات انتظار وارد اليكم  ⚠️';
                    SET @NotifBody  = N'تم الغاء نقل سجلات الانتظارالوارد لديكم من قبل الادارة المرسلة اضغط هنا للاطلاع عليه';
                    SET @NotifUrl   = N'/Housing/WaitingListMoveList';


                    SET @NotifUserID                 = NULL;
                    SET @NotifDistributorID          = NULL;
                    SET @NotifRoleID                 = NULL;
                    SET @NotifDsdID                  = NULL;
                    SET @NotifPermissionTypeID       = NULL;
                    SET @NotifPermissionTypeIDs      = NULL;
                    SET @NotifIdaraID                = @parameter_10;
                    SET @NotifMenuID                 = 275;
                    SET @NotifStartDate              = NULL;
                    SET @NotifEndDate                = NULL;

                           

            END





              ELSE IF @ActionType = 'DELETERESIDENTALLWAITINGLIST'
            BEGIN


            

             IF (
               select count(*) from Housing.V_MoveWaitingList f
               where f.residentInfoID  = @parameter_01 and f.LastActionID is null
            ) > 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا يوجد طلب نقل للمستفيد تحت الاجراء لايمكن عمل اي اجراء الى حين الانتهاء منه';
                GOTO Finish;
            END

                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListByResidentSP]
                    @Action                       = @ActionType
                  --, @ActionID                     = @parameter_01
                  , @residentInfoID_FK            = @parameter_01
                  , @NationalID                   = @parameter_02
                  , @GeneralNo                    = @parameter_03
                  , @buildingActionDecisionNo     = @parameter_30
                  , @buildingActionDecisionDate   = @parameter_31
                  , @ActionTypeID                 = @parameter_15
                  --, @WaitingClassID               = @parameter_07
                  --, @WaitingOrderTypeID           = @parameter_08
                  , @Notes                        = @parameter_13
                  --, @NewIdaraForMoveWaitingList   = @parameter_12
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                           
            END 




            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        end



        ----------------------------------------------------------------
        -- WaitingListByResident
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'WaitingListMoveList'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
              
              IF @ActionType = 'MOVEWAITINGLISTREJECT'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListMoveListSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID_FK            = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_06
                  , @buildingActionDecisionDate   = @parameter_07
                  , @Notes                        = @parameter_23
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                  
                  
                    SET @SendNotif  = 1;
                    SET @NotifTitle = N'رفض نقل سجلات انتظار لمستفيد  ⚠️';
                    SET @NotifBody  = N'تم رفض نقل سجلات انتظار لمستفيد من قبل الادارة المرسل اليها اضغط هنا للاطلاع عليه';
                    SET @NotifUrl   = N'/Housing/WaitingListMoveList';

                    SET @NotifUserID                 = NULL;
                    SET @NotifDistributorID          = NULL;
                    SET @NotifRoleID                 = NULL;
                    SET @NotifDsdID                  = NULL;
                    SET @NotifIdaraID                = @parameter_09;
                    SET @NotifMenuID                 = 275;
                    SET @NotifPermissionTypeID       = NULL;
                    SET @NotifPermissionTypeIDs      = NULL;
                    SET @NotifStartDate              = NULL;
                    SET @NotifEndDate                = NULL;
               
            END

              ELSE IF @ActionType = 'MOVEWAITINGLISTAPPROVE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListMoveListSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID_FK            = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_06
                  , @buildingActionDecisionDate   = @parameter_07
                  , @Notes                        = @parameter_23
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

                   SET @SendNotif  = 1;
                    SET @NotifTitle = N'قبول نقل سجلات انتظار لمستفيد  ✔';
                    SET @NotifBody  = N'تم قبول نقل سجلات انتظار للمستفيد صاحب الهوية رقم :'+@parameter_03 +N'من قبل الادارة المرسل اليها';
                    SET @NotifUrl   = N'/Housing/WaitingListByResident?NID='+@parameter_03;

                    SET @NotifUserID                 = NULL;
                    SET @NotifDistributorID          = NULL;
                    SET @NotifRoleID                 = NULL;
                    SET @NotifDsdID                  = NULL;
                    SET @NotifIdaraID                = @parameter_09;
                    SET @NotifMenuID                 = 273;
                    SET @NotifPermissionTypeID       = NULL;
                    SET @NotifPermissionTypeIDs      = NULL;
                    SET @NotifStartDate              = NULL;
                    SET @NotifEndDate                = NULL;
                           
               
            END





            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END


        
        ----------------------------------------------------------------
        -- WaitingList
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'WaitingList'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'MOVETOASSIGNLIST'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[WaitingListSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID_FK            = @parameter_02
                  , @residentName                 = @parameter_15
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                  
               
            END

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END


         ----------------------------------------------------------------
        -- WaitingList
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'OtherWaitingList'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'MOVETOOCCUPENTPROCEDURES'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[OtherWaitingListSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID_FK            = @parameter_02
                  , @residentName                 = @parameter_15
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @buildingDetailsID            = @parameter_20
                  , @Notes                        = @parameter_12
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                  
               
            END

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END



         ----------------------------------------------------------------
        -- Assign
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'Assign'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'OPENASSIGNPERIOD'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AssignSP]
                       @Action              = @ActionType
                     , @Notes               = @parameter_01
                     , @AssignPeriodID      = @parameter_20
                     , @WaitingClassID      = @parameter_21
                     , @idaraID_FK          = @idaraID
                     , @entryData           = @entrydata
                     , @hostName            = @hostName;

            END

            ELSE IF @ActionType = 'CLOSEASSIGNPERIOD'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AssignSP]
                       @Action              = @ActionType
                     , @Notes               = @parameter_01
                     , @AssignPeriodID      = @parameter_20
                     , @WaitingClassID      = @parameter_21
                     , @idaraID_FK          = @idaraID
                     , @entryData           = @entrydata
                     , @hostName            = @hostName;

            END


            ELSE IF @ActionType = 'ASSIGNHOUSE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AssignSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                  
               
            END

             ELSE IF @ActionType = 'CANCLEASSIGNHOUSE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AssignSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18

                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @lastActionTypeID             = @parameter_16
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                  
               
            END

        ELSE IF @ActionType = 'UPDATEASSIGNHOUSE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AssignSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18

                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @lastActionTypeID             = @parameter_16
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                  
               
            END

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END


        
         ----------------------------------------------------------------
        -- ASSIGNSTATUS
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'ASSIGNSTATUS'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'ENDASSIGNPERIOD'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AssignStatusSP]
                       @Action              = @ActionType
                     , @Notes               = @parameter_01
                     , @AssignPeriodID      = @parameter_02
                     , @idaraID_FK          = @idaraID
                     , @entryData           = @entrydata
                     , @hostName            = @hostName;

            END



            ELSE IF @ActionType = 'ASSIGNSTATUS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AssignStatusSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @BuildingActionTypeCases      = @parameter_23
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                  
               
            END

            

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END



        ----------------------------------------------------------------
        -- HousingResident
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'HousingResident'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'HOUSINGESRESIDENTSCUSTDY'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingResidentSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @BuildingActionTypeCases      = @parameter_23
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;


                  if(cast(@parameter_22 as int) > 0)

                  begin
                  SET @SendNotif  = 1;
                  SET @NotifTitle = N'طلب قراءة عدادات جديد بإنتظار الانهاء ⚡';
                  SET @NotifBody  = N'طلب قراءة عدادات جديد للمستفيد '+@parameter_15+N' وارد بانتظار الانهاء اضغط هنا للاطلاع عليه ';
                  SET @NotifUrl   = N'/ElectronicBillSystem/MeterReadForOccubentAndExit';
                  
                  
                  SET @NotifUserID                 = NULL;
                  SET @NotifDistributorID          = NULL;
                  SET @NotifRoleID                 = NULL;
                  SET @NotifDsdID                  = NULL;
                  SET @NotifPermissionTypeID       = NULL;
                  SET @NotifPermissionTypeIDs      = NULL;
                  SET @NotifIdaraID                = @idaraID;
                  SET @NotifMenuID                 = 281;
                  SET @NotifStartDate              = NULL;
                  SET @NotifEndDate                = NULL;


                  END

            END



            ELSE IF @ActionType = 'HOUSINGESRESIDENTS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingResidentSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @OccupentLetterNo             = @parameter_23
                  , @OccupentLetterDate           = @parameter_24
                  , @OccupentDate                 = @parameter_25
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                  
               
            END


            ELSE IF @ActionType = N'CANCELHOUSINGRESIDENT'
BEGIN
    INSERT INTO @Result (IsSuccessful, Message_)
    EXEC [Housing].[HousingResidentSP]
          @Action                       = @ActionType
        , @ActionID                     = @parameter_01
        , @residentInfoID               = @parameter_02
        , @NationalID                   = @parameter_03
        , @GeneralNo                    = @parameter_04
        , @buildingActionDecisionNo     = @parameter_05
        , @buildingActionDecisionDate   = @parameter_06
        , @WaitingClassID               = @parameter_07
        , @WaitingClassName             = @parameter_08
        , @WaitingOrderTypeID           = @parameter_09
        , @WaitingOrderTypeName         = @parameter_10
        , @waitingClassSequence         = @parameter_11
        , @Notes                        = @parameter_12
        , @WaitingListOrder             = @parameter_14
        , @FullName_A                   = @parameter_15
        , @LastActionTypeID             = @parameter_16
        , @buildingDetailsID            = @parameter_18
        , @AssignPeriodID               = @parameter_20
        , @LastActionID                 = @parameter_21
        , @idaraID_FK                   = @idaraID
        , @entryData                    = @entrydata
        , @hostName                     = @hostName;
END;

            

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END


        ----------------------------------------------------------------
        -- MeterReadForOccubentAndExit
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'MeterReadForOccubentAndExit'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'METERREADFOROCCUBENTANDEXIT'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MeterReadForOccubentAndExitSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @meterID                      = @parameter_23
                  , @MeterServiceTypeID           = @parameter_30
                  , @buildingActionRoot           = @parameter_31
                  , @NewMeterReadValue            = @parameter_27  
                  , @ExitDate                     = @parameter_29
                  , @BillsID                      = @parameter_32
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END



            ELSE IF @ActionType = 'UPDATEMETERREADFOROCCUBENTANDEXIT'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MeterReadForOccubentAndExitSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_06
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @meterID                      = @parameter_23
                  , @NewMeterReadValue            = @parameter_27  
                  , @meterReadID                  = @parameter_28  
                  , @ExitDate                     = @parameter_29
                  , @BillsID                      = @parameter_32
                  , @buildingActionRoot           = @parameter_31
                  , @MeterServiceTypeID           = @parameter_30
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                  
               
            END

             ELSE IF @ActionType = 'APPROVEMETERREADFOROCCUBENTANDEXIT'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MeterReadForOccubentAndExitSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @buildingActionDecisionNo     = @parameter_05
                  , @buildingActionDecisionDate   = @parameter_46
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @buildingDetailsNo            = @parameter_19
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @meterID                      = @parameter_23
                  , @NewMeterReadValue            = @parameter_27  
                  , @meterReadID                  = @parameter_28  
                  , @ExitDate                     = @parameter_29
                  , @BillsID                      = @parameter_32
                  , @buildingActionRoot           = @parameter_31
                  , @MeterServiceTypeID           = @parameter_30
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;
                  

                  if(@parameter_31 = 1)
                  begin
                   SET @SendNotif  = 1;
                   SET @NotifTitle = N'تم قراءة العدادات ⚡';
                   SET @NotifBody  = N' تم قراءة العدادات للمستفيد '+@parameter_15+N' اضغط هنا للاطلاع عليه ';
                   SET @NotifUrl   = N'/Housing/HousingResident';
                   
                   
                   SET @NotifUserID                 = NULL;
                   SET @NotifDistributorID          = NULL;
                   SET @NotifRoleID                 = NULL;
                   SET @NotifDsdID                  = NULL;
                   SET @NotifPermissionTypeID       = NULL;
                   SET @NotifPermissionTypeIDs      = NULL;
                   SET @NotifIdaraID                = @idaraID;
                   SET @NotifMenuID                 = 279;
                   SET @NotifStartDate              = NULL;
                   SET @NotifEndDate                = NULL;
                   END


                   
                  if(@parameter_31 = 2)
                  begin
                   SET @SendNotif  = 1;
                   SET @NotifTitle = N'تم قراءة العدادات ⚡';
                   SET @NotifBody  = N' تم قراءة العدادات للمستفيد '+@parameter_15+N' اضغط هنا للاطلاع عليه ';
                   SET @NotifUrl   = N'/Housing/HousingExit?NID='+@parameter_03;
                   
                   
                   SET @NotifUserID                 = NULL;
                   SET @NotifDistributorID          = NULL;
                   SET @NotifRoleID                 = NULL;
                   SET @NotifDsdID                  = NULL;
                   SET @NotifPermissionTypeID       = NULL;
                   SET @NotifPermissionTypeIDs      = NULL;
                   SET @NotifIdaraID                = @idaraID;
                   SET @NotifMenuID                 = 285;
                   SET @NotifStartDate              = NULL;
                   SET @NotifEndDate                = NULL;
                   END
               
            END


            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType1';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END






        ----------------------------------------------------------------
        -- HousingExtend
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'HousingExtend'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'HOUSINGEXTEND'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExtendSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_26
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @buildingDetailsNo            = @parameter_19
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExtendLetterDate             = @parameter_22
                  , @ExtendLetterNo               = @parameter_23
                  , @ExtendStartDate              = @parameter_24
                  , @ExtendEndDate                = @parameter_25
                  , @ExtendTypeID                 = @parameter_27
                  , @OccupentDate                 = @parameter_45
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END



            ELSE IF @ActionType = 'EDITHOUSINGEXTEND'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExtendSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_26
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @buildingDetailsNo            = @parameter_19
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExtendLetterDate             = @parameter_22
                  , @ExtendLetterNo               = @parameter_23
                  , @ExtendStartDate              = @parameter_24
                  , @ExtendEndDate                = @parameter_25
                  , @ExtendTypeID                 = @parameter_27
                  , @OccupentDate                 = @parameter_45
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END
                  
               

               ELSE IF @ActionType = 'CANCELHOUSINGEXTEND'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExtendSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_26
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @buildingDetailsNo            = @parameter_19
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExtendLetterDate             = @parameter_22
                  , @ExtendLetterNo               = @parameter_23
                  , @ExtendStartDate              = @parameter_24
                  , @ExtendEndDate                = @parameter_25
                  , @ExtendTypeID                 = @parameter_27
                  , @OccupentDate                 = @parameter_45
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END
                  

            ELSE IF @ActionType = 'SENDHOUSINGEXTENDTOFINANCE'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExtendSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_26
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @buildingDetailsNo            = @parameter_19
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExtendLetterDate             = @parameter_22
                  , @ExtendLetterNo               = @parameter_23
                  , @ExtendStartDate              = @parameter_24
                  , @ExtendEndDate                = @parameter_25
                  , @ExtendTypeID                 = @parameter_27
                  , @OccupentDate                 = @parameter_45
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;




                   SET @SendNotif  = 1;
                   SET @NotifTitle = N'طلب تدقيق مالي جديد بإنتظار الانهاء  💵';
                   SET @NotifBody  = N'طلب تدقيق مالي جديد للمستفيد '+@parameter_15+N' وارد بانتظار الانهاء اضغط هنا للاطلاع عليه ';
                   SET @NotifUrl   = N'/IncomeSystem/FinancialAuditForExtendAndEvictions';


                   SET @NotifUserID                 = NULL;
                   SET @NotifDistributorID          = NULL;
                   SET @NotifRoleID                 = NULL;
                   SET @NotifDsdID                  = NULL;
                   SET @NotifPermissionTypeID       = NULL;
                   SET @NotifPermissionTypeIDs      = NULL;
                   SET @NotifIdaraID                = @idaraID;
                   SET @NotifMenuID                 = 284;
                   SET @NotifStartDate              = NULL;
                   SET @NotifEndDate                = NULL;

        


            END

             ELSE IF @ActionType = 'ApproveExtend'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExtendSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_26
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @buildingDetailsNo            = @parameter_19
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExtendLetterDate             = @parameter_22
                  , @ExtendLetterNo               = @parameter_23
                  , @ExtendStartDate              = @parameter_24
                  , @ExtendEndDate                = @parameter_25
                  , @ExtendTypeID                 = @parameter_27
                  , @OccupentDate                 = @parameter_45
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END
            

            
             ELSE IF @ActionType = 'EXTENDINSURANCE'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExtendSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_26
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @buildingDetailsNo            = @parameter_19
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExtendLetterDate             = @parameter_22
                  , @ExtendLetterNo               = @parameter_23
                  , @ExtendStartDate              = @parameter_24
                  , @ExtendEndDate                = @parameter_25
                  , @ExtendTypeID                 = @parameter_27
                  , @InsuranceAmount              = @parameter_30 
                  , @Remaining                    = @parameter_28 
                  , @InsuranceAmountWithRemaining = @parameter_31 
                  , @ExtendInsuranceNo            = @parameter_33 
                  , @ExtendInsuranceDate          = @parameter_35
                  , @ExtendInsuranceType          = @parameter_27
                  , @ExtendInsuranceNote          = @parameter_26
                  , @ExtendInsuranceTypeID        = @parameter_34
                  , @OccupentDate                 = @parameter_45
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END
            

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END

        ----------------------------------------------------------------
        -- HousingExit
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'HousingExit'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'HOUSINGEXIT'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExitSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExitDate                     = @parameter_22
                  , @OccupentDate                 = @parameter_43
                  , @FinalExitDate                = @parameter_44
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END



            ELSE IF @ActionType = 'EDITHOUSINGEXIT'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
               EXEC [Housing].[HousingExitSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExitDate                     = @parameter_22
                  , @LastActionTypeID             = @parameter_16
                  , @OccupentDate                 = @parameter_43
                  , @FinalExitDate                = @parameter_44
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END
                  
               

               ELSE IF @ActionType = 'CANCELHOUSINGEXIT'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExitSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExitDate                     = @parameter_22
                  , @OccupentDate                 = @parameter_43
                  , @FinalExitDate                = @parameter_44
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END
                  

            ELSE IF @ActionType = 'SENDHOUSINGEXITTOFINANCE'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExitSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExitDate                     = @parameter_22
                  , @LastActionTypeID             = @parameter_16
                  , @OccupentDate                 = @parameter_43
                  , @FinalExitDate                = @parameter_44
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;



                   SET @SendNotif  = 1;
                   SET @NotifTitle = N'طلب تدقيق مالي جديد بإنتظار الانهاء  💵';
                   SET @NotifBody  = N'طلب تدقيق مالي جديد للمستفيد '+@parameter_15+N' وارد بانتظار الانهاء اضغط هنا للاطلاع عليه ';
                   SET @NotifUrl   = N'/IncomeSystem/FinancialAuditForExtendAndEvictions';


                   SET @NotifUserID                 = NULL;
                   SET @NotifDistributorID          = NULL;
                   SET @NotifRoleID                 = NULL;
                   SET @NotifDsdID                  = NULL;
                   SET @NotifPermissionTypeID       = NULL;
                   SET @NotifPermissionTypeIDs      = NULL;
                   SET @NotifIdaraID                = @idaraID;
                   SET @NotifMenuID                 = 284;
                   SET @NotifStartDate              = NULL;
                   SET @NotifEndDate                = NULL;

            END


               ELSE IF @ActionType = 'HOUSINGEXITPENALTYRECORD'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExitSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExitDate                     = @parameter_22
                  , @PenaltyPrice                 = @parameter_40
                  , @PenaltyReason                = @parameter_31
                  , @BillsID                      = @parameter_41
                  , @OccupentDate                 = @parameter_43
                  , @FinalExitDate                = @parameter_44
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

                  if(cast(@parameter_42 as int) > 0)

                  begin
                   SET @SendNotif  = 1;
                   SET @NotifTitle = N'طلب قراءة عدادات جديد بإنتظار الانهاء ⚡';
                   SET @NotifBody  = N'طلب قراءة عدادات جديد للمستفيد '+@parameter_15+N' وارد بانتظار الانهاء اضغط هنا للاطلاع عليه ';
                   SET @NotifUrl   = N'/ElectronicBillSystem/MeterReadForOccubentAndExit?U='+@parameter_02;


                   SET @NotifUserID                 = NULL;
                   SET @NotifDistributorID          = NULL;
                   SET @NotifRoleID                 = NULL;
                   SET @NotifDsdID                  = NULL;
                   SET @NotifPermissionTypeID       = NULL;
                   SET @NotifPermissionTypeIDs      = NULL;
                   SET @NotifIdaraID                = @idaraID;
                   SET @NotifMenuID                 = 281;
                   SET @NotifStartDate              = NULL;
                   SET @NotifEndDate                = NULL;

                END

            END

            ELSE IF @ActionType = 'APPROVEHOUSINGEXIT'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingExitSP]
                    @Action                       = @ActionType
                  , @ActionID                     = @parameter_01
                  , @residentInfoID               = @parameter_02
                  , @NationalID                   = @parameter_03
                  , @GeneralNo                    = @parameter_04
                  , @WaitingClassID               = @parameter_07
                  , @WaitingClassName             = @parameter_08
                  , @WaitingOrderTypeID           = @parameter_09
                  , @WaitingOrderTypeName         = @parameter_10
                  , @Notes                        = @parameter_12
                  , @FullName_A                   = @parameter_15
                  , @buildingDetailsID            = @parameter_18
                  , @AssignPeriodID               = @parameter_20
                  , @LastActionID                 = @parameter_21
                  , @ExitDate                     = @parameter_22
                  , @LastActionTypeID             = @parameter_16
                  , @OccupentDate                 = @parameter_43
                  , @FinalExitDate                = @parameter_44
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END
            

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END


          ----------------------------------------------------------------
        -- FinancialAuditForExtendAndEvictions
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'FinancialAuditForExtendAndEvictions'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'FINANCIALAUDITFOREXTENDANDEVICTIONS'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[FinancialAuditForExtendAndEvictionsSP]
                    @Action                             = @ActionType
                  , @ActionID                           = @parameter_22
                  , @residentInfoID                     = @parameter_02
                  , @Notes                              = @parameter_11
                  , @buildingDetailsID                  = @parameter_03
                  , @LastActionID                       = @parameter_21
                  , @LastActionTypeID                   = @parameter_16
                  , @LastActionExtendReasonTypeID       = @parameter_40
                  , @occupentDate                       = @parameter_35
                  , @ExitDate                           = @parameter_36
                  , @idaraID_FK                         = @idaraID
                  , @entryData                          = @entrydata
                  , @hostName                           = @hostName;


                  Declare @residentFullNameForFINANCIALAUDITFOREXTENDANDEVICTIONS nvarchar(2000),@residentNIDForFINANCIALAUDITFOREXTENDANDEVICTIONS nvarchar(2000)
                  set @residentFullNameForFINANCIALAUDITFOREXTENDANDEVICTIONS =
                  (
                  select r.FullName_A from Housing.V_GetFullResidentDetails r where r.residentInfoID = @parameter_02
                  )

                  set @residentNIDForFINANCIALAUDITFOREXTENDANDEVICTIONS =
                  (
                  select r.NationalID from Housing.V_GetFullResidentDetails r where r.residentInfoID = @parameter_02
                  )

                  if(@parameter_16 = 57)
                  BEGIN

                   

                SET @SendNotif  = 1;
                SET @NotifTitle = N'انتهاء التدقيق المالي 🎉';
                SET @NotifBody  = N'انتهى التدقيق المالي للمستفيد '+@residentFullNameForFINANCIALAUDITFOREXTENDANDEVICTIONS+N' اضغط هنا لانهاء اجراءات الاخلاء الان ';
                SET @NotifUrl   = N'/Housing/HousingExit?NID='+@residentNIDForFINANCIALAUDITFOREXTENDANDEVICTIONS;


                SET @NotifUserID                 = NULL;
                SET @NotifDistributorID          = NULL;
                SET @NotifRoleID                 = NULL;
                SET @NotifDsdID                  = NULL;
                SET @NotifPermissionTypeID       = NULL;
                SET @NotifPermissionTypeIDs      = NULL;
                SET @NotifIdaraID                = @idaraID;
                SET @NotifMenuID                 = 285;
                SET @NotifStartDate              = NULL;
                SET @NotifEndDate                = NULL;




                  END



                   if(@parameter_16 = 51)
                  BEGIN

                   

                SET @SendNotif  = 1;
                SET @NotifTitle = N'انتهاء التدقيق المالي 🎉';
                SET @NotifBody  = N'انتهى التدقيق المالي للمستفيد '+@residentFullNameForFINANCIALAUDITFOREXTENDANDEVICTIONS+N' اضغط هنا لانهاء اجراءات الامهال الان ';
                SET @NotifUrl   = N'/Housing/HousingExtend';


                SET @NotifUserID                 = NULL;
                SET @NotifDistributorID          = NULL;
                SET @NotifRoleID                 = NULL;
                SET @NotifDsdID                  = NULL;
                SET @NotifPermissionTypeID       = NULL;
                SET @NotifPermissionTypeIDs      = NULL;
                SET @NotifIdaraID                = @idaraID;
                SET @NotifMenuID                 = 285;
                SET @NotifStartDate              = NULL;
                SET @NotifEndDate                = NULL;




               END

            END

              ELSE IF @ActionType = 'PAYMENTANDREFUNDFOREXTENDANDEXIT'
            BEGIN
                        INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[FinancialAuditForExtendAndEvictionsSP]
                    @Action                             = @ActionType
                  , @ActionID                           = @parameter_22
                  , @residentInfoID                     = @parameter_02
                  , @Notes                              = null
                  , @buildingDetailsID                  = @parameter_05
                  , @LastActionID                       = @parameter_21
                  , @PaymentType                        = @parameter_12
                  , @PaymentNo                          = @parameter_13
                  , @PaymentDate                        = @parameter_14
                  , @Amount                             = @parameter_09
                  , @BillChargeTypeID_FK                = @parameter_03
                  --, @FromBillChargeTypeID_FK            = @parameter_
                  , @description                        = @parameter_27
                  , @idaraID_FK                         = @idaraID
                  , @entryData                          = @entrydata
                  , @hostName                           = @hostName;

            END


             ELSE IF @ActionType = 'FINANCIALSETTLEMENT'
            BEGIN
                        INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[FinancialAuditForExtendAndEvictionsSP]
                    @Action                             = @ActionType
                  , @ActionID                           = @parameter_22
                  , @residentInfoID                     = @parameter_02
                  , @Notes                              = null
                  , @buildingDetailsID                  = @parameter_05
                  , @LastActionID                       = @parameter_21
                  , @PaymentType                        = @parameter_12
                  --, @PaymentNo                          = @parameter_13
                  --, @PaymentDate                        = @parameter_14
                  , @Amount                             = @parameter_39
                  , @FullRemining                       = @parameter_09
                  , @BillChargeTypeID_FK                = @parameter_03
                  , @ToBillChargeTypeID_FK              = @parameter_30
                  , @description                        = @parameter_27
                  , @idaraID_FK                         = @idaraID
                  , @entryData                          = @entrydata
                  , @hostName                           = @hostName;

            END


           

            

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END



            ----------------------------------------------------------------
        -- FinancialAuditForUser
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'FinancialAuditForUser'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'FinancialAuditForUser'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[FinancialAuditForUserSP]
                    @Action                             = @ActionType
                  , @ActionID                           = @parameter_22
                  , @residentInfoID                     = @parameter_02
                  , @Notes                              = @parameter_11
                  , @buildingDetailsID                  = @parameter_03
                  , @LastActionID                       = @parameter_21
                  , @LastActionTypeID                   = @parameter_16
                  , @ExitDate                           = @parameter_30
                  , @LastActionExtendReasonTypeID       = @parameter_40
                  , @idaraID_FK                         = @idaraID
                  , @entryData                          = @entrydata
                  , @hostName                           = @hostName;

            END

              ELSE IF @ActionType = 'PAYMENTANDREFUNDFORUSER'
            BEGIN
                        INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[FinancialAuditForUserSP]
                    @Action                             = @ActionType
                  , @ActionID                           = @parameter_22
                  , @residentInfoID                     = @parameter_02
                  , @Notes                              = null
                  , @buildingDetailsID                  = @parameter_05
                  , @LastActionID                       = @parameter_21
                  , @PaymentType                        = @parameter_12
                  , @PaymentNo                          = @parameter_13
                  , @PaymentDate                        = @parameter_14
                  , @Amount                             = @parameter_09
                  , @BillChargeTypeID_FK                = @parameter_03
                  --, @FromBillChargeTypeID_FK            = @parameter_
                  , @description                        = @parameter_27
                  , @idaraID_FK                         = @idaraID
                  , @entryData                          = @entrydata
                  , @hostName                           = @hostName;

            END


             ELSE IF @ActionType = 'FINANCIALSETTLEMENTFORUSER'
            BEGIN
                        INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[FinancialAuditForUserSP]
                    @Action                             = @ActionType
                  , @ActionID                           = @parameter_22
                  , @residentInfoID                     = @parameter_02
                  , @Notes                              = null
                  , @buildingDetailsID                  = @parameter_05
                  , @LastActionID                       = @parameter_21
                  , @PaymentType                        = @parameter_12
                  --, @PaymentNo                          = @parameter_13
                  --, @PaymentDate                        = @parameter_14
                  , @Amount                             = @parameter_39
                  , @FullRemining                       = @parameter_09
                  , @BillChargeTypeID_FK                = @parameter_03
                  , @ToBillChargeTypeID_FK              = @parameter_30
                  , @description                        = @parameter_27
                  , @idaraID_FK                         = @idaraID
                  , @entryData                          = @entrydata
                  , @hostName                           = @hostName;

            END


           

            

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END

       ----------------------------------------------------------------
        -- MonthlyBillingMonitor
        ----------------------------------------------------------------
       ELSE IF @pageName_ = N'MonthlyBillingMonitor'
        BEGIN
            IF (SELECT COUNT(*) FROM dbo.V_GetListUserPermission v
                WHERE v.userID=@entrydata AND v.menuName_E=@pageName_
                  AND v.permissionTypeName_E=@ActionType) <= 0
            BEGIN
                SET @ok=0; SET @msg=N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
            END;

            DELETE FROM @Result;
            IF @ActionType=N'RETRYMONTHLYBILLING'
            BEGIN
                DECLARE @MonthlyBillingRunID_VALUE BIGINT=TRY_CONVERT(BIGINT,@parameter_01);
                INSERT @Result(IsSuccessful,Message_)
                EXEC Housing.MonthlyBillingMonitorSP
                     @Action=@ActionType
                    ,@MonthlyBillingRunID=@MonthlyBillingRunID_VALUE
                    ,@IdaraID=@idaraID
                    ,@EntryData=@entrydata
                    ,@HostName=@hostName;
            END
            ELSE
            BEGIN
                SET @ok=0; SET @msg=N'نوع العملية المطلوبة غير معروف. ActionType'; GOTO Finish;
            END;
            SELECT TOP(1) @ok=IsSuccessful,@msg=Message_ FROM @Result;
            GOTO Finish;
        END

       ----------------------------------------------------------------
       -- DeductListReport
       ----------------------------------------------------------------
        ELSE IF @pageName_ = N'DeductListReport'
        BEGIN
            IF (SELECT COUNT(*) FROM dbo.V_GetListUserPermission v
                WHERE v.userID=@entrydata AND v.menuName_E=@pageName_
                  AND v.permissionTypeName_E=@ActionType) <= 0
            BEGIN
                SET @ok=0; SET @msg=N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
            END;
            DELETE FROM @Result;
            DECLARE @DeductReportID_VALUE BIGINT=TRY_CONVERT(BIGINT,@parameter_01);
            DECLARE @DeductReportYear_VALUE INT=TRY_CONVERT(INT,@parameter_02);
            DECLARE @DeductReportMonth_VALUE INT=TRY_CONVERT(INT,@parameter_03);
            DECLARE @DeductReportService_VALUE INT=TRY_CONVERT(INT,@parameter_05);
            DECLARE @DeductReportExternalReferenceDate_VALUE DATE=TRY_CONVERT(DATE,@parameter_09);
            INSERT @Result(IsSuccessful,Message_)
            EXEC Housing.DeductListReportSP
                 @Action=@ActionType,@ReportID=@DeductReportID_VALUE
                ,@Year=@DeductReportYear_VALUE,@Month=@DeductReportMonth_VALUE
                ,@BillingType=@parameter_04,@ServiceID=@DeductReportService_VALUE
                ,@CalculationMethod=@parameter_06,@ReportNo=@parameter_07
                ,@ExternalReferenceNo=@parameter_08,@ExternalReferenceDate=@DeductReportExternalReferenceDate_VALUE,@Notes=@parameter_09
                ,@IdaraID=@idaraID,@EntryData=@entrydata,@HostName=@hostName;
            SELECT TOP(1) @ok=IsSuccessful,@msg=Message_ FROM @Result;
            GOTO Finish;
        END

       ----------------------------------------------------------------
        -- Meters
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'Meters'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'INSERTNEWMETERTYPE'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MetersSP]
                     @Action                               = @ActionType
                    ,@meterID                              = null
                    ,@meterTypeID_FK                       = null
                    ,@meterNo                              = null
                    ,@meterName_A                          = null
                    ,@meterName_E                          = null
                    ,@meterDescription                     = null
                    ,@meterStartDate                       = null
                    ,@meterEndDate                         = null
                    ,@meterServiceTypeID                   = @parameter_09
                    ,@meterTypeName_A                      = @parameter_10
                    ,@meterTypeName_E                      = @parameter_11
                    ,@meterTypeConversionFactor            = @parameter_13
                    ,@meterMaxRead                         = @parameter_14
                    ,@meterTypeStartDate                   = @parameter_15
                    ,@meterTypeEndDate                     = @parameter_16
                    ,@meterServicePrice                    = @parameter_17
                    ,@MeterCalculateTypeID                 = @parameter_20
                    ,@MeterTypeFixedAmount                 = @parameter_30
                    ,@meterTypeDescription                 = @parameter_18
                    ,@MeterNote                            = null        
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           
                                                           
                                                           
            END



            ELSE IF @ActionType = 'UPDATENEWMETERTYPE'
            BEGIN 
            
                     INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MetersSP]
                     @Action                               = @ActionType
                    ,@meterID                              = null
                    ,@meterTypeID_FK                       = @parameter_01
                    ,@meterNo                              = null
                    ,@meterName_A                          = null
                    ,@meterName_E                          = null
                    ,@meterDescription                     = null
                    ,@meterStartDate                       = null
                    ,@meterEndDate                         = null
                    ,@meterServiceTypeID                   = @parameter_02
                    ,@meterTypeName_A                      = @parameter_03
                    ,@meterTypeName_E                      = @parameter_04
                    ,@meterTypeConversionFactor            = @parameter_06
                    ,@meterMaxRead                         = @parameter_07
                    ,@meterTypeStartDate                   = @parameter_08
                    ,@meterTypeEndDate                     = @parameter_09
                    ,@meterServicePrice                    = @parameter_15
                    ,@meterTypeDescription                 = @parameter_18
                    ,@MeterCalculateTypeID                 = @parameter_22
                    ,@MeterTypeFixedAmount                 = @parameter_30
                    ,@MeterNote                            = null        
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           

            END
                  
               

                ELSE IF @ActionType = 'DELETENEWMETERTYPE'
            BEGIN 
            
                     INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MetersSP]
                     @Action                               = @ActionType
                    ,@meterTypeID_FK                       = @parameter_01
                    ,@Notes							       = @parameter_18
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           

            END
                  

             ELSE IF @ActionType = 'INSERTNEWMETER'
            BEGIN 
            
                     INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MetersSP]
                     @Action                               = @ActionType
                    ,@meterID                              = null
                    ,@meterTypeID_FK                       = @parameter_02
                    ,@meterNo                              = @parameter_03
                    ,@meterName_A                          = @parameter_04
                    ,@meterName_E                          = @parameter_05
                    ,@meterDescription                     = @parameter_06
                    ,@meterStartDate                       = @parameter_07
                    --,@meterEndDate                         = null
                    ,@meterServiceTypeID                   = @parameter_40
                    ,@meterTypeName_A                      = null
                    ,@meterTypeName_E                      = null
                    ,@meterTypeConversionFactor            = null
                    ,@meterMaxRead                         = null
                    --,@meterTypeStartDate                   = null
                    --,@meterTypeEndDate                     = null
                    ,@meterServicePrice                    = null
                    ,@meterTypeDescription                 = null
                    ,@MeterNote                            = null
                    ,@Notes                                = null
                    ,@meterReadValue                       = @parameter_24
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           

            END

               ELSE IF @ActionType = 'EDITNEWMETER'
            BEGIN 
            
                     INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MetersSP]
                     @Action                               = @ActionType
                    ,@meterID                              = @parameter_01
                    ,@meterTypeID_FK                       = @parameter_02
                    ,@meterNo                              = @parameter_03
                    ,@meterName_A                          = @parameter_04
                    ,@meterName_E                          = @parameter_05
                    ,@meterDescription                     = @parameter_06
                    ,@meterStartDate                       = @parameter_07
                    --,@meterEndDate                         = null
                    ,@meterServiceTypeID                   = @parameter_40
                    ,@meterTypeName_A                      = null
                    ,@meterTypeName_E                      = null
                    ,@meterTypeConversionFactor            = null
                    ,@meterMaxRead                         = null
                    --,@meterTypeStartDate                   = null
                    --,@meterTypeEndDate                     = null
                    ,@meterServicePrice                    = null
                    ,@meterTypeDescription                 = null
                    ,@MeterNote                            = null
                    ,@Notes                                = null
                    ,@meterReadValue                       = @parameter_24
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           

            END


                ELSE IF @ActionType = 'DELETENEWMETER'
            BEGIN 
            
                     INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MetersSP]
                     @Action                               = @ActionType
                    ,@meterID                              = @parameter_01
                    ,@Notes                                = @parameter_45
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           

            END

            
                ELSE IF @ActionType = 'LINKMETERTOBUILDINGS'
            BEGIN 
            
                     INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MetersSP]
                     @Action                               = @ActionType
                    ,@meterID                              = @parameter_04
                    ,@buildingDetailsID_FK                 = @parameter_03
                    ,@Notes                                = @parameter_45
                    ,@meterReadValue                       = @parameter_24
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           

            END

              ELSE IF @ActionType = 'UNLINKMETERTOBUILDINGS'
            BEGIN 
            
                     INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MetersSP]
                     @Action                               = @ActionType
                    ,@meterForBuildingID                   = @parameter_01
                    ,@Notes                                = @parameter_45
                    ,@meterID                              = @parameter_02
                    ,@buildingDetailsID_FK                 = @parameter_03
                    ,@meterReadValue                       = @parameter_24
                    ,@buildingDetailsNo1                   = @parameter_10
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           

            END

            

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END




       ----------------------------------------------------------------
        -- AllMeterRead
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'AllMeterRead'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'OPENMETERREADPERIOD'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AllMeterReadSP]
                     @Action                               = @ActionType
                    ,@MeterServiceTypeID                  = @parameter_01   
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           
                                                           
                                                           
            END



            ELSE IF @ActionType = 'CLOSEMETERREADPERIOD'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AllMeterReadSP]
                     @Action                               = @ActionType
                    ,@MeterServiceTypeID                   = @parameter_02
                    ,@billPeriodID                         = @parameter_01
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           
                                                           
                                                           
            END
                  
               

                ELSE IF @ActionType in( 'READELECTRICITYMETER','READWATERMETER','READGASMETER')
            BEGIN 
            
                     INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AllMeterReadSP]
                     @Action                               = @ActionType
                    ,@MeterServiceTypeID                   = @parameter_01
                    ,@meterID                              = @parameter_02
                    ,@billPeriodID                         = @parameter_03
                    ,@meterReadValue                       = @parameter_04
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           

            END
                  

             ELSE IF @ActionType in(N'EDITELECTRICITYMETER',N'EDITWATERMETER',N'EDITGASMETER')
            BEGIN 
            
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AllMeterReadSP]
                     @Action                               = @ActionType
                    ,@MeterServiceTypeID                   = @parameter_41
                    ,@meterID                              = @parameter_05
                    ,@billPeriodID                         = @parameter_39
                    ,@meterReadValue                       = @parameter_10
                    ,@billsID                              = @parameter_01
                    ,@MeterReadID                          = @parameter_09
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;

            END


              ELSE IF @ActionType in(N'DELETEELECTRICITYMETER',N'DELETEWATERMETER',N'DELETEGASMETER')
            BEGIN 
            
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[AllMeterReadSP]
                     @Action                               = @ActionType
                    ,@MeterServiceTypeID                   = @parameter_41
                    ,@meterID                              = @parameter_05
                    ,@billPeriodID                         = @parameter_39
                    ,@meterReadValue                       = @parameter_10
                    ,@billsID                              = @parameter_01
                    ,@MeterReadID                          = @parameter_09
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;

            END



            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END






        ----------------------------------------------------------------
        -- HousingHandover
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'HousingHandover'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  --AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'HousingHandoverAction'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[HousingHandoverSP]
                    @Action                       = @ActionType
                  , @buildingDetailsID            = @parameter_01
                  , @buildingDetailsNo            = @parameter_02
                  , @LastActionTypeID             = @parameter_10
                  , @NextActionTypeID             = @parameter_07
                  , @LastActionID                 = @parameter_12
                  , @Notes                        = @parameter_11
                  , @idaraID_FK                   = @idaraID
                  , @entryData                    = @entrydata
                  , @hostName                     = @hostName;

            END

            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType1';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END

         ----------------------------------------------------------------
        -- MeterServiceTypeFixedAmount
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'MeterServiceTypeFixedAmount'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'INSERTSERVICEFIXEDAMOUNT'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MeterServiceTypeFixedAmountSP]
                     @Action                               = @ActionType
                    ,@MeterServiceTypeFixedAmountID        = @parameter_01
                    ,@MeterServiceTypeID_FK                = @parameter_02
                    ,@FixedAmount                          = @parameter_03
                    ,@MeterServiceTypeFixedAmountStartDate = @parameter_04
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                 
                                                           
                                                           
                                                           
            END



            ELSE IF @ActionType = 'EDITSERVICEFIXEDAMOUNT'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MeterServiceTypeFixedAmountSP]
                     @Action                               = @ActionType
                    ,@MeterServiceTypeFixedAmountID        = @parameter_01
                    ,@MeterServiceTypeID_FK                = @parameter_02
                    ,@FixedAmount                          = @parameter_03
                    ,@MeterServiceTypeFixedAmountStartDate = @parameter_04
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                                           
                                                           
                                                           
            END
                  
               

                ELSE IF @ActionType ='DELETESERVICEFIXEDAMOUNT'
            BEGIN 
            
                     INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[MeterServiceTypeFixedAmountSP]
                     @Action                               = @ActionType
                    ,@MeterServiceTypeFixedAmountID        = @parameter_01
                    ,@MeterServiceTypeID_FK                = @parameter_02
                    ,@FixedAmount                          = @parameter_03
                    ,@MeterServiceTypeFixedAmountStartDate = @parameter_04
                    ,@IdaraId_FK                           = @idaraID
                    ,@entryData                            = @entrydata
                    ,@hostName                             = @hostName;
                                 
                                                           

            END
                  


            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END



          ----------------------------------------------------------------
        -- RentExemption
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'RentExemption'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'ADDRENTEXEMPTION'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[RentExemptionSP]
                     @Action                            = @ActionType
                    ,@residentRentExemptionID           = null
                    ,@residentRentExemptionTypeID_FK    = @parameter_02
                    ,@residentInfoID_FK                 = @parameter_03
                    ,@residentRentExemptionStartDate    = @parameter_05
                    ,@residentRentExemptionEndDate      = @parameter_06
                    ,@residentRentExemptionDescription  = @parameter_27
                    ,@residentRentExemptionLetterNo     = @parameter_14
                    ,@residentRentExemptionLetterDate   = @parameter_15
                    ,@buildingDetailsID_FK              = @parameter_16
                    ,@buildingDetailsNo                 = @parameter_17
                    ,@idaraID_FK                        = @idaraID
                    ,@entryData                         = @entrydata
                    ,@hostName                          = @hostName;
                                                                             
            END



            ELSE IF @ActionType = 'EDITRENTEXEMPTION'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[RentExemptionSP]
                     @Action                            = @ActionType
                    ,@residentRentExemptionID           = @parameter_01
                    ,@residentRentExemptionTypeID_FK    = @parameter_02
                    ,@residentInfoID_FK                 = @parameter_03
                    ,@residentRentExemptionStartDate    = @parameter_05
                    ,@residentRentExemptionEndDate      = @parameter_06
                    ,@residentRentExemptionDescription  = @parameter_27
                    ,@residentRentExemptionLetterNo     = @parameter_14
                    ,@residentRentExemptionLetterDate   = @parameter_15
                    ,@buildingDetailsID_FK              = @parameter_16
                    ,@buildingDetailsNo                 = @parameter_17
                    ,@idaraID_FK                        = @idaraID
                    ,@entryData                         = @entrydata
                    ,@hostName                          = @hostName;
                    
             END

                ELSE IF @ActionType ='DELETERENTEXEMPTION'
            BEGIN 
            
                     INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[RentExemptionSP]
                     @Action                            = @ActionType
                    ,@residentRentExemptionID           = @parameter_01
                    ,@residentRentExemptionTypeID_FK    = @parameter_02
                    ,@residentInfoID_FK                 = @parameter_03
                    ,@residentRentExemptionStartDate    = @parameter_05
                    ,@residentRentExemptionEndDate      = @parameter_06
                    ,@residentRentExemptionDescription  = @parameter_27
                    ,@residentRentExemptionLetterNo     = @parameter_14
                    ,@residentRentExemptionLetterDate   = @parameter_15
                    ,@buildingDetailsID_FK              = @parameter_16
                    ,@buildingDetailsNo                 = @parameter_17
                    ,@idaraID_FK                        = @idaraID
                    ,@entryData                         = @entrydata
                    ,@hostName                          = @hostName;
                                 
                                                           

            END
                  


            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END


          ----------------------------------------------------------------
        -- ExtendInsurance
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'ExtendInsurance'
        BEGIN
            IF (
                SELECT COUNT(*)
                FROM  dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0;
                SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
                GOTO Finish;
            END

            DELETE FROM @Result;
                             


              IF @ActionType = 'APPROVEEXTENDINSURANCE'
            BEGIN
                      INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[ExtendInsuranceSP]
                     @Action                            = @ActionType
                    ,@ExtendInsuranceID                 = @parameter_01
                    ,@residentInfoID_FK                 = @parameter_03
                    ,@generalNo_FK                      = @parameter_04
                    ,@NationalID                        = @parameter_05
                    ,@unitID                            = @parameter_32
                    ,@FullName                          = @parameter_06
                    ,@buildingDetailsID                 = @parameter_09
                    ,@InsuranceAmountWithRemaining      = @parameter_13
                    ,@ExtendInsuranceIncomeNo           = @parameter_40
                    ,@ExtendInsuranceIncomeDate         = @parameter_41
                    ,@ExtendInsuranceApprovedNote       = @parameter_42
                    ,@idaraID_FK                        = @idaraID
                    ,@entryData                         = @entrydata
                    ,@hostName                          = @hostName;
                                                                             
            END



            ELSE IF @ActionType = 'EDITRENTEXEMPTION'
            BEGIN
                       INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[ExtendInsuranceSP]
                     @Action                            = @ActionType
                    ,@ExtendInsuranceID                 = @parameter_01
                    ,@residentInfoID_FK                 = @parameter_03
                    ,@generalNo_FK                      = @parameter_04
                    ,@NationalID                        = @parameter_05
                    ,@unitID                            = @parameter_32
                    ,@FullName                          = @parameter_06
                    ,@buildingDetailsID                 = @parameter_09
                    ,@InsuranceAmountWithRemaining      = @parameter_13
                    ,@ExtendInsuranceIncomeNo           = @parameter_40
                    ,@ExtendInsuranceIncomeDate         = @parameter_41
                    ,@ExtendInsuranceApprovedNote       = @parameter_42
                    ,@idaraID_FK                        = @idaraID
                    ,@entryData                         = @entrydata
                    ,@hostName                          = @hostName;
                    
             END

              


            ELSE
            BEGIN
                SET @ok = 0;
                SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
                GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END


        ----------------------------------------------------------------
          --نظام الدعم الفني للموقع 
----------------------------------------------------------------

       ----------------------------------------------------------------
        -- SupportMyTickets
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'SupportMyTickets'
        BEGIN
            IF (
                SELECT COUNT(*) FROM dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'SMT_CREATE_TICKET'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [support].[SupportMyTicketsSP]
                      @Action             = @ActionType
                    , @ticketTypeID       = @parameter_01
                    , @priorityID         = @parameter_02
                    , @ticketTitle        = @parameter_03
                    , @ticketDescription  = @parameter_04
                    , @affectedPageName   = @parameter_05
                    , @affectedPageUrl    = @parameter_06
                    , @affectedActionName = @parameter_07
                    , @errorDetails       = @parameter_08
                    , @entryData          = @entrydata
                    , @hostName           = @hostName;
            END
            ELSE
            BEGIN
                SET @ok = 0; SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType'; GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END

        ----------------------------------------------------------------
        -- SupportTicketDetails
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'SupportPhoneTickets'
        BEGIN
            IF (
                SELECT COUNT(*) FROM dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
            END

            DELETE FROM @Result;

            IF @ActionType = 'SPT_CREATE_TICKET'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [support].[SupportPhoneTicketsSP]
                      @Action             = @ActionType
                    , @ticketTypeID       = @parameter_01
                    , @priorityID         = @parameter_02
                    , @ticketTitle        = @parameter_03
                    , @ticketDescription  = @parameter_04
                    , @affectedPageName   = @parameter_05
                    , @affectedPageUrl    = @parameter_06
                    , @affectedActionName = @parameter_07
                    , @errorDetails       = @parameter_08
                    , @callerUserID       = @parameter_09
                    , @entryData          = @entrydata
                    , @hostName           = @hostName;
            END
            ELSE
            BEGIN
                SET @ok = 0; SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType'; GOTO Finish;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END

        ----------------------------------------------------------------
        -- SupportTicketDetails
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'SupportTicketDetails'
        BEGIN
            IF (
                SELECT COUNT(*) FROM dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
            END

            IF @ActionType NOT IN (N'STD_ADD_REPLY', N'STD_CHANGE_STATUS', N'STD_ASSIGN', N'STD_ADD_TASK', N'STD_UPDATE_TASK_STATUS')
            BEGIN
                SET @ok = 0; SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType'; GOTO Finish;
            END

            DELETE FROM @Result;

            INSERT INTO @Result(IsSuccessful, Message_)
            EXEC [support].[SupportTicketDetailsSP]
                  @Action               = @ActionType
                , @ticketID             = @parameter_01
                , @replyText            = @parameter_02
                , @isInternal           = @parameter_03
                , @statusID             = @parameter_04
                , @assignToTeamMemberID = @parameter_05
                , @assignmentNote       = @parameter_06
                , @taskTitle            = @parameter_07
                , @taskDescription      = @parameter_08
                , @taskPriorityID       = @parameter_09
                , @taskAssignToMemberID = @parameter_10
                , @taskDueDate          = @parameter_11
                , @taskID               = @parameter_12
                , @taskStatusID         = @parameter_13
                , @entryData            = @entrydata
                , @hostName             = @hostName;

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END

        ----------------------------------------------------------------
        -- SupportInbox
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'SupportInbox'
        BEGIN
            IF (
                SELECT COUNT(*) FROM dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
            END

            IF @ActionType NOT IN (N'SIN_ASSIGN', N'SIN_CHANGE_STATUS', N'SIN_BULK_ASSIGN')
            BEGIN
                SET @ok = 0; SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType'; GOTO Finish;
            END

            DELETE FROM @Result;

            INSERT INTO @Result(IsSuccessful, Message_)
            EXEC [support].[SupportInboxSP]
                  @Action               = @ActionType
                , @ticketID             = @parameter_01
                , @statusID             = @parameter_02
                , @assignToTeamMemberID = @parameter_03
                , @assignmentNote       = @parameter_04
                , @ticketIDsCsv         = @parameter_05
                , @entryData            = @entrydata
                , @hostName             = @hostName;

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END

        ----------------------------------------------------------------
        -- SupportTeamManagement
        ----------------------------------------------------------------
        ELSE IF @pageName_ = 'SupportTeamManagement'
        BEGIN
            IF (
                SELECT COUNT(*) FROM dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType
            ) <= 0
            BEGIN
                SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
            END

            IF @ActionType NOT IN (N'STM_ADD_MEMBER', N'STM_UPDATE_MEMBER', N'STM_DEACTIVATE_MEMBER', N'STM_ADD_MEMBER_ROLE', N'STM_REMOVE_MEMBER_ROLE')
            BEGIN
                SET @ok = 0; SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType'; GOTO Finish;
            END

            DELETE FROM @Result;

            INSERT INTO @Result(IsSuccessful, Message_)
            EXEC [support].[SupportTeamManagementSP]
                  @Action            = @ActionType
                , @teamMemberID      = @parameter_01
                , @userID            = @parameter_02
                , @canReceiveTickets = @parameter_03
                , @canAssignTickets  = @parameter_04
                , @memberActive      = @parameter_05
                , @teamMemberRoleID  = @parameter_06
                , @roleID            = @parameter_07
                , @entryData         = @entrydata
                , @hostName          = @hostName;

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
            GOTO Finish;
        END



----------------------------------------------------------------
          --العربات 
----------------------------------------------------------------
        ----------------------------------------------------------------
-- Custody_Close
----------------------------------------------------------------
ELSE IF @pageName_ = 'Custody_Close'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[Custody_Close_SP]
              @vehicleWithUsersID = @parameter_01
            , @endDate            = @parameter_02
            , @note               = @parameter_03
            , @entryData          = @entrydata
            , @hostName           = @hostName
            , @idaraID_FK         = @idaraID;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- Custody_Create
----------------------------------------------------------------
ELSE IF @pageName_ = 'Custody_Create'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    DECLARE @Result_CustodyCreate TABLE
    (
          IsSuccessful       INT
        , Message_           NVARCHAR(4000)
        , vehicleWithUsersID INT
    );

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result_CustodyCreate(IsSuccessful, Message_, vehicleWithUsersID)
        EXEC [VIC].[Custody_Create_SP]
              @chassisNumber = @parameter_01
            , @userID_FK      = @parameter_02
            , @startDate      = @parameter_03
            , @note           = @parameter_04
            , @entryData      = @entrydata
            , @hostName       = @hostName
            , @idaraID_FK     = @idaraID;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result_CustodyCreate;
    GOTO Finish;
END

----------------------------------------------------------------
-- Custody_Transfer
----------------------------------------------------------------
ELSE IF @pageName_ = 'Custody_Transfer'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    DECLARE @Result_CustodyTransfer TABLE
    (
          IsSuccessful             INT
        , Message_                 NVARCHAR(4000)
        , ClosedVehicleWithUsersID INT
        , NewVehicleWithUsersID    INT
    );

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result_CustodyTransfer(IsSuccessful, Message_, ClosedVehicleWithUsersID, NewVehicleWithUsersID)
        EXEC [VIC].[Custody_Transfer_SP]
              @chassisNumber = @parameter_01
            , @toUserID_FK    = @parameter_02
            , @transferDate   = @parameter_03
            , @note           = @parameter_04
            , @entryData      = @entrydata
            , @hostName       = @hostName
            , @idaraID_FK     = @idaraID;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result_CustodyTransfer;
    GOTO Finish;
END

----------------------------------------------------------------
-- Handover_Create
----------------------------------------------------------------
ELSE IF @pageName_ = 'Handover_Create'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[Handover_Create_SP]
              @requestID      = @parameter_01
            , @handoverTypeID = @parameter_02
            , @handoverDate   = @parameter_03
            , @note           = @parameter_04
            , @idaraID_FK     = @idaraID
            , @entryData      = @entrydata
            , @hostName       = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- HandoverType
----------------------------------------------------------------
ELSE IF @pageName_ = 'HandoverType'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[HandoverType_Upsert_SP]
              @handoverTypeID     = NULL
            , @handoverTypeName_A = @parameter_01
            , @handoverTypeName_E = @parameter_02
            , @active             = @parameter_03
            , @entryData          = @entrydata
            , @hostName           = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[HandoverType_Upsert_SP]
              @handoverTypeID     = @parameter_01
            , @handoverTypeName_A = @parameter_02
            , @handoverTypeName_E = @parameter_03
            , @active             = @parameter_04
            , @entryData          = @entrydata
            , @hostName           = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- MaintenanceDetails_Delete
----------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenanceDetails_Delete'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'DELETE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenanceDetails_Delete_SP]
              @maintDetailesID = @parameter_01
            , @idaraID_FK      = @idaraID
            , @entryData       = @entrydata
            , @hostName        = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- MaintenanceTemplate_Delete
----------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenanceTemplate_Delete'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'DELETE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenanceTemplate_Delete_SP]
              @TemplateID = @parameter_01
            , @entryData  = @entrydata
            , @hostName   = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END
----------------------------------------------------------------
-- MaintenanceTemplate_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenanceTemplate_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenanceTemplate_Upsert_SP]
              @TemplateID        = NULL
            , @MaintOrdTypeID_FK = @parameter_01
            , @typesID_FK        = @parameter_02
            , @TemplateOrder     = @parameter_03
            , @active            = @parameter_04
            , @entryData         = @entrydata
            , @hostName          = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenanceTemplate_Upsert_SP]
              @TemplateID        = @parameter_01
            , @MaintOrdTypeID_FK = @parameter_02
            , @typesID_FK        = @parameter_03
            , @TemplateOrder     = @parameter_04
            , @active            = @parameter_05
            , @entryData         = @entrydata
            , @hostName          = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- MaintenanceDetails_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenanceDetails_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenanceDetails_Upsert_SP]
              @maintDetailesID  = NULL
            , @maintOrdID       = @parameter_01
            , @typesID          = @parameter_02
            , @supportID        = @parameter_03
            , @checkStatus      = @parameter_04
            , @actionState      = @parameter_05
            , @correctiveAction = @parameter_06
            , @fsn              = @parameter_07
            , @maintLevel       = @parameter_08
            , @currentDate      = @parameter_09
            , @notes            = @parameter_10
            , @idaraID_FK       = @idaraID
            , @entryData        = @entrydata
            , @hostName         = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenanceDetails_Upsert_SP]
              @maintDetailesID  = @parameter_01
            , @maintOrdID       = @parameter_02
            , @typesID          = @parameter_03
            , @supportID        = @parameter_04
            , @checkStatus      = @parameter_05
            , @actionState      = @parameter_06
            , @correctiveAction = @parameter_07
            , @fsn              = @parameter_08
            , @maintLevel       = @parameter_09
            , @currentDate      = @parameter_10
            , @notes            = @parameter_11
            , @idaraID_FK       = @idaraID
            , @entryData        = @entrydata
            , @hostName         = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- MaintenanceOrder_Close
----------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenanceOrder_Close'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenanceOrder_Close_SP]
              @maintOrdID = @parameter_01
            , @endDate    = @parameter_02
            , @idaraID_FK = @idaraID
            , @entryData  = @entrydata
            , @hostName   = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- MaintenanceOrder_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenanceOrder_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenanceOrder_Upsert_SP]
              @maintOrdID     = NULL
            , @maintOrdTypeID = @parameter_01
            , @chassisNumber  = @parameter_02
            , @startDate      = @parameter_03
            , @endDate        = @parameter_04
            , @desc           = @parameter_05
            , @active         = @parameter_06
            , @idaraID_FK     = @idaraID
            , @entryData      = @entrydata
            , @hostName       = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenanceOrder_Upsert_SP]
              @maintOrdID     = @parameter_01
            , @maintOrdTypeID = @parameter_02
            , @chassisNumber  = @parameter_03
            , @startDate      = @parameter_04
            , @endDate        = @parameter_05
            , @desc           = @parameter_06
            , @active         = @parameter_07
            , @idaraID_FK     = @idaraID
            , @entryData      = @entrydata
            , @hostName       = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END
----------------------------------------------------------------
-- MaintenancePlan_AutoGenerate
----------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenancePlan_AutoGenerate'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenancePlan_AutoGenerate_SP]
              @idaraID_FK = @idaraID
            , @entryData  = @entrydata
            , @hostName   = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END
----------------------------------------------------------------
-- MaintenancePlan_SetActive
----------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenancePlan_SetActive'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenancePlan_SetActive_SP]
              @planID      = @parameter_01
            , @active      = @parameter_02
            , @idaraID_FK  = @idaraID
            , @entryData   = @entrydata
            , @hostName    = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END
----------------------------------------------------------------
-- MaintenancePlan_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenancePlan_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenancePlan_Upsert_SP]
              @planID        = NULL
            , @chassisNumber = @parameter_01
            , @periodMonths  = @parameter_02
            , @nextDueDate   = @parameter_03
            , @active        = @parameter_04
            , @idaraID_FK    = @idaraID
            , @entryData     = @entrydata
            , @hostName      = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[MaintenancePlan_Upsert_SP]
              @planID        = @parameter_01
            , @chassisNumber = @parameter_02
            , @periodMonths  = @parameter_03
            , @nextDueDate   = @parameter_04
            , @active        = @parameter_05
            , @idaraID_FK    = @idaraID
            , @entryData     = @entrydata
            , @hostName      = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- Scrap_Action
----------------------------------------------------------------
ELSE IF @pageName_ = 'Scrap_Action'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType IN ('APPROVE', 'CANCEL')
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[Scrap_Action_SP]
              @Action         = @ActionType
            , @ScrapID        = @parameter_01
            , @idaraID_FK     = @idaraID
            , @actionByUserID = @parameter_02
            , @actionNote     = @parameter_03
            , @entryData      = @entrydata
            , @hostName       = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- Scrap_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'Scrap_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DECLARE @Result_ScrapUpsert TABLE
    (
          IsSuccessful INT
        , Message_     NVARCHAR(4000)
        , ScrapID      BIGINT
    );

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result_ScrapUpsert(IsSuccessful, Message_, ScrapID)
        EXEC [VIC].[Scrap_Upsert_SP]
              @ScrapID        = NULL
            , @chassisNumber  = @parameter_01
            , @idaraID_FK     = @idaraID
            , @ScrapDate      = @parameter_02
            , @ScrapTypeID_FK = @parameter_03
            , @RefNo          = @parameter_04
            , @Reason         = @parameter_05
            , @Note           = @parameter_06
            , @Notes          = @parameter_07
            , @entryData      = @entrydata
            , @hostName       = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result_ScrapUpsert(IsSuccessful, Message_, ScrapID)
        EXEC [VIC].[Scrap_Upsert_SP]
              @ScrapID        = @parameter_01
            , @chassisNumber  = @parameter_02
            , @idaraID_FK     = @idaraID
            , @ScrapDate      = @parameter_03
            , @ScrapTypeID_FK = @parameter_04
            , @RefNo          = @parameter_05
            , @Reason         = @parameter_06
            , @Note           = @parameter_07
            , @Notes          = @parameter_08
            , @entryData      = @entrydata
            , @hostName       = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_
    FROM @Result_ScrapUpsert;

    GOTO Finish;
END


----------------------------------------------------------------
-- TransferRequest_Approve
----------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequest_Approve'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[TransferRequest_Approve_SP]
              @requestID  = @parameter_01
            , @actionBy   = @parameter_02
            , @note       = @parameter_03
            , @hostName   = @hostName
            , @idaraID_FK = @idaraID;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- TransferRequest_Cancel
----------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequest_Cancel'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'DELETE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[TransferRequest_Cancel_SP]
              @requestID  = @parameter_01
            , @actionBy   = @parameter_02
            , @note       = @parameter_03
            , @hostName   = @hostName
            , @idaraID_FK = @idaraID;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- TransferRequest_Close
----------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequest_Close'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'CLOSE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[TransferRequest_Close_SP]
              @requestID  = @parameter_01
            , @actionBy   = @parameter_02
            , @note       = @parameter_03
            , @hostName   = @hostName
            , @idaraID_FK = @idaraID;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- TransferRequest_Create
----------------------------------------------------------------
----------------------------------------------------------------
-- TransferRequest_Create
----------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequest_Create'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    DECLARE @Result_TransferRequest_Create TABLE
    (
          IsSuccessful INT
        , Message_     NVARCHAR(4000)
        , RequestID    INT
    );

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result_TransferRequest_Create(IsSuccessful, Message_, RequestID)
        EXEC [VIC].[TransferRequest_Create_SP]
              @requestTypeID = @parameter_01
            , @chassisNumber = @parameter_02
            , @fromUserID    = @parameter_03
            , @toUserID      = @parameter_04
            , @deptID        = @parameter_05
            , @createByUser  = @parameter_06
            , @note          = @parameter_07
            , @idaraID_FK    = @idaraID
            , @entryData     = @entrydata
            , @hostName      = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result_TransferRequest_Create;
    GOTO Finish;
END

----------------------------------------------------------------
-- TransferRequest_Execute
----------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequest_Execute'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    DECLARE @Result_TransferRequest_Execute TABLE
    (
          IsSuccessful       INT
        , Message_           NVARCHAR(4000)
        , vehicleWithUsersID INT
    );

    IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result_TransferRequest_Execute(IsSuccessful, Message_, vehicleWithUsersID)
        EXEC [VIC].[TransferRequest_Execute_SP]
              @requestID  = @parameter_01
            , @entryData  = @entrydata
            , @hostName   = @hostName
            , @idaraID_FK = @idaraID
            , @note       = @parameter_02;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result_TransferRequest_Execute;
    GOTO Finish;
END

----------------------------------------------------------------
-- TransferRequest_Reject
----------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequest_Reject'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[TransferRequest_Reject_SP]
              @requestID  = @parameter_01
            , @actionBy   = @parameter_02
            , @note       = @parameter_03
            , @hostName   = @hostName
            , @idaraID_FK = @idaraID;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- TransferRequestType
----------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequestType'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[TransferRequestType_Upsert_SP]
              @vehicleTransferRequestTypeID = NULL
            , @nameA                        = @parameter_01
            , @nameE                        = @parameter_02
            , @active                       = @parameter_03;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[TransferRequestType_Upsert_SP]
              @vehicleTransferRequestTypeID = @parameter_01
            , @nameA                        = @parameter_02
            , @nameE                        = @parameter_03
            , @active                       = @parameter_04;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- TypesRoot_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'TypesRoot_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[TypesRoot_Upsert_SP]
              @typesID            = NULL
            , @typesName_A        = @parameter_01
            , @typesName_E        = @parameter_02
            , @typesDesc          = @parameter_03
            , @typesActive        = @parameter_04
            , @typesStartDate     = @parameter_05
            , @typesEndDate       = @parameter_06
            , @typesRoot_ParentID = @parameter_07
            , @entryData          = @entrydata
            , @hostName           = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[TypesRoot_Upsert_SP]
              @typesID            = @parameter_01
            , @typesName_A        = @parameter_02
            , @typesName_E        = @parameter_03
            , @typesDesc          = @parameter_04
            , @typesActive        = @parameter_05
            , @typesStartDate     = @parameter_06
            , @typesEndDate       = @parameter_07
            , @typesRoot_ParentID = @parameter_08
            , @entryData          = @entrydata
            , @hostName           = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- Vehicle_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'Vehicle_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    -- ملاحظة: VIC.Vehicle_Upsert_SP يرجّع 3 أعمدة (IsSuccessful, Message_, chassisNumber)
    DECLARE @Result_VehicleUpsert TABLE
    (
          IsSuccessful  INT
        , Message_      NVARCHAR(4000)
        , chassisNumber NVARCHAR(100)
    );

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result_VehicleUpsert(IsSuccessful, Message_, chassisNumber)
        EXEC [VIC].[Vehicle_Upsert_SP]
              @UsersID               = @entrydata
            , @MenuLink              = NULL
            , @SkipPermission        = 1
            , @chassisNumber         = @parameter_01
            , @ownerID_FK            = @parameter_02
            , @ManufacturerNameID_FK = @parameter_03
            , @vehicleModelID_FK     = @parameter_04
            , @vehicleClassID_FK     = @parameter_05
            , @TypeOfUseID_FK        = @parameter_06
            , @vehicleColorID_FK     = @parameter_07
            , @countryMadeID_FK      = @parameter_08
            , @regstritionTypeID_FK  = @parameter_09
            , @regionID_FK           = @parameter_10
            , @fuelTypeID_FK         = @parameter_11
            , @vehicleTypeID_FK      = @parameter_12
            , @yearModel             = @parameter_13
            , @capacity              = @parameter_14
            , @serialNumber          = @parameter_15
            , @plateLetters          = @parameter_16
            , @plateNumbers          = @parameter_17
            , @armyNumber            = @parameter_18
            , @vehicleNote           = @parameter_19
            , @idaraID_FK            = @idaraID
            , @entryData             = @entrydata
            , @hostName              = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result_VehicleUpsert(IsSuccessful, Message_, chassisNumber)
        EXEC [VIC].[Vehicle_Upsert_SP]
              @UsersID               = @entrydata
            , @MenuLink              = NULL
            , @SkipPermission        = 1
            , @chassisNumber         = @parameter_01
            , @ownerID_FK            = @parameter_02
            , @ManufacturerNameID_FK = @parameter_03
            , @vehicleModelID_FK     = @parameter_04
            , @vehicleClassID_FK     = @parameter_05
            , @TypeOfUseID_FK        = @parameter_06
            , @vehicleColorID_FK     = @parameter_07
            , @countryMadeID_FK      = @parameter_08
            , @regstritionTypeID_FK  = @parameter_09
            , @regionID_FK           = @parameter_10
            , @fuelTypeID_FK         = @parameter_11
            , @vehicleTypeID_FK      = @parameter_12
            , @yearModel             = @parameter_13
            , @capacity              = @parameter_14
            , @serialNumber          = @parameter_15
            , @plateLetters          = @parameter_16
            , @plateNumbers          = @parameter_17
            , @armyNumber            = @parameter_18
            , @vehicleNote           = @parameter_19
            , @idaraID_FK            = @idaraID
            , @entryData             = @entrydata
            , @hostName              = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result_VehicleUpsert;
    GOTO Finish;
END

----------------------------------------------------------------
-- VehicleDocument_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'VehicleDocument_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    -- ملاحظة: VIC.VehicleDocument_Upsert_SP يرجّع 3 أعمدة (IsSuccessful, Message_, vehicleDocumentID)
    DECLARE @Result_VehicleDocument TABLE
    (
          IsSuccessful      INT
        , Message_          NVARCHAR(4000)
        , vehicleDocumentID INT
    );

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result_VehicleDocument(IsSuccessful, Message_, vehicleDocumentID)
        EXEC [VIC].[VehicleDocument_Upsert_SP]
              @vehicleDocumentID     = NULL
            , @chassisNumber         = @parameter_01
            , @vehicleDocumentTypeID = @parameter_02
            , @vehicleDocumentNo     = @parameter_03
            , @StartDate             = @parameter_04
            , @EndDate               = @parameter_05
            , @idaraID_FK            = @idaraID
            , @entryData             = @entrydata
            , @hostName              = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result_VehicleDocument(IsSuccessful, Message_, vehicleDocumentID)
        EXEC [VIC].[VehicleDocument_Upsert_SP]
              @vehicleDocumentID     = @parameter_01
            , @chassisNumber         = @parameter_02
            , @vehicleDocumentTypeID = @parameter_03
            , @vehicleDocumentNo     = @parameter_04
            , @StartDate             = @parameter_05
            , @EndDate               = @parameter_06
            , @idaraID_FK            = @idaraID
            , @entryData             = @entrydata
            , @hostName              = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result_VehicleDocument;
    GOTO Finish;
END

----------------------------------------------------------------
-- VehicleDocumentType_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'VehicleDocumentType_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    -- ملاحظة: VIC.VehicleDocumentType_Upsert_SP يرجّع 3 أعمدة (IsSuccessful, Message_, vehicleDocumentTypeID)
    DECLARE @Result_VehicleDocumentType TABLE
    (
          IsSuccessful           INT
        , Message_               NVARCHAR(4000)
        , vehicleDocumentTypeID  INT
    );

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result_VehicleDocumentType(IsSuccessful, Message_, vehicleDocumentTypeID)
        EXEC [VIC].[VehicleDocumentType_Upsert_SP]
              @vehicleDocumentTypeID = NULL
            , @NameA                 = @parameter_01
            , @NameE                 = @parameter_02
            , @Active                = @parameter_03
            , @entryData             = @entrydata
            , @hostName              = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result_VehicleDocumentType(IsSuccessful, Message_, vehicleDocumentTypeID)
        EXEC [VIC].[VehicleDocumentType_Upsert_SP]
              @vehicleDocumentTypeID = @parameter_01
            , @NameA                 = @parameter_02
            , @NameE                 = @parameter_03
            , @Active                = @parameter_04
            , @entryData             = @entrydata
            , @hostName              = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result_VehicleDocumentType;
    GOTO Finish;
END

----------------------------------------------------------------
-- VehicleInsurance_SetActive
----------------------------------------------------------------
ELSE IF @pageName_ = 'VehicleInsurance_SetActive'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'SETACTIVE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[VehicleInsurance_SetActive_SP]
              @VehicleInsuranceID = @parameter_01
            , @active             = @parameter_02
            , @idaraID_FK          = @idaraID
            , @entryData           = @entrydata
            , @hostName            = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- VehicleInsurance_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'VehicleInsurance_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'UPSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[VehicleInsurance_Upsert_SP]
              @VehicleInsuranceID = @parameter_01
            , @chassisNumber      = @parameter_02
            , @OperationTypeID    = @parameter_03
            , @InsuranceTypeID    = @parameter_04
            , @Source             = @parameter_05
            , @StartInsurance     = @parameter_06
            , @EndInsurance       = @parameter_07
            , @Amount             = @parameter_08
            , @Note               = @parameter_09
            , @active             = @parameter_10
            , @idaraID_FK          = @idaraID
            , @entryData           = @entrydata
            , @hostName            = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- VehicleScrap_Approve
----------------------------------------------------------------
ELSE IF @pageName_ = 'VehicleScrap_Approve'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'APPROVE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[VehicleScrap_Approve_SP]
              @ScrapID          = @parameter_01
            , @ApprovedByUserID = @parameter_02
            , @ApprovedDate     = @parameter_03
            , @entryData        = @entrydata
            , @hostName         = @hostName
            , @idaraID_FK        = @idaraID;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END

----------------------------------------------------------------
-- Violation_SetPayment
----------------------------------------------------------------
ELSE IF @pageName_ = 'Violation_SetPayment'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'PAYMENT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[Violation_SetPayment_SP]
              @violationID  = @parameter_01
            , @PaymentDate  = @parameter_02
            , @entryPayment = @entrydata
            , @hostName     = @hostName
            , @idaraID_FK   = @idaraID;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1
          @ok  = IsSuccessful
        , @msg = Message_
    FROM @Result;

    GOTO Finish;
END
----------------------------------------------------------------
-- Violation_Upsert
----------------------------------------------------------------
ELSE IF @pageName_ = 'Violation_Upsert'
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
        SET @msg = N'عفوا لاتملك صلاحية لهذه العملية';
        GOTO Finish;
    END

    DELETE FROM @Result;

    IF @ActionType = 'INSERT'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[Violation_Upsert_SP]
              @violationID       = NULL
            , @violationTypeID   = @parameter_01
            , @chassisNumber     = @parameter_02
            , @violationDate     = @parameter_03
            , @violationPrice    = @parameter_04
            , @violationLocation = @parameter_05
            , @idaraID_FK        = @idaraID
            , @entryData         = @entrydata
            , @hostName          = @hostName;
    END
    ELSE IF @ActionType = 'UPDATE'
    BEGIN
        INSERT INTO @Result(IsSuccessful, Message_)
        EXEC [VIC].[Violation_Upsert_SP]
              @violationID       = @parameter_01
            , @violationTypeID   = @parameter_02
            , @chassisNumber     = @parameter_03
            , @violationDate     = @parameter_04
            , @violationPrice    = @parameter_05
            , @violationLocation = @parameter_06
            , @idaraID_FK        = @idaraID
            , @entryData         = @entrydata
            , @hostName          = @hostName;
    END
    ELSE
    BEGIN
        SET @ok = 0;
        SET @msg = N'نوع العملية المطلوبة غير معروف. ActionType';
        GOTO Finish;
    END

    SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;
    GOTO Finish;
END
















        ----------------------------------------------------------------
        -- DO NOT TOUCH BELOW THIS LINE
        ----------------------------------------------------------------



         ----------------------------------------------------------------
        -- DO NOT TOUCH
        ----------------------------------------------------------------

         
        ELSE
        BEGIN
            SET @ok = 0;
            SET @msg = N'الصفحة المرسلة مقيدة. PageName';
            GOTO Finish;
        END

Finish:
        IF ISNULL(@ok,0) = 0
        BEGIN
            IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
            SELECT 0 AS IsSuccessful, ISNULL(@msg, N'فشل تنفيذ العملية') AS Message_;
            RETURN;
        END

        IF @tc = 0 AND XACT_STATE() = 1 COMMIT;

        IF @SendNotif = 1
        BEGIN
            BEGIN TRY
                EXEC dbo.Notifications_Create
                      @Title             = @NotifTitle
                    , @Body              = @NotifBody
                    , @Url               = @NotifUrl
                    , @StartDate         = @NotifStartDate
                    , @EndDate           = @NotifEndDate
                    , @UserID            = @NotifUserID
                    , @DistributorID     = @NotifDistributorID
                    , @RoleID            = @NotifRoleID
                    , @DsdID             = @NotifDsdID
                    , @PermissionTypeID  = @NotifPermissionTypeID
                    , @PermissionTypeIDs = @NotifPermissionTypeIDs
                    , @IdaraID           = @NotifIdaraID
                    , @MenuID            = @NotifMenuID
                    , @entryData         = @entrydata
                    , @hostName          = @hostName;
            END TRY
            BEGIN CATCH
            --    SELECT 0 AS IsSuccessful, ISNULL(@msg, N'فشل تنفيذ الاشعار') AS Message_;
            --RETURN;
                -- تجاهل فشل الإشعار
            END CATCH
        END

        SELECT 1 AS IsSuccessful, @msg AS Message_;
        RETURN;

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrNumber INT = ERROR_NUMBER();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        DECLARE @IdCatch BIGINT = NULL;

        IF @tc = 0 AND XACT_STATE() <> 0
            ROLLBACK;

        ----------------------------------------------------------------
        -- ✅ أخطاء العميل (Business) لا نسجلها
        -- (أي رقم بين 50001 و 50999)
        ----------------------------------------------------------------
        IF @ErrNumber BETWEEN 50001 AND 50999
        BEGIN
            SELECT 0 AS IsSuccessful, @ErrMsg AS Message_;
            RETURN;
        END

        ----------------------------------------------------------------
        -- ✅ أخطاء برمجية/غير متوقعة: نسجلها ونرجع رمز
        ----------------------------------------------------------------
        BEGIN TRY
            INSERT INTO  dbo.ErrorLog
            (
                  ERROR_MESSAGE_
                , ERROR_SEVERITY_
                , ERROR_STATE_
                , SP_NAME
                , entryData
                , hostName
            )
            VALUES
            (
                  @ErrMsg
                , @ErrSeverity
                , @ErrState
                , N'[dbo].[Masters_CRUD]'
                , @entrydata
                , @hostName
            );

            SET @IdCatch = SCOPE_IDENTITY();
        END TRY
        BEGIN CATCH
            SET @IdCatch = NULL;
        END CATCH

        IF @IdCatch IS NOT NULL
            SELECT 0 AS IsSuccessful,
                   N'حصل خطأ غير معروف رمز الخطأ : ' + CAST(@IdCatch AS NVARCHAR(200)) AS Message_;
        ELSE
            SELECT 0 AS IsSuccessful,
                   N'حصل خطأ غير معروف ولم يتم تسجيله في ErrorLog' AS Message_;
    END CATCH
END
GO

ALTER PROCEDURE [dbo].[Masters_DataLoad]
      @pageName_      NVARCHAR(400)
    , @idaraID        INT
    , @entrydata      INT
    , @hostname       NVARCHAR(400)
    , @parameter_01   NVARCHAR(4000) = NULL
    , @parameter_02   NVARCHAR(4000) = NULL
    , @parameter_03   NVARCHAR(4000) = NULL
    , @parameter_04   NVARCHAR(4000) = NULL
    , @parameter_05   NVARCHAR(4000) = NULL
    , @parameter_06   NVARCHAR(4000) = NULL
    , @parameter_07   NVARCHAR(4000) = NULL
    , @parameter_08   NVARCHAR(4000) = NULL
    , @parameter_09   NVARCHAR(4000) = NULL
    , @parameter_10   NVARCHAR(4000) = NULL
    , @parameter_11   NVARCHAR(4000) = NULL
    , @parameter_12   NVARCHAR(4000) = NULL
    , @parameter_13   NVARCHAR(4000) = NULL
    , @parameter_14   NVARCHAR(4000) = NULL
    , @parameter_15   NVARCHAR(4000) = NULL
    , @parameter_16   NVARCHAR(4000) = NULL
    , @parameter_17   NVARCHAR(4000) = NULL
    , @parameter_18   NVARCHAR(4000) = NULL
    , @parameter_19   NVARCHAR(4000) = NULL
    , @parameter_20   NVARCHAR(4000) = NULL

AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------------
    --                   START TRY BLOCK
    -------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION;

        Declare @isAdmin int;
        Set @isAdmin =(select top(1) 
        
        isnull(ud.usersAuthTypeID_FK,3) 
        
        from dbo.Users s
        Left JOIN  dbo.UsersDetails ud ON s.usersID = ud.usersID_FK
        left Join  dbo.UsersAuthType ua on ud.usersAuthTypeID_FK = ua.UsersAuthTypeID
        
        where s.usersActive = 1 
        and s.usersID = @entrydata 
        and ud.userActive = 1
        order by s.usersID desc)

          -- User Permission
             SELECT permissionTypeName_E
            FROM dbo.ft_UserPagePermissions(@entrydata, @pageName_);

    -------------------------------------------------------------------
    --                     PAGE: Permission
    -------------------------------------------------------------------
        IF @pageName_ = 'Permission'
        BEGIN
          
            -- Permission Data


            Declare @DsdID bigint,@entryDataIdaraID int
            Set @entryDataIdaraID = (
            select distinct f.IdaraID 
            from dbo.V_GetListUsersInDSD u 
            inner join dbo.V_GetFullStructureForDSD f on u.DSDID = f.DSDID
            where u.usersID = @entrydata)

            --by user
            if(@parameter_01 = 1)
            BEGIN
            SELECT 
                  p.permissionID
                , p.userID
                ,p.distributorID_FK
                ,p.PermissionRoleID
                ,p.IdaraID_FK
                ,p.DSDID_FK
                ,P.deptID
                ,p.secID
                ,p.divID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , CONVERT(NVARCHAR(50), p.permissionEndDate, 23) AS permissionEndDate
                , p.permissionNote
            FROM  dbo.V_GetListUserPermission p
           
            WHERE p.userID = @parameter_02
              AND p.distributorID_FK is null
              AND p.PermissionRoleID is null
              AND p.IdaraID_FK is null
              AND p.DSDID_FK is null
              --AND p.IdaraID_FK = @idaraID
            ORDER BY p.permissionID DESC;
            END
          

            --by Distributors
            else if (@parameter_01 = 2)
            Begin
            SELECT 
                  p.permissionID
                , p.userID
                ,p.distributorID_FK
                ,p.PermissionRoleID
                ,p.IdaraID_FK
                ,p.DSDID_FK
                ,P.deptID
                ,p.secID
                ,p.divID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , CONVERT(NVARCHAR(50), p.permissionEndDate, 23) AS permissionEndDate
                , p.permissionNote
            FROM  dbo.V_GetListUserPermission p
            WHERE  p.distributorID_FK = @parameter_03
               AND p.userID  is null
              AND p.PermissionRoleID is null
              AND p.IdaraID_FK is null
              AND p.DSDID_FK is null
              --AND p.IdaraID_FK = @idaraID
            ORDER BY p.permissionID DESC;
            END

              --by Roles
            else if(@parameter_01 = 3)
            Begin
            SELECT 
                 p.permissionID
                , p.userID
                ,p.distributorID_FK
                ,p.PermissionRoleID
                ,p.IdaraID_FK
                ,p.DSDID_FK
                ,P.deptID
                ,p.secID
                ,p.divID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , CONVERT(NVARCHAR(50), p.permissionEndDate, 23) AS permissionEndDate
                , p.permissionNote
            FROM  dbo.V_GetListUserPermission p
            WHERE p.userID is null
              AND p.distributorID_FK is null
              AND p.PermissionRoleID = @parameter_04
              AND p.IdaraID_FK is null
              AND p.DSDID_FK is null
              --AND p.IdaraID_FK = @idaraID
            ORDER BY p.permissionID DESC;
            END
            
              --by idara
            else if(@parameter_01 = 4)
            Begin
            SELECT 
                 p.permissionID
                , p.userID
                ,p.distributorID_FK
                ,p.PermissionRoleID
                ,p.IdaraID_FK
                ,p.DSDID_FK
                ,P.deptID
                ,p.secID
                ,p.divID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , CONVERT(NVARCHAR(50), p.permissionEndDate, 23) AS permissionEndDate
                , p.permissionNote
            FROM  dbo.V_GetListUserPermission p
            WHERE p.userID is null
              AND p.distributorID_FK is null
              AND p.PermissionRoleID is null
              AND p.IdaraID_FK = @parameter_05
              AND p.DSDID_FK is null
              --AND p.IdaraID_FK = @idaraID
            ORDER BY p.permissionID DESC;
            END

            --by Depts
            else if(@parameter_01 = 5 and @parameter_06 is not null and @parameter_07 is null and @parameter_08 is null)
            Begin
            set @DsdID = (select Top(1) d.DSDID from dbo.DeptSecDiv d where d.idaraID_FK = @entryDataIdaraID and d.deptID_FK = @parameter_06 and d.secID_FK is null and d.divID_FK is null order by d.DSDID desc )
            SELECT 
                 p.permissionID
                , p.userID
                ,p.distributorID_FK
                ,p.PermissionRoleID
                ,p.IdaraID_FK
                ,p.DSDID_FK
                ,P.deptID
                ,p.secID
                ,p.divID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , CONVERT(NVARCHAR(50), p.permissionEndDate, 23) AS permissionEndDate
                , p.permissionNote
            FROM  dbo.V_GetListUserPermission p
            WHERE p.userID is null
              AND p.distributorID_FK is null
              AND p.PermissionRoleID is null
              AND p.IdaraID_FK is null
              AND p.DSDID_FK = @DsdID
              --AND p.IdaraID_FK = @idaraID
            ORDER BY p.permissionID DESC;
            END
           

            --by secs
            else if(@parameter_01 = 5 and @parameter_06 is not null and @parameter_07 is not null and @parameter_08 is null)
            Begin
            set @DsdID = (select Top(1) d.DSDID from dbo.DeptSecDiv d where d.idaraID_FK = @entryDataIdaraID and d.deptID_FK = @parameter_06 and d.secID_FK = @parameter_07 and d.divID_FK is null order by d.DSDID desc )
            SELECT 
                 p.permissionID
                , p.userID
                ,p.distributorID_FK
                ,p.PermissionRoleID
                ,p.IdaraID_FK
                ,p.DSDID_FK
                ,P.deptID
                ,p.secID
                ,p.divID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , CONVERT(NVARCHAR(50), p.permissionEndDate, 23) AS permissionEndDate
                , p.permissionNote
            FROM  dbo.V_GetListUserPermission p
            WHERE p.userID is null
              AND p.distributorID_FK is null
              AND p.PermissionRoleID is null
              AND p.IdaraID_FK is null
              AND p.DSDID_FK = @DsdID
              --AND p.IdaraID_FK = @idaraID
            ORDER BY p.permissionID DESC;
            END

             --by secs
            else if(@parameter_01 = 5 and @parameter_06 is not null and @parameter_07 is not null and @parameter_08 is not null)
            Begin
            set @DsdID = (select Top(1) d.DSDID from dbo.DeptSecDiv d where d.idaraID_FK = @entryDataIdaraID and d.deptID_FK = @parameter_06 and d.secID_FK = @parameter_07 and d.divID_FK = @parameter_08 order by d.DSDID desc )
            SELECT 
                 p.permissionID
                , p.userID
                ,p.distributorID_FK
                ,p.PermissionRoleID
                ,p.IdaraID_FK
                ,p.DSDID_FK
                ,P.deptID
                ,p.secID
                ,p.divID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , CONVERT(NVARCHAR(50), p.permissionEndDate, 23) AS permissionEndDate
                , p.permissionNote
            FROM  dbo.V_GetListUserPermission p
            WHERE p.userID is null
              AND p.distributorID_FK is null
              AND p.PermissionRoleID is null
              AND p.IdaraID_FK is null
              AND p.DSDID_FK = @DsdID
              --AND p.IdaraID_FK = @idaraID
            ORDER BY p.permissionID DESC;
            END

              ELSE
            BEGIN

            SELECT 
                  null permissionID
                , null userID
                ,  null menuName_A
                ,  null permissionTypeName_A
                ,null AS permissionStartDate
                , null AS permissionEndDate
                , null permissionNote
            

            END





            -- Users DDL
             if(@isAdmin = 1)
            BEGIN

            SELECT DISTINCT 
                  CAST(d.usersID AS BIGINT) AS userID_
                , CAST(d.nationalID AS NVARCHAR(20)) + ' - ' + d.FullName+' - ' + s.idaraLongName_A AS FullName
                , d.userTypeID
            FROM  dbo.V_GetFullStructureForDSD f
            INNER JOIN  dbo.V_GetListUsersInDSD d ON f.DSDID = d.DSDID
            inner join  dbo.V_GetFullSystemUsersDetails s on d.usersID = s.usersID
            WHERE  d.usersID IS NOT NULL
            ORDER BY d.userTypeID ASC;
            END

            else if(@isAdmin = 2)
            BEGIN
              SELECT DISTINCT 
                  CAST(d.usersID AS BIGINT) AS userID_
                , CAST(d.nationalID AS NVARCHAR(20)) + ' - ' + d.FullName AS FullName
                , d.userTypeID
            FROM  dbo.V_GetFullStructureForDSD f
            INNER JOIN  dbo.V_GetListUsersInDSD d ON f.DSDID = d.DSDID
            WHERE f.IdaraID = @idaraID 
              AND d.usersID IS NOT NULL
            ORDER BY d.userTypeID ASC;

            END
             else if(@isAdmin = 3)

             BEGIN
               SELECT DISTINCT 
                  CAST(d.usersID AS BIGINT) AS userID_
                , CAST(d.nationalID AS NVARCHAR(20)) + ' - ' + d.FullName AS FullName
                , d.userTypeID
            FROM  dbo.V_GetFullStructureForDSD f
            INNER JOIN  dbo.V_GetListUsersInDSD d ON f.DSDID = d.DSDID
            WHERE f.IdaraID = @idaraID 
              AND d.usersID IS NOT NULL
            ORDER BY d.userTypeID ASC;

             END

            -- Distributors DDL
            
            if(@isAdmin = 1)
            BEGIN

            SELECT d.distributorID, d.distributorName_A
            FROM  dbo.Distributor d
            INNER JOIN  dbo.MenuDistributor md ON d.distributorID = md.distributorID_FK
            inner join  dbo.Menu m on md.menuID_FK = m .menuID
            WHERE d.distributorActive = 1 
              AND md.menuDistributorActive = 1
              and m.PageLvl in (1,2,3);
             END
            else if(@isAdmin = 2)
            BEGIN

            SELECT d.distributorID, d.distributorName_A
            FROM  dbo.Distributor d
            INNER JOIN  dbo.MenuDistributor md ON d.distributorID = md.distributorID_FK
            inner join  dbo.Menu m on md.menuID_FK = m .menuID
            WHERE d.distributorActive = 1 
              AND md.menuDistributorActive = 1 
              and m.PageLvl in (2,3);
             END
              else if(@isAdmin = 3)
            BEGIN

            SELECT d.distributorID, d.distributorName_A
            FROM  dbo.Distributor d
            INNER JOIN  dbo.MenuDistributor md ON d.distributorID = md.distributorID_FK
            inner join  dbo.Menu m on md.menuID_FK = m .menuID
            WHERE d.distributorActive = 1 
              AND md.menuDistributorActive = 1 
              and m.PageLvl in (3);
             END
          

            -- Permission Types DDL
      
          

     if(@isAdmin = 1)
            BEGIN

          
            SELECT 
                  dpt.distributorPermissionTypeID
                , pt.permissionTypeName_A
                , dpt.distributorID_FK
            FROM  dbo.DistributorPermissionType dpt
            INNER JOIN  dbo.PermissionType pt ON dpt.permissionTypeID_FK = pt.permissionTypeID
            WHERE pt.permissionTypeActive = 1 
              AND dpt.distributorPermissionTypeActive = 1
              and dpt.permissionAuthLvl in (1,2,3);
              
             


             END
            else if(@isAdmin = 2) 
            BEGIN

          
            SELECT 
                  dpt.distributorPermissionTypeID
                , pt.permissionTypeName_A
                , dpt.distributorID_FK
            FROM  dbo.DistributorPermissionType dpt
            INNER JOIN  dbo.PermissionType pt ON dpt.permissionTypeID_FK = pt.permissionTypeID
            WHERE pt.permissionTypeActive = 1 
              AND dpt.distributorPermissionTypeActive = 1
              and dpt.permissionAuthLvl in (2,3);


             END
              else if(@isAdmin = 3) 
            BEGIN

          
            SELECT 
                  dpt.distributorPermissionTypeID
                , pt.permissionTypeName_A
                , dpt.distributorID_FK
            FROM  dbo.DistributorPermissionType dpt
            INNER JOIN  dbo.PermissionType pt ON dpt.permissionTypeID_FK = pt.permissionTypeID
            WHERE pt.permissionTypeActive = 1 
              AND dpt.distributorPermissionTypeActive = 1
              and dpt.permissionAuthLvl in (3);


             END



              -- IDara DDL
            SELECT distinct D.idaraID,D.idaraLongName_A 
            FROM  DBO.Idara D
            order by D.idaraID asc


               -- Dept DDL
            SELECT distinct D.deptID,D.deptName_A ,d.idaraID_FK
            FROM  DBO.Department D
            WHERE D.deptActive = 1 and d.idaraID_FK = @idaraID

            -- Section DDL
            SELECT distinct s.secID,s.secName_A,a.deptID
            FROM  DBO.Section s
            inner join  dbo.DeptSecDiv d on s.secID =d.secID_FK
            inner join  dbo.Department a on d.deptID_FK = a.deptID
            WHERE s.secActive = 1 and a.idaraID_FK = @idaraID

            
            -- Divison DDL
            SELECT distinct s.divID,s.divName_A,a.secID
            FROM  DBO.Divison s
            inner join  dbo.DeptSecDiv d on s.divID =d.divID_FK
             inner join  dbo.Section a on d.secID_FK= a.secID
             inner join  dbo.Department dd on d.deptID_FK = dd.deptID
            WHERE s.divActive = 1 AND dd.IdaraID_FK = @idaraID

            -- Role DDL
            select r.roleID,r.roleName_A 
            from  dbo.[Role] r
            
              -- Distributors To give permission DDL
            SELECT d.distributorID, d.distributorName_A
            FROM  dbo.Distributor d
            WHERE d.distributorActive = 1 and d.distributorType_FK = 2 
            and d.DSDID_FK in (select ds.DSDID from dbo.DeptSecDiv ds where ds.idaraID_FK = @entryDataIdaraID)

            -- Programs DDL
            SELECT DISTINCT
                   p.programID,
                   p.programName_A
            FROM dbo.Menu m
            LEFT JOIN dbo.Menu parentMenu
                ON parentMenu.menuID = m.parentMenuID_FK
            INNER JOIN dbo.Program p
                ON p.programID = COALESCE(m.programID_FK, parentMenu.programID_FK)
            INNER JOIN dbo.MenuDistributor md
                ON md.menuID_FK = m.menuID
               AND md.menuDistributorActive = 1
            INNER JOIN dbo.Distributor d
                ON d.distributorID = md.distributorID_FK
               AND d.distributorActive = 1
            WHERE p.programActive = 1
              AND m.menuActive = 1
              AND ISNULL(m.menuLink, '') <> 'MVC'
              AND (
                    (@isAdmin = 1 AND m.PageLvl IN (1, 2, 3))
                 OR (@isAdmin = 2 AND m.PageLvl IN (2, 3))
                 OR (@isAdmin = 3 AND m.PageLvl IN (3))
              )
            ORDER BY p.programName_A;

            -- Pages DDL
            SELECT DISTINCT
                   d.distributorID,
                   m.menuName_A,
                   COALESCE(m.programID_FK, parentMenu.programID_FK) AS programID_FK,
                   m.menuID,
                   m.PageLvl
            FROM dbo.Menu m
            LEFT JOIN dbo.Menu parentMenu
                ON parentMenu.menuID = m.parentMenuID_FK
            INNER JOIN dbo.MenuDistributor md
                ON md.menuID_FK = m.menuID
               AND md.menuDistributorActive = 1
            INNER JOIN dbo.Distributor d
                ON d.distributorID = md.distributorID_FK
               AND d.distributorActive = 1
            WHERE m.menuActive = 1
              AND m.menuLink IS NOT NULL
              AND ISNULL(m.menuLink, '') <> 'MVC'
              AND (
                    (@isAdmin = 1 AND m.PageLvl IN (1, 2, 3))
                 OR (@isAdmin = 2 AND m.PageLvl IN (2, 3))
                 OR (@isAdmin = 3 AND m.PageLvl IN (3))
              )
            ORDER BY m.menuName_A;
          
        END



    -------------------------------------------------------------------
    --                     PAGE: Users
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'Users'
        BEGIN
       EXEC [dbo].[UsersDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    

        END  
    -------------------------------------------------------------------
    --                     PAGE: Home
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'Home'
        BEGIN
            -- User Permission
           EXEC [dbo].[ChartsDL] 
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @UsersID                        = @parameter_01
        END


    -------------------------------------------------------------------
    --                     PAGE: ImportExcelForBuildingPayment
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'ImportExcelForBuildingPayment'
        BEGIN

          EXEC [Housing].[ImportExcelForBuildingPaymentDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName


        --   SELECT  [BillChargeTypeID]
        --          ,[BillChargeTypeName_A]
      
        --FROM [DATACORE].[Housing].[BillChargeType] 
        --where BillChargeTypeActive = 1 and BillChargeTypeID <> 5
        --order by BillChargeTypeID asc


        -- DECLARE @StartYear INT = 2017;
        --DECLARE @EndYear   INT = YEAR(GETDATE());
        
        --;WITH YearsCTE AS
        --(
        --    SELECT @StartYear AS Year_
        --    UNION ALL
        --    SELECT Year_ + 1
        --    FROM YearsCTE
        --    WHERE Year_ + 1 <= @EndYear
        --)
        --SELECT Year_
        --FROM YearsCTE
        --ORDER BY Year_
        --OPTION (MAXRECURSION 100);



        --DECLARE @StartDate DATE = '2017-01-01';
        --DECLARE @EndDate   DATE = EOMONTH(GETDATE());
        
        --;WITH MonthsCTE AS
        --(
        --    SELECT @StartDate AS MonthStart
        --    UNION ALL
        --    SELECT DATEADD(MONTH, 1, MonthStart)
        --    FROM MonthsCTE
        --    WHERE DATEADD(MONTH, 1, MonthStart) <= @EndDate
        --)
        --SELECT
        --    YEAR(MonthStart)  AS Year_,
        --    MONTH(MonthStart) AS MonthNumber,
        --    CASE MONTH(MonthStart)
        --        WHEN 1  THEN N'يناير'
        --        WHEN 2  THEN N'فبراير'
        --        WHEN 3  THEN N'مارس'
        --        WHEN 4  THEN N'أبريل'
        --        WHEN 5  THEN N'مايو'
        --        WHEN 6  THEN N'يونيو'
        --        WHEN 7  THEN N'يوليو'
        --        WHEN 8  THEN N'أغسطس'
        --        WHEN 9  THEN N'سبتمبر'
        --        WHEN 10 THEN N'أكتوبر'
        --        WHEN 11 THEN N'نوفمبر'
        --        WHEN 12 THEN N'ديسمبر'
        --    END AS ArabicMonthName
        --FROM MonthsCTE
        --ORDER BY MonthStart
        --OPTION (MAXRECURSION 1000);
           
           
        END



  -------------------------------------------------------------------
    --                     PAGE: PagesManagment
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'PagesManagment'
        BEGIN

        -- prgrams

            select 
            p.[programID]
           ,p.[programName_A]
           ,p.[programName_E]
           ,p.[programDescription]
           ,case 
           when p.[programActive] = 1 then N'نشط'
           when p.[programActive] = 0 then N'غير نشط'
           END programActive
           ,case 
           when p.[programActive] = 1 then N'1'
           when p.[programActive] = 0 then N'0'
           END programActiveBit
           ,p.[programLink]
           ,p.[programIcon]
           ,p.[programSerial]
           
            From dbo.Program p

            ORDER BY P.programID DESC
            --where programActive = 1



            --SubPrograms
            
              
            select 
          
            m.[menuID]
           ,p.programID
           ,p.programName_A
           ,m.[menuName_A]
           ,m.[menuName_E]
           ,m.[menuDescription]
           ,m.[parentMenuID_FK]
           ,m.[menuLink]
           ,m.[programID_FK]
           ,m.[menuSerial]
           ,m.[menuActive]
           ,m.[isDashboard]
           ,m.[PageLvl]

            from dbo.Menu m
            inner join dbo.Program p on m.programID_FK = p. programID
            where (m.menuLink is null OR m.menuLink = 'MVC') and m.menuID not in
            (select md.menuID_FK from dbo.MenuDistributor md
            inner join dbo.Distributor d on md.distributorID_FK = d.distributorID and d.distributorType_FK = 4
            where d.distributorType_FK = 4 and d.distributorActive = 1)
            order by m.menuID desc




         --Menus
            
              
            select 
            md.menuDistributorID
           , 
           m.[menuID]
           ,m.[menuName_A]
           , d.distributorID
           ,d.distributorName_A
           ,m.[menuName_E]
           ,m.[menuDescription]
           ,m.[parentMenuID_FK]
           ,m.[menuLink]
           ,COALESCE(m.[programID_FK], parentMenu.[programID_FK]) AS programID_FK
           ,m.[menuSerial]
           ,m.[menuActive]
           ,m.[isDashboard]
           ,m.[PageLvl]

            from dbo.Menu m
            left join dbo.Menu parentMenu on parentMenu.menuID = m.parentMenuID_FK
            left join dbo.MenuDistributor md on m.menuID = md.menuID_FK
            left join dbo.Distributor d on d.distributorID = md.distributorID_FK and d.distributorType_FK = 4
            where m.menuLink is not null and m.menuLink <> 'MVC'
            --where m.[menuActive] = 1 
            order by m.menuID desc

            --Permission

           
            SELECT 
       t.[distributorPermissionTypeID]
      ,t.[permissionTypeID_FK]
      ,t.[DistributorID_FK]
      ,t.[distributorPermissionTypeStartDate]
      ,t.[distributorPermissionTypeEndDate]
      ,t.[distributorPermissionTypeActive]
      ,t.[permissionAuthLvl]
      ,d.distributorName_A
      ,d.distributorType_FK
      ,pt.permissionTypeName_A
      ,pt.permissionTypeName_E
      ,pa.permissionAuthLvlName_A
    
    
  FROM [DATACORE].[dbo].[DistributorPermissionType] t 
  inner join dbo.Distributor d on d.distributorID = t.distributorID_FK and d.distributorActive = 1 and d.distributorType_FK = 4
  inner join dbo.MenuDistributor md on md.distributorID_FK = t.distributorID_FK and md.menuDistributorActive = 1
  inner join dbo.Menu m on m.menuID = md.menuID_FK and m.menuActive = 1
  inner join dbo.PermissionType pt on pt.permissionTypeID = t.permissionTypeID_FK
  inner join dbo.permissionAuthLvl pa on pa.permissionAuthLvlID = t.permissionAuthLvl and pa.permissionAuthLvlActive = 1
  where t.distributorPermissionTypeActive = 1
  order by t.distributorPermissionTypeID desc
           
        

        
           select 

            p.[programID]
           ,p.[programName_A]

            From dbo.Program p

            
            where programActive = 1
            ORDER BY P.programID asc



            select u.UsersAuthTypeID,u.UsersAuthTypeName_A
            from dbo.UsersAuthType u
            where u.UsersAuthTypeActive = 1

            -- Side Menus DDL
            SELECT
                  m.menuID
                , m.menuName_A
                , m.programID_FK
            FROM dbo.Menu m
            WHERE m.menuActive = 1
              AND m.programID_FK IS NOT NULL
              AND (m.menuLink IS NULL OR m.menuLink = 'MVC')
            ORDER BY m.menuName_A;

            -- Pages DDL
            SELECT DISTINCT
                  m.menuID
                , m.menuName_A
                , COALESCE(m.programID_FK, parentMenu.programID_FK) AS programID_FK
            FROM dbo.Menu m
            LEFT JOIN dbo.Menu parentMenu
                ON parentMenu.menuID = m.parentMenuID_FK
            INNER JOIN dbo.MenuDistributor md
                ON md.menuID_FK = m.menuID
               AND md.menuDistributorActive = 1
            INNER JOIN dbo.Distributor d
                ON d.distributorID = md.distributorID_FK
               AND d.distributorActive = 1
               AND d.distributorType_FK = 4
            WHERE m.menuActive = 1
              AND m.menuLink IS NOT NULL
              AND m.menuLink <> 'MVC'
            ORDER BY m.menuName_A;

            -- Permission Types DDL
            SELECT
                  p.permissionTypeID
                , p.permissionTypeName_A
            FROM dbo.PermissionType p
            WHERE p.permissionTypeActive = 1
            ORDER BY p.permissionTypeName_A;

            -- Permission Auth Levels DDL
            SELECT
                  pa.permissionAuthLvlID
                , pa.permissionAuthLvlName_A
            FROM dbo.permissionAuthLvl pa
            WHERE pa.permissionAuthLvlActive = 1
            ORDER BY pa.permissionAuthLvlID;


END


-------------------------------------------------------------------
--                     PAGE: RealChartsDemo
-------------------------------------------------------------------
        
        ELSE IF @pageName_ = 'RealChartsDemo'
        BEGIN



            -- Pie3D Data (Table 1) من جدول الديمو
            SELECT
                SegmentKey     AS [Key],
                SegmentLabel_A AS [Label],
                SegmentValue   AS [Value],
                SegmentHref    AS [Href],
                SegmentHint    AS [Hint]
            FROM Demo.Demo_Pie3D_UnitDistribution
            WHERE IsActive = 1
              AND (@idaraID IS NULL OR IdaraId_FK IS NULL OR IdaraId_FK = @idaraID)
            ORDER BY SortOrder;
        END






         -------------------------------------------------------------------
    --                     DO NOT TOUCH ABOVE THIS LINE
    -------------------------------------------------------------------

    --

    --

    --


    --

    --
    --

    -------------------------------------------------------------------
    --                     PAGE: BuildingType
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'BuildingType'
        BEGIN


            
                EXEC [Housing].[BuildingTypeDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
          
        END

    -------------------------------------------------------------------
    --                     PAGE: BuildingClass
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'BuildingClass'
        BEGIN


            -- Building Class Data
			  EXEC [Housing].[BuildingClassDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
         
        END

    -------------------------------------------------------------------
    --                     PAGE: buildingUtilityType
    -------------------------------------------------------------------
              

ELSE IF @pageName_ = 'buildingUtilityType'
        BEGIN



            -- Utility Type EXEC
           EXEC [Housing].[buildingUtilityTypeDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
        END


    -------------------------------------------------------------------
    --                     PAGE: BuildingType
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'MilitaryLocation'
        BEGIN


            -- MilitaryLocation Data
             EXEC [Housing].[MilitaryLocationDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
        END

    -------------------------------------------------------------------
    --                     PAGE: BuildingDetails
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'BuildingDetails'
        BEGIN


             EXEC [Housing].[BuildingDetailsDL]
                                           
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @buildingUtilityTypeID_FK       = @parameter_01


        END



         -------------------------------------------------------------------
    --                     PAGE: Residents
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'Residents'
        BEGIN



            -- Residents Data
           EXEC [Housing].[ResidentsDL] 
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
            



           


        END


    -------------------------------------------------------------------
    --                     PAGE: WaitingListByResident
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'WaitingListByResident'
        BEGIN


            -- One Resident Data

          EXEC [Housing].[WaitingListByResidentDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @NationalID                      =@parameter_01


           


        END


         -------------------------------------------------------------------
    --                     PAGE: WaitingListMoveList
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'WaitingListMoveList'
        BEGIN


            -- One Resident Data

           EXEC [Housing].[WaitingListMoveListDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName



        END

    -------------------------------------------------------------------
    --                     PAGE: WaitingList
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'WaitingList'
        BEGIN

			
                      EXEC [Housing].[WaitingListDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @WaitingClassID_nvar            = @parameter_01

                    


        END


    -------------------------------------------------------------------
    --                     PAGE: OtherWaitingList
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'OtherWaitingList'
        BEGIN

			
                      EXEC [Housing].[OtherWaitingListDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @WaitingClassID_nvar            = @parameter_01

                    


        END



   
    -------------------------------------------------------------------
    --                     PAGE: Assign
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'Assign'
        BEGIN



            -- Assign Data

   EXEC [Housing].[AssignDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @WaitingClassID                 = @parameter_01
                    , @AssignPeriodID                 = @parameter_01


          

        END



   


   -------------------------------------------------------------------
    --                     PAGE: AssignStatus
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'AssignStatus'
        BEGIN



       
	     -- Assign Data

   EXEC [Housing].[AssignStatusDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @AssignPeriodID                  = @parameter_01



        END


      

    -------------------------------------------------------------------
    --                     PAGE: HousingResident
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'HousingResident'
        BEGIN



            -- HousingResident Data

           EXEC [Housing].[HousingResidentDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                   
   

        END





    -------------------------------------------------------------------
    --                     PAGE: HousingResident
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'MeterReadForOccubentAndExit'
        BEGIN



            -- MeterReadForOccubentAndExit Data

           EXEC [Housing].[MeterReadForOccubentAndExitDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @residentInfoID                  = @parameter_01

        END




    -------------------------------------------------------------------
    --                     PAGE: HousingExtend
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'HousingExtend'
        BEGIN



            -- HousingExtend Data
			 EXEC [Housing].[HousingExtendDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                   



   

        END


            -------------------------------------------------------------------
    --                     PAGE: HousingExtendFollowUp
    -------------------------------------------------------------------
    ELSE IF @pageName_ = 'HousingExtendFollowUp'
    BEGIN
        EXEC [Housing].[HousingExtendFollowUpDL]
              @pageName_ = @pageName_
            , @idaraID = @idaraID
            , @entrydata = @entrydata
            , @hostname = @hostname;
    END


    -------------------------------------------------------------------
    --                     PAGE: FinancialAuditForUser
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'FinancialAuditForUser'
        BEGIN



      EXEC [Housing].[FinancialAuditForUserDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @NationalID                     = @parameter_01


        END



    -------------------------------------------------------------------
    --                     PAGE: FinancialAuditForExtendAndEvictions
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'FinancialAuditForExtendAndEvictions'
        BEGIN



      EXEC [Housing].[FinancialAuditForExtendAndEvictionsDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @residentInfoID                 = @parameter_01


        END

            -------------------------------------------------------------------
    --                     PAGE: HousingExit
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'HousingExit'
        BEGIN



            -- HousingExit Data

           EXEC [Housing].[HousingExitDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @NationalID                     = @parameter_01
     




   

        END





    -------------------------------------------------------------------
    --                     PAGE: Meters
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'Meters'
        BEGIN

         EXEC [Housing].[MetersDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                   

     


        END




   -------------------------------------------------------------------
    --                     PAGE: AllMeterRead
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'AllMeterRead'
        BEGIN

         EXEC [Housing].[AllMeterReadDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @meterServiceTypeID_FK          = @parameter_01
                   

     


        END



          -------------------------------------------------------------------
    --                     PAGE: HousingHandover
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'HousingHandover'
        BEGIN

         EXEC [Housing].[HousingHandoverDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @LastActionTypeID                 = @parameter_01
                   

     


        END





        
    -------------------------------------------------------------------
    --                     PAGE: RentExemption
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'RentExemption'
        BEGIN


            -- One Resident Data

          EXEC [Housing].[RentExemptionDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    , @NationalID                      =@parameter_01


           


        END

    -------------------------------------------------------------------
    --                     PAGE: MeterServiceTypeFixedAmount
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'MeterServiceTypeFixedAmount'
        BEGIN


            -- One Resident Data

          EXEC [Housing].[MeterServiceTypeFixedAmountDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    


           


        END


         -------------------------------------------------------------------
    --                     PAGE: ExtendInsurance
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'ExtendInsurance'
        BEGIN


            -- One Resident Data

          EXEC [Housing].[ExtendInsuranceDL]
                      @pageName_                      = @pageName_
                    , @idaraID                        = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName
                    


           


        END



         -------------------------------------------------------------------
    --                     PAGE: MonthlyBillingMonitor
    -------------------------------------------------------------------

         ELSE IF @pageName_ = N'MonthlyBillingMonitor'
        BEGIN
            DECLARE @MonitorYear INT = TRY_CONVERT(INT, @parameter_01);
            DECLARE @MonitorMonth INT = TRY_CONVERT(INT, @parameter_02);
            DECLARE @MonitorIdaraID BIGINT = CASE
                WHEN @isAdmin = 1 THEN TRY_CONVERT(BIGINT, @parameter_03)
                ELSE @idaraID
            END;


            EXEC Housing.MonthlyBillingMonitorDL
                  @Year = @MonitorYear
                , @Month = @MonitorMonth
                , @IdaraID = @MonitorIdaraID;
        END



         -------------------------------------------------------------------
    --                     PAGE: DeductListReport
    -------------------------------------------------------------------

        ELSE IF @pageName_ = N'DeductListReport'
        BEGIN
           
            DECLARE @DeductReportID BIGINT=TRY_CONVERT(BIGINT,@parameter_03);

            EXEC Housing.DeductListReportDL
                  @pageName_                      = @pageName_
                , @idaraID                        = @idaraID
                , @entryData                      = @entrydata
                , @hostName                       = @hostName
                , @Year                           = @parameter_01
                , @Month                          = @parameter_02
                , @ReportID                       = @DeductReportID;
        END



          -------------------------------------------------------------------
    --                     نظام الدعم الفني للموقع
    -------------------------------------------------------------------

      -------------------------------------------------------------------
    --                     PAGE: SupportMyTickets
    -------------------------------------------------------------------


          ELSE IF @pageName_ = 'SupportMyTickets'
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E IN (N'SMT_ACCESS', N'SMT_SELECT')
            )
            BEGIN
                SELECT 0 AS IsSuccessful, N'عفوا لاتملك صلاحية عرض هذه الصفحة' AS Message_;
            END
            ELSE
            BEGIN
                EXEC [support].[SupportMyTicketsDL]
                      @pageName_ = @pageName_
                    , @idaraID   = @idaraID
                    , @entryData = @entrydata
                    , @hostName  = @hostName;
            END
        END

         -------------------------------------------------------------------
    --                     PAGE: SupportPhoneTickets
    -------------------------------------------------------------------

ELSE IF @pageName_ = 'SupportPhoneTickets'
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E IN (N'SPT_ACCESS', N'SPT_SELECT')
            )
            BEGIN
                SELECT 0 AS IsSuccessful, N'عفوا لاتملك صلاحية عرض هذه الصفحة' AS Message_;
            END
            ELSE
            BEGIN
                EXEC [support].[SupportPhoneTicketsDL]
                      @pageName_ = @pageName_
                    , @idaraID   = @idaraID
                    , @entryData = @entrydata
                    , @hostName  = @hostName
                    , @permissionUserID = @parameter_01;
            END
        END

ELSE IF @pageName_ = 'SupportTicketDetails'
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E IN (N'STD_ACCESS', N'STD_SELECT')
            )
            BEGIN
                SELECT 0 AS IsSuccessful, N'عفوا لاتملك صلاحية عرض هذه الصفحة' AS Message_;
            END
            ELSE
            BEGIN
                EXEC [support].[SupportTicketDetailsDL]
                      @pageName_ = @pageName_
                    , @idaraID   = @idaraID
                    , @entryData = @entrydata
                    , @hostName  = @hostName
                    , @ticketID  = @parameter_01;
            END
        END

         -------------------------------------------------------------------
    --                     PAGE: SupportInbox
    -------------------------------------------------------------------

ELSE IF @pageName_ = 'SupportInbox'
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E IN (N'SIN_ACCESS', N'SIN_SELECT')
            )
            BEGIN
                SELECT 0 AS IsSuccessful, N'عفوا لاتملك صلاحية عرض هذه الصفحة' AS Message_;
            END
            ELSE
            BEGIN
                EXEC [support].[SupportInboxDL]
                      @pageName_    = @pageName_
                    , @idaraID      = @idaraID
                    , @entryData    = @entrydata
                    , @hostName     = @hostName
                    , @statusID     = @parameter_01
                    , @priorityID   = @parameter_02
                    , @ticketTypeID = @parameter_03
                    , @assignedToID = @parameter_04
                    , @dateFrom     = @parameter_05
                    , @dateTo       = @parameter_06
                    , @searchText   = @parameter_07;
            END
        END

         -------------------------------------------------------------------
    --                     PAGE: SupportTeamManagement
    -------------------------------------------------------------------

ELSE IF @pageName_ = 'SupportTeamManagement'
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.V_GetListUserPermission v
                WHERE v.userID = @entrydata
                  AND v.menuName_E = @pageName_
                  AND v.permissionTypeName_E IN (N'STM_ACCESS', N'STM_SELECT')
            )
            BEGIN
                SELECT 0 AS IsSuccessful, N'عفوا لاتملك صلاحية عرض هذه الصفحة' AS Message_;
            END
            ELSE
            BEGIN
                DECLARE @supportOnlyActive BIT = CASE WHEN @parameter_01 = '0' THEN 0 ELSE 1 END;

                EXEC [support].[SupportTeamManagementDL]
                      @pageName_  = @pageName_
                    , @idaraID    = @idaraID
                    , @entryData  = @entrydata
                    , @hostName   = @hostName
                    , @onlyActive = @supportOnlyActive;
            END
        END





        ------------------------------------------------------------------
--                     PAGE: VehicleS
-------------------------------------------------------------------




        -------------------------------------------------------------------
--                     PAGE: Admin_VehicleDocumentType
--DECLARE @ActiveOnly BIT;

--SET @ActiveOnly =
--    CASE
--        WHEN @parameter_01 IN ('1','0') THEN CAST(@parameter_01 AS BIT)
--        ELSE NULL
--    END;

--EXEC [VIC].[Admin_VehicleDocumentType_List_DL]
--     @ActiveOnly = @ActiveOnly;
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Admin_VehicleDocumentType'
    BEGIN
        

        EXEC [VIC].[Admin_VehicleDocumentType_List_DL]
    @ActiveOnly = @parameter_01;

    END
    -------------------------------------------------------------------
--                     PAGE: Custody_Current_ByUser
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Custody_Current_ByUser'
    BEGIN
        

        -- Current Custody By User Data
       EXEC [VIC].[Custody_Current_ByUser_DL]
      @userID     = @parameter_01
    , @idaraID_FK = @parameter_02;
    END

    -------------------------------------------------------------------
--                     PAGE: Custody
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Custody'
    BEGIN
        

        -- Current Custody List Data
       EXEC [VIC].[CustodyCurrentListDL]
      @userID        = @parameter_01
    , @generalNo     = @parameter_02
    , @chassisNumber = @parameter_03
    , @pageNumber    = @parameter_04
    , @pageSize      = @parameter_05
    , @idaraID_FK    = @parameter_06;
    END

    -------------------------------------------------------------------
--                     PAGE: Custody_History_ByUser
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Custody_History_ByUser'
    BEGIN
        
        -- Custody History By User Data
        EXEC [VIC].[Custody_History_ByUser_DL]
      @userID     = @parameter_01
    , @fromDate   = @parameter_02
    , @toDate     = @parameter_03
    , @pageNumber = @parameter_04
    , @pageSize   = @parameter_05
    , @idaraID_FK = @parameter_06;
    END

    -------------------------------------------------------------------
--                     PAGE: Custody_History_ByVehicle
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Custody_History_ByVehicle'
    BEGIN
        

        -- Custody History By Vehicle Data
        EXEC [VIC].[Custody_History_ByVehicle_DL]
      @chassisNumber = @parameter_01
    , @fromDate      = @parameter_02
    , @toDate        = @parameter_03
    , @pageNumber    = @parameter_04
    , @pageSize      = @parameter_05;
    END

    -------------------------------------------------------------------
--                     PAGE: Dashboard
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Dashboard'
    BEGIN
        

        -- Dashboard Data
        EXEC [VIC].[Dashboard_Get_DL]
      @onlyHasCustody         = @parameter_01
    , @onlyHasActiveInsurance = @parameter_02
    , @onlyHasDocExpiry       = @parameter_03
    , @onlyHasInsExpiry       = @parameter_04
    , @idaraID_FK             = @parameter_05;
    END

    -------------------------------------------------------------------
--                     PAGE: Handover_Get
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Handover_Get'
    BEGIN
        

        -- Handover Get Data
       EXEC [VIC].[Handover_Get_DL]
      @vehicleHandoverID = @parameter_01
    , @idaraID_FK        = @parameter_02;
    END

    -------------------------------------------------------------------
--                     PAGE: Handover_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Handover_List'
    BEGIN
        

        -- Handover List Data
        EXEC [VIC].[Handover_List_DL]
      @requestID      = @parameter_01
    , @handoverTypeID = @parameter_02
    , @fromDate       = @parameter_03
    , @toDate         = @parameter_04
    , @pageNumber     = @parameter_05
    , @pageSize       = @parameter_06
    , @idaraID_FK      = @parameter_07;
    END

    -------------------------------------------------------------------
--                     PAGE: Handover_Print_Get
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Handover_Print_Get'
    BEGIN
        
        -- Handover Print Get Data
        EXEC [VIC].[Handover_Print_Get_DL]
      @vehicleHandoverID = @parameter_01
    , @idaraID_FK        = @parameter_02;
    END

    -------------------------------------------------------------------
--                     PAGE: HandoverType
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'HandoverType'
    BEGIN
        

        -- Handover Type Data
        EXEC [VIC].[HandoverType_List_DL]
              @activeOnly =  @parameter_01;
    END

    -------------------------------------------------------------------
--                     PAGE: MaintenanceDetails_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'MaintenanceDetails_List'
    BEGIN
        

        -- Maintenance Details List Data
        EXEC [VIC].[MaintenanceDetails_List_DL]
      @maintOrdID = @parameter_01
    , @idaraID_FK = @parameter_02;
    END

    -------------------------------------------------------------------
--                     MaintenanceTemplate_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'MaintenanceTemplate_List'
BEGIN
    

    EXEC [VIC].[MaintenanceTemplate_List_DL]
          @MaintOrdTypeID_FK = @parameter_01
        , @active            = @parameter_02;
END
    -------------------------------------------------------------------
--                     PAGE: MaintenanceOrder_Get
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'MaintenanceOrder_Get'
    BEGIN
        

        -- Maintenance Order Get Data
        EXEC [VIC].[MaintenanceOrder_Get_DL]
      @maintOrdID = @parameter_01
    , @idaraID_FK = @parameter_02;
    END

    -------------------------------------------------------------------
--                     PAGE: MaintenanceOrder_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'MaintenanceOrder_List'
    BEGIN
        

        -- Maintenance Order List Data
        EXEC [VIC].[MaintenanceOrder_List_DL]
      @chassisNumber  = @parameter_01
    , @maintOrdTypeID = @parameter_02
    , @active         = @parameter_03
    , @fromDate       = @parameter_04
    , @toDate         = @parameter_05
    , @pageNumber     = @parameter_06
    , @pageSize       = @parameter_07
    , @idaraID_FK      = @parameter_08;
    END

    -------------------------------------------------------------------
--                     PAGE: Report_DocumentsExpiring
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Report_DocumentsExpiring'
    BEGIN
       

        -- Documents Expiring Report
        EXEC [VIC].[Report_DocumentsExpiring_DL]
      @days           = @parameter_01
    , @includeExpired = @parameter_02
    , @idaraID_FK     = @parameter_03;
    END

    -------------------------------------------------------------------
--                     PAGE: Report_InsuranceExpiring
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Report_InsuranceExpiring'
    BEGIN
       

        -- Insurance Expiring Report
        EXEC [VIC].[Report_InsuranceExpiring_DL]
      @days           = @parameter_01
    , @includeExpired = @parameter_02
    , @activeOnly     = @parameter_03
    , @idaraID_FK      = @parameter_04;
    END

    -------------------------------------------------------------------
--                     PAGE: Report_MaintenanceCostByVehicle
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Report_MaintenanceCostByVehicle'
    BEGIN
        

        -- Maintenance Cost By Vehicle Report
        EXEC [VIC].[Report_MaintenanceCostByVehicle_DL]
      @fromDate   = @parameter_01
    , @toDate     = @parameter_02
    , @idaraID_FK = @parameter_03;
    END

    -------------------------------------------------------------------
--                     PAGE: Report_UnpaidViolations
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Report_UnpaidViolations'
    BEGIN
        

        -- Unpaid Violations Report
        EXEC [VIC].[Report_UnpaidViolations_DL]
      @chassisNumber = @parameter_01
    , @fromDate      = @parameter_02
    , @toDate        = @parameter_03
    , @idaraID_FK     = @parameter_04;
    END

    -------------------------------------------------------------------
--                     PAGE: Report_VehiclesWithoutCustody
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Report_VehiclesWithoutCustody'
    BEGIN
        

        -- Vehicles Without Custody Report
        EXEC [VIC].[Report_VehiclesWithoutCustody_DL]
      @onlyActiveVehicles = @parameter_01
    , @idaraID_FK         = @parameter_02;
    END

    -------------------------------------------------------------------
--                     PAGE: Report_VehicleTimeline
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Report_VehicleTimeline'
    BEGIN
        

        -- Vehicle Timeline Report
        EXEC [VIC].[Report_VehicleTimeline_DL]
      @chassisNumber = @parameter_01
    , @fromDate      = @parameter_02
    , @toDate        = @parameter_03
    , @idaraID_FK     = @parameter_04;
    END

    -------------------------------------------------------------------
--                     PAGE: TransferRequest_Get
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'TransferRequest_Get'
    BEGIN
        

        -- Transfer Request Get Data
        EXEC [VIC].[TransferRequest_Get_DL]
      @requestID  = @parameter_01
    , @idaraID_FK = @parameter_02;
    END

    -------------------------------------------------------------------
--                     PAGE: TransferRequestHistory_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'TransferRequestHistory_List'
    BEGIN
        

        -- Transfer Request History List Data
        EXEC [VIC].[TransferRequestHistory_List_DL]
      @requestID  = @parameter_01
    , @idaraID_FK = @parameter_02;
    END

    -------------------------------------------------------------------
--                     PAGE: TransferRequest_Vehicles_ByUserDept
-------------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequest_Vehicles_ByUserDept'
BEGIN
    

    EXEC [VIC].[TransferRequest_Vehicles_ByUserDept_DL]
          @userID        = @parameter_01
        , @idaraID_FK    = @parameter_02
        , @pageNumber    = @parameter_03
        , @pageSize      = @parameter_04
        , @chassisNumber = @parameter_05;
END

-------------------------------------------------------------------
--                     PAGE: TransferRequest_EligibleUsers
-------------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequest_EligibleUsers'
BEGIN
    

    EXEC [VIC].[TransferRequest_EligibleUsers_DL]
          @chassisNumber = @parameter_01
        , @userID        = @parameter_02
        , @idaraID_FK    = @parameter_03;
END

-------------------------------------------------------------------
--                     PAGE: TransferRequest_Pending_ByDept
-------------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequest_Pending_ByDept'
BEGIN
    

    EXEC [VIC].[TransferRequest_Pending_ByDept_DL]
          @userID        = @parameter_01
        , @idaraID_FK    = @parameter_02
        , @pageNumber    = @parameter_03
        , @pageSize      = @parameter_04;
END

-------------------------------------------------------------------
--                     PAGE: TransferRequest_Approved_List
-------------------------------------------------------------------
ELSE IF @pageName_ = 'TransferRequest_Approved_List'
BEGIN
    

    EXEC [VIC].[TransferRequest_Approved_List_DL]
          @requestID      = @parameter_01
        , @chassisNumber  = @parameter_02
        , @fromUserID     = @parameter_03
        , @toUserID       = @parameter_04
        , @pageNumber     = @parameter_05
        , @pageSize       = @parameter_06
        , @idaraID_FK     = @parameter_07;
END
---------------------------------------------------------------------
--وش يسوي؟

--يرجع:
--?? خطة وحدة فقط

--تستخدمه في:
--شاشة التعديل
--لما تضغط “Edit”
-------------------------------------------------------------------

ELSE IF @pageName_ = 'MaintenancePlan_Get'
BEGIN
    

    EXEC [VIC].[MaintenancePlan_Get_DL]
          @planID      = @parameter_01
        , @idaraID_FK  = @idaraID;
END

----------------------------------------------------------------
-- MaintenanceDetails_Get
----------------------------------------------------------------
-- Description:
-- جلب بند صيانة واحد من جدول VIC.MaintenanceDetails حسب MaintDetailesID
-- مع التحقق من وجود السجل ومطابقة الإدارة عبر أمر الصيانة المرتبط (VehicleMaintenance).
--
-- Parameters:
-- @parameter_01 = MaintDetailesID
--
-- Notes:
-- - يستخدم في شاشة التعديل أو عرض تفاصيل بند صيانة واحد.
-- - يعتمد على idaraID لضمان أن البيانات ضمن نفس الإدارة.
----------------------------------------------------------------

ELSE IF @pageName_ = 'MaintenanceDetails_Get'
BEGIN
    

    EXEC [VIC].[MaintenanceDetails_Get_DL]
          @maintDetailesID = @parameter_01
        , @idaraID_FK      = @idaraID;
END
-------------------------------------------------------------------
--                  يرجع لك:
--?? كل خطط الصيانة الدورية

--مع معلومات إضافية:

--رقم اللوحة
--كل كم شهر
--متى الموعد القادم
--هل الخطة مفعلة أو لا
--تستخدمه في:
--صفحة عرض الخطط (Grid)
--الفلترة (حسب مركبة / مفعلة)
-------------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenancePlan_List'
BEGIN
    

    EXEC [VIC].[MaintenancePlan_List_DL]
          @chassisNumber = @parameter_01
        , @active        = @parameter_02
        , @pageNumber    = @parameter_03
        , @pageSize      = @parameter_04
        , @idaraID_FK    = @idaraID;
END

-------------------------------------------------------------------
ELSE IF @pageName_ = 'MaintenancePlan_Get'
BEGIN

    EXEC [VIC].[MaintenancePlan_Get_DL]
          @planID     = @parameter_01
        , @idaraID_FK = @idaraID;
END
-------------------------------------------------------------------
--                    داش بورد الصيانه الدوريه
-------------------------------------------------------------------

ELSE IF @pageName_ = 'Dashboard_MaintenanceDue'
BEGIN
    

    EXEC [VIC].[Dashboard_MaintenanceDue_DL]
          @daysAhead  = @parameter_01
        , @idaraID_FK = @idaraID;
END
    -------------------------------------------------------------------
--                     PAGE: TransferRequestType_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'TransferRequestType_List'
    BEGIN
        

        -- Transfer Request Type Lookup
        EXEC [VIC].[TransferRequestType_List_DL]
    @activeOnly = @parameter_01;
    END

    -------------------------------------------------------------------
--                     PAGE: TypesRoot_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'TypesRoot_List'
    BEGIN
        

        -- Types Root Lookup / List
        EXEC [VIC].[TypesRoot_List_DL]
      @parentID   = @parameter_01
    , @activeOnly = @parameter_02
    , @search     = @parameter_03;
    END
    -------------------------------------------------------------------
--                     PAGE: Scrap
-------------------------------------------------------------------
ELSE IF @pageName_ = 'Scrap'
BEGIN

    -- Scrap List / Get / Print
    EXEC [VIC].[ScrapDL]
          @scrapID       = @parameter_01
        , @chassisNumber = @parameter_02
        , @Status        = @parameter_03
        , @DateFrom      = @parameter_04
        , @DateTo        = @parameter_05
        , @pageNumber    = @parameter_06
        , @pageSize      = @parameter_07
        , @idaraID_FK    = @idaraID;
END
    -------------------------------------------------------------------
--                     PAGE: Vehicle_Get
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Vehicle_Get'
    BEGIN
        

        -- Vehicle Get Data
        EXEC [VIC].[Vehicle_Get_DL]
      @UsersID        = @parameter_01
    , @MenuLink       = @parameter_02
    , @SkipPermission = @parameter_03
    , @chassisNumber  = @parameter_04
    , @idaraID_FK      = @parameter_05;
    END

    -------------------------------------------------------------------
--                     PAGE: Vehicle_GetLookups
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Vehicle_GetLookups'
    BEGIN
        

        -- Vehicle Lookups Data
        EXEC [VIC].[Vehicle_GetLookups_DL]
      @UsersID            = @parameter_01
    , @MenuLink           = @parameter_02
    , @SkipPermission     = @parameter_03
    , @TypesRoot_ParentID = @parameter_04;
    END

    -------------------------------------------------------------------
--                     PAGE: Vehicle_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Vehiclelist'
    BEGIN
        

        -- Vehicle List Data
        EXEC [VIC].[Vehicle_List_DL]
      @ownerID_FK   = @parameter_01
    , @plateLetters = @parameter_02
    , @plateNumbers = @parameter_03
    , @hasCustody   = @parameter_04
    , @pageNumber   = @parameter_05
    , @pageSize     = @parameter_06
    , @idaraID_FK     = @parameter_07;
    END

    -------------------------------------------------------------------
--                     PAGE: Vehicle_List_EXT
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Vehicle_List_EXT'
    BEGIN
       

        -- Vehicle List EXT Data
        EXEC [VIC].[Vehicle_List_EXT_DL]
      @UsersID          = @parameter_01
    , @MenuLink         = @parameter_02
    , @SkipPermission   = @parameter_03
    , @q                = @parameter_04
    , @ownerID_FK       = @parameter_05
    , @plateLetters     = @parameter_06
    , @plateNumbers     = @parameter_07
    , @HasCustody       = @parameter_08
    , @HasActiveRequest = @parameter_09
    , @PageNumber       = @parameter_10
    , @PageSize         = @parameter_11
    , @idaraID_FK        = @parameter_12;
    END


    -------------------------------------------------------------------
--                     PAGE: Vehicle_Profile_Get
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Vehicle_Profile_Get'
    BEGIN
        

        -- Vehicle Profile (multiple result-sets)
        EXEC [VIC].[Vehicle_Profile_Get_DL]
      @UsersID        = @parameter_01
    , @MenuLink       = @parameter_02
    , @SkipPermission = @parameter_03
    , @chassisNumber  = @parameter_04
    , @TopDocuments   = @parameter_05
    , @TopInsurance   = @parameter_06
    , @TopMaintenance = @parameter_07
    , @TopViolations  = @parameter_08
    , @idaraID_FK      = @parameter_09;
    END
-------------------------------------------------------------------
--                     PAGE: Vehicles
-------------------------------------------------------------------
ELSE IF @pageName_ = 'Vehicles'
BEGIN

    -- Vehicle List Data
    EXEC [VIC].[Vehicle_List_DL]
          @ownerID_FK   = @parameter_01
        , @plateLetters = @parameter_02
        , @plateNumbers = @parameter_03
        , @hasCustody   = @parameter_04
        , @pageNumber   = @parameter_05
        , @pageSize     = @parameter_06
        , @idaraID_FK   = @parameter_07;
END
    -------------------------------------------------------------------
--                     PAGE: Vehicle_Search
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Vehicle_Search'
    BEGIN
       

        -- Vehicle Search (fast by plate OR general q)
        EXEC [VIC].[Vehicle_Search_DL]
      @q            = @parameter_01
    , @plateLetters = @parameter_02
    , @plateNumbers = @parameter_03
    , @Top          = @parameter_04
    , @idaraID_FK     = @parameter_05;
    END

    -------------------------------------------------------------------
--                     PAGE: VehicleDocument_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'VehicleDocument_List'
    BEGIN
        

        -- Vehicle Documents List (normal list OR expiring mode)
        EXEC [VIC].[VehicleDocument_List_DL]
      @chassisNumber         = @parameter_01
    , @vehicleDocumentTypeID = @parameter_02
    , @DocumentNo            = @parameter_03
    , @OnlyActiveNow         = @parameter_04
    , @Page                  = @parameter_05
    , @PageSize              = @parameter_06
    , @ExpireDays            = @parameter_07
    , @IncludeExpired        = @parameter_08
    , @idaraID_FK            = @parameter_09;
    END

    -------------------------------------------------------------------
--                     PAGE: VehicleDocumentType_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'VehicleDocumentType_List'
    BEGIN
        

        -- Vehicle Document Types (Lookup/Dropdown)
        EXEC [VIC].[VehicleDocumentType_List_DL]
    @ActiveOnly = @parameter_01;
    END

    -------------------------------------------------------------------
--                     PAGE: VehicleInsurance_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'VehicleInsurance_List'
    BEGIN
        

        -- Vehicle Insurance List (filters + optional expiring)
       EXEC [VIC].[VehicleInsurance_List_DL]
      @chassisNumber   = @parameter_01
    , @InsuranceTypeID = @parameter_02
    , @OperationTypeID = @parameter_03
    , @Active          = @parameter_04
    , @FromDate        = @parameter_05
    , @ToDate          = @parameter_06
    , @Page            = @parameter_07
    , @PageSize        = @parameter_08
    , @Days            = @parameter_09
    , @IncludeExpired  = @parameter_10;
    END

    -------------------------------------------------------------------
--                     PAGE: Violation_GetLookups
-------------------------------------------------------------------
   ----------------------------------------------------------------
-- Violation_GetLookups
----------------------------------------------------------------
ELSE IF @pageName_ = 'Violation_GetLookups'
BEGIN
    EXEC [VIC].[Violation_GetLookups_DL]
          @ActiveOnly = @parameter_01;
END

    -------------------------------------------------------------------
--                     PAGE: Violation_List
-------------------------------------------------------------------
    ELSE IF @pageName_ = 'Violation_List'
    BEGIN
        

        -- Violations List (filters + paging)
        EXEC [VIC].[Violation_List_DL]
      @chassisNumber   = @parameter_01
    , @violationTypeID = @parameter_02
    , @Paid            = @parameter_03
    , @FromDate        = @parameter_04
    , @ToDate          = @parameter_05
    , @Page            = @parameter_06
    , @PageSize        = @parameter_07
    , @idaraID_FK       = @parameter_08;
    END
     -------------------------------------------------------------------
--                    Violation_Get
-------------------------------------------------------------------

    ELSE IF @pageName_ = 'Violation_Get'
BEGIN
    EXEC [VIC].[Violation_Get_DL]
          @violationID = @parameter_01
        , @idaraID_FK  = @parameter_02;
END





    -------------------------------------------------------------------
    --                     PAGE NOT FOUND
    --            DO NOT TOUCH DOWN THIS LINE PLEASE
    -------------------------------------------------------------------
       
        ELSE
        BEGIN
            SELECT 0 AS IsSuccessful, N'الصفحة المرسلة مقيدة. PageName' AS Message_;
        END

        COMMIT TRANSACTION;
    END TRY

    -------------------------------------------------------------------
    --                     CATCH BLOCK
    -------------------------------------------------------------------
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(4000), @ErrSeverity INT, @ErrState INT, @IdentityCatchError INT;

        SELECT 
              @ErrMsg      = ERROR_MESSAGE(),
              @ErrSeverity = ERROR_SEVERITY(),
              @ErrState    = ERROR_STATE();

        INSERT INTO  dbo.ErrorLog
        (
              ERROR_MESSAGE_
            , ERROR_SEVERITY_
            , ERROR_STATE_
            , SP_NAME
            , entryData
            , hostName
        )
        VALUES
        (
              @ErrMsg
            , @ErrSeverity
            , @ErrState
            , N'[dbo].[Masters_DataLoad]'
            , @entrydata
            , @hostname
        );

        SET @IdentityCatchError = SCOPE_IDENTITY();

        SELECT 
              0 AS IsSuccessful,
              N'حصل خطأ غير معروف رمز الخطأ : ' + CAST(@IdentityCatchError AS NVARCHAR(200)) AS Message_;
    END CATCH
END
GO

ALTER PROCEDURE [MoveData].[usp_ResetSystemUsers]
    @ConfirmReset bit = 0,
    @RollbackAfterTest bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF DB_NAME() <> N'DATACORE'
        THROW 59100, N'This procedure can run only in the DATACORE database.', 1;

    IF @ConfirmReset <> 1
        THROW 59101, N'User reset was not confirmed. Pass @ConfirmReset = 1.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE usersID > 12)
    BEGIN
        BEGIN TRANSACTION;
        DBCC CHECKIDENT (N'dbo.Users', RESEED, 12) WITH NO_INFOMSGS;

        SELECT
            @RollbackAfterTest AS RollbackAfterTest,
            CONVERT(bigint, 0) AS UsersDeleted,
            CONVERT(bigint, 12) AS UsersIdentityReseed,
            N'No users above usersID 12 were found.' AS Message_;

        IF @RollbackAfterTest = 1 ROLLBACK TRANSACTION; ELSE COMMIT TRANSACTION;
        RETURN;
    END;

    /*
      Support tickets are operational records, not user permissions.  Do not
      silently erase them as part of an account reset.  They must be handled
      explicitly before deleting the referenced users/team members.
    */
    IF EXISTS (SELECT 1 FROM support.Ticket WHERE createdByUserID_FK > 12 OR assignedByUserID_FK > 12)
       OR EXISTS (SELECT 1 FROM support.TicketAssignmentHistory WHERE actionByUserID_FK > 12)
       OR EXISTS (SELECT 1 FROM support.TicketAttachment WHERE uploadedByUserID_FK > 12)
       OR EXISTS (SELECT 1 FROM support.TicketReply WHERE replyByUserID_FK > 12)
       OR EXISTS (SELECT 1 FROM support.TicketTask WHERE assignedByUserID_FK > 12)
       OR EXISTS
       (
           SELECT 1
           FROM support.TeamMember teamMember
           WHERE teamMember.userID_FK > 12
             AND
             (
                 EXISTS (SELECT 1 FROM support.Ticket ticketRow WHERE ticketRow.assignedToTeamMemberID_FK = teamMember.teamMemberID)
                 OR EXISTS (SELECT 1 FROM support.TicketAssignmentHistory historyRow WHERE historyRow.fromTeamMemberID_FK = teamMember.teamMemberID OR historyRow.toTeamMemberID_FK = teamMember.teamMemberID)
                 OR EXISTS (SELECT 1 FROM support.TicketTask taskRow WHERE taskRow.assignedToTeamMemberID_FK = teamMember.teamMemberID)
             )
       )
        THROW 59102, N'Cannot reset users: support transactions reference one or more users above usersID 12. Reassign or remove those transactions explicitly first.', 1;

    DECLARE
        @UsersBefore bigint = (SELECT COUNT_BIG(*) FROM dbo.Users WHERE usersID > 12),
        @MenuPermissionsDeleted bigint = 0,
        @PermissionsDeleted bigint = 0,
        @ProgramDistributorsDeleted bigint = 0,
        @UserDistributorsDeleted bigint = 0,
        @UsersDeleted bigint = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* User preferences, notifications, photos, and direct account data. */
        DELETE FROM dbo.ChartListUsers WHERE UsersID_FK > 12;
        DELETE FROM dbo.MvcThameUser WHERE UsersID_FK > 12;
        DELETE FROM dbo.UserNotifications WHERE UserId_FK > 12;
        DELETE FROM dbo.UserPhoto WHERE userID_FK > 12;
        DELETE FROM dbo.UsersPhoto WHERE usersID_FK > 12;
        DELETE FROM dbo.contactInfo WHERE userID_FK > 12;

        /* User-specific permissions and administrative assignments. */
        DELETE FROM dbo.MenuDistributor WHERE userID_FK > 12;
        SET @MenuPermissionsDeleted = @@ROWCOUNT;

        DELETE FROM dbo.Permission WHERE UsersID_FK > 12;
        SET @PermissionsDeleted = @@ROWCOUNT;

        DELETE FROM dbo.ProgramDistributor WHERE userID_FK > 12;
        SET @ProgramDistributorsDeleted = @@ROWCOUNT;

        DELETE FROM dbo.UserDistributor WHERE userID_FK > 12;
        SET @UserDistributorsDeleted = @@ROWCOUNT;

        /* Remove support-team roles/membership after transactional references were checked. */
        DELETE teamMemberRole
        FROM support.TeamMemberRole teamMemberRole
        JOIN support.TeamMember teamMember
          ON teamMember.teamMemberID = teamMemberRole.teamMemberID_FK
        WHERE teamMember.userID_FK > 12;

        DELETE FROM support.TeamMember WHERE userID_FK > 12;

        /* Preserve operational rows but remove reusable user IDs from nullable, non-FK columns. */
        UPDATE dbo.DecisionForSolider SET userID_FK = NULL WHERE userID_FK > 12;
        UPDATE dbo.Document SET userID_FK = NULL WHERE userID_FK > 12;
        UPDATE Tickets.Ticket SET UserID_FK = NULL WHERE UserID_FK > 12;
        UPDATE VIC.vehicleWithUsers SET userID_FK = NULL WHERE userID_FK > 12;

        /* Required children of dbo.Users. */
        DELETE FROM dbo.UsersPassword WHERE usersID_FK > 12;
        DELETE FROM dbo.UsersDetails WHERE usersID_FK > 12;

        DELETE FROM dbo.Users WHERE usersID > 12;
        SET @UsersDeleted = @@ROWCOUNT;

        IF EXISTS (SELECT 1 FROM dbo.Users WHERE usersID > 12)
            THROW 59103, N'User reset verification failed: users above usersID 12 remain.', 1;

        /* With rows 1..12 retained, RESEED 12 makes the next Users identity 13. */
        DBCC CHECKIDENT (N'dbo.Users', RESEED, 12) WITH NO_INFOMSGS;

        SELECT
            @RollbackAfterTest AS RollbackAfterTest,
            @UsersBefore AS UsersBeforeReset,
            @UsersDeleted AS UsersDeleted,
            @MenuPermissionsDeleted AS MenuPermissionsDeleted,
            @PermissionsDeleted AS PermissionsDeleted,
            @ProgramDistributorsDeleted AS ProgramDistributorsDeleted,
            @UserDistributorsDeleted AS UserDistributorsDeleted,
            (SELECT COUNT_BIG(*) FROM dbo.Users) AS UsersRemaining,
            CONVERT(bigint, 13) AS NextUsersIdentity;

        IF @RollbackAfterTest = 1
            ROLLBACK TRANSACTION;
        ELSE
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DROP PROCEDURE IF EXISTS [dbo].[sp_AiChat_Dashboard];
    DROP PROCEDURE IF EXISTS [dbo].[sp_AiChat_GetQuestionsNeedingImprovement];
    DROP PROCEDURE IF EXISTS [dbo].[sp_AiChat_GetStatistics];
    DROP PROCEDURE IF EXISTS [dbo].[sp_AiChat_UpdateFrequentQuestions];
    DROP PROCEDURE IF EXISTS [dbo].[sp_AiChat_SaveCitation];
    DROP PROCEDURE IF EXISTS [dbo].[sp_AiChat_SaveFeedback];
    DROP PROCEDURE IF EXISTS [dbo].[sp_AiChat_SaveHistory];

    DROP VIEW IF EXISTS [dbo].[V_AiChat_Kpi_30Days];
    DROP FUNCTION IF EXISTS [dbo].[ft_UserAllPermissionsForAi];

    DROP TABLE IF EXISTS [dbo].[AiChatCitations];
    DROP TABLE IF EXISTS [dbo].[AiChatFeedback];
    DROP TABLE IF EXISTS [dbo].[AiFrequentQuestions];
    DROP TABLE IF EXISTS [dbo].[AiChatLog];
    DROP TABLE IF EXISTS [dbo].[AiChatHistory];

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO