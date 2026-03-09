
create PROCEDURE [dbo].[Masters_CRUD_2025-12-24]
      @pageName_      NVARCHAR(400)
    , @ActionType     NVARCHAR(100) -- INSERT, UPDATE, DELETE, ...
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
    SET XACT_ABORT ON;  -- أي خطأ SQL حقيقي يفشل العملية ويروح للـ CATCH

    DECLARE @tc INT = @@TRANCOUNT;

    -- نستقبل نتيجة أي SP فرعي
    DECLARE @Result TABLE
    (
        IsSuccessful INT,
        Message_ NVARCHAR(4000)
    );

    DECLARE @ok INT = 0;
    DECLARE @msg NVARCHAR(4000) = N'';

    BEGIN TRY
        -- ابدأ ترانزكشن واحدة (فقط إذا ما فيه ترانزكشن)
        IF @tc = 0
            BEGIN TRAN;

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
                -- فشل منطقي: Rollback + رجع رسالة
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, N'عفوا لاتملك صلاحية لهذه العملية' AS Message_;
                RETURN;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERT'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)

                EXEC [dbo].[PermissionSP]
                      @Action                         = @ActionType
                    , @DistributorPermissionTypeID_FK = @parameter_02
                    , @permissionStartDate            = @parameter_03
                    , @permissionEndDate              = @parameter_04
                    , @permissionNote                 = @parameter_05
                    , @UsersID						  = @parameter_06
					, @RoleID						  = @parameter_07
					, @IdaraID                        = @parameter_08
					, @DeptID                         = @parameter_09
					, @SectionID                      = @parameter_10
					, @DivisonID                      = @parameter_11
					, @distributorID                  = @parameter_12
					, @searchID                       = @parameter_13
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName;
            END
            ELSE IF @ActionType = 'INSERTFULLACCESS'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PermissionSP]
                      @Action                         = @ActionType
                    , @distributorIDFroGiveAllPermissions = @parameter_01
                    , @permissionStartDate            = @parameter_02
                    , @permissionEndDate              = @parameter_03
                    , @permissionNote                 = @parameter_04
                    , @UsersID						  = @parameter_05
					, @RoleID						  = @parameter_06
					, @IdaraID                        = @parameter_07
					, @DeptID                         = @parameter_08
					, @SectionID                      = @parameter_09
					, @DivisonID                      = @parameter_10
					, @distributorID                  = @parameter_11
					, @searchID                       = @parameter_12
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName;

            END
            ELSE IF @ActionType = 'UPDATE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PermissionSP]
                      @Action                         = @ActionType
                    , @PermissionID                   = @parameter_01
                    , @permissionStartDate            = @parameter_04
                    , @permissionEndDate              = @parameter_05
                    , @permissionNote                 = @parameter_06
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName;
            END
			ELSE IF @ActionType ='DELETE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [dbo].[PermissionSP]
                      @Action                         = @ActionType
                    , @PermissionID                   = @parameter_01
                    , @DistributorPermissionTypeID_FK = @parameter_02
                    , @permissionStartDate            = @parameter_03
                    , @permissionEndDate              = @parameter_04
                    , @permissionNote                 = @parameter_05
                    , @UsersID						  = @parameter_06
					, @RoleID						  = @parameter_07
					, @IdaraID                        = @parameter_08
					, @DeptID                         = @parameter_09
					, @SectionID                      = @parameter_10
					, @DivisonID                      = @parameter_11
					, @distributorID                  = @parameter_12
					, @searchID                       = @parameter_13
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName;
            END

            ELSE
            BEGIN
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, N'نوع العملية المطلوبة غير معروف. ActionType' AS Message_;
                RETURN;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;

            IF ISNULL(@ok,0) = 0
            BEGIN
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, ISNULL(@msg, N'فشل تنفيذ العملية') AS Message_;
                RETURN;
            END

            IF @tc = 0 AND XACT_STATE() = 1 COMMIT;
            SELECT 1 AS IsSuccessful, @msg AS Message_;
            RETURN;
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
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, N'عفوا لاتملك صلاحية لهذه العملية' AS Message_;
                RETURN;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERT'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingTypeSP]
                      @Action                  = @ActionType
                    , @buildingTypeID          = NULL
                    , @buildingTypeCode        = @parameter_01
                    , @buildingTypeName_A      = @parameter_02
                    , @buildingTypeName_E      = @parameter_03
                    , @buildingTypeDescription = @parameter_04
                    , @idaraID_FK                 = @idaraID
                    , @entryData               = @entrydata
                    , @hostName                = @hostName;
            END
            ELSE IF @ActionType = 'UPDATE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingTypeSP]
                      @Action                  = @ActionType
                    , @buildingTypeID          = @parameter_01
                    , @buildingTypeCode        = @parameter_02
                    , @buildingTypeName_A      = @parameter_03
                    , @buildingTypeName_E      = @parameter_04
                    , @buildingTypeDescription = @parameter_05
                    , @idaraID_FK              = @idaraID
                    , @entryData               = @entrydata
                    , @hostName                = @hostName;
            END
            ELSE IF @ActionType = 'DELETE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingTypeSP]
                      @Action         = @ActionType
                    , @buildingTypeID = @parameter_01
                    , @entryData      = @entrydata
                    , @hostName       = @hostName;
            END
            ELSE
            BEGIN
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, N'نوع العملية المطلوبة غير معروف. ActionType' AS Message_;
                RETURN;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;

            IF ISNULL(@ok,0) = 0
            BEGIN
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, ISNULL(@msg, N'فشل تنفيذ العملية') AS Message_;
                RETURN;
            END

            IF @tc = 0 AND XACT_STATE() = 1 COMMIT;
            SELECT 1 AS IsSuccessful, @msg AS Message_;
            RETURN;
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
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, N'عفوا لاتملك صلاحية لهذه العملية' AS Message_;
                RETURN;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERT'
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
            ELSE IF @ActionType = 'UPDATE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingClassSP]
                      @Action                   = @ActionType
                    , @BuildingClassID          = @parameter_01
                    , @BuildingClassName_A      = @parameter_02
                    , @BuildingClassName_E      = @parameter_03
                    , @BuildingClassDescription = @parameter_04
                    , @idaraID_FK               = @idaraID
                    , @entryData                = @entrydata
                    , @hostName                 = @hostName;
            END
            ELSE IF @ActionType = 'DELETE'
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
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, N'نوع العملية المطلوبة غير معروف. ActionType' AS Message_;
                RETURN;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;

            IF ISNULL(@ok,0) = 0
            BEGIN
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, ISNULL(@msg, N'فشل تنفيذ العملية') AS Message_;
                RETURN;
            END

            IF @tc = 0 AND XACT_STATE() = 1 COMMIT;
            SELECT 1 AS IsSuccessful, @msg AS Message_;
            RETURN;
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
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, N'عفوا لاتملك صلاحية لهذه العملية' AS Message_;
                RETURN;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERT'
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
            ELSE IF @ActionType = 'UPDATE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingUtilityTypeSP]
                      @Action                         = @ActionType
                    , @buildingUtilityTypeID          = @parameter_01
                    , @buildingUtilityTypeName_A      = @parameter_02
                    , @buildingUtilityTypeName_E      = @parameter_03
                    , @buildingUtilityTypeDescription = @parameter_04
                    , @buildingUtilityTypeStartDate   = @parameter_06
                    , @buildingUtilityTypeEndDate     = @parameter_07
                    , @buildingUtilityIsRent          = @parameter_08
                    , @idaraID_FK                     = @idaraID
                    , @entryData                      = @entrydata
                    , @hostName                       = @hostName;
            END
            ELSE IF @ActionType = 'DELETE'
            BEGIN
                INSERT INTO @Result(IsSuccessful, Message_)
                EXEC [Housing].[BuildingUtilityTypeSP]
                      @Action                    = @ActionType
                    , @buildingUtilityTypeID     = @parameter_01
                    , @entryData                 = @entrydata
                    , @hostName                  = @hostName;
            END
            ELSE
            BEGIN
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, N'نوع العملية المطلوبة غير معروف. ActionType' AS Message_;
                RETURN;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;

            IF ISNULL(@ok,0) = 0
            BEGIN
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, ISNULL(@msg, N'فشل تنفيذ العملية') AS Message_;
                RETURN;
            END

            IF @tc = 0 AND XACT_STATE() = 1 COMMIT;
            SELECT 1 AS IsSuccessful, @msg AS Message_;
            RETURN;
        END

         ----------------------------------------------------------------
        -- BuildingType
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
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, N'عفوا لاتملك صلاحية لهذه العملية' AS Message_;
                RETURN;
            END

            DELETE FROM @Result;

            IF @ActionType = 'INSERT'
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
            ELSE IF @ActionType = 'UPDATE'
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
            ELSE IF @ActionType = 'DELETE'
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
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, N'نوع العملية المطلوبة غير معروف. ActionType' AS Message_;
                RETURN;
            END

            SELECT TOP 1 @ok = IsSuccessful, @msg = Message_ FROM @Result;

            IF ISNULL(@ok,0) = 0
            BEGIN
                IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
                SELECT 0 AS IsSuccessful, ISNULL(@msg, N'فشل تنفيذ العملية') AS Message_;
                RETURN;
            END

            IF @tc = 0 AND XACT_STATE() = 1 COMMIT;
            SELECT 1 AS IsSuccessful, @msg AS Message_;
            RETURN;
        END

        ----------------------------------------------------------------
        -- PageName غير معروف
        ----------------------------------------------------------------
        ELSE
        BEGIN
            IF @tc = 0 AND XACT_STATE() = 1 ROLLBACK;
            SELECT 0 AS IsSuccessful, N'الصفحة المرسلة مقيدة. PageName' AS Message_;
            RETURN;
        END

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        DECLARE @IdCatch BIGINT = NULL;

        IF @tc = 0 AND XACT_STATE() <> 0
            ROLLBACK;

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
                   N'حصل خطأ غير معروف رمز الخطأ : ' + CAST(@IdCatch AS NVARCHAR(200)) 
                   AS Message_;
        ELSE
            SELECT 0 AS IsSuccessful,
                   N'حصل خطأ غير معروف ولم يتم تسجيله في ErrorLog' AS Message_;
    END CATCH
END
