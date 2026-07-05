CREATE TABLE [Tickets].[TicketPauseSession] (
    [ticketPauseSessionID]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]               BIGINT          NULL,
    [pauseReasonID_FK]         INT             NULL,
    [StartedByUsersID_FK]      BIGINT          NULL,
    [EndedByUsersID_FK]        BIGINT          NULL,
    [pauseNotes]               NVARCHAR (4000) NULL,
    [startedAt]                DATETIME        NULL,
    [endedAt]                  DATETIME        NULL,
    [pausedMinutes]            INT             NULL,
    [ticketPauseSessionActive] BIT             NULL,
    CONSTRAINT [PK_TicketPauseSession] PRIMARY KEY CLUSTERED ([ticketPauseSessionID] ASC),
    CONSTRAINT [FK_TicketPauseSession_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_TicketPauseSession_PauseReason] FOREIGN KEY ([pauseReasonID_FK]) REFERENCES [Tickets].[PauseReason] ([pauseReasonID])
);

