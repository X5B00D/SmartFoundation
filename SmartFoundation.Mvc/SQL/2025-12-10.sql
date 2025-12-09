USE [DATACORE]
GO
/****** Object:  View [dbo].[V_GetListUserPermission]    Script Date: 10/12/2025 01:18:21 ص ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_GetListUserPermission]
AS
SELECT        p.UserID_FK AS userID, m.menuName_A, m.menuName_E, pt.permissionTypeName_A, pt.permissionTypeName_E, m.menuID, md.menuDistributorID, d.distributorID, dpt.distributorPermissionTypeID, p.permissionID, 
                         p.DistributorPermissionTypeID_FK, pt.permissionTypeID, p.permissionStartDate, p.permissionEndDate, p.permissionActive, p.entryDate, p.entryData, p.hostName, dpt.distributorPermissionTypeStartDate, 
                         dpt.distributorPermissionTypeEndDate, dpt.distributorPermissionTypeActive, p.permissionNote
FROM            dbo.Menu AS m INNER JOIN
                         dbo.MenuDistributor AS md ON md.menuID_FK = m.menuID INNER JOIN
                         dbo.Distributor AS d ON md.distributorID_FK = d.distributorID INNER JOIN
                         dbo.distributorPermissionType AS dpt ON d.distributorID = dpt.distributorID_FK INNER JOIN
                         dbo.Permission AS p ON dpt.distributorPermissionTypeID = p.DistributorPermissionTypeID_FK INNER JOIN
                         dbo.PermissionType AS pt ON pt.permissionTypeID = dpt.permissionTypeID_FK
WHERE        (m.menuActive = 1) AND (md.menuDistributorActive = 1) AND (d.distributorActive = 1) AND (dpt.distributorPermissionTypeActive = 1) AND (p.permissionActive = 1) AND (pt.permissionTypeActive = 1) AND 
                         (dpt.distributorPermissionTypeStartDate IS NOT NULL) AND (CAST(dpt.distributorPermissionTypeStartDate AS date) <= CAST(GETDATE() AS date)) AND (p.permissionStartDate IS NOT NULL) AND 
                         (CAST(p.permissionEndDate AS date) >= CAST(GETDATE() AS date)) AND (dpt.distributorPermissionTypeEndDate IS NULL) OR
                         (m.menuActive = 1) AND (md.menuDistributorActive = 1) AND (d.distributorActive = 1) AND (dpt.distributorPermissionTypeActive = 1) AND (p.permissionActive = 1) AND (pt.permissionTypeActive = 1) AND 
                         (dpt.distributorPermissionTypeStartDate IS NOT NULL) AND (CAST(dpt.distributorPermissionTypeStartDate AS date) <= CAST(GETDATE() AS date)) AND (p.permissionStartDate IS NOT NULL) AND 
                         (CAST(p.permissionEndDate AS date) >= CAST(GETDATE() AS date)) AND (CAST(dpt.distributorPermissionTypeEndDate AS date) >= CAST(GETDATE() AS date)) OR
                         (m.menuActive = 1) AND (md.menuDistributorActive = 1) AND (d.distributorActive = 1) AND (dpt.distributorPermissionTypeActive = 1) AND (p.permissionActive = 1) AND (pt.permissionTypeActive = 1) AND 
                         (dpt.distributorPermissionTypeStartDate IS NOT NULL) AND (CAST(dpt.distributorPermissionTypeStartDate AS date) <= CAST(GETDATE() AS date)) AND (p.permissionStartDate IS NOT NULL) AND 
                         (dpt.distributorPermissionTypeEndDate IS NULL) AND (p.permissionEndDate IS NULL) OR
                         (m.menuActive = 1) AND (md.menuDistributorActive = 1) AND (d.distributorActive = 1) AND (dpt.distributorPermissionTypeActive = 1) AND (p.permissionActive = 1) AND (pt.permissionTypeActive = 1) AND 
                         (dpt.distributorPermissionTypeStartDate IS NOT NULL) AND (CAST(dpt.distributorPermissionTypeStartDate AS date) <= CAST(GETDATE() AS date)) AND (p.permissionStartDate IS NOT NULL) AND 
                         (CAST(dpt.distributorPermissionTypeEndDate AS date) >= CAST(GETDATE() AS date)) AND (p.permissionEndDate IS NULL)
GO
/****** Object:  StoredProcedure [dbo].[Masters_CRUD]    Script Date: 10/12/2025 01:18:21 ص ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Masters_CRUD]
    @pageName_ NVARCHAR(400),
    @ActionType NVARCHAR(100) , -- INSERT, UPDATE, DELETE
	@idaraID INT,
	@entrydata INT,
	@hostName	  NVARCHAR(4000) = NULL,
    @parameter_01 NVARCHAR(4000) = NULL,
    @parameter_02 NVARCHAR(4000) = NULL,
    @parameter_03 NVARCHAR(4000) = NULL,
    @parameter_04 NVARCHAR(4000) = NULL,
    @parameter_05 NVARCHAR(4000) = NULL,
    @parameter_06 NVARCHAR(4000) = NULL,
    @parameter_07 NVARCHAR(4000) = NULL,
    @parameter_08 NVARCHAR(4000) = NULL,
    @parameter_09 NVARCHAR(4000) = NULL,
    @parameter_10 NVARCHAR(4000) = NULL,
    @parameter_11 NVARCHAR(4000) = NULL,
    @parameter_12 NVARCHAR(4000) = NULL,
    @parameter_13 NVARCHAR(4000) = NULL,
    @parameter_14 NVARCHAR(4000) = NULL,
    @parameter_15 NVARCHAR(4000) = NULL,
    @parameter_16 NVARCHAR(4000) = NULL,
    @parameter_17 NVARCHAR(4000) = NULL,
    @parameter_18 NVARCHAR(4000) = NULL,
    @parameter_19 NVARCHAR(4000) = NULL,
    @parameter_20 NVARCHAR(4000) = NULL,
    @parameter_21 NVARCHAR(4000) = NULL,
    @parameter_22 NVARCHAR(4000) = NULL,
    @parameter_23 NVARCHAR(4000) = NULL,
    @parameter_24 NVARCHAR(4000) = NULL,
    @parameter_25 NVARCHAR(4000) = NULL,
    @parameter_26 NVARCHAR(4000) = NULL,
    @parameter_27 NVARCHAR(4000) = NULL,
    @parameter_28 NVARCHAR(4000) = NULL,
    @parameter_29 NVARCHAR(4000) = NULL,
    @parameter_30 NVARCHAR(4000) = NULL,
    @parameter_31 NVARCHAR(4000) = NULL,
    @parameter_32 NVARCHAR(4000) = NULL,
    @parameter_33 NVARCHAR(4000) = NULL,
    @parameter_34 NVARCHAR(4000) = NULL,
    @parameter_35 NVARCHAR(4000) = NULL,
    @parameter_36 NVARCHAR(4000) = NULL,
    @parameter_37 NVARCHAR(4000) = NULL,
    @parameter_38 NVARCHAR(4000) = NULL,
    @parameter_39 NVARCHAR(4000) = NULL,
    @parameter_40 NVARCHAR(4000) = NULL,
    @parameter_41 NVARCHAR(4000) = NULL,
    @parameter_42 NVARCHAR(4000) = NULL,
    @parameter_43 NVARCHAR(4000) = NULL,
    @parameter_44 NVARCHAR(4000) = NULL,
    @parameter_45 NVARCHAR(4000) = NULL,
    @parameter_46 NVARCHAR(4000) = NULL,
    @parameter_47 NVARCHAR(4000) = NULL,
    @parameter_48 NVARCHAR(4000) = NULL,
    @parameter_49 NVARCHAR(4000) = NULL,
    @parameter_50 NVARCHAR(4000) = NULL
    
AS
BEGIN
    SET NOCOUNT ON;

	--/////////////////// Start OF CHECK PERMISSION NEVER TOUCH PLEASE ///////////--




	--/////////////////// END OF CHECK PERMISSION NEVER TOUCH PLEASE ///////////--

    BEGIN TRY
       DECLARE @tc int = @@TRANCOUNT;
       IF @tc = 0 BEGIN TRANSACTION; 


	   				---/////////////////////--Start Permission Page SP--////////////////////////--


        IF @pageName_ ='Permission'
        BEGIN
                -- عملية INSERT
           IF @ActionType = 'INSERT'
              BEGIN
				IF(select count(*) FROM DATACORE.dbo.V_GetListUserPermission v where v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType) > 0
				--GetListUserPermission(@entrydata,@pageName_,@ActionType)
				Begin

                    EXEC [dbo].[PermissionSP]
                        @Action =    @ActionType
					   ,@DistributorID_FK = @parameter_01
					   ,@DistributorPermissionTypeID_FK =@parameter_02
					   ,@permissionStartDate 	=@parameter_03
                       ,@permissionEndDate 	=@parameter_04
                       ,@permissionNote =@parameter_05
                       ,@UserID_FK 		=@parameter_06
					   ,@entryData 					=@entrydata
					   ,@hostName 					=@hostName

              END
           
				ELSE
			 BEGIN
				SELECT 0 As IsSuccessful,N'عفوا لاتملك صلاحية لهذه العملية' AS Message_
		     END
       
		END
				

                -- عملية UPDATE
                ELSE IF @ActionType = 'UPDATE'
                BEGIN
				IF(select count(*) FROM DATACORE.dbo.V_GetListUserPermission v where v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType) > 0
				Begin
                    EXEC [dbo].[PermissionSP]
                        @Action =    @ActionType
                       ,@PermissionID = @parameter_01
					   ,@DistributorID_FK = @parameter_02
					   ,@DistributorPermissionTypeID_FK =@parameter_03
					   ,@permissionStartDate 	=@parameter_04
                       ,@UserID_FK 		=@parameter_05
					   ,@permissionEndDate 	=@parameter_06
					   ,@permissionActive 	= @parameter_07
					   ,@entryData 					=@entrydata
					   ,@hostName 					=@hostName
                END
				
				ELSE
			 BEGIN
				SELECT 0 As IsSuccessful,N'عفوا لاتملك صلاحية لهذه العملية' AS Message_
		     END
			 END


                -- عملية DELETE
                ELSE IF @ActionType = 'DELETE'
                BEGIN
            IF(select count(*) FROM DATACORE.dbo.V_GetListUserPermission v where v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType) > 0
				Begin
                       EXEC [dbo].[PermissionSP]
                        @Action =    @ActionType
                       ,@PermissionID = @parameter_01
					   ,@DistributorID_FK = @parameter_02
					   ,@DistributorPermissionTypeID_FK =@parameter_03
					   ,@permissionStartDate 	=@parameter_04
                       ,@UserID_FK 		=@parameter_05
					   ,@permissionEndDate 	=@parameter_06
					   ,@permissionActive 	= @parameter_07
					   ,@entryData 					=@entrydata
					   ,@hostName 					=@hostName
                END

				ELSE
			 BEGIN
				SELECT 0 As IsSuccessful,N'عفوا لاتملك صلاحية لهذه العملية' AS Message_
		     END
			 END

			 ----///////////////////////////////////// DOWN CODE IF ActionType Not Exist /////////////////////////////////////////---
                ELSE
                BEGIN
                   SELECT 0 As IsSuccessful,N'نوع العملية المطلوبة غير معروف. ActionType' AS Message_
                END
			----///////////////////////////////////// UP CODE IF ActionType Not Exist /////////////////////////////////////////---

        
    END
	


			---/////////////////////--END BuildingClassSP Page SP--////////////////////////--






					---/////////////////////--Start BuildingType Page SP--////////////////////////--


        IF @pageName_ ='BuildingType'
        BEGIN
                -- عملية INSERT
           IF @ActionType = 'INSERT'
              BEGIN
				IF(select count(*) FROM DATACORE.dbo.V_GetListUserPermission v where v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType) > 0
				--GetListUserPermission(@entrydata,@pageName_,@ActionType)
				Begin
                    EXEC [Housing].[BuildingTypeSP]
                        @Action =    @ActionType
					   ,@buildingTypeID				=null
					   ,@buildingTypeCode			=@parameter_01
					   ,@buildingTypeName_A 		=@parameter_02
					   ,@buildingTypeName_E 		=@parameter_03
					   ,@buildingTypeDescription 	=@parameter_04
					   ,@entryData 					=@entrydata
					   ,@hostName 					=@hostName

              END
				ELSE
			 BEGIN
        
				SELECT 0 As IsSuccessful,N'عفوا لاتملك صلاحية لهذه العملية' AS Message_
		     END
		END
				

                -- عملية UPDATE
                ELSE IF @ActionType = 'UPDATE'
                BEGIN
				IF(select count(*) FROM DATACORE.dbo.V_GetListUserPermission v where v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType) > 0
				Begin
                    EXEC [Housing].[BuildingTypeSP]
                       @Action =    @ActionType
					   ,@buildingTypeID				=@parameter_01
					   ,@buildingTypeCode			=@parameter_02
					   ,@buildingTypeName_A 		=@parameter_03
					   ,@buildingTypeName_E 		=@parameter_04
					   ,@buildingTypeDescription 	=@parameter_05
					   ,@entryData 					=@entrydata
					   ,@hostName 					=@hostName
                END
				
				ELSE
			 BEGIN
				SELECT 0 As IsSuccessful,N'عفوا لاتملك صلاحية لهذه العملية' AS Message_
		     END
			 END


                -- عملية DELETE
                ELSE IF @ActionType = 'DELETE'
                BEGIN
            IF(select count(*) FROM DATACORE.dbo.V_GetListUserPermission v where v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType) > 0
				Begin
                        EXEC [Housing].[BuildingTypeSP]
                        @Action =    @ActionType
					   ,@buildingTypeID				=@parameter_01
					   ,@entryData 					=@entrydata
					   ,@hostName 					=@hostName
                END

				ELSE
			 BEGIN
				SELECT 0 As IsSuccessful,N'عفوا لاتملك صلاحية لهذه العملية' AS Message_
		     END
			 END

			 ----///////////////////////////////////// DOWN CODE IF ActionType Not Exist /////////////////////////////////////////---
                ELSE
                BEGIN
                   SELECT 0 As IsSuccessful,N'نوع العملية المطلوبة غير معروف. ActionType' AS Message_
                END
			----///////////////////////////////////// UP CODE IF ActionType Not Exist /////////////////////////////////////////---

      
    END
	


			---/////////////////////--END BuildingType Page SP--////////////////////////--




			
					---/////////////////////--Start BuildingClass Page SP--////////////////////////--


        ELSE IF @pageName_ ='BuildingClass'
        BEGIN
                -- عملية INSERT
           IF @ActionType = 'INSERT'
              BEGIN
				IF(select count(*) FROM DATACORE.dbo.V_GetListUserPermission v where v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType) > 0
				--GetListUserPermission(@entrydata,@pageName_,@ActionType)
				Begin
                    EXEC [Housing].[BuildingClassSP]
                        @Action =    @ActionType
					   ,@BuildingClassName_A 		=@parameter_01
					   ,@BuildingClassName_E 		=@parameter_02
					   ,@BuildingClassDescription 	=@parameter_03
					   ,@entryData 					=@entrydata
					   ,@hostName 					=@hostName

              END
				ELSE
			 BEGIN
				SELECT 0 As IsSuccessful,N'عفوا لاتملك صلاحية لهذه العملية' AS Message_
		     END
		END
				

                -- عملية UPDATE
                ELSE IF @ActionType = 'UPDATE'
                BEGIN
				IF(select count(*) FROM DATACORE.dbo.V_GetListUserPermission v where v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType) > 0
				Begin
                    EXEC [Housing].[BuildingClassSP]
                       @Action =    @ActionType
					   ,@BuildingClassID				=@parameter_01
					   ,@BuildingClassName_A 		=@parameter_02
					   ,@BuildingClassName_E 		=@parameter_03
					   ,@BuildingClassDescription 	=@parameter_04
					   ,@entryData 					=@entrydata
					   ,@hostName 					=@hostName
                END
				
				ELSE
			 BEGIN
				SELECT 0 As IsSuccessful,N'عفوا لاتملك صلاحية لهذه العملية' AS Message_
		     END
			 END


                -- عملية DELETE
                ELSE IF @ActionType = 'DELETE'
                BEGIN
            IF(select count(*) FROM DATACORE.dbo.V_GetListUserPermission v where v.userID = @entrydata AND v.menuName_E = @pageName_ AND v.permissionTypeName_E = @ActionType) > 0
				Begin
                        EXEC [Housing].[BuildingClassSP]
                        @Action =    @ActionType
					   ,@BuildingClassID				=@parameter_01
					   ,@BuildingClassName_A 		=@parameter_02
					   ,@BuildingClassName_E 		=@parameter_03
					   ,@BuildingClassDescription 	=@parameter_04
					   ,@entryData 					=@entrydata
					   ,@hostName 					=@hostName
                END

				ELSE
			 BEGIN
				SELECT 0 As IsSuccessful,N'عفوا لاتملك صلاحية لهذه العملية' AS Message_
		     END
			 END

			 ----///////////////////////////////////// DOWN CODE IF ActionType Not Exist /////////////////////////////////////////---
                ELSE
                BEGIN
                   SELECT 0 As IsSuccessful,N'نوع العملية المطلوبة غير معروف. ActionType' AS Message_
                END
			----///////////////////////////////////// UP CODE IF ActionType Not Exist /////////////////////////////////////////---

        
    END
	


			---/////////////////////--END BuildingClassSP Page SP--////////////////////////--










----/////////////////////////////////////NAVER TOUCH DOWN CODE PLEASE/////////////////////////////////////////---
   
    ELSE
    BEGIN
         SELECT 0 As IsSuccessful,N'الصفحة المرسلة مقيدة. PageName' AS Message_
    END


	 COMMIT TRANSACTION;
    END TRY

   BEGIN CATCH
    DECLARE @ErrMsg       NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSeverity  INT           = ERROR_SEVERITY();
    DECLARE @ErrState     INT           = ERROR_STATE();
    DECLARE @IdCatch      INT = NULL;

    -- إذا كانت المعاملة غير قابلة للاعتماد: لازم ROLLBACK أولاً
    IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION;                  -- فكّ المعاملة التالفة أولاً
        INSERT INTO DATACORE.dbo.ErrorLog
        (
            ERROR_MESSAGE_, ERROR_SEVERITY_, ERROR_STATE_,
            SP_NAME, entryData, hostName
        )
        VALUES
        (
            @ErrMsg, @ErrSeverity, @ErrState,
            N'[dbo].[Masters_CRUD]', @entrydata, @hostName
        );
        SET @IdCatch = SCOPE_IDENTITY();
    END
    ELSE IF XACT_STATE() = 1 AND @tc = 0
    BEGIN
        -- لازالت المعاملة صالحة لكننا سنرجع كل شيء
        ROLLBACK TRANSACTION;

        INSERT INTO DATACORE.dbo.ErrorLog
        (
            ERROR_MESSAGE_, ERROR_SEVERITY_, ERROR_STATE_,
            SP_NAME, entryData, hostName
        )
        VALUES
        (
            @ErrMsg, @ErrSeverity, @ErrState,
            N'[dbo].[Masters_CRUD]', @entrydata, @hostName
        );
        SET @IdCatch = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        -- لا توجد معاملة نشطة
        INSERT INTO DATACORE.dbo.ErrorLog
        (
            ERROR_MESSAGE_, ERROR_SEVERITY_, ERROR_STATE_,
            SP_NAME, entryData, hostName
        )
        VALUES
        (
            @ErrMsg, @ErrSeverity, @ErrState,
            N'[dbo].[Masters_CRUD]', @entrydata, @hostName
        );
        SET @IdCatch = SCOPE_IDENTITY();
    END

    IF @IdCatch IS NOT NULL
        SELECT 0 AS IsSuccessful, N'حصل خطأ غير معروف رمز الخطأ : ' + CAST(@IdCatch AS NVARCHAR(200)) AS Message_;
    ELSE
        SELECT 0 AS IsSuccessful, N'حصل خطأ غير معروف رمز الخطأ : xxx' AS Message_;
END CATCH

END

----/////////////////////////////////////NAVER TOUCH UP CODE PLEASE/////////////////////////////////////////---

GO
/****** Object:  StoredProcedure [dbo].[Masters_DataLoad]    Script Date: 10/12/2025 01:18:21 ص ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Masters_DataLoad]
    @pageName_ NVARCHAR(400),
	@idaraID INT,
	@entrydata int,
	@hostname NVARCHAR(400),
    @parameter_01 NVARCHAR(4000) = NULL,
    @parameter_02 NVARCHAR(4000) = NULL,
    @parameter_03 NVARCHAR(4000) = NULL,
    @parameter_04 NVARCHAR(4000) = NULL,
    @parameter_05 NVARCHAR(4000) = NULL,
    @parameter_06 NVARCHAR(4000) = NULL,
    @parameter_07 NVARCHAR(4000) = NULL,
    @parameter_08 NVARCHAR(4000) = NULL,
    @parameter_09 NVARCHAR(4000) = NULL,
    @parameter_10 NVARCHAR(4000) = NULL
   
    
AS
BEGIN
    SET NOCOUNT ON;

	--/////////////////// Start OF CHECK PERMISSION NEVER TOUCH PLEASE ///////////--




	--/////////////////// END OF CHECK PERMISSION NEVER TOUCH PLEASE ///////////--

    BEGIN TRY
        BEGIN TRANSACTION;


			---/////////////////////--Start BuildingType Page SP--////////////////////////--


			
			---/////////////////////--Start Permission Page SP--////////////////////////--


       IF @pageName_ ='Permission'
        BEGIN
              	---/////////////////////--Start User Permission Data--////////////////////////--
               select v.permissionTypeName_E 
			FROM DATACORE.dbo.V_GetListUserPermission v 
			where v.userID = @entrydata 
			AND v.menuName_E = @pageName_
		---/////////////////////--END User Permission Data--////////////////////////--



		---/////////////////////--Start Permission Data--////////////////////////--



			SELECT p.permissionID,p.userID,p.menuName_A,p.permissionTypeName_A,convert(nvarchar(50),p.permissionStartDate,23) permissionStartDate,isnull(convert(nvarchar(10),p.permissionEndDate,23),N'غير محدد') permissionEndDate,p.permissionNote
			FROM [DATACORE].[dbo].[V_GetListUserPermission] p
			inner join DATACORE.dbo.V_GetListUsersInDSD d on p.userID = d.userID
			inner join [DATACORE].[dbo].[V_GetFullStructureForDSD] f on f.DSDID = d.DSDID
			where f.idaraID_FK = @idaraID 
			and p.userID = @parameter_01
			order by p.permissionID desc

			
			  
			     

		---/////////////////////--END Permission Data--////////////////////////--

		---/////////////////////--Start Users List DDL Data--////////////////////////--
            SELECT distinct  cast(d.userID as bigint) userID_,cast(d.userID as nvarchar(20))+' - '+d.FullName as FullName,d.userTypeID
			 FROM [DATACORE].[dbo].[V_GetFullStructureForDSD] f
			 inner join DATACORE.dbo.V_GetListUsersInDSD d on f.DSDID = d.DSDID
			 where f.idaraID_FK = 1 and d.userID is not null
			 order by d.userTypeID asc
			
		---/////////////////////--END Users List DDL Data--////////////////////////--

			---/////////////////////--Start Distributor List DDL Data--////////////////////////--

            select d.distributorID,d.distributorName_A
			from DATACORE.dbo.Distributor d 
			inner join DATACORE.dbo.MenuDistributor md on d.distributorID = md.distributorID_FK
			where d.distributorDescription = 'MVC'

		---/////////////////////--END Distributor List DDL Data--////////////////////////--

		
			---/////////////////////--Start Permission List DDL Data--////////////////////////--

            select dpt.distributorPermissionTypeID,pt.permissionTypeName_A,dpt.distributorID_FK
			from DATACORE.dbo.DistributorPermissionType dpt
			inner join DATACORE.dbo.PermissionType pt on dpt.permissionTypeID_FK = pt.permissionTypeID
			where pt.permissionTypeActive = 1 and dpt.distributorPermissionTypeActive = 1

		---/////////////////////--END Permission List DDL Data--////////////////////////--




         
        END
	


			---/////////////////////--END Permission Page SP--////////////////////////--



        ELSE  IF @pageName_ ='BuildingType'
        BEGIN

		---/////////////////////--Start User Permission Data--////////////////////////--
              select v.permissionTypeName_E 
			FROM DATACORE.dbo.V_GetListUserPermission v 
			where v.userID = @entrydata 
			AND v.menuName_E = @pageName_
		---/////////////////////--END User Permission Data--////////////////////////--



		---/////////////////////--Start BuildingType Data--////////////////////////--
            select t.buildingTypeID,t.buildingTypeCode,t.buildingTypeName_A,t.buildingTypeName_E,t.buildingTypeDescription 
			FROM DATACORE.Housing.BuildingType t
			where t.buildingTypeActive = 1
			
		---/////////////////////--END BuildingType Data--////////////////////////--

		---/////////////////////--Start City DDL Data--////////////////////////--
            select c.cityID,c.cityName_A
			FROM DATACORE.dbo.City c
			where c.cityActive = 1 
			
		---/////////////////////--END City DDL Data--////////////////////////--
      
	    END
	


			---/////////////////////--END BuildingType Page SP--////////////////////////--




			
			---/////////////////////--Start BuildingClass Page SP--////////////////////////--


        ELSE IF @pageName_ ='BuildingClass'
        BEGIN
                ---/////////////////////--Start User Permission Data--////////////////////////--
             select v.permissionTypeName_E 
			FROM DATACORE.dbo.V_GetListUserPermission v 
			where v.userID = @entrydata 
			AND v.menuName_E = @pageName_
		       ---/////////////////////--END User Permission Data--////////////////////////--


		---/////////////////////--Start BuildingType Data--////////////////////////--
           
			select c.buildingClassID,c.buildingClassName_A,c.buildingClassName_E,c.buildingClassDescription,c.buildingClassOrder,c.buildingClassActive
			from DATACORE.Housing.BuildingClass c
			where c.buildingClassActive = 1
			
		---/////////////////////--END BuildingType Data--////////////////////////--

         
        END
	


			---/////////////////////--END BuildingClassSP Page SP--////////////////////////--










----/////////////////////////////////////NAVER TOUCH DOWN CODE PLEASE/////////////////////////////////////////---
   
    ELSE
    BEGIN
         SELECT 0 As IsSuccessful,N'الصفحة المرسلة مقيدة. PageName' AS Message_
    END


	 COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
		BEGIN

		 DECLARE @ErrMsg NVARCHAR(4000), @ErrSeverity INT, @ErrState INT,@IdentityCatchError int
        --SELECT 
          set  @ErrMsg = ERROR_MESSAGE();
          set  @ErrSeverity = ERROR_SEVERITY();
          set  @ErrState = ERROR_STATE();

		  INSERT INTO DATACORE.dbo.ErrorLog
		  (ERROR_MESSAGE_,
		  ERROR_SEVERITY_,
		  ERROR_STATE_,
		  SP_NAME,
		  entryData,
		  hostName)
		  Values
		  (@ErrMsg,
		  @ErrSeverity,
		  @ErrState,
		  N'[dbo].[Masters_DataLoad]',
		  @entrydata,
		  @hostName
		  )

		  set @IdentityCatchError = SCOPE_IDENTITY()
		  if(@IdentityCatchError > 0)
		  Begin

		   SELECT 0 As IsSuccessful,N'حصل خطأ غير معروف رمز الخطأ : '+CAST(@IdentityCatchError as nvarchar(200)) AS Message_

		  END
    ELSE
		  BEGIN

		   SELECT 0 As IsSuccessful,N'حصل خطأ غير معروف رمز الخطأ : xxx'

		  END

            ROLLBACK TRANSACTION;

       END

        --RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END

----/////////////////////////////////////NAVER TOUCH UP CODE PLEASE/////////////////////////////////////////---

GO
/****** Object:  StoredProcedure [dbo].[PermissionSP]    Script Date: 10/12/2025 01:18:21 ص ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PermissionSP] ( @Action NVARCHAR(200)   
										  ,@PermissionID bigint					   =   NULL
										  ,@DistributorPermissionTypeID_FK bigint					   =   NULL
										  ,@DistributorID_FK bigint					   =   NULL
										  ,@UserID_FK nvarchar(100)		   =   NULL
										  ,@permissionStartDate nvarchar(100)		   =   NULL
										  ,@permissionEndDate nvarchar(1000)	   =   NULL
										  ,@permissionNote nvarchar(2000)	   =   NULL
										  ,@permissionActive bit				=NULL
										  ,@entryData nvarchar(20)					   =   NULL
										  ,@hostName nvarchar(200)				       =  NULL
										  )
AS
BEGIN
	SET NOCOUNT ON; 
    DECLARE @ErrorMessage NVARCHAR(4000)
	, @NewID        INT
	, @Note         NVARCHAR(MAX)
	, @Identity_Insert NVARCHAR(500)
	, @Identity_Update NVARCHAR(500)
	, @Identity_Delete NVARCHAR(500)
	, @PermissionStartDateDT DATETIME;

	SET @PermissionStartDateDT = TRY_CONVERT(DATETIME, NULLIF(@permissionStartDate, ''), 120);

	UPDATE DATACORE.dbo.Permission 
	set permissionActive = 0
	where cast(permissionEndDate as date) < cast(GETDATE() as date)

	UPDATE DATACORE.dbo.Permission 
	set permissionEndDate = cast(GETDATE() as date)
	where  permissionActive = 0 and permissionEndDate is null


	UPDATE DATACORE.dbo.UserDistributor 
	set UDActive = 0
	where cast(UDEndDate as date) < cast(GETDATE() as date)

	UPDATE DATACORE.dbo.UserDistributor 
	set UDEndDate = cast(GETDATE() as date)
	where  UDActive = 0 and UDEndDate is null



	BEGIN TRY
	BEGIN TRANSACTION;

	
	IF @Action = 'INSERT'


	BEGIN
		
		IF (@UserID_FK IS NULL OR LTRIM(RTRIM(@UserID_FK)) = '')
		BEGIN

		SELECT 0 As IsSuccessful,N'الرجاء اختيار المستخدم اولا'  AS Message_
		END
		ELSE

		BEGIN

			IF ( select 
					count (*) 
					from DATACORE.dbo.Permission p
					inner join DistributorPermissionType dt on p.DistributorPermissionTypeID_FK = dt.distributorPermissionTypeID
					inner join DATACORE.dbo.UserDistributor ud on ud.distributorID_FK = dt.distributorID_FK
					where 1=1
					and p.DistributorPermissionTypeID_FK = @DistributorPermissionTypeID_FK 
					AND p.UserID_FK = @UserID_FK 
					AND p.permissionActive = 1 
					and dt.distributorPermissionTypeActive = 1 
					and ud.UDActive = 1 
					and (p.permissionEndDate is null or cast(p.permissionEndDate as date) > cast(GETDATE() as date))  ) > 0 
		    BEGIN

				SELECT 0 As IsSuccessful,N'البيانات مدخلة مسبقا' AS Message_
			 END 
		ELSE
			 BEGIN

			 IF ( select 
					count (*) 
					from DATACORE.dbo.UserDistributor ud 
					where ud.distributorID_FK = @DistributorID_FK 
					and ud.userID_FK = @UserID_FK 
					and ud.UDActive = 1 
					and (ud.UDEndDate is null or cast(ud.UDEndDate as date) > cast(GETDATE() as date))) < 1
						
						BEGIN
						INSERT INTO DATACORE.dbo.UserDistributor
						([distributorID_FK],
						[userID_FK],
						[UDStartDate],
						[UDActive],
						[Note],
						[entryData],
						[hostName])
						 VALUES
					    (@DistributorID_FK,
						@UserID_FK,
						isnull(@PermissionStartDateDT,Getdate()),
						1,
						null,
						@entryData,
						@hostName)

						set @Identity_Insert = SCOPE_IDENTITY()
						if(@Identity_Insert > 0)
						BEGIN
						
								INSERT INTO DATACORE.dbo.Permission
							           ([DistributorPermissionTypeID_FK]
							           ,[UserID_FK]
							           ,[permissionStartDate]
							           ,[permissionEndDate]
									   ,[permissionActive]
									   ,[permissionNote]
							           ,[entryData]
							           ,[hostName])
							     VALUES
							           (@DistributorPermissionTypeID_FK 
							           ,@UserID_FK 
							           ,isnull(@PermissionStartDateDT,Getdate())
									   ,@permissionEndDate
							           ,1 
									   ,@permissionNote
							           ,@entryData 
							           ,@hostName )
							
							
							           
							     
							
							        SET @NewID = SCOPE_IDENTITY(); 
							        SET @Note = '{' + '"distributorID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @distributorID_FK), '') + '"' 
									+ ',' + '"userID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @userID_FK), '') + '"' + ',' + '"UDStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionStartDate), '') + '"' 
									+ ',' + '"Note": "' + ISNULL(CONVERT(NVARCHAR(MAX), @Note), '') + '"' + ','+ '"DistributorPermissionTypeID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @DistributorPermissionTypeID_FK), '') + '"' + 
									',' + '"permissionStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionStartDate), '') + '"'
									+',' + '"permissionNote": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionNote), '') + '"'
									+',' + '"entryData": "' + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + '"'
									+ ',' + '"hostName": "' + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + '"' + '}'; 
							
							
									SET @Identity_Insert = SCOPE_IDENTITY(); 
									IF(@Identity_Insert > 0)
									Begin
									        INSERT INTO DATACORE.dbo.AuditLog ( TableName,            ActionType, RecordID, PerformedBy,  Notes )
									VALUES                ( '[dbo].[PermissionSP]', 'INSERT',   @NewID,   @entryData, @Note ); 
							        COMMIT;
									SELECT 1 As IsSuccessful,N'تم اضافة البيانات 1 بنجاح' AS Message_
									END
								ELSE
								    Begin
									       
							        RollBAck;
									SELECT 0 As IsSuccessful,N'حصل خطأ في اضافة البيانات ' AS Message_
									END


						end
							ELSE
								    Begin
									       
							        RollBAck;
									SELECT 0 As IsSuccessful,N'حصل خطأ في اضافة البيانات ' AS Message_
									END


						end
					ELSE
					    BEGIN


						INSERT INTO DATACORE.dbo.Permission
			           ([DistributorPermissionTypeID_FK]
			           ,[UserID_FK]
			           ,[permissionStartDate]
			           ,[permissionEndDate]
					   ,[permissionActive]
					   ,[permissionNote]
			           ,[entryData]
			           ,[hostName])
			     VALUES
			           (@DistributorPermissionTypeID_FK 
			           ,@UserID_FK 
			           ,isnull(@PermissionStartDateDT,Getdate())
					   ,@permissionEndDate
			           ,1 
					   ,@permissionNote
			           ,@entryData 
			           ,@hostName )
			
			
			           
			     
			
			       SET @NewID = SCOPE_IDENTITY(); 
							        SET @Note = '{' + '"distributorID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @distributorID_FK), '') + '"' 
									+ ',' + '"userID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @userID_FK), '') + '"' + ',' + '"UDStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionStartDate), '') + '"' 
									+ ',' + '"Note": "' + ISNULL(CONVERT(NVARCHAR(MAX), @Note), '') + '"' + ','+ '"DistributorPermissionTypeID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @DistributorPermissionTypeID_FK), '') + '"' + 
									',' + '"permissionStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionStartDate), '') + '"'
									+',' + '"permissionNote": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionNote), '') + '"'
									+',' + '"entryData": "' + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + '"'
									+ ',' + '"hostName": "' + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + '"' + '}'; 
			
					SET @Identity_Insert = SCOPE_IDENTITY(); 
					IF(@Identity_Insert > 0)
					Begin
					        INSERT INTO DATACORE.dbo.AuditLog ( TableName,            ActionType, RecordID, PerformedBy,  Notes )
					VALUES                 ( '[dbo].[PermissionSP]', 'INSERT',   @NewID,   @entryData, @Note ); 
			        COMMIT;
					SELECT 1 As IsSuccessful,N'تم اضافة البيانات 2 بنجاح' AS Message_
					END
				ELSE
				    Begin
					       
			        RollBAck;
					SELECT 0 As IsSuccessful,N'حصل خطأ في اضافة البيانات ' AS Message_
					END

	  end
	END 
	

		END
		
	END


    ELSE IF @Action = 'UPDATE'
		BEGIN

		SELECT 1
	--		IF EXISTS (SELECT 1
	--			FROM DATACORE.[Housing].[BuildingClass]
	--			WHERE BuildingClassID = @BuildingClassID)
	--		BEGIN
	--			UPDATE DATACORE.[Housing].[BuildingClass]
	--			SET  [BuildingClassName_A]	  =ISNULL(@BuildingClassName_A, [BuildingClassName_A])
	--			,   [BuildingClassName_E]	  =ISNULL(@BuildingClassName_E, [BuildingClassName_E])
	--			,   [BuildingClassDescription] =ISNULL(@BuildingClassDescription, [BuildingClassActive])
	--			,   [BuildingClassActive]	  =ISNULL(1, [BuildingClassActive])
	--			,   [entryData]			      =ISNULL(@entryData, [entryData])
	--			,   [hostName]			      =ISNULL(@entryData,  [hostName])
	--			WHERE [BuildingClassID] = @BuildingClassID; 

				
	--			 SET @Note = '{' + '"BuildingClassName_A": "' + ISNULL(CONVERT(NVARCHAR(MAX), @BuildingClassName_A), '') + '"' 
	--						+ ',' + '"BuildingClassName_E": "' + ISNULL(CONVERT(NVARCHAR(MAX), @BuildingClassName_E), '') + '"' + ',' + '"BuildingClassDescription": "' + ISNULL(CONVERT(NVARCHAR(MAX), @BuildingClassDescription), '') + '"' 
	--						+ ',' + '"BuildingClassActive": "' + ISNULL(CONVERT(NVARCHAR(MAX), 1), '') + '"' + ',' + '"entryData": "' + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + '"'
	--						+ ',' + '"hostName": "' + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + '"' + '}'; 




	--						SET @Identity_Update = @@ROWCOUNT; 
	--	IF(@Identity_Update > 0)
	--	Begin
	--	         INSERT INTO AuditLog ( TableName,            ActionType, RecordID, PerformedBy,  Notes )
	--				VALUES                ( '[Housing].[BuildingClass]', 'UPDATE',   @NewID,   @entryData, @Note ); 
	--			COMMIT;
	--			SELECT 1 As IsSuccessful,N'تم تحديث البيانات بنجاح' AS Message_
	--	END
	--ELSE
	--    Begin
		       
 --       RollBAck;
	--	SELECT 0 As IsSuccessful,N'حصل خطأ في تحديث البيانات ' AS Message_
	--	END



				
	--		END 
	--		ELSE 
	--		SELECT 0 As IsSuccessful,N'حصل خطأ في تحديث البيانات x' AS Message_


		END 

		ELSE IF @Action = 'DELETE'
		BEGIN
			IF EXISTS (SELECT 1
				FROM DATACORE.dbo.Permission 
				WHERE permissionID = @PermissionID)
			BEGIN
				UPDATE DATACORE.dbo.Permission 
				set permissionEndDate = cast(GETDATE() as date),
				permissionActive = 0
				where  permissionID = @PermissionID

				  SET @NewID = SCOPE_IDENTITY(); 
							        SET @Note = '{' + '"distributorID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @distributorID_FK), '') + '"' 
									+ ',' + '"userID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @userID_FK), '') + '"' + ',' + '"UDStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionStartDate), '') + '"' 
									+ ',' + '"Note": "' + ISNULL(CONVERT(NVARCHAR(MAX), @Note), '') + '"' + ','+ '"DistributorPermissionTypeID_FK": "' + ISNULL(CONVERT(NVARCHAR(MAX), @DistributorPermissionTypeID_FK), '') + '"' + 
									',' + '"permissionStartDate": "' + ISNULL(CONVERT(NVARCHAR(MAX), @permissionStartDate), '') + '"'
									+',' + '"permissionNote": "' + ISNULL(CONVERT(NVARCHAR(MAX), @Note), '') + '"'
									+',' + '"entryData": "' + ISNULL(CONVERT(NVARCHAR(MAX), @entryData), '') + '"'
									+ ',' + '"hostName": "' + ISNULL(CONVERT(NVARCHAR(MAX), @hostName), '') + '"' + '}'; 

							
							SET @Identity_Update = @@ROWCOUNT; 
		IF(@Identity_Update > 0)
		Begin
		         INSERT INTO AuditLog ( TableName,            ActionType, RecordID, PerformedBy,  Notes )
					VALUES                ( '[Housing].[BuildingClass]', 'UPDATE',   @NewID,   @entryData, @Note ); 
				COMMIT;
				SELECT 1 As IsSuccessful,N'تم حذف البيانات بنجاح' AS Message_
		END
	ELSE
	    Begin
		       
        RollBAck;
		SELECT 0 As IsSuccessful,N'حصل خطأ في حذف البيانات ' AS Message_
		END



				
			END 
			ELSE 
			SELECT 0 As IsSuccessful,N'حصل خطأ في حذف البيانات x' AS Message_


		END 


	 
	ELSE 
	SELECT 0 As IsSuccessful,N'العملية غير مسجلة' AS Message_
		
	END TRY
	BEGIN CATCH
    DECLARE 
        @ErrMsg NVARCHAR(4000),
        @ErrSeverity INT,
        @ErrState INT,
        @IdentityCatchError INT;

    -- جيب معلومات الخطأ
    SELECT 
        @ErrMsg      = ERROR_MESSAGE(),
        @ErrSeverity = ERROR_SEVERITY(),
        @ErrState    = ERROR_STATE();

    -- أول شيء: لو في ترانزاكشن (سواء committable أو doomed) نسوي ROLLBACK
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END

    -- نحاول نسجل الخطأ في ErrorLog "خارج الترانزاكشن"
    BEGIN TRY
        INSERT INTO DATACORE.dbo.ErrorLog
        (
              ERROR_MESSAGE_,
              ERROR_SEVERITY_,
              ERROR_STATE_,
              SP_NAME,
              entryData,
              hostName
        )
        VALUES
        (
              @ErrMsg,
              @ErrSeverity,
              @ErrState,
              N'[dbo].[PermissionSP]',   -- عدلتها لاسم SP الصحيح
              @entryData,
              @hostName
        );

        SET @IdentityCatchError = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        -- حتى لو فشل تسجيل الخطأ، ما نبغى نطيح في Error داخل Error 🙂
        SET @IdentityCatchError = NULL;
    END CATCH;

    IF @IdentityCatchError IS NOT NULL
    BEGIN
        SELECT 
            0 AS IsSuccessful,
            N'حصل خطأ غير معروف رمز الخطأ : ' + CAST(@IdentityCatchError AS NVARCHAR(200)) AS Message_;
    END
    ELSE
    BEGIN
        SELECT 
            0 AS IsSuccessful,
            N'حصل خطأ غير معروف ولم يتم تسجيله في ErrorLog' AS Message_;
    END
END CATCH

END;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "m"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 221
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "md"
            Begin Extent = 
               Top = 6
               Left = 259
               Bottom = 136
               Right = 468
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 6
               Left = 506
               Bottom = 136
               Right = 710
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "dpt"
            Begin Extent = 
               Top = 6
               Left = 748
               Bottom = 136
               Right = 1024
            End
            DisplayFlags = 280
            TopColumn = 3
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 296
            End
            DisplayFlags = 280
            TopColumn = 6
         End
         Begin Table = "pt"
            Begin Extent = 
               Top = 6
               Left = 1062
               Bottom = 136
               Right = 1280
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 54
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width =' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_GetListUserPermission'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N' 1665
         Width = 1500
         Width = 2430
         Width = 1875
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1980
         Width = 1725
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 3015
         Alias = 2520
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_GetListUserPermission'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_GetListUserPermission'
GO
