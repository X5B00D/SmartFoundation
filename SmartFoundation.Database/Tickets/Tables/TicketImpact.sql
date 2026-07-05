CREATE TABLE [Tickets].[TicketImpact] (
    [ticketImpactID]          INT             IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]              BIGINT          NULL,
    [ticketImpactCode]        NVARCHAR (50)   NULL,
    [ticketImpactName_A]      NVARCHAR (200)  NULL,
    [ticketImpactName_E]      NVARCHAR (200)  NULL,
    [ticketImpactScore]       INT             NULL,
    [ticketImpactDescription] NVARCHAR (1000) NULL,
    [ticketImpactActive]      BIT             NULL,
    CONSTRAINT [PK_TicketImpact] PRIMARY KEY CLUSTERED ([ticketImpactID] ASC),
    CONSTRAINT [FK_TicketImpact_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

