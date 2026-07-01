CREATE TABLE [Tickets].[ClarificationReason] (
    [clarificationReasonID]          INT             IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                     BIGINT          NOT NULL,
    [clarificationReasonCode]        NVARCHAR (50)   NULL,
    [clarificationReasonName_A]      NVARCHAR (200)  NULL,
    [clarificationReasonName_E]      NVARCHAR (200)  NULL,
    [clarificationReasonDescription] NVARCHAR (1000) NULL,
    [clarificationReasonActive]      BIT             NULL,
    CONSTRAINT [PK_ClarificationReason] PRIMARY KEY CLUSTERED ([clarificationReasonID] ASC),
    CONSTRAINT [FK_ClarificationReason_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

