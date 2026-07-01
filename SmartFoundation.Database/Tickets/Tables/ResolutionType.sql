CREATE TABLE [Tickets].[ResolutionType] (
    [resolutionTypeID]          INT             IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                BIGINT          NULL,
    [resolutionTypeCode]        NVARCHAR (50)   NULL,
    [resolutionTypeName_A]      NVARCHAR (200)  NULL,
    [resolutionTypeName_E]      NVARCHAR (200)  NULL,
    [resolutionTypeDescription] NVARCHAR (1000) NULL,
    [resolutionTypeActive]      BIT             NULL,
    CONSTRAINT [PK_ResolutionType] PRIMARY KEY CLUSTERED ([resolutionTypeID] ASC),
    CONSTRAINT [FK_ResolutionType_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

