CREATE TABLE [Tickets].[PauseReason] (
    [pauseReasonID]          INT             IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]             BIGINT          NULL,
    [pauseReasonCode]        NVARCHAR (50)   NULL,
    [pauseReasonName_A]      NVARCHAR (200)  NULL,
    [pauseReasonName_E]      NVARCHAR (200)  NULL,
    [pauseReasonSLA]         BIT             NULL,
    [pauseReasonDescription] NVARCHAR (1000) NULL,
    [pauseReasonActive]      BIT             NULL,
    CONSTRAINT [PK_PauseReason] PRIMARY KEY CLUSTERED ([pauseReasonID] ASC),
    CONSTRAINT [FK_PauseReason_Idara1] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

