CREATE TABLE [Tickets].[ServiceCategory] (
    [serviceCategoryID]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [IdaraID_FK]                 BIGINT          NULL,
    [serviceCategoryCode]        NVARCHAR (50)   NULL,
    [serviceCategoryName_A]      NVARCHAR (200)  NULL,
    [serviceCategoryName_E]      NVARCHAR (200)  NULL,
    [serviceCategoryDescription] NVARCHAR (1000) NULL,
    [serviceCategorySortOrder]   INT             NULL,
    [serviceCategoryActive]      BIT             NULL,
    CONSTRAINT [PK_ServiceCategory] PRIMARY KEY CLUSTERED ([serviceCategoryID] ASC),
    CONSTRAINT [FK_ServiceCategory_Idara] FOREIGN KEY ([IdaraID_FK]) REFERENCES [dbo].[Idara] ([idaraID])
);

