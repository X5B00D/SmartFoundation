-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
Create FUNCTION [Housing].[GetCountAllResident]
(
	-- Add the parameters for the function here
	
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int

	-- Add the T-SQL statements to compute the return value here
	 SET @Result = 
					(
						SELECT count(*) N'AllResident' FROM Housing.ResidentDetails rd
    INNER JOIN KFMC.Housing.ResidentInfo ri ON rd.generalNo_FK = ri.generalNo
	WHERE rd.residentDetailsActive =1

					)

	-- Return the result of the function
	RETURN @Result

END
