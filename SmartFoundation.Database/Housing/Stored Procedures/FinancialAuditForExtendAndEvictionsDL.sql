-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Housing].[FinancialAuditForExtendAndEvictionsDL] 
	-- Add the parameters for the stored procedure here
	    @pageName_      NVARCHAR(400)
    , @idaraID        INT
    , @entrydata      INT
    , @hostname       NVARCHAR(400)
	,@residentInfoID   INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	    -- MeterReadForOccubentAndExit Data
 -- HousingExtend Data
        -- FinancialAuditForExtendAndEvictions Data

          
       
             SELECT 
                 fr.residentInfoID [residentInfoID]
                ,fr.NationalID [NationalID]
                ,fr.generalNo_FK [generalNo_FK]
                ,fr.firstName_A [firstName_A]
                ,fr.secondName_A [secondName_A]
                ,fr.thirdName_A [thirdName_A]
                ,fr.lastName_A [lastName_A]
                ,fr.firstName_E [firstName_E]
                ,fr.secondName_E [secondName_E]
                ,fr.thirdName_E [thirdName_E]
                ,fr.lastName_E [lastName_E]
                ,LTRIM(RTRIM(
                 CONCAT_WS(N' ',
                     fr.firstName_A,
                     fr.secondName_A,
                     fr.thirdName_A,
                     fr.lastName_A
                 )
                 )) AS FullName_A
                ,LTRIM(RTRIM(
                 CONCAT_WS(N' ',
                     fr.firstName_E,
                     fr.secondName_E,
                     fr.thirdName_E,
                     fr.lastName_E
                 )
                 )) AS FullName_E
                ,fr.rankID_FK [rankID_FK]
                ,fr.rankNameA
                ,fr.militaryUnitID_FK [militaryUnitID_FK]
                ,fr.militaryUnitName_A
                ,fr.martialStatusID_FK [martialStatusID_FK]
                ,fr.maritalStatusName_A
                ,fr.dependinceCounter [dependinceCounter]
                ,fr.nationalityID_FK [nationalityID_FK]
                ,fr.nationalityName_A
                ,fr.genderID_FK [genderID_FK]
                ,fr.genderName_A
                ,convert(nvarchar(10),fr.birthdate,23) birthdate
                ,fr.residentcontactDetails
                ,fr.note [note]
                ,fr.IdaraID IdaraID
                ,fr.IdaraName IdaraName
                ,w.buildingDetailsID
                ,w.buildingDetailsNo
                ,r.buildingRentAmount
                ,w.LastActionID
                ,w.LastActionTypeID
                ,w.ActionID
                ,convert(nvarchar(10),w.LastActionDate,23) LastActionDate
                ,w.LastActionExtendReasonTypeID
                
           FROM [DATACORE].[Housing].V_WaitingList w
           inner join [DATACORE].[Housing].V_GetFullResidentDetails fr on fr.residentInfoID = w.residentInfoID
           inner join Housing.V_buildingWithRent r on w.buildingDetailsID = r.buildingDetailsID
           where w.LastActionTypeID in (51,57) 
           and fr.residentInfoID = @residentInfoID
           and fr.IdaraID = @idaraID

           





          
        SELECT 
            rd.FullName_A+' - '+rd.NationalID+' - '+case when w.LastActionTypeID = 51 then N'امهال' when w.LastActionTypeID = 57 then N'اخلاء' END as FullName_A,
            w.residentInfoID
          
    FROM Housing.V_WaitingList w 
    INNER JOIN Housing.V_GetFullResidentDetails rd 
        ON w.residentInfoID = rd.residentInfoID
        Inner Join Housing.BuildingActionType ba on w.LastActionTypeID = ba.buildingActionTypeID
    WHERE w.IdaraId = @idaraID
      AND  w.LastActionTypeID in (51,57)
      order by   w.waitingClassSequence asc


      --or w.LastActionTypeID in (2,3,18,19,20,21,22,23,24,26,27,28,33,34,35)


------------------------



SELECT
    ROW_NUMBER() OVER (ORDER BY x.BillChargeTypeID) AS Order_,
    x.residentInfoID,
    x.BillChargeTypeID,
    bt.BillChargeTypeName_A,
    x.TotalBillsAmount,
    x.TotalBillsPaid,
    x.BillsAmountresidual,
    CASE
        WHEN x.BillsAmountresidual > 0 THEN N'فواتير ' + bt.BillChargeTypeName_A + N' مستحقة للادارة'
        WHEN x.BillsAmountresidual < 0 THEN N'فواتير ' + bt.BillChargeTypeName_A + N' زائدة للمستفيد'
        ELSE N'لايوجد مطالبات'
    END AS BillsStatus,
    CASE
        WHEN x.BillsAmountresidual > 0 THEN N'0'
        WHEN x.BillsAmountresidual < 0 THEN N'1'
        ELSE N'2'
    END AS BillsStatusID,
    fr.IdaraID
FROM DATACORE.Housing.V_WaitingList w
JOIN DATACORE.Housing.V_GetFullResidentDetails fr
    ON fr.residentInfoID = w.residentInfoID
JOIN DATACORE.Housing.V_ResidentBillsFinancialSummary s
    ON s.residentInfoID = fr.residentInfoID
CROSS APPLY
(
    VALUES
      (s.residentInfoID, 1, s.TotalRentBillsAmount,        s.TotalRentBillsPaid,
       s.TotalRentBillsAmount - s.TotalRentBillsPaid),

      (s.residentInfoID, 2, s.TotalElectrecityBillsAmount, s.TotalElectrecityBillsPaid,
       s.TotalElectrecityBillsAmount - s.TotalElectrecityBillsPaid),

      (s.residentInfoID, 3, s.TotalWaterBillsAmount,       s.TotalWaterBillsPaid,
       s.TotalWaterBillsAmount - s.TotalWaterBillsPaid),

      (s.residentInfoID, 4, s.TotalGasBillsAmount,         s.TotalGasBillsPaid,
       s.TotalGasBillsAmount - s.TotalGasBillsPaid),

      (s.residentInfoID, 5, s.TotalFineBillsAmount,        s.TotalFineBillsPaid,
       s.TotalFineBillsAmount - s.TotalFineBillsPaid)
) x(residentInfoID, BillChargeTypeID, TotalBillsAmount, TotalBillsPaid, BillsAmountresidual)
JOIN DATACORE.housing.BillChargeType bt
    ON bt.BillChargeTypeID = x.BillChargeTypeID
   AND bt.BillChargeTypeActive = 1
WHERE
    s.residentInfoID = @residentInfoID
    AND w.LastActionTypeID IN (51, 57)
    AND fr.IdaraID = @idaraID;



      --SELECT
      --  ROW_NUMBER() OVER (ORDER BY s.residentInfoID ASC) AS Order_
      -- ,s.residentInfoID
      --,s.TotalRentBillsAmount
      --,s.[TotalRentBillsPaid]
      --,(s.[TotalRentBillsAmount] - s.[TotalRentBillsPaid]) RentBillsAmountresidual
      --, CASE 
      --  WHEN (s.TotalRentBillsAmount - s.TotalRentBillsPaid) > 0 THEN N'ايجارات مستحقة للادارة'
      --  WHEN (s.TotalRentBillsAmount - s.TotalRentBillsPaid) < 0 THEN N'مبالغ ايجارات زائدة للمستفيد'
      --  WHEN (s.TotalRentBillsAmount - s.TotalRentBillsPaid) = 0 THEN N'لايوجد مطالبات'
      --  END AS RentBillsStatus
      --  , CASE 
      --  WHEN (s.TotalRentBillsAmount - s.TotalRentBillsPaid) > 0 THEN N'0'
      --  WHEN (s.TotalRentBillsAmount - s.TotalRentBillsPaid) < 0 THEN N'1'
      --  WHEN (s.TotalRentBillsAmount - s.TotalRentBillsPaid) = 0 THEN N'2'
      --  END AS RentBillsStatusID

      --,s.TotalElectrecityBillsAmount
      --,s.TotalElectrecityBillsPaid
      --,(s.TotalElectrecityBillsAmount - s.TotalElectrecityBillsPaid) ElectrecityBillsAmountresidual
      --, CASE 
      --  WHEN (s.TotalElectrecityBillsAmount - s.TotalElectrecityBillsPaid) > 0 THEN N' فواتير كهرباء مستحقة للادارة'
      --  WHEN (s.TotalElectrecityBillsAmount - s.TotalElectrecityBillsPaid) < 0 THEN N'فواتير كهرباء زائدة للمستفيد'
      --  WHEN (s.TotalElectrecityBillsAmount - s.TotalElectrecityBillsPaid) = 0 THEN N'لايوجد مطالبات'
      --  END AS  ElectrecityBillStatus
      --  , CASE 
      --  WHEN (s.TotalElectrecityBillsAmount - s.TotalElectrecityBillsPaid) > 0 THEN N'0'
      --  WHEN (s.TotalElectrecityBillsAmount - s.TotalElectrecityBillsPaid) < 0 THEN N'1'
      --  WHEN (s.TotalElectrecityBillsAmount - s.TotalElectrecityBillsPaid) = 0 THEN N'2'
      --  END AS  ElectrecityBillStatusID,
      --  fr.IdaraID


      ----,(([TotalRentBillsAmount]+[TotalServiceBillsAmount]) - ([TotalRentBillsPaid]+[TotalServiceBillsPaid])) AllAmountresidual
      --FROM [DATACORE].[Housing].V_WaitingList w
      --     inner join [DATACORE].[Housing].V_GetFullResidentDetails fr on fr.residentInfoID = w.residentInfoID
      --  inner join [DATACORE].[Housing].[V_ResidentBillsFinancialSummary] s on fr.residentInfoID = s.residentInfoID

      --  where s.residentInfoID = @residentInfoID
      --  AND  w.LastActionTypeID in (51,57)
      --  and fr.IdaraID = @idaraID






         SELECT
      
        (([TotalRentBillsAmount]+[TotalServiceBillsAmount]) - ([TotalRentBillsPaid]+[TotalServiceBillsPaid])) AllAmountresidual
      
      ,([TotalRentBillsAmount] - [TotalRentBillsPaid]) RentBillsAmountresidual
      ,([TotalServiceBillsAmount] - [TotalServiceBillsPaid]) ServiceBillsAmountresidual


        FROM [DATACORE].[Housing].V_WaitingList w
           inner join [DATACORE].[Housing].V_GetFullResidentDetails fr on fr.residentInfoID = w.residentInfoID
        inner join [DATACORE].[Housing].[V_ResidentFinancialSummary] s on fr.residentInfoID = s.residentInfoID

        where s.residentInfoID = @residentInfoID
        AND  w.LastActionTypeID in (51,57)
        and fr.IdaraID = @idaraID






        select 
        t.billPaymentTypeID,
        t.billPaymentTypeName_A
        from Housing.billPaymentType t 
        where t.billPaymentDestainationID_FK = 1
        



         select 
        t.billPaymentTypeID,
        t.billPaymentTypeName_A
        from Housing.billPaymentType t 
        where t.billPaymentDestainationID_FK = 2
     

     select 
        t.billPaymentTypeID,
        t.billPaymentTypeName_A
        from Housing.billPaymentType t 
        where t.billPaymentTypeID in(1,2)


     select r.buildingRentAmount * 40 insuranceRentAmount,r.buildingRentAmount

     FROM [DATACORE].[Housing].V_WaitingList w
        inner join [DATACORE].[Housing].V_GetFullResidentDetails fr on fr.residentInfoID = w.residentInfoID
        inner join [DATACORE].[Housing].[V_ResidentFinancialSummary] s on fr.residentInfoID = s.residentInfoID
        inner join Housing.V_buildingWithRent r on w.buildingDetailsID = r.buildingDetailsID
        where s.residentInfoID = @residentInfoID
        AND  w.LastActionTypeID in (51,57)
        and fr.IdaraID = @idaraID



         Select e.ExtendReasonTypeID,e.ExtendReasonTypeName_A 
      from Housing.ExtendReasonType e
      where e.Active = 1

     


END
