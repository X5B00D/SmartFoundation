USE [DATACORE]
GO
/****** Object:  StoredProcedure [dbo].[Notifications_Create]    Script Date: 15/12/2025 12:48:47 ص ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[Notifications_Create]
(
    @Title      NVARCHAR(200),
    @Body       NVARCHAR(MAX),
    @Url        NVARCHAR(500) = NULL,
    @StartDate        NVARCHAR(500) = NULL,
    @EndDate        NVARCHAR(500) = NULL,
    @UserID BigInt = NULL,  
    @DistributorID   BigInt = NULL,
    @RoleID BigInt = NULL,  
    @DsdID   BigInt = NULL,
    @entryData  NVARCHAR(20),
    @hostName   NVARCHAR(200)

    
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

  Declare @NotificationId BIGINT, @UserNotificationId BIGINT

    BEGIN TRAN;

    INSERT INTO dbo.Notifications (Title, Body, Url_,StartDate,EndDate, entryData, hostName)
    VALUES (@Title, @Body, @Url,ISNULL(@StartDate,GetDate()),@EndDate, @entryData, @hostName);

    SET @NotificationId = SCOPE_IDENTITY();

    if(@NotificationId > 0)
    Begin

      


    if(@UserID is not null and @DistributorID is null and @RoleID is null and @DsdID is null )

                  Begin

                        INSERT INTO dbo.UserNotifications
                        (NotificationId_FK, UserId_FK, IsRead, DeliveredUtc, entryData, hostName)

                        SELECT @NotificationId,u.userID,0,GETDATE(),@entryData,@hostName AS UserId
                        FROM dbo.[User] u
                        WHERE u.userID = @UserID AND u.userActive = 1

                        SET @UserNotificationId = SCOPE_IDENTITY();

                         if(@NotificationId > 0)
                        Begin

                        commit
                        END
                        else
                         Begin

                        rollback
                        END


                  END

   ELSE  if(@UserID is null and @DistributorID is Not null and @RoleID is null and @DsdID is null )

                 Begin

                        INSERT INTO dbo.UserNotifications
                        (NotificationId_FK, UserId_FK, IsRead, DeliveredUtc, entryData, hostName)

                        SELECT @NotificationId,u.userID,0,GETDATE(),@entryData,@hostName AS UserId
                        FROM dbo.[User] u
                        inner join dbo.UserDistributor ud on ud.userID_FK = u.userID
                        inner join dbo.Distributor d on ud.distributorID_FK = d.distributorID
                        WHERE d.distributorID = @DistributorID AND u.userActive = 1 AND d.distributorActive = 1 and ud.UDActive = 1
                          AND CAST(ud.UDStartDate AS date) <= CAST(GETDATE() AS date)
                          AND (ud.UDEndDate IS NULL OR CAST(ud.UDEndDate AS date) > CAST(GETDATE() AS date))

                        SET @UserNotificationId = SCOPE_IDENTITY();

                         if(@NotificationId > 0)
                        Begin

                        commit
                        END
                        else
                         Begin

                        rollback
                        END


                 END




     ELSE  if(@UserID is null and @DistributorID is null and @RoleID is Not null and @DsdID is null )

                 Begin

                        INSERT INTO dbo.UserNotifications
                        (NotificationId_FK, UserId_FK, IsRead, DeliveredUtc, entryData, hostName)

                        SELECT @NotificationId,u.userID,0,GETDATE(),@entryData,@hostName AS UserId
                        FROM dbo.[User] u
                        inner join dbo.UserDistributor ud on ud.userID_FK = u.userID
                        inner join dbo.Distributor d on ud.distributorID_FK = d.distributorID
                        WHERE d.roleID_FK = @RoleID AND u.userActive = 1 AND d.distributorActive = 1 and ud.UDActive = 1
                          AND CAST(ud.UDStartDate AS date) <= CAST(GETDATE() AS date)
                          AND (ud.UDEndDate IS NULL OR CAST(ud.UDEndDate AS date) > CAST(GETDATE() AS date))

                        SET @UserNotificationId = SCOPE_IDENTITY();

                         if(@NotificationId > 0)
                        Begin

                        commit
                        END
                        else
                         Begin

                        rollback
                        END


                 END

    ELSE  if(@UserID is null and @DistributorID is null and @RoleID is null and @DsdID is Not null )

                 Begin

                        INSERT INTO dbo.UserNotifications
                        (NotificationId_FK, UserId_FK, IsRead, DeliveredUtc, entryData, hostName)

                        SELECT @NotificationId,u.userID,0,GETDATE(),@entryData,@hostName AS UserId
                        FROM  [DATACORE].[dbo].[V_AllUsersInDSD] u
                        where u.DSDID = @DsdID
                           
                        SET @UserNotificationId = SCOPE_IDENTITY();

                         if(@NotificationId > 0)
                        Begin

                        commit
                        END
                        else
                         Begin

                        rollback
                        END


                 END

            

     ELSE if(@UserID is null and @DistributorID is null and @RoleID is null and @DsdID is null )

                  Begin

                        INSERT INTO dbo.UserNotifications
                        (NotificationId_FK, UserId_FK, IsRead, DeliveredUtc, entryData, hostName)

                        SELECT @NotificationId,u.userID,0,GETDATE(),@entryData,@hostName AS UserId
                        FROM dbo.[User] u
                        WHERE u.userActive = 1

                        SET @UserNotificationId = SCOPE_IDENTITY();

                         if(@NotificationId > 0)
                        Begin

                        commit
                        END
                        else
                         Begin

                        rollback
                        END


                  END

    ELSE
                 Begin

                 Select 0
                 RollBack;

                 END



    END


  ELSE
    Begin

    Select 0
    RollBack;

    END
   

    

    SELECT @NotificationId AS NotificationId;
END
GO
/****** Object:  StoredProcedure [dbo].[Notifications_CRUD]    Script Date: 15/12/2025 12:48:47 ص ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Notifications_CRUD]
    @UserID NVARCHAR(50),
    @Type NVARCHAR(20) = NULL,
    @UserNotificationId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get notification details
    IF @Type = 'Body'
    BEGIN
        SELECT 
            un.UserNotificationId,
            un.NotificationId_FK,
            n.Title,
            n.Body,
            n.Url_,
            un.DeliveredUtc,
            un.IsClicked,
            un.IsRead,
            un.ReadUtc,
            un.ClickUtc
        FROM 
            DATACORE.dbo.UserNotifications un
            INNER JOIN DATACORE.dbo.Notifications n 
                ON un.NotificationId_FK = n.NotificationId
        WHERE 
            un.UserId_FK = @UserID 
            AND un.IsClicked = 0 
            AND un.ClickUtc IS NULL
        ORDER BY 
            un.DeliveredUtc DESC;
    END
    
    -- Get notification count (unread only)
    ELSE IF @Type = 'Count'
    BEGIN
        SELECT COUNT(*) AS NotificationCount
        FROM DATACORE.dbo.UserNotifications
        WHERE UserId_FK = @UserID 
          AND IsRead = 0
          AND ReadUtc IS NULL;
    END
    
    -- Mark single notification as clicked
    ELSE IF @Type = 'MarkClicked'
    BEGIN
        UPDATE DATACORE.dbo.UserNotifications
        SET 
            IsClicked = 1,
            ClickUtc = GETUTCDATE(),
            IsRead = 1,
            ReadUtc = ISNULL(ReadUtc, GETUTCDATE())
        WHERE 
            UserNotificationId = @UserNotificationId
            AND UserId_FK = @UserID;
            
        SELECT @@ROWCOUNT AS RowsAffected;
    END
    
    -- ✅ NEW: Mark single notification as read (on hover)
    ELSE IF @Type = 'MarkRead'
    BEGIN
        UPDATE DATACORE.dbo.UserNotifications
        SET 
            IsRead = 1,
            ReadUtc = GETUTCDATE()
        WHERE 
            UserNotificationId = @UserNotificationId
            AND UserId_FK = @UserID
            AND IsRead = 0;  -- Only if not already read
            
        SELECT @@ROWCOUNT AS RowsAffected;
    END
    
    -- Mark all notifications as read
    ELSE IF @Type = 'MarkAllRead'
    BEGIN
        UPDATE DATACORE.dbo.UserNotifications
        SET 
            IsRead = 1,
            ReadUtc = GETUTCDATE()
        WHERE 
            UserId_FK = @UserID
            AND IsRead = 0
            AND ReadUtc IS NULL;
            
        SELECT @@ROWCOUNT AS RowsAffected;
    END
    
    -- Mark all notifications as clicked
    ELSE IF @Type = 'MarkAllClicked'
    BEGIN
        UPDATE DATACORE.dbo.UserNotifications
        SET 
            IsClicked = 1,
            ClickUtc = GETUTCDATE(),
            IsRead = 1,
            ReadUtc = ISNULL(ReadUtc, GETUTCDATE())
        WHERE 
            UserId_FK = @UserID
            AND IsClicked = 0
            AND ClickUtc IS NULL;
            
        SELECT @@ROWCOUNT AS RowsAffected;
    END
END
GO
