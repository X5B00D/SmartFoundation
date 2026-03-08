-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
/*
 
 exec [DashBoard].[DashBoardDeteils] @CardId = 1

*/
create PROCEDURE [Housing].[DashBoardHousingDeteils] 
	-- Add the parameters for the stored procedure here
	@CardId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	 IF OBJECT_ID('tempdb..#building') IS NOT NULL
    DROP TABLE #building


 if(@CardId = 1)
 begin

						 
select gf.BuildingNo,gf.BuildingTypeID,gf.BuildingClassID,gf.BuildingClassName,gb.ActionTypeID LastAction,gb.ActionDate,gf.LocationName,gf.buildingClassOrder
INTO #building
from kfmc.Housing.GetGeneralListForBuilding() gf
left join kfmc.Housing.GetGeneralListActionForBuildig() gb on gb.BuildingNo = gf.BuildingNo
INNER join Housing.V_LastActionForBuilding v on gb.ActionID = v.buildingActionID
where gf.UtilityTypeID in (1,11,15) 
union ALL

select gb.BuildingNo,gb.BuildingTypeID,gb.BuildingClassID,gb.BuildingClassName,8 AS LastAction, null as ActionDate,gb.LocationName , null as buildingClassOrder
from kfmc.Housing.GetGeneralListForBuilding() gb
where gb.BuildingNo not in(select gg.BuildingNo from kfmc.Housing.GetGeneralListActionForBuildig() gg ) and gb.UtilityTypeID in (1,11,15)




select  N' الاحصائية العامة' as N' '

				SELECT 1 AS #, N'المساكن المشغولة' as N'الحالة / الفئة',
				
				(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=6)) AS N'القادة'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=1)) AS N'كبار الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=2)) AS N'الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=14)) AS N'الضباط العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=5)) AS N'ضباط الصف'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=15)) AS N'ضباط الصف العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=3)) AS N'الجنود'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=10)) AS N'الشئون الدينية'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=8)) AS N'الدفاع الجوي'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=4)) AS N'مدنيين'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=7)) AS N'بند تشغيل'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24)) AND (bg.BuildingClassID=9)) AS N'عمال'
			   ,(select count(*) from #building bg where (bg.LastAction in (2,24))) AS N'الاجمالي'

union all

			   SELECT 2 AS #, N'المساكن الخالية' as N'الحالة / الفئة',
				
				(select count(*) from #building bg where (bg.LastAction in (3,4,15)) AND (bg.BuildingClassID=6)) AS N'القادة'
			   ,(select count(*) from #building bg where (bg.LastAction in (3,4,15)) AND (bg.BuildingClassID=1)) AS N'كبار الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction in (3,4,15)) AND (bg.BuildingClassID=2)) AS N'الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction IN (3,4,15)) AND (bg.BuildingClassID=14)) AS N'الضباط العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (3,4,15)) AND (bg.BuildingClassID=5)) AS N'ضباط الصف'
			   ,(select count(*) from #building bg where (bg.LastAction IN (3,4,15)) AND (bg.BuildingClassID=15)) AS N'ضباط الصف العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (3,4,15)) AND (bg.BuildingClassID=3)) AS N'الجنود'
			   ,(select count(*) from #building bg where (bg.LastAction IN (3,4,15)) AND (bg.BuildingClassID=10)) AS N'الشئون الدينية'
			   ,(select count(*) from #building bg where (bg.LastAction in (3,4,15)) AND (bg.BuildingClassID=8)) AS N'الدفاع الجوي'
			   ,(select count(*) from #building bg where (bg.LastAction in (3,4,15)) AND (bg.BuildingClassID=4)) AS N'مدنيين'
			   ,(select count(*) from #building bg where (bg.LastAction in (3,4,15)) AND (bg.BuildingClassID=7)) AS N'بند تشغيل'
			   ,(select count(*) from #building bg where (bg.LastAction in (3,4,15)) AND (bg.BuildingClassID=9)) AS N'عمال'
			   ,(select count(*) from #building bg where (bg.LastAction in (3,4,15))) AS N'الاجمالي'


			   union all

			   SELECT 3 AS #, N'المساكن الجاهزة للتسكين' as N'الحالة / الفئة',
				
				(select count(*) from #building bg where (bg.LastAction in (5)) AND (bg.BuildingClassID=6)) AS N'القادة'
			   ,(select count(*) from #building bg where (bg.LastAction in (5)) AND (bg.BuildingClassID=1)) AS N'كبار الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction in (5)) AND (bg.BuildingClassID=2)) AS N'الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction IN (5)) AND (bg.BuildingClassID=14)) AS N'الضباط العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (5)) AND (bg.BuildingClassID=5)) AS N'ضباط الصف'
			   ,(select count(*) from #building bg where (bg.LastAction IN (5)) AND (bg.BuildingClassID=15)) AS N'ضباط الصف العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (5)) AND (bg.BuildingClassID=3)) AS N'الجنود'
			   ,(select count(*) from #building bg where (bg.LastAction IN (5)) AND (bg.BuildingClassID=10)) AS N'الشئون الدينية'
			   ,(select count(*) from #building bg where (bg.LastAction in (5)) AND (bg.BuildingClassID=8)) AS N'الدفاع الجوي'
			   ,(select count(*) from #building bg where (bg.LastAction in (5)) AND (bg.BuildingClassID=4)) AS N'مدنيين'
			   ,(select count(*) from #building bg where (bg.LastAction in (5)) AND (bg.BuildingClassID=7)) AS N'بند تشغيل'
			   ,(select count(*) from #building bg where (bg.LastAction in (5)) AND (bg.BuildingClassID=9)) AS N'عمال'
			   ,(select count(*) from #building bg where (bg.LastAction in (5))) AS N'الاجمالي'

union all

			   SELECT 4 AS #, N'المساكن الغير معروفة' as N'الحالة / الفئة',
				
				(select count(*) from #building bg  where (bg.LastAction in (8)) AND (bg.BuildingClassID=6)) AS N'القادة'
			   ,(select count(*) from #building bg  where (bg.LastAction in (8)) AND (bg.BuildingClassID=1)) AS N'كبار الضباط'
			   ,(select count(*) from #building bg  where (bg.LastAction in (8)) AND (bg.BuildingClassID=2)) AS N'الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction IN (8)) AND (bg.BuildingClassID=14)) AS N'الضباط العزاب'
			   ,(select count(*) from #building bg  where (bg.LastAction in (8)) AND (bg.BuildingClassID=5)) AS N'ضباط الصف'
			   ,(select count(*) from #building bg where (bg.LastAction IN (8)) AND (bg.BuildingClassID=15)) AS N'ضباط الصف العزاب'
			   ,(select count(*) from #building bg  where (bg.LastAction in (8)) AND (bg.BuildingClassID=3)) AS N'الجنود'
			   ,(select count(*) from #building bg  where (bg.LastAction IN (8)) AND (bg.BuildingClassID=10)) AS N'الشئون الدينية'
			   ,(select count(*) from #building bg  where (bg.LastAction in (8)) AND (bg.BuildingClassID=8)) AS N'الدفاع الجوي'
			   ,(select count(*) from #building bg  where (bg.LastAction in (8)) AND (bg.BuildingClassID=4)) AS N'مدنيين'
			   ,(select count(*) from #building bg  where (bg.LastAction in (8)) AND (bg.BuildingClassID=7)) AS N'بند تشغيل'
			   ,(select count(*) from #building bg  where (bg.LastAction in (8)) AND (bg.BuildingClassID=9)) AS N'عمال'
			   ,(select count(*) from #building bg  where (bg.LastAction in (8))) AS N'الاجمالي'

union all

			   SELECT 5 AS #, N'المساكن تحت الصيانة' as N'الحالة / الفئة',
				
				(select count(*) from #building bg where (bg.LastAction in (9,10,16)) AND (bg.BuildingClassID=6)) AS N'القادة'
			   ,(select count(*) from #building bg where (bg.LastAction in (9,10,16)) AND (bg.BuildingClassID=1)) AS N'كبار الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction in (9,10,16)) AND (bg.BuildingClassID=2)) AS N'الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction IN (9,10,16)) AND (bg.BuildingClassID=14)) AS N'الضباط العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (9,10,16)) AND (bg.BuildingClassID=5)) AS N'ضباط الصف'
			   ,(select count(*) from #building bg where (bg.LastAction IN (9,10,16)) AND (bg.BuildingClassID=15)) AS N'ضباط الصف العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (9,10,16)) AND (bg.BuildingClassID=3)) AS N'الجنود'
			   ,(select count(*) from #building bg where (bg.LastAction IN (9,10,16)) AND (bg.BuildingClassID=10)) AS N'الشئون الدينية'
			   ,(select count(*) from #building bg where (bg.LastAction in (9,10,16)) AND (bg.BuildingClassID=8)) AS N'الدفاع الجوي'
			   ,(select count(*) from #building bg where (bg.LastAction in (9,10,16)) AND (bg.BuildingClassID=4)) AS N'مدنيين'
			   ,(select count(*) from #building bg where (bg.LastAction in (9,10,16)) AND (bg.BuildingClassID=7)) AS N'بند تشغيل'
			   ,(select count(*) from #building bg where (bg.LastAction in (9,10,16)) AND (bg.BuildingClassID=9)) AS N'عمال'
			   ,(select count(*) from #building bg where (bg.LastAction in (9,10,16))) AS N'الاجمالي'		
			   
union all

			   SELECT 6 AS #, N'المساكن في الجودة' as N'الحالة / الفئة',
				
				(select count(*) from #building bg where (bg.LastAction in (11,12,17)) AND (bg.BuildingClassID=6)) AS N'القادة'
			   ,(select count(*) from #building bg where (bg.LastAction in (11,12,17)) AND (bg.BuildingClassID=1)) AS N'كبار الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction in (11,12,17)) AND (bg.BuildingClassID=2)) AS N'الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction IN (11,12,17)) AND (bg.BuildingClassID=14)) AS N'الضباط العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (11,12,17)) AND (bg.BuildingClassID=5)) AS N'ضباط الصف'
			   ,(select count(*) from #building bg where (bg.LastAction IN (11,12,17)) AND (bg.BuildingClassID=15)) AS N'ضباط الصف العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (11,12,17)) AND (bg.BuildingClassID=3)) AS N'الجنود'
			   ,(select count(*) from #building bg where (bg.LastAction IN (11,12,17)) AND (bg.BuildingClassID=10)) AS N'الشئون الدينية'
			   ,(select count(*) from #building bg where (bg.LastAction in (11,12,17)) AND (bg.BuildingClassID=8)) AS N'الدفاع الجوي'
			   ,(select count(*) from #building bg where (bg.LastAction in (11,12,17)) AND (bg.BuildingClassID=4)) AS N'مدنيين'
			   ,(select count(*) from #building bg where (bg.LastAction in (11,12,17)) AND (bg.BuildingClassID=7)) AS N'بند تشغيل'
			   ,(select count(*) from #building bg where (bg.LastAction in (11,12,17)) AND (bg.BuildingClassID=9)) AS N'عمال'
			   ,(select count(*) from #building bg where (bg.LastAction in (11,12,17))) AS N'الاجمالي'	


			   union all

			   SELECT 7 AS #, N'المساكن في التنفيذ ' as N'الحالة / الفئة',
				
				(select count(*) from #building bg where (bg.LastAction in (30,31)) AND (bg.BuildingClassID=6)) AS N'القادة'
			   ,(select count(*) from #building bg where (bg.LastAction in (30,31)) AND (bg.BuildingClassID=1)) AS N'كبار الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction in (30,31)) AND (bg.BuildingClassID=2)) AS N'الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction IN (30,31)) AND (bg.BuildingClassID=14)) AS N'الضباط العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (30,31)) AND (bg.BuildingClassID=5)) AS N'ضباط الصف'
			   ,(select count(*) from #building bg where (bg.LastAction IN (30,31)) AND (bg.BuildingClassID=15)) AS N'ضباط الصف العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (30,31)) AND (bg.BuildingClassID=3)) AS N'الجنود'
			   ,(select count(*) from #building bg where (bg.LastAction IN (30,31)) AND (bg.BuildingClassID=10)) AS N'الشئون الدينية'
			   ,(select count(*) from #building bg where (bg.LastAction in (30,31)) AND (bg.BuildingClassID=8)) AS N'الدفاع الجوي'
			   ,(select count(*) from #building bg where (bg.LastAction in (30,31)) AND (bg.BuildingClassID=4)) AS N'مدنيين'
			   ,(select count(*) from #building bg where (bg.LastAction in (30,31)) AND (bg.BuildingClassID=7)) AS N'بند تشغيل'
			   ,(select count(*) from #building bg where (bg.LastAction in (30,31)) AND (bg.BuildingClassID=9)) AS N'عمال'
			   ,(select count(*) from #building bg where (bg.LastAction in (30,31))) AS N'الاجمالي'	

union all

			   SELECT 8 AS #, N'المساكن تحت اجراءات النظافة' as N'الحالة / الفئة',
				
				(select count(*) from #building bg where (bg.LastAction in (13,14)) AND (bg.BuildingClassID=6)) AS N'القادة'
			   ,(select count(*) from #building bg where (bg.LastAction in (13,14)) AND (bg.BuildingClassID=1)) AS N'كبار الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction in (13,14)) AND (bg.BuildingClassID=2)) AS N'الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction IN (13,14)) AND (bg.BuildingClassID=14)) AS N'الضباط العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (13,14)) AND (bg.BuildingClassID=5)) AS N'ضباط الصف'
			   ,(select count(*) from #building bg where (bg.LastAction IN (13,14)) AND (bg.BuildingClassID=15)) AS N'ضباط الصف العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (13,14)) AND (bg.BuildingClassID=3)) AS N'الجنود'
			   ,(select count(*) from #building bg where (bg.LastAction IN (13,14)) AND (bg.BuildingClassID=10)) AS N'الشئون الدينية'
			   ,(select count(*) from #building bg where (bg.LastAction in (13,14)) AND (bg.BuildingClassID=8)) AS N'الدفاع الجوي'
			   ,(select count(*) from #building bg where (bg.LastAction in (13,14)) AND (bg.BuildingClassID=4)) AS N'مدنيين'
			   ,(select count(*) from #building bg where (bg.LastAction in (13,14)) AND (bg.BuildingClassID=7)) AS N'بند تشغيل'
			   ,(select count(*) from #building bg where (bg.LastAction in (13,14)) AND (bg.BuildingClassID=9)) AS N'عمال'
			   ,(select count(*) from #building bg where (bg.LastAction in (13,14))) AS N'الاجمالي'	
					
union all

			   SELECT 9 AS #, N'الاجمالي' as N'الحالة / الفئة',
				
				(select count(*) from #building bg where (bg.LastAction in (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=6)) AS N'القادة'
			   ,(select count(*) from #building bg where (bg.LastAction in (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=1)) AS N'كبار الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction in (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=2)) AS N'الضباط'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=14)) AS N'الضباط العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=5)) AS N'ضباط الصف'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=15)) AS N'ضباط الصف العزاب'
			   ,(select count(*) from #building bg where (bg.LastAction in (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=3)) AS N'الجنود'
			   ,(select count(*) from #building bg where (bg.LastAction IN (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=10)) AS N'الشئون الدينية'
			   ,(select count(*) from #building bg where (bg.LastAction in (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=8)) AS N'الدفاع الجوي'
			   ,(select count(*) from #building bg where (bg.LastAction in (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=4)) AS N'مدنيين'
			   ,(select count(*) from #building bg where (bg.LastAction in (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=7)) AS N'بند تشغيل'
			   ,(select count(*) from #building bg where (bg.LastAction in (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17)) AND (bg.BuildingClassID=9)) AS N'عمال'
			   ,(select count(*) from #building bg where (bg.LastAction in (2,24,3,4,8,9,10,11,12,13,14,5,15,16,17))) AS N'الاجمالي'
					
					--------------------------------------------------------------------------------------------

					 if(select count(*) from #building bg where (bg.LastAction in (5))) > 0
					begin

					select  N' المساكن الجاهزة للتسكين' as N' '
				
				    select ROW_NUMBER() OVER (ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc) AS N'م' ,
					case 
					when bg.BuildingClassID = 1 then N'كبار ضباط عقيد فأعلى'
					when bg.BuildingClassID = 2 then N'الضباط مقدم فأدنى'
					else
					bg.BuildingClassName
					END N'فئة المساكن ',
					bg.LocationName N'الحي',
					bg.BuildingNo as N'ارقام المساكن '
					,
					
					convert(nvarchar(10),bg.ActionDate,23) N'تاريخ التحويل',
					DATEDIFF(DAY,bg.ActionDate,GETDATE()) N'عدد الايام الى الان'

					
					
					from #building bg 
					where (bg.LastAction in (5)) 
			 ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc
			  end

			  else
			  begin
			  select
			  N'' as N'.',
			  N' لا يوجد مساكن جاهزة للتسكين' as N' ',
			  N'' as N'..'
			  end

			  --------------------------------------------------------------------------------------------


					--------------------------------------------------------------------------------------------

					 if(select count(*) from #building bg where (bg.LastAction in (8))) > 0
					begin

					select  N' المساكن الغير معروفة' as N' '
				
				     select ROW_NUMBER() OVER (ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc) AS N'م' ,
					case 
					when bg.BuildingClassID = 1 then N'كبار ضباط عقيد فأعلى'
					when bg.BuildingClassID = 2 then N'الضباط مقدم فأدنى'
					else
					bg.BuildingClassName
					END N'فئة المساكن ',
					bg.LocationName N'الحي',
					bg.BuildingNo as N'ارقام المساكن '
					
					
					from #building bg 
					where (bg.LastAction in (8)) 
			 ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc

			  end

			  else
			  begin
			  select
			  N'' as N'.',
			  N' لا يوجد مساكن غير معروفة' as N' ',
			  N'' as N'..'
			  end
			  --------------------------------------------------------------------------------------------

			   if(select count(*) from #building bg where (bg.LastAction in (9,10,16))) > 0
					begin

					select  N' المساكن في الصيانة' as N' '
				
				    select ROW_NUMBER() OVER (ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc) AS N'م' ,
					case 
					when bg.BuildingClassID = 1 then N'كبار ضباط عقيد فأعلى'
					when bg.BuildingClassID = 2 then N'الضباط مقدم فأدنى'
					else
					bg.BuildingClassName
					END N'فئة المساكن ',
					bg.LocationName N'الحي',
					bg.BuildingNo as N'ارقام المساكن '
					,
					
					convert(nvarchar(10),bg.ActionDate,23) N'تاريخ التحويل',
					DATEDIFF(DAY,bg.ActionDate,GETDATE()) N'عدد الايام الى الان'

					from #building bg  
					where (bg.LastAction in (9,10,16)) 
			 ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc
			  end

			  else
			  begin
			  select
			  N'' as N'.',
			  N' لا يوجد مساكن في الصيانة' as N' ',
			  N'' as N'..'
			  end

			    --------------------------------------------------------------------------------------------



					select  N' المساكن في الجودة' as N' '
				

				    if(select count(*) from #building bg where (bg.LastAction in (11,12,17))) > 0
					begin
				   select ROW_NUMBER() OVER (ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc) AS N'م' ,
					case 
					when bg.BuildingClassID = 1 then N'كبار ضباط عقيد فأعلى'
					when bg.BuildingClassID = 2 then N'الضباط مقدم فأدنى'
					else
					bg.BuildingClassName
					END N'فئة المساكن ',
					bg.LocationName N'الحي',
					bg.BuildingNo as N'ارقام المساكن '
					,
					
					convert(nvarchar(10),bg.ActionDate,23) N'تاريخ التحويل',
					DATEDIFF(DAY,bg.ActionDate,GETDATE()) N'عدد الايام الى الان'

					from #building bg 
					where (bg.LastAction in (11,12,17)) 
			 ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc

			  end

			  else
			  begin
			  select
			  N'' as N'.',
			  N' لا يوجد مساكن في الجودة' as N' ',
			  N'' as N'..'
			  end
			    --------------------------------------------------------------------------------------------


				
					select  N' المساكن في التنفيذ' as N' '
				

				    if(select count(*) from #building bg where (bg.LastAction in (30,31))) > 0
					begin
				   select ROW_NUMBER() OVER (ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc) AS N'م' ,
					case 
					when bg.BuildingClassID = 1 then N'كبار ضباط عقيد فأعلى'
					when bg.BuildingClassID = 2 then N'الضباط مقدم فأدنى'
					else
					bg.BuildingClassName
					END N'فئة المساكن ',
					bg.LocationName N'الحي',
					bg.BuildingNo as N'ارقام المساكن '
					,
					
					convert(nvarchar(10),bg.ActionDate,23) N'تاريخ التحويل',
					DATEDIFF(DAY,bg.ActionDate,GETDATE()) N'عدد الايام الى الان'

					from #building bg 
					where (bg.LastAction in (30,31)) 
			 ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc

			  end

			  else
			  begin
			  select
			  N'' as N'.',
			  N' لا يوجد مساكن في التنفيذ' as N' ',
			  N'' as N'..'
			  end
			    --------------------------------------------------------------------------------------------


				 if(select count(*) from #building bg where (bg.LastAction in (13,14))) > 0
					begin
					select  N' المساكن تحت اجراءات النظافة' as N' '
				
				   select ROW_NUMBER() OVER (ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc) AS N'م' ,
					case 
					when bg.BuildingClassID = 1 then N'كبار ضباط عقيد فأعلى'
					when bg.BuildingClassID = 2 then N'الضباط مقدم فأدنى'
					else
					bg.BuildingClassName
					END N'فئة المساكن ',
					bg.LocationName N'الحي',
					bg.BuildingNo as N'ارقام المساكن '
					,
					
					convert(nvarchar(10),bg.ActionDate,23) N'تاريخ التحويل',
					DATEDIFF(DAY,bg.ActionDate,GETDATE()) N'عدد الايام الى الان'

					from #building bg  
					where (bg.LastAction in (13,14)) 
			 ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc
			   end

			  else
			  begin
			  select
			  N'' as N'.',
			  N' لا يوجد مساكن تحت اجراءات النظافة' as N' ',
			  N'' as N'..'
			  end
			  --------------------------------------------------------------------------------------------


			   if(select count(*) from #building bg where (bg.LastAction in (3,4,15))) > 0
					begin
					select  N' المساكن الخالية' as N' '
				
				   select ROW_NUMBER() OVER (ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc) AS N'م' ,
					case 
					when bg.BuildingClassID = 1 then N'كبار ضباط عقيد فأعلى'
					when bg.BuildingClassID = 2 then N'الضباط مقدم فأدنى'
					else
					bg.BuildingClassName
					END N'فئة المساكن ',
					bg.LocationName N'الحي',
					bg.BuildingNo as N'ارقام المساكن '
					,
					
					convert(nvarchar(10),bg.ActionDate,23) N'تاريخ التحويل',
					DATEDIFF(DAY,bg.ActionDate,GETDATE()) N'عدد الايام الى الان'

					
					from #building bg  
					where (bg.LastAction in (3,4,15)) 
			 ORDER BY bg.buildingClassOrder asc, DATEDIFF(DAY,bg.ActionDate,GETDATE()) desc
			   end

			  else
			  begin
			  select
			  N'' as N'.',
			  N' لا يوجد مساكن الخالية' as N' ',
			  N'' as N'..'
			  end




   DROP TABLE #building

 End

END
