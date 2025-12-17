USE [DATACORE]
GO
/****** Object:  Table [dbo].[Permission]    Script Date: 17/12/2025 11:35:24 م ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Permission](
	[permissionID] [bigint] IDENTITY(1,1) NOT NULL,
	[DistributorPermissionTypeID_FK] [int] NULL,
	[UserID_FK] [bigint] NULL,
	[distributorID_FK] [bigint] NULL,
	[IdaraID_FK] [bigint] NULL,
	[RoleID_FK] [bigint] NULL,
	[deptID_FK] [bigint] NULL,
	[secID_FK] [bigint] NULL,
	[divID_FK] [bigint] NULL,
	[permissionStartDate] [datetime] NULL,
	[permissionEndDate] [datetime] NULL,
	[permissionActive] [bit] NULL,
	[permissionNote] [nvarchar](2000) NULL,
	[entryDate] [datetime] NULL,
	[entryData] [nvarchar](20) NULL,
	[hostName] [nvarchar](200) NULL,
 CONSTRAINT [PK_permission] PRIMARY KEY CLUSTERED 
(
	[permissionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Permission] ADD  CONSTRAINT [DF_permission_entryDate]  DEFAULT (getdate()) FOR [entryDate]
GO
/****** Object:  StoredProcedure [dbo].[Masters_DataLoad]    Script Date: 17/12/2025 11:35:25 م ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Masters_DataLoad]
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
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------------
    --                   START TRY BLOCK
    -------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION;

    -------------------------------------------------------------------
    --                     PAGE: Permission
    -------------------------------------------------------------------
        IF @pageName_ = 'Permission'
        BEGIN
            -- User Permission
             SELECT permissionTypeName_E
            FROM dbo.ft_UserPagePermissions(@entrydata, @pageName_);

            -- Permission Data


            

            --by user
            if(@parameter_01 = 1)
            BEGIN
            SELECT 
                  p.permissionID
                , p.userID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , ISNULL(CONVERT(NVARCHAR(10), p.permissionEndDate, 23), N'غير محدد') AS permissionEndDate
                , p.permissionNote
            FROM DATACORE.dbo.V_GetListUserPermission p
            INNER JOIN DATACORE.dbo.V_GetListUsersInDSD d ON p.userID = d.userID
            INNER JOIN DATACORE.dbo.V_GetFullStructureForDSD f ON f.DSDID = d.DSDID
            WHERE f.idaraID_FK = @idaraID
              AND p.userID = @parameter_02
            ORDER BY p.permissionID DESC;
            END
          

            --by Distributors
            else if (@parameter_01 = 2)
            Begin
            SELECT 
                  p.permissionID
                , p.userID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , ISNULL(CONVERT(NVARCHAR(10), p.permissionEndDate, 23), N'غير محدد') AS permissionEndDate
                , p.permissionNote
            FROM DATACORE.dbo.V_GetListUserPermission p
            INNER JOIN DATACORE.dbo.V_GetListUsersInDSD d ON p.userID = d.userID
            INNER JOIN DATACORE.dbo.V_GetFullStructureForDSD f ON f.DSDID = d.DSDID
            WHERE f.idaraID_FK = @idaraID
              AND p.distributorID = @parameter_03
            ORDER BY p.permissionID DESC;
            END

              --by Roles
            else if(@parameter_01 = 3)
            Begin
            SELECT 
                  p.permissionID
                , p.userID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , ISNULL(CONVERT(NVARCHAR(10), p.permissionEndDate, 23), N'غير محدد') AS permissionEndDate
                , p.permissionNote
            FROM DATACORE.dbo.V_GetListUserPermission p
            INNER JOIN DATACORE.dbo.V_GetListUsersInDSD d ON p.userID = d.userID
            INNER JOIN DATACORE.dbo.V_GetFullStructureForDSD f ON f.DSDID = d.DSDID
            WHERE f.idaraID_FK = @idaraID
              AND p.RoleID_FK = @parameter_04
            ORDER BY p.permissionID DESC;
            END
            
            ----by idara
            else if(@parameter_01 = 4)
            Begin
            SELECT 
                  p.permissionID
                , p.userID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , ISNULL(CONVERT(NVARCHAR(10), p.permissionEndDate, 23), N'غير محدد') AS permissionEndDate
                , p.permissionNote
            FROM DATACORE.dbo.V_GetListUserPermission p
            INNER JOIN DATACORE.dbo.V_GetListUsersInDSD d ON p.userID = d.userID
            INNER JOIN DATACORE.dbo.V_GetFullStructureForDSD f ON f.DSDID = d.DSDID
            WHERE f.idaraID_FK = @idaraID
              AND p.IdaraID_FK = @parameter_05
            ORDER BY p.permissionID DESC;
            END

            
              --by Depts
            else if(@parameter_01 = 5 and @parameter_06 is not null and @parameter_07 is null and @parameter_08 is null)
            Begin
            SELECT 
                  p.permissionID
                , p.userID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , ISNULL(CONVERT(NVARCHAR(10), p.permissionEndDate, 23), N'غير محدد') AS permissionEndDate
                , p.permissionNote
            FROM DATACORE.dbo.V_GetListUserPermission p
            INNER JOIN DATACORE.dbo.V_GetListUsersInDSD d ON p.userID = d.userID
            INNER JOIN DATACORE.dbo.V_GetFullStructureForDSD f ON f.DSDID = d.DSDID
            WHERE f.idaraID_FK = @idaraID
              AND p.deptID_FK = @parameter_06
            ORDER BY p.permissionID DESC;
            END

            -- --by Sections
            --if(@parameter_01 is  null and @parameter_02 is  null and @parameter_03 is null and @parameter_04 is not null and @parameter_05 is not null and @parameter_06 is null and @parameter_07 is null )
            --Begin
            --SELECT 
            --      p.permissionID
            --    , p.userID
            --    , p.menuName_A
            --    , p.permissionTypeName_A
            --    , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
            --    , ISNULL(CONVERT(NVARCHAR(10), p.permissionEndDate, 23), N'غير محدد') AS permissionEndDate
            --    , p.permissionNote
            --FROM DATACORE.dbo.V_GetListUserPermission p
            --INNER JOIN DATACORE.dbo.V_GetListUsersInDSD d ON p.userID = d.userID
            --INNER JOIN DATACORE.dbo.V_GetFullStructureForDSD f ON f.DSDID = d.DSDID
            --WHERE f.idaraID_FK = @idaraID
            --  AND p.secID_FK = @parameter_05
            --ORDER BY p.permissionID DESC;
            --END

            --  --by Divisons
            --if(@parameter_01 is  null and @parameter_02 is  null and @parameter_03 is null and @parameter_04 is not null and @parameter_05 is not null and @parameter_06 is not null and @parameter_07 is null )
            --Begin
            --SELECT 
            --      p.permissionID
            --    , p.userID
            --    , p.menuName_A
            --    , p.permissionTypeName_A
            --    , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
            --    , ISNULL(CONVERT(NVARCHAR(10), p.permissionEndDate, 23), N'غير محدد') AS permissionEndDate
            --    , p.permissionNote
            --FROM DATACORE.dbo.V_GetListUserPermission p
            --INNER JOIN DATACORE.dbo.V_GetListUsersInDSD d ON p.userID = d.userID
            --INNER JOIN DATACORE.dbo.V_GetFullStructureForDSD f ON f.DSDID = d.DSDID
            --WHERE f.idaraID_FK = @idaraID
            --  AND p.divID_FK = @parameter_06
            --ORDER BY p.permissionID DESC;
            --END

           

              ELSE
            BEGIN

            SELECT 
                  p.permissionID
                , p.userID
                , p.menuName_A
                , p.permissionTypeName_A
                , CONVERT(NVARCHAR(50), p.permissionStartDate, 23) AS permissionStartDate
                , ISNULL(CONVERT(NVARCHAR(10), p.permissionEndDate, 23), N'غير محدد') AS permissionEndDate
                , p.permissionNote
            FROM DATACORE.dbo.V_GetListUserPermission p
            INNER JOIN DATACORE.dbo.V_GetListUsersInDSD d ON p.userID = d.userID
            INNER JOIN DATACORE.dbo.V_GetFullStructureForDSD f ON f.DSDID = d.DSDID
            WHERE f.idaraID_FK = @idaraID
              AND p.userID = @parameter_01
            ORDER BY p.permissionID DESC;

            END





            -- Users DDL
            SELECT DISTINCT 
                  CAST(d.userID AS BIGINT) AS userID_
                , CAST(d.userID AS NVARCHAR(20)) + ' - ' + d.FullName AS FullName
                , d.userTypeID
            FROM DATACORE.dbo.V_GetFullStructureForDSD f
            INNER JOIN DATACORE.dbo.V_GetListUsersInDSD d ON f.DSDID = d.DSDID
            WHERE f.idaraID_FK = 1 
              AND d.userID IS NOT NULL
            ORDER BY d.userTypeID ASC;

            -- Distributors DDL
            SELECT d.distributorID, d.distributorName_A
            FROM DATACORE.dbo.Distributor d
            INNER JOIN DATACORE.dbo.MenuDistributor md ON d.distributorID = md.distributorID_FK
            WHERE d.distributorActive = 1 
              AND md.menuDistributorActive = 1;

           
            -- Permission Types DDL
            SELECT 
                  dpt.distributorPermissionTypeID
                , pt.permissionTypeName_A
                , dpt.distributorID_FK
            FROM DATACORE.dbo.DistributorPermissionType dpt
            INNER JOIN DATACORE.dbo.PermissionType pt ON dpt.permissionTypeID_FK = pt.permissionTypeID
            WHERE pt.permissionTypeActive = 1 
              AND dpt.distributorPermissionTypeActive = 1;

              -- IDara DDL
            SELECT distinct D.idaraID,D.idaraLongName_A 
            FROM DATACORE.DBO.Idara D
            order by D.idaraID asc


               -- Dept DDL
            SELECT distinct D.deptID,D.deptName_A ,d.idaraID_FK
            FROM DATACORE.DBO.Department D
            WHERE D.deptActive = 1 

            -- Section DDL
            SELECT distinct s.secID,s.secName_A,a.deptID
            FROM DATACORE.DBO.Section s
            inner join DATACORE.dbo.DeptSecDiv d on s.secID =d.secID_FK
            inner join DATACORE.dbo.Department a on d.deptID_FK = a.deptID
            WHERE s.secActive = 1 

            
            -- Divison DDL
            SELECT distinct s.divID,s.divName_A,a.secID
            FROM DATACORE.DBO.Divison s
            inner join DATACORE.dbo.DeptSecDiv d on s.divID =d.divID_FK
             inner join DATACORE.dbo.Section a on d.secID_FK= a.secID
            WHERE s.divActive = 1 

            -- Role DDL
            select r.roleID,r.roleName_A 
            from DATACORE.dbo.[Role] r


          
        END

    -------------------------------------------------------------------
    --                     PAGE: BuildingType
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'BuildingType'
        BEGIN
            -- User Permission
             SELECT permissionTypeName_E
            FROM dbo.ft_UserPagePermissions(@entrydata, @pageName_);

            -- BuildingType Data
            SELECT 
                  t.buildingTypeID
                , t.buildingTypeCode
                , t.buildingTypeName_A
                , t.buildingTypeName_E
                , t.buildingTypeDescription
            FROM DATACORE.Housing.BuildingType t
            WHERE t.buildingTypeActive = 1;

            -- Cities DDL
            SELECT c.cityID, c.cityName_A
            FROM DATACORE.dbo.City c
            WHERE c.cityActive = 1;
        END

    -------------------------------------------------------------------
    --                     PAGE: BuildingClass
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'BuildingClass'
        BEGIN
            -- User Permission
           SELECT permissionTypeName_E
            FROM dbo.ft_UserPagePermissions(@entrydata, @pageName_);

            -- Building Class Data
            SELECT 
                  c.buildingClassID
                , c.buildingClassName_A
                , c.buildingClassName_E
                , c.buildingClassDescription
                , c.buildingClassOrder
                , c.buildingClassActive
            FROM DATACORE.Housing.BuildingClass c
            WHERE c.buildingClassActive = 1;
        END

    -------------------------------------------------------------------
    --                     PAGE: buildingUtilityType
    -------------------------------------------------------------------
        ELSE IF @pageName_ = 'buildingUtilityType'
        BEGIN
            -- User Permission
           SELECT permissionTypeName_E
            FROM dbo.ft_UserPagePermissions(@entrydata, @pageName_);


            -- Utility Type Data
            SELECT 
                  t.buildingUtilityTypeID
                , t.buildingUtilityTypeName_A
                , t.buildingUtilityTypeName_E
                , t.buildingUtilityTypeDescription
                , t.buildingUtilityTypeActive
                , convert(nvarchar(10),t.buildingUtilityTypeStartDate,23) buildingUtilityTypeStartDate
                , convert(nvarchar(10),t.buildingUtilityTypeEndDate,23) buildingUtilityTypeEndDate
                , CASE 
                    WHEN t.buildingUtilityIsRent = 0 THEN N'0'
                    WHEN t.buildingUtilityIsRent = 1 THEN N'1'
                    ELSE N''
                  END AS buildingUtilityIsRent
            FROM DATACORE.Housing.buildingUtilityType t
            WHERE t.buildingUtilityTypeActive = 1
            ORDER BY t.buildingUtilityTypeID DESC;
        END

    -------------------------------------------------------------------
    --                     PAGE NOT FOUND
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

        INSERT INTO DATACORE.dbo.ErrorLog
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
/****** Object:  StoredProcedure [dbo].[PermissionSP]    Script Date: 17/12/2025 11:35:25 م ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PermissionSP]
(
      @Action                          NVARCHAR(200)
    , @PermissionID                    BIGINT          = NULL
    , @DistributorPermissionTypeID_FK  BIGINT          = NULL
    , @DistributorID_FK                BIGINT          = NULL
    , @UserID_FK                       NVARCHAR(100)   = NULL
    , @permissionStartDate             NVARCHAR(100)   = NULL
    , @permissionEndDate               NVARCHAR(1000)  = NULL
    , @permissionNote                  NVARCHAR(2000)  = NULL
    , @permissionActive                BIT             = NULL
    , @entryData                       NVARCHAR(20)    = NULL
    , @hostName                        NVARCHAR(200)   = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
          @NewID                 INT
        , @Note                  NVARCHAR(MAX)
        , @Identity_Insert       INT
        , @Identity_Update       INT
        , @Identity_Delete       INT
        , @PermissionStartDateDT DATETIME;

    SET @PermissionStartDateDT = TRY_CONVERT(DATETIME, NULLIF(@permissionStartDate, ''), 120);

    ----------------------------------------------------------------
    -- تحديث صلاحيات منتهية (خارج الترانزاكشن الرئيسية)
    ----------------------------------------------------------------
    UPDATE DATACORE.dbo.Permission
    SET permissionActive = 0
    WHERE CAST(permissionEndDate AS DATE) < CAST(GETDATE() AS DATE);

    UPDATE DATACORE.dbo.Permission
    SET permissionEndDate = CAST(GETDATE() AS DATE)
    WHERE permissionActive = 0
      AND permissionEndDate IS NULL;

    UPDATE DATACORE.dbo.UserDistributor
    SET UDActive = 0
    WHERE CAST(UDEndDate AS DATE) < CAST(GETDATE() AS DATE);

    UPDATE DATACORE.dbo.UserDistributor
    SET UDEndDate = CAST(GETDATE() AS DATE)
    WHERE UDActive = 0
      AND UDEndDate IS NULL;

    ----------------------------------------------------------------
    -- المنطق الرئيسي
    ----------------------------------------------------------------
    BEGIN TRY

        ------------------------------------------------------------
        -- INSERT
        ------------------------------------------------------------
        IF @Action = 'INSERT'
        BEGIN
            IF (@UserID_FK IS NULL OR LTRIM(RTRIM(@UserID_FK)) = '')
            BEGIN
                SELECT 0 AS IsSuccessful, N'الرجاء اختيار المستخدم اولا' AS Message_;
                RETURN;
            END

            IF
            (
                SELECT COUNT(*)
                FROM DATACORE.dbo.Permission p
                INNER JOIN DATACORE.dbo.DistributorPermissionType dt
                    ON p.DistributorPermissionTypeID_FK = dt.distributorPermissionTypeID
                INNER JOIN DATACORE.dbo.UserDistributor ud
                    ON ud.distributorID_FK = dt.distributorID_FK
                WHERE p.DistributorPermissionTypeID_FK = @DistributorPermissionTypeID_FK
                  AND p.UserID_FK = @UserID_FK
                  AND p.permissionActive = 1
                  AND dt.distributorPermissionTypeActive = 1
                  AND ud.UDActive = 1
                  AND (p.permissionEndDate IS NULL
                       OR CAST(p.permissionEndDate AS DATE) > CAST(GETDATE() AS DATE))
            ) > 0
            BEGIN
                SELECT 0 AS IsSuccessful, N'البيانات مدخلة مسبقا' AS Message_;
                RETURN;
            END

            -- لو ما عنده UserDistributor فعال -> نضيفه أولاً
            IF
            (
                SELECT COUNT(*)
                FROM DATACORE.dbo.UserDistributor ud
                WHERE ud.distributorID_FK = @DistributorID_FK
                  AND ud.userID_FK = @UserID_FK
                  AND ud.UDActive = 1
                  AND (ud.UDEndDate IS NULL
                       OR CAST(ud.UDEndDate AS DATE) > CAST(GETDATE() AS DATE))
            ) < 1
            BEGIN
                INSERT INTO DATACORE.dbo.UserDistributor
                (
                      [distributorID_FK]
                    , [userID_FK]
                    , [UDStartDate]
                    , [UDActive]
                    , [Note]
                    , [entryData]
                    , [hostName]
                )
                VALUES
                (
                      @DistributorID_FK
                    , @UserID_FK
                    , ISNULL(@PermissionStartDateDT, GETDATE())
                    , 1
                    , NULL
                    , @entryData
                    , @hostName
                );

                SET @Identity_Insert = @@ROWCOUNT;

                IF (@Identity_Insert <= 0)
                BEGIN
                    SELECT 0 AS IsSuccessful, N'حصل خطأ في اضافة البيانات' AS Message_;
                    RETURN;
                END
            END

            -- إضافة صلاحية Permission
            INSERT INTO DATACORE.dbo.Permission
            (
                  [DistributorPermissionTypeID_FK]
                , [UserID_FK]
                , [permissionStartDate]
                , [permissionEndDate]
                , [permissionActive]
                , [permissionNote]
                , [entryData]
                , [hostName]
            )
            VALUES
            (
                  @DistributorPermissionTypeID_FK
                , @UserID_FK
                , ISNULL(@PermissionStartDateDT, GETDATE())
                , @permissionEndDate
                , 1
                , @permissionNote
                , @entryData
                , @hostName
            );

            SET @NewID = SCOPE_IDENTITY();

            SET @Note = '{'
                + '"distributorID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @DistributorID_FK), '') + '"'
                + ',"userID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @UserID_FK), '') + '"'
                + ',"permissionStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionStartDate), '') + '"'
                + ',"permissionEndDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionEndDate), '') + '"'
                + ',"permissionNote": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionNote), '') + '"'
                + ',"DistributorPermissionTypeID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @DistributorPermissionTypeID_FK), '') + '"'
                + ',"entryData": "' + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + '"'
                + ',"hostName": "' + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + '"'
                + '}';

            SET @Identity_Insert = @@ROWCOUNT;

            IF (@Identity_Insert > 0)
            BEGIN
                INSERT INTO DATACORE.dbo.AuditLog
                (
                      TableName
                    , ActionType
                    , RecordID
                    , PerformedBy
                    , Notes
                )
                VALUES
                (
                      '[dbo].[PermissionSP]'
                    , 'INSERT'
                    , @NewID
                    , @entryData
                    , @Note
                );

                SELECT 1 AS IsSuccessful, N'تم اضافة البيانات بنجاح' AS Message_;
            END
            ELSE
            BEGIN
                SELECT 0 AS IsSuccessful, N'حصل خطأ في اضافة البيانات' AS Message_;
            END

            RETURN;
        END

        ------------------------------------------------------------
        -- INSERTFULLACCESS
        ------------------------------------------------------------
        ELSE IF @Action = 'INSERTFULLACCESS'
        BEGIN
            INSERT INTO DATACORE.dbo.Permission
            (
                  DistributorPermissionTypeID_FK
                , UserID_FK
                , permissionStartDate
                , permissionEndDate
                , permissionNote
                , permissionActive
                , entryData
                , hostName
            )
            SELECT
                  dt.distributorPermissionTypeID
                , @UserID_FK
                , ISNULL(@PermissionStartDateDT, GETDATE())
                , @permissionEndDate
                , @permissionNote
                , 1
                , @entryData
                , @hostName
            FROM DATACORE.dbo.DistributorPermissionType dt
            INNER JOIN DATACORE.dbo.PermissionType p
                ON dt.permissionTypeID_FK = p.permissionTypeID
            WHERE dt.distributorID_FK = @DistributorID_FK
              AND dt.distributorPermissionTypeActive = 1
              AND p.permissionTypeActive = 1
              AND CAST(dt.distributorPermissionTypeStartDate AS DATE) <= CAST(GETDATE() AS DATE)
              AND (CAST(dt.distributorPermissionTypeEndDate AS DATE) > CAST(GETDATE() AS DATE)
                   OR dt.distributorPermissionTypeEndDate IS NULL)
              AND dt.distributorPermissionTypeID NOT IN
              (
                    SELECT r.DistributorPermissionTypeID_FK
                    FROM DATACORE.dbo.Permission r
                    WHERE r.permissionActive = 1
                      AND CAST(r.permissionStartDate AS DATE) <= CAST(GETDATE() AS DATE)
                      AND (CAST(r.permissionEndDate AS DATE) > CAST(GETDATE() AS DATE)
                           OR r.permissionEndDate IS NULL)
                      AND r.UserID_FK = @UserID_FK
              );

            SET @Identity_Insert = @@ROWCOUNT;

            SET @NewID = SCOPE_IDENTITY();

            SET @Note = '{'
                + '"distributorID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @DistributorID_FK), '') + '"'
                + ',"userID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @UserID_FK), '') + '"'
                + ',"permissionStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionStartDate), '') + '"'
                + ',"permissionEndDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionEndDate), '') + '"'
                + ',"permissionNote": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionNote), '') + '"'
                + ',"entryData": "' + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + '"'
                + ',"hostName": "' + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + '"'
                + '}';

            IF (@Identity_Insert > 0)
            BEGIN
                INSERT INTO DATACORE.dbo.AuditLog
                (
                      TableName
                    , ActionType
                    , RecordID
                    , PerformedBy
                    , Notes
                )
                VALUES
                (
                      '[dbo].[PermissionSP]'
                    , 'INSERTFULLACCESS'
                    , @NewID
                    , @entryData
                    , @Note
                );

                SELECT 1 AS IsSuccessful, N'تم اضافة البيانات بنجاح' AS Message_;
            END
            ELSE
            BEGIN
                SELECT 0 AS IsSuccessful, N'حصل خطأ في اضافة البيانات او الموظف يملك جميع الصلاحيات' AS Message_;
            END

            RETURN;
        END

        ------------------------------------------------------------
        -- UPDATE (لم تُنفّذ بعد)
        ------------------------------------------------------------
        ELSE IF @Action = 'UPDATE'
        BEGIN
            SELECT 1 AS IsSuccessful, N'تحديث غير مفعّل حالياً' AS Message_;
            RETURN;
        END

        ------------------------------------------------------------
        -- DELETE (إيقاف صلاحية)
        ------------------------------------------------------------
        ELSE IF @Action = 'DELETE'
        BEGIN
            IF EXISTS
            (
                SELECT 1
                FROM DATACORE.dbo.Permission
                WHERE permissionID = @PermissionID
            )
            BEGIN
                UPDATE DATACORE.dbo.Permission
                SET permissionEndDate = CAST(GETDATE() AS DATE),
                    permissionActive = 0
                WHERE permissionID = @PermissionID;

                SET @Identity_Update = @@ROWCOUNT;

                SET @Note = '{'
                    + '"PermissionID": "' + ISNULL(CONVERT(NVARCHAR(MAX), @PermissionID), '') + '"'
                    + ',"DistributorPermissionTypeID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @DistributorPermissionTypeID_FK), '') + '"'
                    + ',"userID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @UserID_FK), '') + '"'
                    + ',"permissionStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionStartDate), '') + '"'
                    + ',"permissionEndDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionEndDate), '') + '"'
                    + ',"permissionNote": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionNote), '') + '"'
                    + ',"entryData": "' + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + '"'
                    + ',"hostName": "' + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + '"'
                    + '}';

                IF (@Identity_Update > 0)
                BEGIN
                    INSERT INTO DATACORE.dbo.AuditLog
                    (
                          TableName
                        , ActionType
                        , RecordID
                        , PerformedBy
                        , Notes
                    )
                    VALUES
                    (
                          '[dbo].[PermissionSP]'
                        , 'DELETE'
                        , @PermissionID
                        , @entryData
                        , @Note
                    );

                    SELECT 1 AS IsSuccessful, N'تم حذف البيانات بنجاح' AS Message_;
                END
                ELSE
                BEGIN
                    SELECT 0 AS IsSuccessful, N'حصل خطأ في حذف البيانات' AS Message_;
                END
            END
            ELSE
            BEGIN
                SELECT 0 AS IsSuccessful, N'حصل خطأ في حذف البيانات x' AS Message_;
            END

            RETURN;
        END

        ------------------------------------------------------------
        -- Action غير معروف
        ------------------------------------------------------------
        ELSE
        BEGIN
            SELECT 0 AS IsSuccessful, N'العملية غير مسجلة' AS Message_;
            RETURN;
        END

    END TRY
    BEGIN CATCH

        DECLARE
              @ErrMsg NVARCHAR(4000)
            , @ErrSeverity INT
            , @ErrState INT
            , @IdentityCatchError INT;

        SELECT
              @ErrMsg = ERROR_MESSAGE()
            , @ErrSeverity = ERROR_SEVERITY()
            , @ErrState = ERROR_STATE();

        -- لا يوجد ROLLBACK هنا لأن الترانزاكشن تُدار من SP خارجي (Masters_CRUD)

        BEGIN TRY
            INSERT INTO DATACORE.dbo.ErrorLog
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
                , N'[dbo].[PermissionSP]'
                , @entryData
                , @hostName
            );

            SET @IdentityCatchError = SCOPE_IDENTITY();
        END TRY
        BEGIN CATCH
            SET @IdentityCatchError = NULL;
        END CATCH;

        IF @IdentityCatchError IS NOT NULL
        BEGIN
            SELECT
                  0 AS IsSuccessful
                , N'حصل خطأ غير معروف رمز الخطأ : ' + CAST(@IdentityCatchError AS NVARCHAR(200)) AS Message_;
        END
        ELSE
        BEGIN
            SELECT
                  0 AS IsSuccessful
                , N'حصل خطأ غير معروف ولم يتم تسجيله في ErrorLog' AS Message_;
        END

    END CATCH
END
GO
