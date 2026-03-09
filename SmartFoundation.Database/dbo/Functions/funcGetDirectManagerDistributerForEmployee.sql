-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[funcGetDirectManagerDistributerForEmployee]
(
	-- Add the parameters for the function here
	@UserID INT
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
--	DECLARE @disID INT

--DECLARE @managerID INT
Declare @ToDistributor INT

	-- Add the T-SQL statements to compute the return value here
--	SET @managerID = (SELECT CASE WHEN vu.userID = vu.SvID THEN vu.MaID
--WHEN vu.userID = vu.MaID THEN vu.GMID
--ELSE vu.SvID
--END dist
--from dbo.V_ManagerOfUser vu
--WHERE userID = @userID)


--SET @disID = (SELECT TOP(1) d.distributorID FROM dbo.UserDistributor ud inner join dbo.Distributor d on d.distributorID = ud.distributorID_FK WHERE ud.userID_FK = @managerID AND d.distributorActive = 1 ORDER BY d.roleID_FK ASC )
set @ToDistributor=(SELECT  top (1)ud.distributorID_FK  FROM  dbo.UserDistributor ud
INNER JOIN  dbo.Distributor d ON ud.distributorID_FK=d.distributorID 
AND d.distributorActive=1 
AND ud.UDActive=1
AND ud.UDStartDate IS NOT NULL
AND ud.UDEndDate IS NULL
AND d.distributorType_FK=2
WHERE d.roleID_FK IN (1,2,3,4,5,6) AND ud.userID_FK=(
SELECT case when mu.AdID is not null AND mu.userID <> mu.AdID then mu.AdID
	  when mu.AdID is not null AND mu.userID = mu.AdID and mu.SvID is not null then mu.SvID
	  when mu.AdID is not null AND mu.userID = mu.AdID and mu.SvID is null then mu.MaID
	  when mu.AdID is  null AND mu.SvID is not null AND mu.userID <> mu.SvID then mu.SvID
	  when mu.AdID is  null AND mu.SvID is not null AND mu.userID = mu.SvID then mu.MaID
	  when mu.AdID is  null AND mu.SvID is null  AND mu.userID <> mu.MaID then mu.MaID
	  when mu.AdID is  null AND mu.SvID is null  AND mu.userID = mu.MaID then mu.GMID
	  END managerID
	 
	  FROM dbo.V_ManagerOfUser mu
	  where mu.userID=@userID
	  )
	  
	  order by ud.UDID desc
	  )




	-- Return the result of the function
	RETURN @ToDistributor

END
