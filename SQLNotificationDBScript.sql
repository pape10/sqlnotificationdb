USE [master]
GO
/****** Object:  Database [SQLNotificationRequestDB]    Script Date: 03/24/2007 20:36:36 ******/
CREATE DATABASE [SQLNotificationRequestDB]

GO
ALTER DATABASE [SQLNotificationRequestDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET  ENABLE_BROKER 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET  READ_WRITE 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET RECOVERY FULL 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET  MULTI_USER 
GO
ALTER DATABASE [SQLNotificationRequestDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [SQLNotificationRequestDB] SET DB_CHAINING OFF 


USE [SQLNotificationRequestDB] ;

GO

CREATE QUEUE ChangeMessages ;

CREATE SERVICE ChangeNotifications

ON QUEUE ChangeMessages

([http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification]) ;

CREATE ROUTE

ChangeRoute

WITH SERVICE_NAME = 'ChangeNotifications',

ADDRESS = 'LOCAL' ;

GO


USE [SQLNotificationRequestDB]
GO
/****** Object:  Table [dbo].[NotificationTable]    Script Date: 03/24/2007 20:37:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SQLNotificationRequestTable](
	[Name] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Number] [int] NOT NULL,
 CONSTRAINT [PK_SQLNotificationRequestTable] PRIMARY KEY CLUSTERED 
(
	[Number] ASC
)WITH (PAD_INDEX  = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]


set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go




CREATE TRIGGER [dbo].[Triggers]
   ON  [dbo].[SQLNotificationRequestTable]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

--Strategy: look at the Inserted and Deleted tables available in the trigger to determine which rows were inserted, updated, or deleted
--Once we know that, build a string that contains information we want client app to know about. I go as far as to store all the data of the inserted/deleted tables
--into the string by looping through each row of the temporary table I make

DECLARE @Message xml
set @Message = N''

declare @tempTable Table
(
rowNumber int IDENTITY(0,1) NOT NULL,
Number int,
Name nvarchar(50)
)

declare @iterator int
set @iterator = 0
declare @count int
declare @string nvarchar(1024)
set @string = 'Values '

	-- If a delete occurred
	if Exists(Select Number from Deleted) and not Exists(Select Number from Inserted)
	Begin    
		insert into @tempTable (Name, Number) select Name, Number from Deleted		
		set @count = (select count(Name) from @tempTable)
		while @iterator < @count
		Begin
			if @count > 1
			begin			
				if(@iterator != @count-1)
				begin
					set @string = @string + Cast((select Number from @tempTable where rowNumber = @iterator) as nvarchar) + ', '
					set @string = @string + Cast((select Name from @tempTable where rowNumber = @iterator) as nvarchar) + ', 
'
				end
				else
				begin
					set @string = @string + Cast((select Number from @tempTable where rowNumber = @iterator) as nvarchar) + ', '
					set @string = @string + Cast((select Name from @tempTable where rowNumber = @iterator) as nvarchar) + ' were deleted.'				
				end
			end
			else
			begin
				set @string = @string + Cast((select Number from @tempTable where rowNumber = @iterator) as nvarchar) + ', '
				set @string = @string + Cast((select Name from @tempTable where rowNumber = @iterator) as nvarchar) + ' was deleted.'			
			end			
			set @iterator = @iterator + 1
		end		

		set @Message = @string 
	End
	-- If an Insert occurred
	if Exists(Select Number from Inserted) and not Exists(Select Number from Deleted)
	Begin		
		insert into @tempTable (Name, Number) select Name, Number from Inserted
		set @count = (select count(Name) from @tempTable)
		while @iterator < @count
		Begin
			if @count > 1
			begin			
				if(@iterator != @count-1)
				begin
					set @string = @string + Cast((select Number from @tempTable where rowNumber = @iterator) as nvarchar) + ', '
					set @string = @string + Cast((select Name from @tempTable where rowNumber = @iterator) as nvarchar) + ', 
'
				end
				else
				begin
					set @string = @string + Cast((select Number from @tempTable where rowNumber = @iterator) as nvarchar) + ', '
					set @string = @string + Cast((select Name from @tempTable where rowNumber = @iterator) as nvarchar) + ' were Inserted.'				
				end
			end
			else
			begin
				set @string = @string + Cast((select Number from @tempTable where rowNumber = @iterator) as nvarchar) + ', '
				set @string = @string + Cast((select Name from @tempTable where rowNumber = @iterator) as nvarchar) + ' was inserted.'			
			end			
			set @iterator = @iterator + 1
		end		

		set @Message = @string 
	end
    if Exists(Select Number from Deleted) and Exists(Select Number from Inserted)
	--Update Occurred
	begin	
		insert into @tempTable (Name, Number) select Name, Number from Inserted		
		set @count = (select count(Name) from @tempTable)
		while @iterator < @count
		Begin
			if @count > 1
			begin			
				if(@iterator != @count-1)
				begin
					set @string = @string + Cast((select Number from @tempTable where rowNumber = @iterator) as nvarchar) + ', '
					set @string = @string + Cast((select Name from @tempTable where rowNumber = @iterator) as nvarchar) + ', 
'
				end
				else
				begin
					set @string = @string + Cast((select Number from @tempTable where rowNumber = @iterator) as nvarchar) + ', '
					set @string = @string + Cast((select Name from @tempTable where rowNumber = @iterator) as nvarchar) + ' were Updated.'				
				end
			end
			else
			begin
				set @string = @string + Cast((select Number from @tempTable where rowNumber = @iterator) as nvarchar) + ', '
				set @string = @string + Cast((select Name from @tempTable where rowNumber = @iterator) as nvarchar) + ' was Updated.'			
			end			
			set @iterator = @iterator + 1
		end		

		set @Message = @string 
	end

--By using the PostQueryNotification Contract and QueryNotification Message Type, These messages will be caught by the SQLNotificationRequest

DECLARE @NotificationDialog uniqueidentifier
SET QUOTED_IDENTIFIER ON
BEGIN DIALOG CONVERSATION @NotificationDialog
  FROM SERVICE ChangeNotifications
  TO SERVICE 'ChangeNotifications'
  ON CONTRACT [http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification]
  WITH ENCRYPTION = OFF;
SEND ON CONVERSATION @NotificationDialog 
  MESSAGE TYPE [http://schemas.microsoft.com/SQL/Notifications/QueryNotification] (@Message)

END