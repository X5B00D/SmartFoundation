CREATE TABLE Housing.DeductListReportImport
(
    DeductListReportImportID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DeductListReportImport PRIMARY KEY,
    DeductListReportID_FK BIGINT NOT NULL, DeductListID_FK INT NOT NULL,
    ImportedAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_DeductListReportImport_Amount DEFAULT(0),
    ImportedRows INT NOT NULL CONSTRAINT DF_DeductListReportImport_Rows DEFAULT(0),
    entryDate DATETIME NOT NULL CONSTRAINT DF_DeductListReportImport_EntryDate DEFAULT(GETDATE()),
    entryData NVARCHAR(20) NULL, hostName NVARCHAR(200) NULL,
    CONSTRAINT FK_DeductListReportImport_Report FOREIGN KEY(DeductListReportID_FK) REFERENCES Housing.DeductListReport(DeductListReportID),
    CONSTRAINT FK_DeductListReportImport_DeductList FOREIGN KEY(DeductListID_FK) REFERENCES Housing.DeductList(deductListID)
);
GO
CREATE UNIQUE INDEX UX_DeductListReportImport_DeductList ON Housing.DeductListReportImport(DeductListID_FK);
