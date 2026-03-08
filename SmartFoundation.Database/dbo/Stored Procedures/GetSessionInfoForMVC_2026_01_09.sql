
create   PROCEDURE [dbo].[GetSessionInfoForMVC_2026_01_09]
    @NationalID NVARCHAR(20),
    @Password Nvarchar(200),
    @hostName Nvarchar(200)

AS
BEGIN
    SET NOCOUNT ON;

     DECLARE @usersID bigint;
     DECLARE @GeneralNo bigint 

    set @usersID = (
    select TOP(1) u.usersID
    from DATACORE.dbo.Users u 
    where u.nationalID = @NationalID
    and u.usersActive = 1 
    and u.usersStartDate is not null 
    and cast(u.usersStartDate as date) <= cast(GETDATE() as date)
    and((cast(u.usersEndDate as date) > cast(GETDATE() as date)) OR u.usersEndDate is null)
    order by u.usersID desc
    )

    DECLARE @Salt VARBINARY(32);
    DECLARE @StoredHash VARBINARY(64);
    DECLARE @PasswordResult int

  -- هل يوجد كلمة مرور للمستخدم؟
IF NOT EXISTS (
    SELECT 1 
    FROM DATACORE.dbo.usersPassword us
    WHERE us.usersID_FK = @UsersID and us.userPasswordActive = 1
)
BEGIN
    SET @PasswordResult = 3;   -- لا يوجد كلمة مرور
END
ELSE
BEGIN
    -- جلب الهاش والسولت
    SELECT 
        @Salt = PasswordSalt,
        @StoredHash = PasswordHash
    FROM DATACORE.dbo.usersPassword
    WHERE usersID_FK = @UsersID;

    -- فحص كلمة المرور
    IF @StoredHash = HASHBYTES('SHA2_256', @Salt + CAST(@Password AS VARBINARY(200)))
    BEGIN
        SET @PasswordResult = 1;  -- كلمة المرور صحيحة
    END
    ELSE
    BEGIN
        SET @PasswordResult = 0;  -- كلمة المرور خاطئة
    END
END

    
         if(select count(us.usersID) from DATACORE.dbo.[Users] us where us.usersID = @UsersID) > 0
             begin
                 set @GeneralNo = (
                 select TOP(1) ud.GeneralNo 
                 from DATACORE.dbo.[Users] us 
                 inner join DATACORE.dbo.UsersDetails ud on us.usersID = ud.usersID_FK
                 where us.usersID = @UsersID and us.usersActive = 1 
                 and us.usersStartDate is not null 
                 and cast(us.usersStartDate as date) <= cast(GETDATE() as date)
                 and((cast(us.usersEndDate as date) > cast(GETDATE() as date)) OR us.usersEndDate is null)
                 order by us.entryDate desc
                 )
             END
         ELSE
             BEGIN
                 set @GeneralNo = -99
             END
    -- Create a temporary table to store the department info
    DECLARE @DepartmentInfo TABLE (
        UserID bigINT,
        OrganizationName NVARCHAR(255),
        IdaraName NVARCHAR(255),
        DepartmentName NVARCHAR(255),
        SectionName NVARCHAR(255),
        DivisonName NVARCHAR(255),
		DeptCode nvarchar(20),
		OrganizationID INT,
        IdaraID INT,
        DepartmentID INT,
        SectionID INT,
        DivisonID INT
    );


	  DECLARE @ThameInfo TABLE (
        UserID bigINT,
        ThameName NVARCHAR(255)
    );
    
    -- Get the department info first
    INSERT INTO @DepartmentInfo (UserID,OrganizationName,IdaraName, DepartmentName,SectionName,DivisonName, DeptCode,OrganizationID,IdaraID,DepartmentID,SectionID,DivisonID)
    SELECT TOP 1 
        udsd.usersID,
        dsd.OrganizationName,
        dsd.IdaraName,
        dsd.DepartmentName,
        dsd.SectionName,
        dsd.DivisonName,
		d.deptCode,
        dsd.OrganizationID,
		dsd.IdaraID,
        dsd.DepartmentID,
        dsd.SectionID,
        dsd.DivisonID
    FROM dbo.V_GetFullStructureForDSD dsd
    INNER JOIN dbo.V_GetListUsersInDSD udsd ON dsd.DSDID = udsd.DSDID
	INNER JOIN dbo.Department d ON dsd.DepartmentID = d.deptID
    WHERE udsd.usersID = @UsersID;


	--INSERT INTO @ThameInfo (UserID, ThameName)
 --           SELECT TOP 1 
 --                  @GeneralNo,
 --                  ISNULL(
 --                       m.MvcThameName,
 --                       'default'
 --                  ) AS ThameName
 --           FROM DATACORE.dbo.MvcThameUser u
 --           LEFT JOIN DATACORE.dbo.MvcThame m 
 --                  ON u.MvcThameID_FK = m.MvcThameID
 --           WHERE u.UserID_FK = @GeneralNo
 --             AND u.MvcThameUserActive = 1
 --             AND m.MvcThameActive = 1;

 --               -- إذا لم يرجع السطر السابق أي نتيجة → إدراج default يدويًا
 --           IF NOT EXISTS (SELECT 1 FROM @ThameInfo WHERE UserID = @GeneralNo)
 --           BEGIN
 --               INSERT INTO @ThameInfo (UserID, ThameName)
 --               VALUES (@GeneralNo, 'default');
 --           END


     

    
    -- Combine the user and department information along with photo from Payroll database
    if(@GeneralNo = -99)
    
     BEGIN
          select
            0 as userActive,
            N'عذرا لايوجد حساب مسجل بالنظام لصاحب الهوية رقم : '+@UsersID as Message_
                
     END
    
    

     ELSE
           
      begin

      

    if(select Count(*) From DATACORE.dbo.[Users] uu where uu.usersID = @UsersID and uu.usersActive = 1) > 0
                begin



                if(select Count(*) FROM dbo.[Users] u
                    LEFT JOIN @DepartmentInfo d ON u.usersID = d.UserID
                	LEFT JOIN @ThameInfo t ON u.usersID = t.UserID
                    WHERE u.usersID = @usersID and u.usersActive = 1 and d.IdaraID is not null and d.DepartmentName is not null) > 0
                    begin

                    if(@PasswordResult = 1)
                    begin
                    SELECT 
                        CONCAT_WS(' ', ud.firstName_A, ud.secondName_A, ud.lastName_A) AS fullName, 
                        u.usersID,
                        d.OrganizationID,
                        d.OrganizationName,
                		d.IdaraID,
                        d.IdaraName,
                        d.DepartmentID,
                        d.DepartmentName,
                        d.SectionID,
                        d.SectionName,
                        d.DivisonID,
                        d.DivisonName,
                        (SELECT Photo FROM DATACORE.dbo.UsersPhoto up WHERE up.usersID_FK = @usersID) AS Photo,
                		case when t.ThameName is null Then 'default'
                		else t.ThameName
                		END ThameName,
                		d.DeptCode,
                        u.nationalID,
                        u.usersActive,
						@GeneralNo GeneralNo,
                        N'مرحبا بك : '+CONCAT_WS(' ', ud.firstName_A, ud.secondName_A, ud.lastName_A)+N' تم تسجيل دخولك للنظام في '+convert(nvarchar(50),GETDATE(),111)+N' الساعة ' +convert(nvarchar(50),GETDATE(),108) as Message_
                    FROM dbo.[Users] u
                    inner join DATACORE.dbo.UsersDetails ud on u.usersID = ud.usersID_FK
                    LEFT JOIN @DepartmentInfo d ON u.usersID = d.UserID
                	LEFT JOIN @ThameInfo t ON u.usersID = t.UserID
                    WHERE u.usersID = @usersID and u.usersActive = 1

                    end
                else if(@PasswordResult = 0)
                    begin

                     select
                        0 as userActive,
                         N'عذرا اسم المستخدم او كلمة المرور غير صحيحة' as Message_
                    end

                    else if(@PasswordResult = 3)
                    begin

                     select
                        
                        0 as userActive,
                         N'يجب اعادة ضبط كلمة المرور للمستخدم' as Message_
                    end


                    end
                  else
                     begin

                     select
                        0 as userActive,
                        N'عذرا يوجد خطأ بالهيكل الاداري لصاحب الهوية رقم : '+@UsersID as Message_

                     end
                END
           ELSE
                BEGIN
                      select
                        0 as userActive,
                        N'عذرا لايوجد حساب نشط بالنظام لصاحب الهوية رقم : '+@UsersID as Message_

                
                END

    end     
    
END;
