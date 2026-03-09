-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION dbo.EMPFirstContractStart
(
	-- Add the parameters for the function here
	@userID INT
)
RETURNS Date
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar Date

	-- Add the T-SQL statements to compute the return value here
	set @ResultVar =(
	select convert(date,gh.gregorianDate)rDate_G
	FROM		 Payroll.dbo.personel AS p 
	LEFT JOIN    dbo._GregorianHijriDate AS gh ON gh.hijriDateddmmyyyy_= SUBSTRING(p.rdate, 4, 2) + '/' + SUBSTRING(p.rdate, 1, 2) + '/' + SUBSTRING(p.rdate, 7, 4)
	where p.moifno = cast(@userID as nvarchar(15)))

	-- Return the result of the function
	RETURN @ResultVar

END
