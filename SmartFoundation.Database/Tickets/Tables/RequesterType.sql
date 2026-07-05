CREATE TABLE [Tickets].[RequesterType] (
    [requesterTypeID]          INT             IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]               BIGINT          NULL,
    [requesterTypeCode]        NVARCHAR (50)   NULL,
    [requesterTypeName_A]      NVARCHAR (200)  NULL,
    [requesterTypeName_E]      NVARCHAR (200)  NULL,
    [requesterTypeDescription] NVARCHAR (1000) NULL,
    [requesterTypeActive]      BIT             NULL,
    CONSTRAINT [PK_RequesterType] PRIMARY KEY CLUSTERED ([requesterTypeID] ASC),
    CONSTRAINT [FK_RequesterType_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

