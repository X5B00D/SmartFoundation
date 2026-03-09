-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION dbo.VAC_checkUserVacationHasBeenApproved
(
	-- Add the parameters for the function here
	@userID int
)
RETURNS  int
AS
BEGIN
Declare @Result int
	-- Declare the return variable here
	set @Result =(
select count(*) count_ from  dbo.VAC_OldDecision o
where 1=1
and o.vacOldDecisionUserID_FK = @userID
and o.entryDate is not null
and o.entryData is not null
and o.hostName is not null	
and o.vacOldVacationTypeID_FK is null
and o.vacOldDecisionNo = 0
and o.vacOldDecisionTotalDays = 0
and o.vacOldDecisionNote is not null
and o.vacOldDecisionActive = 1)

	-- Add the T-SQL statements to compute the return value here
	

	-- Return the result of the function
	RETURN  @Result 

END
