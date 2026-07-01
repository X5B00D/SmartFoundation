CREATE TABLE [Tickets].[TicketApproval] (
    [ticketApprovalID]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]           BIGINT          NULL,
    [TicketID_FK]          BIGINT          NULL,
    [approvalStepID_FK]    BIGINT          NULL,
    [stepOrder]            INT             NULL,
    [ApproverUsersID_FK]   BIGINT          NULL,
    [approvalStatus]       NVARCHAR (50)   NULL,
    [approvalNotes]        NVARCHAR (4000) NULL,
    [requestedAt]          DATETIME        NULL,
    [decidedAt]            DATETIME        NULL,
    [ticketApprovalActive] BIT             NULL,
    CONSTRAINT [PK_TicketApproval] PRIMARY KEY CLUSTERED ([ticketApprovalID] ASC),
    CONSTRAINT [FK_TicketApproval_ApprovalStep] FOREIGN KEY ([approvalStepID_FK]) REFERENCES [Tickets].[ApprovalStep] ([approvalStepID]),
    CONSTRAINT [FK_TicketApproval_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_TicketApproval_Ticket] FOREIGN KEY ([TicketID_FK]) REFERENCES [Tickets].[Ticket] ([ticketID])
);

