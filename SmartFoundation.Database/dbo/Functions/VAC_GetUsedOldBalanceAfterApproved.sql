-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================

/*

select [dbo].[VAC_GetUsedOldBalanceAfterApproved](60013508)

*/
CREATE FUNCTION [dbo].[VAC_GetUsedOldBalanceAfterApproved]
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
(select isnull(sum(o.vacOldDecisionTotalDays),0)  
from kfmc.dbo.VAC_OldDecision o
where 1=1
and o.vacOldDecisionUserID_FK = @userID
and o.entryDate is not null
and o.entryData is not null
and o.hostName is not null	
and o.vacOldVacationTypeID_FK = 1
and o.vacOldDecisionActive = 1)


+

(
select isnull(sum(d.noOfDay),0)
From kfmc.dbo.VAC_VacationRequests r
inner join kfmc.dbo.VAC_VacationDetails d on r.vacationRequestID = d.vacationRequestID_FK
inner join kfmc.dbo.VAC_VacationActions a on r.vacationRequestID = a.vacationRequestID_FK
inner join kfmc.dbo.GetLastActionForVacationRequest() la on a.vacationActionsID = la.ActionsID and a.actionTypeID_FK <> 4
where r.userID_FK = @userID and d.EntitlementYear =2022
--inner join kfmc.dbo.GetLastActionForVacationRequest() lr on lr.RequestID
)
)

	-- Add the T-SQL statements to compute the return value here
	

	-- Return the result of the function
	RETURN  @Result 

END
