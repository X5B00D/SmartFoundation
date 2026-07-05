CREATE TABLE [Tickets].[OperationalType] (
    [operationalTypeID]          INT             IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                 BIGINT          NULL,
    [operationalTypeCode]        NVARCHAR (50)   NULL,
    [operationalTypeName_A]      NVARCHAR (200)  NULL,
    [operationalTypeName_E]      NVARCHAR (200)  NULL,
    [operationalTypeDescription] NVARCHAR (1000) NULL,
    [operationalTypeActive]      BIT             NULL,
    CONSTRAINT [PK_OperationalType] PRIMARY KEY CLUSTERED ([operationalTypeID] ASC),
    CONSTRAINT [FK_OperationalType_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

