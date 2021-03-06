USE [BookCheckInCheckOut]
GO
/****** Object:  StoredProcedure [dbo].[usp_CheckInBook]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_CheckInBook]
@BookID int,
@UTCDatetime datetime,
@oRetVal int output
as
Begin
	Declare @ID int, @FetchBookId int = 0;
	
	select top 1 @FetchBookId = BookID,@ID = CurrentBorrowerID from dbo.BookDetails (nolock) 
	where BookID = @BookID and ModifiedOn = @UTCDatetime and CurrentBorrowerID is not null

	if @FetchBookId != 0
	Begin 
		Update BorrowerDetails set ReturnDate = getDate() where ID = @ID
		Update BookDetails set CheckOutStatusID = 1, CurrentBorrowerID = NULL, ModifiedOn=GETUTCDATE() where BookID = @BookID
		set @oRetVal = 101
	end
	else
	begin
		set @oRetVal = 404
	end
End


GO
/****** Object:  StoredProcedure [dbo].[usp_CheckOutBook]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_CheckOutBook] --2,'Hassaan','03007045803','42101-0179557-7','2018-07-29 23:36:09.000','2018-07-29 18:42:48.400', '2018-08-15 23:36:09.000'
@BookID int,
@Name nvarchar(250),
@MobileNo nvarchar(11),
@NationalID nvarchar(11),
@CheckOutDate datetime,
@UTCDatetime datetime,
@ReturnDate datetime,
@oRetVal  int output
as
Begin

	Declare @ID int, @FetchBookId int = 0;
	
	select @FetchBookId = BookID from dbo.BookDetails (nolock)
	where BookID = @BookID and ModifiedOn = @UTCDatetime and CurrentBorrowerID is null

	if @FetchBookId != 0
	Begin 

		Insert into BorrowerDetails (Name, Mobile, NationalID, CheckOutDate, ReturnDate, BookID) 
		values (@Name, @MobileNo, @NationalID, @CheckOutDate, @ReturnDate, @BookID)
		
		select @ID = Scope_identity()

		Update BookDetails 
		set CheckOutStatusID = 2,
		CurrentBorrowerID = @ID,
		ModifiedOn = GETUTCDATE()
		where BookID = @BookID
		
		set @oRetVal = 101
	end
	else
	begin
		set @oRetVal = 404
	end
End



GO
/****** Object:  StoredProcedure [dbo].[usp_getBookBorrowingHistory]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_getBookBorrowingHistory]
@BookID int
as
begin
	select Name, CheckOutDate, ReturnDate from BorrowerDetails (nolock) where BookID = @BookID
	order by CheckOutDate desc
end
GO
/****** Object:  StoredProcedure [dbo].[usp_getBorrowerDetails]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_getBorrowerDetails]
@BookID int
as
begin
	select BD.Name, BD.Mobile, BD.ReturnDate, B.ModifiedOn from BorrowerDetails BD (nolock) inner join BookDetails B (nolock) 
	on B.CurrentBorrowerID = BD.ID 
	where B.BookID = @BookID
end
GO
/****** Object:  StoredProcedure [dbo].[usp_LogException]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_LogException]
@pMethodName nvarchar(250),
@pParamVal nvarchar(max),
@pMessage nvarchar(500),
@pRawException nvarchar(max)
as
begin
	insert into dbo.Exceptions([Message],[RawException],[MethodName],[ParamValues],[CreatedOn]) values (@pMessage, @pRawException,@pMethodName,@pParamVal,GETUTCDATE())
end

GO
/****** Object:  StoredProcedure [dbo].[usp_RetrieveBookDetails]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_RetrieveBookDetails] 
@BookID int
as

select top 1
B.BookID,
B.Title,
B.ISBN,
B.PublishYear,
B.CoverPrice,
B.Image,
B.ModifiedOn,
D.CheckOutStatusDescription

from BookDetails B (nolock) inner join CheckOutStatusDescription D (nolock)
on 
B.CheckOutStatusID = D.CheckOutStatusID

where B.BookID = @BookID
GO
/****** Object:  StoredProcedure [dbo].[usp_RetrieveBooksList]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_RetrieveBooksList]
as

select 
B.BookID,
B.Title,
B.ISBN,
B.PublishYear,
B.CoverPrice,
B.ModifiedOn,
D.CheckOutStatusDescription

from BookDetails B (nolock) inner join CheckOutStatusDescription D (nolock)
on 
B.CheckOutStatusID = D.CheckOutStatusID
GO
/****** Object:  Table [dbo].[BookDetails]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BookDetails](
	[BookID] [int] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](500) NOT NULL,
	[ISBN] [nvarchar](25) NOT NULL,
	[PublishYear] [char](4) NOT NULL,
	[CoverPrice] [decimal](12, 6) NOT NULL,
	[CheckOutStatusID] [int] NOT NULL,
	[Image] [image] NULL,
	[CurrentBorrowerID] [int] NULL,
	[ModifiedOn] [datetime] NULL,
 CONSTRAINT [PK_BookDetails] PRIMARY KEY CLUSTERED 
(
	[BookID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BorrowerDetails]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BorrowerDetails](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Mobile] [nvarchar](11) NOT NULL,
	[NationalID] [nvarchar](11) NOT NULL,
	[CheckOutDate] [datetime] NOT NULL,
	[ReturnDate] [datetime] NOT NULL,
	[BookID] [int] NOT NULL,
 CONSTRAINT [PK_BorrowerDetails] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CheckOutStatusDescription]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CheckOutStatusDescription](
	[CheckOutStatusID] [int] IDENTITY(1,1) NOT NULL,
	[CheckOutStatusDescription] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_CheckOutStatusDescription] PRIMARY KEY CLUSTERED 
(
	[CheckOutStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Exceptions]    Script Date: 8/3/2018 3:03:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Exceptions](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Message] [nvarchar](500) NULL,
	[RawException] [nvarchar](max) NULL,
	[MethodName] [nvarchar](250) NULL,
	[ParamValues] [nvarchar](max) NULL,
	[CreatedOn] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET IDENTITY_INSERT [dbo].[BookDetails] ON 

GO
INSERT [dbo].[BookDetails] ([BookID], [Title], [ISBN], [PublishYear], [CoverPrice], [CheckOutStatusID], [Image], [CurrentBorrowerID], [ModifiedOn]) VALUES (1, N'The kite runner', N'0-684-84328-5', N'2016', CAST(250.500000 AS Decimal(12, 6)), 1, NULL, NULL, CAST(0x0000A931003563E9 AS DateTime))
GO
INSERT [dbo].[BookDetails] ([BookID], [Title], [ISBN], [PublishYear], [CoverPrice], [CheckOutStatusID], [Image], [CurrentBorrowerID], [ModifiedOn]) VALUES (2, N'Twilight', N'0-684-84328-1', N'2016', CAST(300.500000 AS Decimal(12, 6)), 1, NULL, NULL, CAST(0x0000A93100A3744B AS DateTime))
GO
SET IDENTITY_INSERT [dbo].[BookDetails] OFF
GO
SET IDENTITY_INSERT [dbo].[CheckOutStatusDescription] ON 

GO
INSERT [dbo].[CheckOutStatusDescription] ([CheckOutStatusID], [CheckOutStatusDescription]) VALUES (1, N'Check in')
GO
INSERT [dbo].[CheckOutStatusDescription] ([CheckOutStatusID], [CheckOutStatusDescription]) VALUES (2, N'Check out')
GO
SET IDENTITY_INSERT [dbo].[CheckOutStatusDescription] OFF
GO
ALTER TABLE [dbo].[BookDetails]  WITH CHECK ADD  CONSTRAINT [FK_BookDetails_CheckOutStatusDescription] FOREIGN KEY([CheckOutStatusID])
REFERENCES [dbo].[CheckOutStatusDescription] ([CheckOutStatusID])
GO
ALTER TABLE [dbo].[BookDetails] CHECK CONSTRAINT [FK_BookDetails_CheckOutStatusDescription]
GO
USE [master]
GO
ALTER DATABASE [BookCheckInCheckOut] SET  READ_WRITE 
GO
