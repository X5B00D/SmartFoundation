CREATE TABLE [Tickets].[ArbitrationReason] (
    [arbitrationReasonID]          INT             IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                   BIGINT          NULL,
    [arbitrationReasonCode]        NVARCHAR (50)   NULL,
    [arbitrationReasonName_A]      NVARCHAR (200)  NULL,
    [arbitrationReasonName_E]      NVARCHAR (200)  NULL,
    [arbitrationReasonDescription] NVARCHAR (1000) NULL,
    [arbitrationReasonActive]      BIT             NULL,
    CONSTRAINT [PK_ArbitrationReason] PRIMARY KEY CLUSTERED ([arbitrationReasonID] ASC),
    CONSTRAINT [FK_ArbitrationReason_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

