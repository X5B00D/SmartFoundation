-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [Housing].[GetMaxValueForSlide] 
(
	-- Add the parameters for the function here
	  @buildingUtilityTypeID int
	 ,@meterServiceTypeID int
	 ,@meterSlideSequence int
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar int

	-- Add the T-SQL statements to compute the return value here
		Set @ResultVar = ( SELECT
							GSRS.meterSlideMaxValue
							FROM KFMC.Housing.GetSlideForReadByServiceTypeID(@buildingUtilityTypeID, @meterServiceTypeID, @meterSlideSequence) GSRS)

	-- Return the result of the function
	RETURN @ResultVar

END
