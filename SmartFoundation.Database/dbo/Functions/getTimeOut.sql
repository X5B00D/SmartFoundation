create FUNCTION [dbo].[getTimeOut]
(
    @userID int,
	@dateOfDay date
)
RETURNS NVARCHAR(12)
AS
BEGIN
DECLARE @Result NVARCHAR(12)

SET @Result=(	
				select top 1 cast(shiftTimeOut AS NVARCHAR (12))
				from KFMC.dbo.AttendanceShiftTime st
				WHERE 1=1
				AND (st.shiftTypeID_FK=dbo.GetUserTypeID(@userID))
				AND (st.shiftDayNo=DATEPART(dw,@dateOfDay))

)
    RETURN @Result

END
