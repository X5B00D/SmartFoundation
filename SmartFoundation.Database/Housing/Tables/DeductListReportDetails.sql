CREATE TABLE Housing.DeductListReportDetails
(
    DeductListReportDetailsID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DeductListReportDetails PRIMARY KEY,
    DeductListReportID_FK BIGINT NOT NULL, BillsID_FK BIGINT NOT NULL,
    BillNumber NVARCHAR(100) NULL, ResidentInfoID_FK BIGINT NULL, GeneralNo_FK BIGINT NULL, IDNumber NVARCHAR(20) NULL, ResidentFullName_A NVARCHAR(250) NULL, MilitaryUnitName_A NVARCHAR(250) NULL,
    BuildingDetailsID_FK BIGINT NULL, BuildingDetailsNo NVARCHAR(200) NULL, MeterID_FK INT NULL, MeterNo NVARCHAR(100) NULL,
    BillsFromDate DATE NULL, BillsToDate DATE NULL, AmountBeforeTax DECIMAL(18,2) NOT NULL,
    TaxAmount DECIMAL(18,2) NOT NULL, TotalAmount DECIMAL(18,2) NOT NULL,
    entryDate DATETIME NOT NULL CONSTRAINT DF_DeductListReportDetails_EntryDate DEFAULT(GETDATE()),
    CONSTRAINT FK_DeductListReportDetails_Report FOREIGN KEY(DeductListReportID_FK) REFERENCES Housing.DeductListReport(DeductListReportID),
    CONSTRAINT FK_DeductListReportDetails_Bill FOREIGN KEY(BillsID_FK) REFERENCES Housing.Bills(BillsID)
);
GO
CREATE UNIQUE INDEX UX_DeductListReportDetails_ReportBill ON Housing.DeductListReportDetails(DeductListReportID_FK,BillsID_FK);
