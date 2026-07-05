CREATE TABLE [Tickets].[ServiceCatalogSuggestion] (
    [serviceCatalogSuggestionID]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                     BIGINT          NULL,
    [TicketID_FK]                    BIGINT          NULL,
    [requesterTypeID_FK]             INT             NULL,
    [proposedServiceName]            NVARCHAR (200)  NULL,
    [proposedCategoryName]           NVARCHAR (200)  NULL,
    [proposedTargetDSDID_FK]         BIGINT          NULL,
    [reviewedByUsersID_FK]           BIGINT          NULL,
    [reviewDecision]                 NVARCHAR (50)   NULL,
    [reviewNotes]                    NVARCHAR (4000) NULL,
    [reviewedAt]                     DATETIME        NULL,
    [serviceCatalogSuggestionActive] BIT             NULL,
    CONSTRAINT [PK_ServiceCatalogSuggestion] PRIMARY KEY CLUSTERED ([serviceCatalogSuggestionID] ASC),
    CONSTRAINT [FK_ServiceCatalogSuggestion_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID]),
    CONSTRAINT [FK_ServiceCatalogSuggestion_RequesterType] FOREIGN KEY ([requesterTypeID_FK]) REFERENCES [Tickets].[RequesterType] ([requesterTypeID]),
    CONSTRAINT [FK_ServiceCatalogSuggestion_Ticket] FOREIGN KEY ([TicketID_FK]) REFERENCES [Tickets].[Ticket] ([ticketID])
);

