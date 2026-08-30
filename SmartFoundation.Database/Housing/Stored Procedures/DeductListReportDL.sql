CREATE PROCEDURE Housing.DeductListReportDL @IdaraID BIGINT,@Year INT=NULL,@Month INT=NULL,@ReportID BIGINT=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SELECT r.*,i.idaraLongName_A,s.meterServiceTypeName_A,ISNULL(x.ImportedAmount,0) ImportedAmount,ISNULL(x.ImportedRows,0) ImportedRows,r.TotalAmount-ISNULL(x.ImportedAmount,0) DifferenceAmount
 FROM Housing.DeductListReport r JOIN dbo.Idara i ON i.idaraID=r.IdaraID_FK LEFT JOIN Housing.MeterServiceType s ON s.meterServiceTypeID=r.MeterServiceTypeID_FK
 OUTER APPLY(SELECT SUM(ImportedAmount) ImportedAmount,SUM(ImportedRows) ImportedRows FROM Housing.DeductListReportImport z WHERE z.DeductListReportID_FK=r.DeductListReportID)x
 WHERE r.IdaraID_FK=@IdaraID AND (@Year IS NULL OR r.PeriodYear=@Year) AND (@Month IS NULL OR r.PeriodMonth=@Month) ORDER BY r.DeductListReportID DESC;
 SELECT d.* FROM Housing.DeductListReportDetails d WHERE @ReportID IS NOT NULL AND d.DeductListReportID_FK=@ReportID ORDER BY d.DeductListReportDetailsID;
 SELECT x.*,l.deductName,l.paymentNo,l.paymentDate,log.OriginalFileName,log.UploadedAt FROM Housing.DeductListReportImport x JOIN Housing.DeductList l ON l.deductListID=x.DeductListID_FK LEFT JOIN Housing.UploadExcelImportLog log ON log.DeductListID_FK=l.deductListID WHERE @ReportID IS NOT NULL AND x.DeductListReportID_FK=@ReportID ORDER BY x.DeductListReportImportID DESC;
 SELECT serviceType.meterServiceTypeID,serviceType.meterServiceTypeName_A
 FROM Housing.MeterServiceType serviceType
 WHERE serviceType.meterServiceTypeActive=1
   AND EXISTS
   (
       SELECT 1
       FROM Housing.MeterForBuilding meterLink
       JOIN Housing.Meter meter ON meter.meterID=meterLink.meterID_FK AND meter.meterActive=1
       JOIN Housing.MeterType meterType ON meterType.meterTypeID=meter.meterTypeID_FK
           AND meterType.meterTypeActive=1
           AND meterType.MeterCalculateTypeID_FK=1
           AND meterType.meterServiceTypeID_FK=serviceType.meterServiceTypeID
           AND meterType.IdaraId_FK=@IdaraID
       JOIN Housing.BuildingDetailsMeterServices buildingService ON buildingService.BuildingDetailsID_FK=meterLink.buildingDetailsID_FK
           AND buildingService.MeterServicesTypeID_FK=serviceType.meterServiceTypeID
           AND buildingService.IdaraId_FK=@IdaraID
           AND buildingService.BuildingDetailsMeterServicesActive=1
       WHERE meterLink.IdaraID_FK=@IdaraID AND meterLink.meterForBuildingActive=1
   )
 ORDER BY serviceType.meterServiceTypeName_A;
END;
