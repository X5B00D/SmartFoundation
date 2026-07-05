CREATE TABLE [Tickets].[TicketClarification] (
    [ticketClarificationID]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                BIGINT          NULL,
    [TicketID_FK]               BIGINT          NULL,
    [clarificationReasonID_FK]  INT             NULL,
    [RequestedByUsersID_FK]     BIGINT          NULL,
    [RequestedFromUsersID_FK]   BIGINT          NULL,
    [RequestedFromDSDID_FK]     BIGINT          NULL,
    [requestText]               NVARCHAR (4000) NULL,
    [responseText]              NVARCHAR (4000) NULL,
    [respondedByUsersID_FK]     BIGINT          NULL,
    [requestedAt]               DATETIME        NULL,
    [respondedAt]               DATETIME        NULL,
    [ticketClarificationActive] BIT             NULL,
    CONSTRAINT [PK_TicketClarification] PRIMARY KEY CLUSTERED ([ticketClarificationID] ASC),
    CONSTRAINT [FK_TicketClarification_ClarificationReason] FOREIGN KEY ([clarificationReasonID_FK]) REFERENCES [Tickets].[ClarificationReason] ([clarificationReasonID]),
    CONSTRAINT [FK_TicketClarification_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_TicketClarification_Ticket] FOREIGN KEY ([TicketID_FK]) REFERENCES [Tickets].[Ticket] ([ticketID])
);

