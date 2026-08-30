CREATE TABLE Housing.DeductListReport
(
    DeductListReportID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DeductListReport PRIMARY KEY,
    IdaraID_FK BIGINT NOT NULL,
    PeriodYear INT NOT NULL,
    PeriodMonth INT NOT NULL,
    BillingType NVARCHAR(20) NOT NULL,
    MeterServiceTypeID_FK INT NULL,
    CalculationMethod NVARCHAR(30) NOT NULL,
    ReportNo NVARCHAR(50) NOT NULL,
    RevisionNo INT NOT NULL CONSTRAINT DF_DeductListReport_Revision DEFAULT(1),
    ReportStatus NVARCHAR(20) NOT NULL CONSTRAINT DF_DeductListReport_Status DEFAULT(N'DRAFT'),
    IsCurrent BIT NOT NULL CONSTRAINT DF_DeductListReport_Current DEFAULT(1),
    InvoiceCount INT NOT NULL CONSTRAINT DF_DeductListReport_Count DEFAULT(0),
    AmountBeforeTax DECIMAL(18,2) NOT NULL CONSTRAINT DF_DeductListReport_Amount DEFAULT(0),
    TaxAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_DeductListReport_Tax DEFAULT(0),
    TotalAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_DeductListReport_Total DEFAULT(0),
    ApprovedDate DATETIME NULL, ApprovedBy NVARCHAR(20) NULL,
    SentDate DATETIME NULL, SentBy NVARCHAR(20) NULL, ExternalReferenceNo NVARCHAR(100) NULL, ExternalReferenceDate DATE NULL,
    Notes NVARCHAR(1000) NULL, entryDate DATETIME NOT NULL CONSTRAINT DF_DeductListReport_EntryDate DEFAULT(GETDATE()),
    entryData NVARCHAR(20) NULL, hostName NVARCHAR(200) NULL,
    CONSTRAINT CK_DeductListReport_Period CHECK(PeriodMonth BETWEEN 1 AND 12),
    CONSTRAINT CK_DeductListReport_Status CHECK(ReportStatus IN(N'DRAFT',N'APPROVED',N'SENT',N'CANCELLED')),
    CONSTRAINT CK_DeductListReport_Type CHECK(BillingType IN(N'RENT',N'SERVICE')),
    CONSTRAINT FK_DeductListReport_Idara FOREIGN KEY(IdaraID_FK) REFERENCES dbo.Idara(idaraID)
);
GO
CREATE UNIQUE INDEX UX_DeductListReport_CurrentScope ON Housing.DeductListReport
(IdaraID_FK,PeriodYear,PeriodMonth,BillingType,MeterServiceTypeID_FK,CalculationMethod)
WHERE IsCurrent=1;
GO
CREATE UNIQUE INDEX UX_DeductListReport_ReportNo ON Housing.DeductListReport(ReportNo);
