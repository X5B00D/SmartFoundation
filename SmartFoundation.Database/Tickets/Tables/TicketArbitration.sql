CREATE TABLE [Tickets].[TicketArbitration] (
    [ticketArbitrationID]                   BIGINT          IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                            BIGINT          NULL,
    [TicketID_FK]                           BIGINT          NULL,
    [ticketArbitrationReasonID_FK]          INT             NULL,
    [ticketArbitrationRequestedByUserID_FK] BIGINT          NULL,
    [RequestedFromDSDID_FK]                 BIGINT          NULL,
    [ArbitratorDSDID_FK]                    BIGINT          NULL,
    [DecisionByUsersID_FK]                  BIGINT          NULL,
    [DecisionTargetDSDID_FK]                BIGINT          NULL,
    [ticketArbitrationDecisionNotes]        NVARCHAR (4000) NULL,
    [ticketArbitrationRequestedAt]          DATETIME        NULL,
    [ticketArbitrationDecideAt]             DATETIME        NULL,
    [ticketArbitrationActive]               BIT             NULL,
    CONSTRAINT [PK_TicketArbitration] PRIMARY KEY CLUSTERED ([ticketArbitrationID] ASC),
    CONSTRAINT [FK_TicketArbitration_ArbitrationReason] FOREIGN KEY ([ticketArbitrationReasonID_FK]) REFERENCES [Tickets].[ArbitrationReason] ([arbitrationReasonID]),
    CONSTRAINT [FK_TicketArbitration_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_TicketArbitration_Ticket] FOREIGN KEY ([TicketID_FK]) REFERENCES [Tickets].[Ticket] ([ticketID])
);

