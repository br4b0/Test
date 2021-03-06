USE [master]
GO
/****** Object:  Database [GHT_Blincoe_01]    Script Date: 26/08/2018 16:33:58 ******/
CREATE DATABASE [GHT_Blincoe_01]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'GHT_Blincoe_01', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\GHT_Blincoe_01.mdf' , SIZE = 2860032KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'GHT_Blincoe_01_log', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\GHT_Blincoe_01_log.ldf' , SIZE = 15993536KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [GHT_Blincoe_01] SET COMPATIBILITY_LEVEL = 120
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [GHT_Blincoe_01].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [GHT_Blincoe_01] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET ARITHABORT OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [GHT_Blincoe_01] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [GHT_Blincoe_01] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET  DISABLE_BROKER 
GO
ALTER DATABASE [GHT_Blincoe_01] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [GHT_Blincoe_01] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [GHT_Blincoe_01] SET  MULTI_USER 
GO
ALTER DATABASE [GHT_Blincoe_01] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [GHT_Blincoe_01] SET DB_CHAINING OFF 
GO
ALTER DATABASE [GHT_Blincoe_01] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [GHT_Blincoe_01] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [GHT_Blincoe_01] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'GHT_Blincoe_01', N'ON'
GO
USE [GHT_Blincoe_01]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_get_mention]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_get_mention] (@String NVARCHAR(max) )
RETURNS NVARCHAR(255)
AS
BEGIN
	
   /*Declaring Local Variables*/
   DECLARE @FirstIndexOfChar INT,
         @LastIndexOfChar INT,
         @LengthOfStringBetweenChars INT,
		 @startChar NVARCHAR(1) ='@',
		 @endChar NVARCHAR(1)=' '

	
   SET @FirstIndexOfChar   = CHARINDEX(@startChar,@String,0) 
   SET @LastIndexOfChar   = CHARINDEX(@endChar,@String,@FirstIndexOfChar+1)
   SET @LengthOfStringBetweenChars = @LastIndexOfChar - @FirstIndexOfChar -1
   IF(@LastIndexOfChar <> 0)
   begin
   SET @String = SUBSTRING(@String,@FirstIndexOfChar+1,@LengthOfStringBetweenChars)
   END
   ELSE 
   BEGIN
	SET @String = null
   end
   RETURN @String

END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_proj_magnet]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_proj_magnet]
(
    @project_id INT,
    @period DATE,
    @period_in_months INT
)
RETURNS NUMERIC(11, 10)
AS
BEGIN

	DECLARE @total_contributors AS NUMERIC (10,0)
	DECLARE @new_contributors AS NUMERIC (10,0)
	DECLARE @A TABLE (author_id INT )
	DECLARE @B TABLE (author_id INT )

	INSERT INTO @A
	SELECT DISTINCT
		   com.author_id
	FROM dbo.project_commits pro_com
		INNER JOIN dbo.commits com
			ON com.id = pro_com.commit_id
	WHERE com.created_at
	BETWEEN DATEADD(MONTH, - (2 * @period_in_months), @period) AND DATEADD(MONTH, - (@period_in_months), @period)
	AND pro_com.project_id = @project_id

	INSERT INTO @B
	SELECT DISTINCT
		   com.author_id
	FROM dbo.project_commits pro_com
		INNER JOIN dbo.commits com
			ON com.id = pro_com.commit_id
	WHERE com.created_at
	BETWEEN DATEADD(MONTH, - (@period_in_months), @period) AND @period
	AND pro_com.project_id = @project_id
	
	SELECT @total_contributors = COUNT(*)
	FROM @A A
		FULL OUTER JOIN @B B
			ON A.author_id = B.author_id
	

	SELECT @new_contributors = COUNT(*)
	FROM @A A
		RIGHT JOIN @B B
			ON A.author_id = B.author_id
	WHERE A.author_id IS NULL;


	IF (@total_contributors <10)
		RETURN	-1
	RETURN @new_contributors / @total_contributors
END;




GO
/****** Object:  UserDefinedFunction [dbo].[fn_proj_popularity2]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_proj_popularity2]
(
    @project_id INT
)
RETURNS int
AS
BEGIN
	DECLARE @watchers AS INT = (SELECT COUNT(*) FROM  dbo.watchers WHERE repo_id = @project_id)
	DECLARE @forks AS INT =(SELECT COUNT(*) FROM dbo.projects WHERE forked_from = @project_id)
	DECLARE @pulls AS INT = (SELECT COUNT(*) FROM dbo.pull_requests WHERE base_repo_id = @project_id)
	DECLARE @pop AS INT = ISNULL(@watchers,0) + ISNULL(@forks,0) + ISNULL((@pulls * @pulls),0);
	RETURN @pop
END;

GO
/****** Object:  UserDefinedFunction [dbo].[fn_proj_sticky]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_proj_sticky]
(
    @project_id INT,
    @period DATE,
    @period_in_months INT
)
RETURNS NUMERIC(11, 10)
AS
BEGIN

	DECLARE @total_contributors AS NUMERIC (10,0)
	DECLARE @old_contributors AS NUMERIC (10,0)
	DECLARE @A TABLE (author_id INT )
	DECLARE @B TABLE (author_id INT )

	INSERT INTO @A
	SELECT DISTINCT
		   com.author_id
	FROM dbo.project_commits pro_com
		INNER JOIN dbo.commits com
			ON com.id = pro_com.commit_id
	WHERE com.created_at
	BETWEEN DATEADD(MONTH, - (2 * @period_in_months), @period) AND DATEADD(MONTH, - (@period_in_months), @period)
	AND pro_com.project_id = @project_id

	INSERT INTO @B
	SELECT DISTINCT
		   com.author_id
	FROM dbo.project_commits pro_com
		INNER JOIN dbo.commits com
			ON com.id = pro_com.commit_id
	WHERE com.created_at
	BETWEEN DATEADD(MONTH, - (@period_in_months), @period) AND @period
	AND pro_com.project_id = @project_id
	
	SELECT @total_contributors = COUNT(*)
	FROM @A A
	

	SELECT @old_contributors = COUNT(*)
	FROM @A A
		inner JOIN @B B
			ON A.author_id = B.author_id


	IF (@total_contributors <10)
		RETURN	-1
	RETURN @old_contributors / @total_contributors
END;

GO
/****** Object:  UserDefinedFunction [dbo].[fn_temporal_contribution_level]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_temporal_contribution_level]
(
    @developer_id INT,
    @project_id INT,
    @limit_date DATE
)
RETURNS NUMERIC(38, 20)
AS
BEGIN
    DECLARE @t0 AS DATE;
    DECLARE @tc AS DATE;
    DECLARE @c AS INT = 1; --Constante
    DECLARE @h AS INT = 1;
    DECLARE @m AS INT = 0;
    DECLARE @CL AS NUMERIC(38, 20);
    SET @CL = 0;
    SET @t0 =
    (
        SELECT MAX(CAST(c.created_at AS DATE))
        FROM dbo.project_commits pc
            INNER JOIN dbo.commits c
                ON pc.commit_id = c.id
            INNER JOIN dbo.projects p
                ON p.id = pc.project_id
        WHERE p.id = @project_id
		AND c.author_id = @developer_id
		AND c.created_at < @limit_date
    );

	DECLARE @months TABLE(
	id_temp INT IDENTITY (1,1),
	dt_commit DATE)

   
    INSERT INTO @months
    SELECT DISTINCT
           EOMONTH(c.created_at)
    FROM dbo.project_commits pc
        INNER JOIN dbo.commits c
            ON pc.commit_id = c.id
        INNER JOIN dbo.projects p
            ON p.id = pc.project_id
    WHERE p.id = @project_id
          AND c.author_id = @developer_id;
	
	DELETE FROM @months WHERE EOMONTH(dt_commit ) = EOMONTH(@limit_date)

    SET @m =
    (
        SELECT COUNT(*) + 1 FROM @months
    );


    WHILE @h < @m
    BEGIN

        SELECT @tc = dt_commit
        FROM @months
        WHERE id_temp = @h;
        --SELECT @cl[cl antes],  (DATEDIFF(MONTH, @tc, @t0)+1)[conta]
        SET @CL = @CL + ((CAST(1 AS FLOAT) / CAST((DATEDIFF(MONTH, @tc, @t0) + 1) AS FLOAT)) * @c);
        --SELECT @tc [data commit], @h [h], @CL [CL depois], DATEDIFF(MONTH, @t0, @tc) [diff de semana]
        SET @h = @h + 1;

    END;
    RETURN @CL
END;







GO
/****** Object:  Table [dbo].[a_base_project]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[a_base_project](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[base_project_id] [int] NOT NULL,
	[filter_2] [bit] NULL,
	[filter_3] [bit] NULL,
	[filter_4] [bit] NULL,
	[filter_5] [bit] NULL,
	[all_filters] [bit] NULL,
 CONSTRAINT [PK_a_base_project] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[a_base_temporal_project]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[a_base_temporal_project](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[project_id] [int] NULL,
	[days] [nchar](10) NULL,
	[distinct_contributors] [int] NULL,
	[commits] [int] NULL,
	[heuristic_pull_requests] [int] NULL,
	[pull_requests] [int] NULL,
	[initial_date] [date] NULL,
	[final_date] [date] NULL,
	[magnet] [numeric](11, 10) NULL,
	[sticky] [numeric](11, 10) NULL,
	[popularity_2] [int] NULL,
	[window_size] [int] NULL,
	[opened_pull_requests] [int] NULL,
	[watchers] [int] NULL,
	[forks] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[a_role]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[a_role](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[dc_role] [varchar](30) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[a_temporal_developer_relationship]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[a_temporal_developer_relationship](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[developer_id_1] [int] NOT NULL,
	[developer_id_2] [int] NOT NULL,
	[total_proj_dev1] [int] NULL,
	[total_proj_dev2] [int] NULL,
	[common_proj] [int] NULL,
	[relationship] [numeric](38, 20) NULL,
	[limit_date] [date] NULL,
 CONSTRAINT [PK_a_temporal_developer_relationship] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[a_temporal_developer_roles]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[a_temporal_developer_roles](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[developer_id] [int] NULL,
	[project_id] [int] NULL,
	[role] [tinyint] NULL,
	[limit_date] [date] NULL,
	[popularity_on_project] [int] NULL,
	[contribution_level] [numeric](38, 20) NULL,
	[total_commits] [int] NULL,
	[mutant_commits] [int] NULL,
 CONSTRAINT [PK_a_temporal_developer_roles_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[a_temporal_developers]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[a_temporal_developers](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[developer_id] [int] NULL,
	[dev] [numeric](20, 5) NULL,
	[initial_date] [date] NULL,
	[final_date] [date] NULL,
	[popularity] [int] NULL,
	[mentions] [int] NULL,
	[followers] [int] NULL,
 CONSTRAINT [PK_a_temporal_developers] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[a_temporal_discussion_contributors]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[a_temporal_discussion_contributors](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NULL,
	[project_id] [int] NULL,
	[limit_date] [date] NULL,
 CONSTRAINT [PK_a_temporal_discussion_contributors_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[a_temporal_project_contributors]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[a_temporal_project_contributors](
	[id] [int] NOT NULL,
	[base_project_id] [int] NOT NULL,
	[developer_id] [int] NOT NULL,
	[contribution_level] [numeric](38, 20) NULL,
	[limit_date] [date] NULL,
 CONSTRAINT [PK_a_temporal_project_contributors] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[a_temporal_projects]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[a_temporal_projects](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[project_id] [int] NULL,
	[days] [nchar](10) NULL,
	[distinct_contributors] [int] NULL,
	[commits] [int] NULL,
	[heuristic_pull_requests] [int] NULL,
	[pull_requests] [int] NULL,
	[initial_date] [date] NULL,
	[final_date] [date] NULL,
	[magnet] [numeric](11, 10) NULL,
	[sticky] [numeric](11, 10) NULL,
	[popularity_2] [int] NULL,
	[window_size] [int] NULL,
	[opened_pull_requests] [int] NULL,
	[watchers] [int] NULL,
	[forks] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[a_time_window]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[a_time_window](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[initial_date] [date] NULL,
	[final_date] [date] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[commit_comments]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[commit_comments](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[commit_id] [int] NOT NULL,
	[user_id] [int] NOT NULL,
	[body] [nvarchar](256) NULL,
	[line] [int] NULL,
	[position] [int] NULL,
	[comment_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_commit_comments_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[commit_parents]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[commit_parents](
	[commit_id] [int] NOT NULL,
	[parent_id] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[commits]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[commits](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[sha] [nvarchar](50) NULL,
	[author_id] [int] NULL,
	[committer_id] [int] NULL,
	[project_id] [int] NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_commits_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[developer_roles]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[developer_roles](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[developer_id] [int] NULL,
	[project_id] [int] NULL,
	[role] [tinyint] NULL,
	[popularity_on_project] [int] NULL,
 CONSTRAINT [PK_developer_roles_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[discussion_contributors]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[discussion_contributors](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NULL,
	[project_id] [int] NULL,
 CONSTRAINT [PK_discussion_contributors_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[followers]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[followers](
	[user_id] [int] NOT NULL,
	[follower_id] [int] NOT NULL,
	[created_at] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_followers_follower_id_user_id] PRIMARY KEY CLUSTERED 
(
	[follower_id] ASC,
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[issue_comments]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[issue_comments](
	[issue_id] [int] NOT NULL,
	[user_id] [int] NOT NULL,
	[comment_id] [int] NULL,
	[created_at] [datetime2](0) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[issue_events]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[issue_events](
	[event_id] [int] NULL,
	[issue_id] [int] NOT NULL,
	[actor_id] [int] NOT NULL,
	[action] [nvarchar](255) NOT NULL,
	[action_specific] [nvarchar](50) NULL,
	[created_at] [datetime2](0) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[issue_labels]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[issue_labels](
	[label_id] [int] NOT NULL,
	[issue_id] [int] NOT NULL,
 CONSTRAINT [PK_issue_labels_issue_id_label_id] PRIMARY KEY CLUSTERED 
(
	[issue_id] ASC,
	[label_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[issues]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[issues](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[repo_id] [int] NULL,
	[reporter_id] [int] NULL,
	[assignee_id] [int] NULL,
	[pull_request] [int] NOT NULL,
	[pull_request_id] [int] NULL,
	[created_at] [datetime2](0) NOT NULL,
	[issue_id] [int] NOT NULL,
 CONSTRAINT [PK_issues_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[log]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[log](
	[ErrorCode] [nvarchar](50) NULL,
	[ErrorColumn] [nvarchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[organization_members]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[organization_members](
	[org_id] [int] NOT NULL,
	[user_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[project_commits]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[project_commits](
	[project_id] [int] NOT NULL,
	[commit_id] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[project_languages]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[project_languages](
	[project_id] [int] NOT NULL,
	[language] [nvarchar](255) NULL,
	[bytes] [int] NULL,
	[created_at] [datetime2](0) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[project_members]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[project_members](
	[repo_id] [int] NOT NULL,
	[user_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[ext_ref_id] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_project_members_repo_id_user_id] PRIMARY KEY CLUSTERED 
(
	[repo_id] ASC,
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[projects]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[projects](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[url] [nvarchar](255) NULL,
	[owner_id] [int] NULL,
	[name] [nvarchar](255) NOT NULL,
	[description] [nvarchar](255) NULL,
	[language] [nvarchar](255) NULL,
	[created_at] [datetime2](0) NOT NULL,
	[forked_from] [int] NULL,
	[deleted] [smallint] NOT NULL,
	[updated_at] [datetime2](0) NOT NULL,
	[commits_count] [int] NULL,
	[fork_commits] [int] NULL,
	[commiters_count] [int] NULL,
	[Pop_2] [int] NULL,
 CONSTRAINT [PK_projects_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pull_request_comments]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pull_request_comments](
	[pull_request_id] [int] NOT NULL,
	[user_id] [int] NOT NULL,
	[comment_id] [int] NOT NULL,
	[position] [int] NULL,
	[body] [nvarchar](256) NULL,
	[commit_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pull_request_commits]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pull_request_commits](
	[pull_request_id] [int] NOT NULL,
	[commit_id] [int] NOT NULL,
 CONSTRAINT [pull_request_commits_pull_commit] PRIMARY KEY CLUSTERED 
(
	[pull_request_id] ASC,
	[commit_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pull_request_history]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pull_request_history](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pull_request_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[action] [nvarchar](255) NOT NULL,
	[actor_id] [int] NULL,
 CONSTRAINT [PK_pull_request_history_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pull_requests]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pull_requests](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[head_repo_id] [int] NULL,
	[base_repo_id] [int] NOT NULL,
	[head_commit_id] [int] NULL,
	[base_commit_id] [int] NOT NULL,
	[pullreq_id] [int] NOT NULL,
	[intra_branch] [smallint] NOT NULL,
 CONSTRAINT [PK_pull_requests_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[repo_labels]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[repo_labels](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[repo_id] [int] NULL,
	[name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_repo_labels_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[repo_milestones]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[repo_milestones](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[repo_id] [int] NULL,
	[name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_repo_milestones_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[users]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[users](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[login] [nvarchar](255) NOT NULL,
	[company] [nvarchar](255) NULL,
	[created_at] [datetime2](7) NOT NULL,
	[type] [nvarchar](255) NOT NULL,
	[fake] [smallint] NOT NULL,
	[deleted] [smallint] NOT NULL,
	[long] [nvarchar](50) NULL,
	[lat] [nvarchar](50) NULL,
	[country_code] [nvarchar](50) NULL,
	[state] [nvarchar](255) NULL,
	[city] [nvarchar](255) NULL,
	[location] [nvarchar](255) NULL,
	[mentions] [int] NULL,
	[followers] [int] NULL,
	[popularity] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[watchers]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[watchers](
	[repo_id] [int] NOT NULL,
	[user_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_watchers_repo_id_user_id] PRIMARY KEY CLUSTERED 
(
	[repo_id] ASC,
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [IX_a_base_temporal_project_project_id]    Script Date: 26/08/2018 16:33:58 ******/
CREATE NONCLUSTERED INDEX [IX_a_base_temporal_project_project_id] ON [dbo].[a_base_temporal_project]
(
	[project_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [comment_id]    Script Date: 26/08/2018 16:33:58 ******/
CREATE UNIQUE NONCLUSTERED INDEX [comment_id] ON [dbo].[commit_comments]
(
	[comment_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [sha]    Script Date: 26/08/2018 16:33:58 ******/
CREATE UNIQUE NONCLUSTERED INDEX [sha] ON [dbo].[commits]
(
	[sha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [commit_id]    Script Date: 26/08/2018 16:33:58 ******/
CREATE NONCLUSTERED INDEX [commit_id] ON [dbo].[project_commits]
(
	[commit_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [project_id]    Script Date: 26/08/2018 16:33:58 ******/
CREATE NONCLUSTERED INDEX [project_id] ON [dbo].[project_languages]
(
	[project_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [name]    Script Date: 26/08/2018 16:33:58 ******/
CREATE NONCLUSTERED INDEX [name] ON [dbo].[projects]
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [pullreq_id]    Script Date: 26/08/2018 16:33:58 ******/
CREATE UNIQUE NONCLUSTERED INDEX [pullreq_id] ON [dbo].[pull_requests]
(
	[pullreq_id] ASC,
	[base_repo_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [login]    Script Date: 26/08/2018 16:33:58 ******/
CREATE UNIQUE NONCLUSTERED INDEX [login] ON [dbo].[users]
(
	[login] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[commit_comments] ADD  CONSTRAINT [DF__commit_com__body__787EE5A0]  DEFAULT (NULL) FOR [body]
GO
ALTER TABLE [dbo].[commit_comments] ADD  CONSTRAINT [DF__commit_com__line__797309D9]  DEFAULT (NULL) FOR [line]
GO
ALTER TABLE [dbo].[commit_comments] ADD  CONSTRAINT [DF__commit_co__posit__7A672E12]  DEFAULT (NULL) FOR [position]
GO
ALTER TABLE [dbo].[commit_comments] ADD  CONSTRAINT [DF__commit_co__creat__7B5B524B]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[commits] ADD  CONSTRAINT [DF_commits_sha]  DEFAULT (NULL) FOR [sha]
GO
ALTER TABLE [dbo].[commits] ADD  CONSTRAINT [DF_commits_author_id]  DEFAULT (NULL) FOR [author_id]
GO
ALTER TABLE [dbo].[commits] ADD  CONSTRAINT [DF_commits_committer_id]  DEFAULT (NULL) FOR [committer_id]
GO
ALTER TABLE [dbo].[commits] ADD  CONSTRAINT [DF_commits_project_id]  DEFAULT (NULL) FOR [project_id]
GO
ALTER TABLE [dbo].[commits] ADD  CONSTRAINT [DF_commits_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[issue_comments] ADD  CONSTRAINT [DF_issue_comments_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[issue_events] ADD  CONSTRAINT [DF_issue_events_action_specific]  DEFAULT (NULL) FOR [action_specific]
GO
ALTER TABLE [dbo].[issue_events] ADD  CONSTRAINT [DF_issue_events_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[issues] ADD  CONSTRAINT [DF_issues_repo_id]  DEFAULT (NULL) FOR [repo_id]
GO
ALTER TABLE [dbo].[issues] ADD  CONSTRAINT [DF_issues_reporter_id]  DEFAULT (NULL) FOR [reporter_id]
GO
ALTER TABLE [dbo].[issues] ADD  CONSTRAINT [DF_issues_assignee_id]  DEFAULT (NULL) FOR [assignee_id]
GO
ALTER TABLE [dbo].[issues] ADD  CONSTRAINT [DF_issues_pull_request_id]  DEFAULT (NULL) FOR [pull_request_id]
GO
ALTER TABLE [dbo].[issues] ADD  CONSTRAINT [DF_issues_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[organization_members] ADD  CONSTRAINT [DF_organization_members_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[project_commits] ADD  CONSTRAINT [DF_project_commits_project_id]  DEFAULT ('0') FOR [project_id]
GO
ALTER TABLE [dbo].[project_commits] ADD  CONSTRAINT [DF_project_commits_commit_id]  DEFAULT ('0') FOR [commit_id]
GO
ALTER TABLE [dbo].[project_languages] ADD  CONSTRAINT [DF_project_languages_language]  DEFAULT (NULL) FOR [language]
GO
ALTER TABLE [dbo].[project_languages] ADD  CONSTRAINT [DF_project_languages_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[project_members] ADD  CONSTRAINT [DF_project_members_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[project_members] ADD  CONSTRAINT [DF_project_members_ext_ref_id]  DEFAULT ('0') FOR [ext_ref_id]
GO
ALTER TABLE [dbo].[projects] ADD  CONSTRAINT [DF_projects_url]  DEFAULT (NULL) FOR [url]
GO
ALTER TABLE [dbo].[projects] ADD  CONSTRAINT [DF_projects_owner_id]  DEFAULT (NULL) FOR [owner_id]
GO
ALTER TABLE [dbo].[projects] ADD  CONSTRAINT [DF_projects_description]  DEFAULT (NULL) FOR [description]
GO
ALTER TABLE [dbo].[projects] ADD  CONSTRAINT [DF_projects_language]  DEFAULT (NULL) FOR [language]
GO
ALTER TABLE [dbo].[projects] ADD  CONSTRAINT [DF_projects_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[projects] ADD  CONSTRAINT [DF_projects_forked_from]  DEFAULT (NULL) FOR [forked_from]
GO
ALTER TABLE [dbo].[projects] ADD  CONSTRAINT [DF_projects_deleted]  DEFAULT ('0') FOR [deleted]
GO
ALTER TABLE [dbo].[projects] ADD  CONSTRAINT [DF_projects_updated_at]  DEFAULT ('1970-01-01 00:00:01') FOR [updated_at]
GO
ALTER TABLE [dbo].[pull_request_comments] ADD  CONSTRAINT [DF_pull_request_comments_position]  DEFAULT (NULL) FOR [position]
GO
ALTER TABLE [dbo].[pull_request_comments] ADD  CONSTRAINT [DF_pull_request_comments_body]  DEFAULT (NULL) FOR [body]
GO
ALTER TABLE [dbo].[pull_request_comments] ADD  CONSTRAINT [DF_pull_request_comments_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[pull_request_history] ADD  CONSTRAINT [DF_pull_request_history_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[pull_request_history] ADD  CONSTRAINT [DF_pull_request_history_actor_id]  DEFAULT (NULL) FOR [actor_id]
GO
ALTER TABLE [dbo].[pull_requests] ADD  CONSTRAINT [DF_pull_requests_head_repo_id]  DEFAULT (NULL) FOR [head_repo_id]
GO
ALTER TABLE [dbo].[pull_requests] ADD  CONSTRAINT [DF_pull_requests_head_commit_id]  DEFAULT (NULL) FOR [head_commit_id]
GO
ALTER TABLE [dbo].[repo_labels] ADD  CONSTRAINT [DF_repo_labels_repo_id]  DEFAULT (NULL) FOR [repo_id]
GO
ALTER TABLE [dbo].[repo_milestones] ADD  CONSTRAINT [DF_repo_milestones_repo_id]  DEFAULT (NULL) FOR [repo_id]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_company]  DEFAULT (NULL) FOR [company]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_type]  DEFAULT ('USR') FOR [type]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_fake]  DEFAULT ('0') FOR [fake]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_deleted]  DEFAULT ('0') FOR [deleted]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_location]  DEFAULT (NULL) FOR [location]
GO
ALTER TABLE [dbo].[watchers] ADD  CONSTRAINT [DF_watchers_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
/****** Object:  StoredProcedure [dbo].[set_temporal_base_projects]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Set temporal projects statistics taking forked repositories into account
*/
CREATE PROCEDURE [dbo].[set_temporal_base_projects]
    @initial_date DATE,
    @final_date DATE,
    @window_in_months INT
AS
SET NOCOUNT ON;
DECLARE @message_helper AS VARCHAR(500);
DECLARE @total_periods INT = (
                                 SELECT (DATEDIFF(MONTH, @initial_date, @final_date) + 1) / @window_in_months
                             );
DECLARE @window_date DATE = @initial_date;
DECLARE @window_final_date DATE;
DECLARE @i INT = 0;
DECLARE @start AS DATETIME = GETDATE();
DECLARE @window_start AS DATETIME = GETDATE();
/*For each window between observed dates*/
WHILE @i < (@total_periods + 1)
BEGIN
    SET @window_start = GETDATE();
    SET @window_final_date = DATEADD(MONTH, @window_in_months, @window_date);
	/*Insert basic data for each base project*/
    INSERT INTO dbo.a_base_temporal_project
    (
        project_id,
        initial_date,
        final_date,
        window_size
    )
    SELECT base_project_id,
           @window_date,
           @window_final_date,
           @window_in_months
    FROM dbo.a_base_project;

	/*Update basic statistics for each project:
	commits -> Total commits
    distinct_contributors -> Distinct users that had commits merged to the master branch
    days -> Distinct days of commit activity
    heuristic_pull_requests -> All commits from forks that where incorporated to master branch and do not have a registered pull request
    pull_requests -> Commits that have a pull request registered
	*/
    WITH pulls
    AS (SELECT pvt.project_id,
               pvt.GitHub,
               pvt.Heuristic
        FROM
        (
            SELECT DISTINCT
                   CASE
                       WHEN prh.pull_request_id IS NULL THEN
                           'Heuristic'
                       ELSE
                           'GitHub'
                   END [accepted],
                   prc.pull_request_id,
                   CASE p.forked_from
                       WHEN 0 THEN
                           p.id
                       ELSE
                           p.forked_from
                   END [project_id],
                   1 [ahui]
            FROM dbo.project_commits pc
                INNER JOIN dbo.commits c
                    ON c.id = pc.commit_id
                INNER JOIN dbo.projects p
                    ON p.id = pc.project_id
					AND c.project_id = p.id
                LEFT JOIN dbo.pull_request_commits prc
                    ON prc.commit_id = pc.commit_id
                LEFT JOIN dbo.pull_request_history prh
                    ON prh.pull_request_id = prc.pull_request_id
                       AND prh.action IN ( 'merged', 'synchronize' )
            WHERE 1 = 1
                  AND c.created_at
                  BETWEEN @window_date AND @window_final_date
                  AND EXISTS
            (
                SELECT *
                FROM dbo.a_base_temporal_project abtp
                WHERE p.id = abtp.project_id
                      OR p.forked_from = abtp.project_id
            )
        ) AS SourceTable
        PIVOT
        (
            COUNT(pull_request_id)
            FOR accepted IN ([Heuristic], [GitHub])
        ) AS pvt)
    UPDATE tp
    SET tp.commits = interna.commits,
        tp.distinct_contributors = interna.[distinct contributors],
        tp.days = interna.days,
        tp.heuristic_pull_requests = interna.Heuristic,
        tp.pull_requests = interna.GitHub
    FROM dbo.a_base_temporal_project tp
        INNER JOIN
        (
            SELECT CASE p.forked_from
                       WHEN 0 THEN
                           p.id
                       ELSE
                           p.forked_from
                   END [project_id],
                   COUNT(DISTINCT c.id) [commits],
                   COUNT(DISTINCT c.author_id) [distinct contributors],
                   COUNT(DISTINCT CAST(c.created_at AS DATE)) [days],
                   @window_date [initial],
                   @window_final_date [final],
                   pull.Heuristic,
                   pull.GitHub
            FROM dbo.project_commits pc
                INNER JOIN dbo.commits c
                    ON pc.commit_id = c.id
                INNER JOIN dbo.projects p
                    ON p.id = pc.project_id
                INNER JOIN pulls pull
                    ON pull.project_id = p.id
            WHERE c.created_at
                  BETWEEN @window_date AND @window_final_date
                  AND EXISTS
            (
                SELECT *
                FROM dbo.a_base_temporal_project abtp
                WHERE p.id = abtp.project_id
                      OR p.forked_from = abtp.project_id
            )
            GROUP BY CASE p.forked_from
                         WHEN 0 THEN
                             p.id
                         ELSE
                             p.forked_from
                     END,
                     pull.Heuristic,
                     pull.GitHub
        ) interna
            ON interna.project_id = tp.project_id
               AND interna.initial = tp.initial_date
               AND interna.final = tp.final_date;
    

	/*Project independent metrics*/	
	EXEC dbo.spu_temporal_base_proj_pop_2 @initial_date,
                                 @final_date,
                                 @window_in_months;

	
	SET @message_helper
    = CONCAT(
                CONVERT(VARCHAR(30), GETDATE(), 120),
                ' - Temporal base projects from window ',
                @window_date,
                ' in ',
                CONVERT(VARCHAR(30), DATEDIFF(MINUTE, GETDATE(), @window_start)),
                ' minutes.'
            );
	RAISERROR(@message_helper, 0, 0) WITH NOWAIT;
	

    SET @window_date = @window_final_date;
    SET @i = @i + 1;
END;
SET @message_helper
    = CONCAT(
                CONVERT(VARCHAR(30), GETDATE(), 120),
                ' - Temporal base projects created in  ',
                CONVERT(VARCHAR(30), DATEDIFF(MINUTE, GETDATE(), @start)),
                ' minutes.'
            );
RAISERROR(@message_helper, 0, 0) WITH NOWAIT;

SET NOCOUNT OFF;



GO
/****** Object:  StoredProcedure [dbo].[sp_project_filters]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_project_filters]
    @initial_date DATE,
    @final_date DATE,
    @window_in_months INT
AS
/*Variables for testing*/

--DECLARE @initial_date DATE = '2016-07-01';
--DECLARE @final_date DATE = '2016-10-30';
--DECLARE @window_in_months INT = 3;
SET NOCOUNT ON
DECLARE @message_helper AS VARCHAR(500)
DECLARE @total_periods INT = (
                                 SELECT (DATEDIFF(MONTH, @initial_date, @final_date) + 1) / @window_in_months
                             );
DECLARE @window_date DATE = @initial_date;
DECLARE @window_final_date DATE;
DECLARE @i INT = 0;

/*For each window between observed dates*/
WHILE @i < (@total_periods + 1)
BEGIN
    SET @window_final_date = DATEADD(MONTH, @window_in_months, @window_date);

    INSERT INTO dbo.a_temporal_projects
    (
        project_id,
        initial_date,
        final_date,
        window_size
    )
    SELECT base_project_id,
           @window_date,
           @window_final_date,
           @window_in_months
	 FROM dbo.a_base_project;

    WITH pulls
    AS (SELECT pvt.project_id,
               pvt.GitHub,
               pvt.Heuristic
        FROM
        (
            SELECT DISTINCT
                   CASE
                       WHEN prh.pull_request_id IS NULL THEN
                           'Heuristic'
                       ELSE
                           'GitHub'
                   END [accepted],
                   prc.pull_request_id,
                   pc.project_id,
                   1 [ahui]
            FROM dbo.project_commits pc
                INNER JOIN dbo.commits c
                    ON c.id = pc.commit_id
                INNER JOIN dbo.projects p
                    ON p.id = pc.project_id
                LEFT JOIN dbo.pull_request_commits prc
                    ON prc.commit_id = pc.commit_id
                LEFT JOIN dbo.pull_request_history prh
                    ON prh.pull_request_id = prc.pull_request_id
                       AND prh.action IN ( 'merged', 'synchronize' )
            WHERE 1 = 1
                  AND c.created_at
                  BETWEEN @window_date AND @window_final_date
        ) AS SourceTable
        PIVOT
        (
            COUNT(pull_request_id)
            FOR accepted IN ([Heuristic], [GitHub])
        ) AS pvt)
    UPDATE tp
    SET tp.commits = interna.commits,
        tp.distinct_contributors = interna.[distinct contributors],
        tp.days = interna.days,
        tp.heuristic_pull_requests = interna.Heuristic,
        tp.pull_requests = interna.GitHub
    FROM dbo.a_temporal_projects tp
        INNER JOIN
        (
            SELECT pc.project_id,
                   COUNT(DISTINCT c.id) [commits],
                   COUNT(DISTINCT c.author_id) [distinct contributors],
                   COUNT(DISTINCT CAST(c.created_at AS DATE)) [days],
                   @window_date [initial],
                   @window_final_date [final],
                   pull.Heuristic,
                   pull.GitHub
            FROM dbo.project_commits pc
                LEFT JOIN dbo.commits c
                    ON pc.commit_id = c.id
                LEFT JOIN dbo.projects p
                    ON p.id = pc.project_id
                LEFT JOIN pulls pull
                    ON pull.project_id = p.id
            WHERE c.created_at
                  BETWEEN @window_date AND @window_final_date
                  AND EXISTS (SELECT * FROM dbo.a_base_project bp WHERE bp.base_project_id =p.id)
            GROUP BY pc.project_id,
                     pull.Heuristic,
                     pull.GitHub
        ) interna
            ON interna.project_id = tp.project_id
               AND interna.initial = tp.initial_date
               AND interna.final = tp.final_date;

    EXEC dbo.sp_set_DEV @window_date, @window_final_date;

	/*Loop iteration done*/ 
	SET @message_helper =CONCAT('Temporal developers and projects from window ',@window_date, ' created in ',CONVERT(VARCHAR(30),GETDATE(),120))
	RAISERROR(@message_helper, 0, 0) WITH NOWAIT

    SET @window_date = @window_final_date;
    SET @i = @i + 1;
END;





GO
/****** Object:  StoredProcedure [dbo].[sp_set_all_contribution_level]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_set_all_contribution_level]
    @usr AS int ,
    @project AS int,
	  @window_size_month AS int
AS
    BEGIN
/*Testing variables*/
--DECLARE @usr AS INT = 537487;
--DECLARE @project AS INT = 683351;
--DECLARE @window_size_month AS INT =3
/*End Test*/

DECLARE @CL NUMERIC(38, 20) = 0;
DECLARE @lastCommitDate AS DATE; /*@t0*/
DECLARE @tempoCommit AS DATE; /*@tc*/
DECLARE @commitQuality AS INT = 1; /*Change if willing to measure commit quality @c*/
DECLARE @months AS INT = 1; /*@h*/
DECLARE @totalCommit AS INT = 0;/*@m*/
SET @lastCommitDate =
(
    SELECT MAX(CAST(c.created_at AS DATE))
    FROM dbo.project_commits pc
        INNER JOIN dbo.commits c
            ON pc.commit_id = c.id
        INNER JOIN dbo.projects p
            ON p.id = pc.project_id
    WHERE p.id = @project
          AND c.author_id = @usr
);


CREATE TABLE #commits
(
    id_temp INT IDENTITY(1, 1),
    dt_commit DATE
);
INSERT INTO #commits
SELECT EOMONTH(c.created_at)
FROM dbo.project_commits pc
    INNER JOIN dbo.commits c
        ON pc.commit_id = c.id
    INNER JOIN dbo.projects p
        ON p.id = pc.project_id
WHERE p.id = @project
      AND c.author_id = @usr
ORDER BY  1 ASC



/*For each month of user activity*/
CREATE TABLE #contribution_level (cl NUMERIC(38,20), tempoCommit date, t0 date)
SET @totalCommit =(SELECT COUNT(*)+1 FROM #commits);

/*Set contribution level for each state where a commit is registered*/
WHILE @months < @totalCommit
BEGIN
    SELECT @tempoCommit = dt_commit
    FROM #commits
    WHERE id_temp = @months;
    SET @CL = @CL + ((CAST(1 AS FLOAT) / CAST((DATEDIFF(MONTH, @tempoCommit, @lastCommitDate) + 1) AS FLOAT)) * @commitQuality);
    SET @months = @months + 1;    	   
	INSERT INTO #contribution_level
	SELECT @CL , @tempoCommit, @lastCommitDate
END;


/*Create time windows perspective for temporal developers with roles on project*/
WITH time_windows
AS (SELECT atdr.developer_id,
           atdr.project_id,
           DATEADD(MONTH, -@window_size_month, atdr.limit_date) [initial_date],
           atdr.limit_date
    FROM dbo.a_temporal_developer_roles atdr
    WHERE atdr.project_id = @project
          AND atdr.developer_id = @usr)
SELECT tw.developer_id,
       tw.project_id,
       tw.limit_date,
       MAX(c.cl)
	   OVER (PARTITION BY tw.developer_id,
         tw.project_id,
         tw.limit_date)
		  contribution_level,
       COUNT(*) 
		OVER (PARTITION BY tw.developer_id,
         tw.project_id,
         tw.limit_date)
		  total_commits
INTO #updateHelper
FROM time_windows tw
    INNER JOIN #contribution_level c
        ON c.tempoCommit
           BETWEEN tw.initial_date AND tw.limit_date;

/*Update @CL activity for each time window*/
UPDATE atdr
SET atdr.contribution_level= ahui.contribution_level,
	atdr.total_commits = ahui.total_commits
FROM dbo.a_temporal_developer_roles atdr
	INNER JOIN #updateHelper ahui ON 1=1
		AND atdr.developer_id = ahui.developer_id
		AND atdr.limit_date = ahui.limit_date
		AND atdr.project_id = ahui.project_id
WHERE 1=1
	AND atdr.developer_id = @usr
	AND atdr.project_id = @project
	


/*Set flag for inactivity*/
UPDATE atdr
SET atdr.contribution_level = 0,
atdr.total_commits = 0
 FROM dbo.a_temporal_developer_roles atdr
WHERE 1=1
AND atdr.project_id = @project
AND atdr.developer_id = @usr
AND (atdr.contribution_level IS NULL OR atdr.total_commits IS null)
AND atdr.limit_date 
BETWEEN (SELECT MIN(limit_date) FROM #updateHelper)
AND 
(SELECT MAX(limit_date) FROM #updateHelper)

/*Set flag for retirement*/
UPDATE atdr
SET atdr.contribution_level = -1,
atdr.total_commits = -1
 FROM dbo.a_temporal_developer_roles atdr
WHERE 1=1
AND atdr.project_id = @project
AND atdr.developer_id = @usr
AND (atdr.contribution_level IS NULL OR atdr.total_commits IS null)
AND atdr.limit_date > (SELECT MAX(limit_date) FROM #updateHelper)

/*Set flag for newcomer*/
UPDATE atdr
SET atdr.contribution_level = -2,
atdr.total_commits = -2
 FROM dbo.a_temporal_developer_roles atdr
WHERE 1=1
AND atdr.project_id = @project
AND atdr.developer_id = @usr
AND (atdr.contribution_level IS NULL OR atdr.total_commits IS null)
AND atdr.limit_date < (SELECT min(limit_date) FROM #updateHelper);

/*Set mutant commit count*/
WITH mutant_commits
AS (SELECT COUNT(*) mutant_commit,
           atdr.limit_date
    FROM dbo.commits c
        INNER JOIN dbo.a_temporal_developer_roles atdr
            ON 1 = 1
               AND c.created_at
               BETWEEN DATEADD(MONTH, -@window_size_month, atdr.limit_date) AND atdr.limit_date
               AND c.author_id = @usr
               AND c.author_id = atdr.developer_id
               AND c.project_id IN (
                                       SELECT p.id FROM dbo.projects p WHERE forked_from = @project
                                   )
    GROUP BY atdr.limit_date)
UPDATE atdr
SET atdr.mutant_commits = mc.mutant_commit
FROM dbo.a_temporal_developer_roles atdr
    INNER JOIN mutant_commits mc
        ON mc.limit_date = atdr.limit_date
           AND atdr.developer_id = @usr
           AND atdr.project_id = @project;
	

DROP TABLE #updateHelper	
DROP TABLE #contribution_level
DROP TABLE #commits;
    END

GO
/****** Object:  StoredProcedure [dbo].[sp_set_base_project_filters]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_set_base_project_filters]
AS
WITH project_filters AS (
SELECT DISTINCT p.id,
CASE WHEN p.commits_count > 265 THEN 1 ELSE 0 END [Filter_2],
CASE WHEN abtp.id IS NULL THEN 0 ELSE 1 END [Filter_3],
CASE WHEN abtp4.id IS NULL THEN 0 ELSE 1 END [Filter_4],
CASE WHEN abtp5.id IS NULL THEN 0 ELSE 1 END [Filter_5],
CASE WHEN abtp6.id IS NULL THEN 0 ELSE 1 END [Filter_6]
FROM dbo.projects p
    INNER JOIN dbo.a_base_project base
        ON p.id = base.base_project_id
	LEFT JOIN dbo.a_base_temporal_project abtp ON 1=1
		AND abtp.project_id = p.id AND abtp.initial_date > '2016-12-31' AND abtp.commits > 0
	LEFT JOIN dbo.a_base_temporal_project abtp4 ON 1=1
		AND abtp4.distinct_contributors >= 10
	LEFT JOIN dbo.a_base_temporal_project abtp5 ON 1=1
		AND abtp5.project_id = p.id AND 1=1
		AND (abtp5.pull_requests > 0)
	LEFT JOIN dbo.a_base_temporal_project abtp6 ON 1=1
		AND abtp6.project_id = p.id AND 1=1
		AND (abtp6.pull_requests > 0 OR abtp6.heuristic_pull_requests > 0))
UPDATE abp
SET abp.filter_2 = pf.Filter_2,
    abp.filter_3 = pf.Filter_3,
    abp.filter_4 = pf.Filter_4,
    abp.filter_5 = pf.Filter_5
FROM project_filters pf
    INNER JOIN dbo.a_base_project abp
        ON abp.base_project_id = pf.id
		
UPDATE dbo.a_base_project
SET all_filters = 1
WHERE filter_2 = 1
      AND filter_3 = 1
      AND filter_4 = 1
      AND filter_5 = 1;


GO
/****** Object:  StoredProcedure [dbo].[sp_set_contribution_level]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_set_contribution_level]
    @usr AS VARCHAR(100) ,
    @project AS VARCHAR(100) ,
    @CL NUMERIC(38, 20) OUTPUT
AS
    BEGIN
/*Testing variables*/
--DECLARE @usr AS INT = 31089
--DECLARE @project AS INT =4784541
--DECLARE  @CL AS NUMERIC(38, 20)

        DECLARE @t0 AS DATE;
        DECLARE @tc AS DATE;
        DECLARE @c AS INT = 1; --Constante
        DECLARE @h AS INT = 1;
        DECLARE @m AS INT = 0;
        SET @CL = 0
		SET @t0 =
		(
			SELECT MAX(CAST(c.created_at AS DATE))
			FROM dbo.project_commits pc
				INNER JOIN dbo.commits c
					ON pc.commit_id = c.id
				INNER JOIN dbo.projects p
					ON p.id = pc.project_id
			WHERE p.id = @project
		)

       		
        CREATE TABLE #months
            (
              id_temp INT IDENTITY(1, 1) ,
              dt_commit DATE
            );			
        INSERT  INTO #months
		SELECT DISTINCT EOMONTH(c.created_at) FROM 	dbo.project_commits pc
			INNER JOIN dbo.commits c
				ON pc.commit_id = c.id
			INNER JOIN dbo.projects p
				ON p.id = pc.project_id
		WHERE p.id = @project
		AND c.author_id = @usr	                       
		
		SET @m = (SELECT COUNT(*)+1 FROM #months)


        WHILE @h < @m
            BEGIN
 
                SELECT  @tc = dt_commit
                FROM    #months
                WHERE   id_temp = @h;
                --SELECT @cl[cl antes],  (DATEDIFF(MONTH, @tc, @t0)+1)[conta]
                SET @CL = @CL  +  (
                ( cast (1 AS FLOAT)/CAST((DATEDIFF(MONTH, @tc, @t0)+1) AS FLOAT) ) * @c
                );
				--SELECT @tc [data commit], @h [h], @CL [CL depois], DATEDIFF(MONTH, @t0, @tc) [diff de semana]
                SET @h = @h + 1;
				
            END;
        DROP TABLE #months;
   
    END
GO
/****** Object:  StoredProcedure [dbo].[sp_set_DEV]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_set_DEV]
    @initialDate AS DATE,
    @finalDate AS DATE
AS
BEGIN;
    WITH commits
    AS (SELECT author_id,
               LOG10(COUNT(*)) [log_commits]
        FROM dbo.commits
        WHERE created_at
        BETWEEN @initialDate AND @finalDate
        GROUP BY author_id),
         prs
    AS (SELECT *,
               (p.closed + p.reopened + p.opened) [total]
        FROM
        (
            SELECT action,
                   actor_id
            FROM dbo.pull_request_history
            WHERE 1 = 1
                  AND created_at
                  BETWEEN @initialDate AND @finalDate
                  AND action IN ( 'closed', 'reopened', 'opened' )
        ) AS pr_actions
        PIVOT
        (
            COUNT(action)
            FOR action IN ([closed], [reopened], [opened])
        ) p)
    INSERT INTO dbo.a_temporal_developers
    (
        developer_id,
        dev,
        initial_date,
        final_date
    )
    SELECT c.author_id,
           ISNULL(c.log_commits, 0) + ISNULL(pr.total, 0) [DEV],
           @initialDate [initial_date],
           @finalDate [final_date]
    FROM commits c
        LEFT JOIN prs pr
            ON pr.actor_id = c.author_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_set_developer_roles]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_set_developer_roles]
    @project_id AS INT
AS
SET NOCOUNT ON
/*Core Devs*/
SELECT DISTINCT author_id [usr] INTO #coreDevs FROM dbo.commits WHERE project_id =@project_id

/*External*/
SELECT DISTINCT c.author_id [usr] INTO #externalDevs
FROM dbo.project_commits pc
INNER JOIN  dbo.commits c ON pc.commit_id = c.id
WHERE pc.project_id = @project_id
AND pc.project_id <> c.project_id

/*Candidate*/
SELECT DISTINCT prh.actor_id [usr] INTO #candidateDevs
FROM dbo.pull_requests pr
INNER JOIN dbo.pull_request_history prh ON pr.id = prh.pull_request_id
WHERE base_repo_id = @project_id
AND prh.action = 'opened'

/*Mutant*/
SELECT DISTINCT c.author_id [usr] INTO #mutantDevs FROM dbo.projects p 
INNER JOIN dbo.commits c ON c.project_id = p.id
WHERE p.forked_from = @project_id

/*Only one role for each user*/
DELETE FROM #externalDevs  WHERE usr  IN (SELECT usr FROM #coreDevs)
DELETE FROM #candidateDevs  WHERE usr  IN (SELECT usr FROM #coreDevs)
DELETE FROM #candidateDevs  WHERE usr  IN (SELECT usr FROM #externalDevs)
DELETE FROM #mutantDevs  WHERE usr IN (SELECT usr FROM #coreDevs)
DELETE FROM #mutantDevs  WHERE usr IN (SELECT usr FROM #externalDevs)
DELETE FROM #mutantDevs  WHERE usr IN (SELECT usr FROM #candidateDevs)

/*Store*/
INSERT INTO dbo.developer_roles (developer_id,project_id,role)
SELECT usr,@project_id,1 FROM #coreDevs
INSERT INTO dbo.developer_roles (developer_id,project_id,role)
SELECT usr,@project_id,2 FROM #externalDevs
INSERT INTO dbo.developer_roles (developer_id,project_id,role)
SELECT usr,@project_id,3 FROM #candidateDevs
INSERT INTO dbo.developer_roles (developer_id,project_id,role)
SELECT usr,@project_id,4 FROM #mutantDevs

/*Drop temp tables*/
DROP TABLE #coreDevs
DROP TABLE #externalDevs
DROP TABLE #candidateDevs
DROP TABLE #mutantDevs
SET NOCOUNT OFF



GO
/****** Object:  StoredProcedure [dbo].[sp_set_discussion_contributors]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_set_discussion_contributors]
    @project_id AS INT, @limit_date AS DATE
AS
SET NOCOUNT ON

/*Get all related projects*/
SELECT DISTINCT p.id 
INTO #projects
FROM dbo.projects p
WHERE p.id = @project_id
      OR p.forked_from = @project_id;

/*Store discussion contributors from all comments stored*/
CREATE TABLE #discussion_contributors (usr INT)	  

INSERT INTO #discussion_contributors
SELECT DISTINCT cc.user_id
FROM dbo.commit_comments cc
WHERE EXISTS(SELECT * FROM #projects p INNER JOIN dbo.commits c ON c.project_id = p.id WHERE cc.commit_id = c.id)
      AND NOT EXISTS (SELECT * FROM dbo.a_temporal_developer_roles dr WHERE dr.developer_id = cc.user_id)
	  AND cc.created_at < @limit_date;

INSERT INTO #discussion_contributors
SELECT DISTINCT ic.user_id FROM dbo.issue_comments  ic
	INNER JOIN dbo.issues i ON ic.issue_id = i.id
	INNER JOIN #projects p ON i.repo_id = p.id
WHERE NOT EXISTS (SELECT * FROM dbo.a_temporal_developer_roles dr WHERE dr.developer_id = ic.user_id)
AND ic.created_at < @limit_date

INSERT INTO #discussion_contributors
SELECT DISTINCT prc.user_id FROM dbo.pull_request_comments prc
INNER JOIN dbo.pull_requests pr ON pr.id = prc.pull_request_id
WHERE EXISTS(SELECT * FROM #projects p INNER JOIN dbo.commits c ON pr.base_repo_id= p.id WHERE prc.commit_id = c.id)
      AND NOT EXISTS (SELECT * FROM dbo.a_temporal_developer_roles dr WHERE dr.developer_id = prc.user_id)
	  AND prc.created_at < @limit_date;

/*Insert distinct user contributors*/	  
INSERT INTO dbo.a_temporal_discussion_contributors
(
    user_id,
    project_id,
    limit_date
)
SELECT DISTINCT usr, @project_id,@limit_date FROM #discussion_contributors
DROP TABLE	 #discussion_contributors

SET NOCOUNT OFF

GO
/****** Object:  StoredProcedure [dbo].[sp_set_project_statistics]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_set_project_statistics] AS

/*Set commits_count*/
WITH total_project_commits
AS (SELECT COUNT(c.id) [total],
        p.id
    FROM dbo.projects p
        LEFT JOIN dbo.commits c
            ON p.id = c.project_id
    GROUP BY p.id)
UPDATE p
SET p.commits_count = c.total
FROM dbo.projects p
    INNER JOIN total_project_commits c
        ON c.id = p.id;


/*Set fork_commits*/
WITH total_fork_commits
AS (SELECT COUNT(*) [total],
           p.forked_from
    FROM dbo.commits c
        INNER JOIN dbo.projects p
            ON c.project_id = p.id
    GROUP BY p.forked_from)
UPDATE p
SET p.fork_commits = fc.total
FROM dbo.projects p
    INNER JOIN total_fork_commits fc
        ON p.id = fc.forked_from;
/*Set committers_count*/
WITH total_committers_count
AS
(SELECT COUNT(*) [total],
        project_id
 FROM dbo.developer_roles
 WHERE role IN ( 1, 2 )
 GROUP BY project_id)
UPDATE p
SET p.commiters_count = cc.total
FROM dbo.projects p
    INNER JOIN total_committers_count cc
        ON p.id = cc.project_id;


GO
/****** Object:  StoredProcedure [dbo].[sp_set_temporal_developer_relationship]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_set_temporal_developer_relationship]
AS
DECLARE @message_helper AS VARCHAR(500);
SET @message_helper = CONCAT('Setting developer relationships started at ', CONVERT(VARCHAR(30), GETDATE(), 120));
RAISERROR(@message_helper, 0, 0) WITH NOWAIT;
/*Get contributors for each project and date*/
SELECT DISTINCT
       developer_id,
       project_id,
       limit_date,
       DENSE_RANK() OVER (PARTITION BY developer_id, limit_date ORDER BY project_id ASC)
       + DENSE_RANK() OVER (PARTITION BY developer_id, limit_date ORDER BY project_id DESC) - 1 [total_projects]
INTO #contributors
FROM dbo.a_temporal_developer_roles
WHERE 1=1
AND contribution_level > -0.5 /*-2 = not a newcomer, -1 = retired*/
AND role IN (1,2) /*CL for mutant and candidates are always 0*/
ORDER BY limit_date DESC;


/*Set temporal pairs based on common projects*/
INSERT INTO dbo.a_temporal_developer_relationship
(
    developer_id_1,
    developer_id_2,
    total_proj_dev1,
    total_proj_dev2,
    limit_date
)
SELECT DISTINCT
       c1.developer_id [developer_id_1],
       c2.developer_id [developer_id_2],
       c1.total_projects [total_proj_dev1],
       c2.total_projects [total_proj_dev2],
       c1.limit_date
--INTO #a_temporal_developer_relationship
FROM #contributors c1
    INNER JOIN #contributors c2
        ON c1.project_id = c2.project_id
           AND c2.developer_id <> c1.developer_id
           AND c2.limit_date = c1.limit_date
           AND c2.developer_id < c1.developer_id
WHERE 1 = 1;
SET @message_helper = CONCAT('Pairs inserted ', CONVERT(VARCHAR(30), GETDATE(), 120));
RAISERROR(@message_helper, 0, 0) WITH NOWAIT;
/*Set Relationship*/
UPDATE atdrEXT
SET atdrEXT.common_proj = interna.common_projects,
    atdrEXT.relationship = (interna.CL_dev1 + interna.CL_dev2) / interna.total_projects
FROM
(
--SELECT  (interna.CL_dev1 + interna.CL_dev2) / interna.total_projects, interna.common_projects, atdrEXT.developer_id_1,atdrEXT.developer_id_2 FROM (
    SELECT DISTINCT
           atdrel.developer_id_1,
           atdrel.developer_id_2,
           atdr1.limit_date,
           SUM(atdr1.contribution_level) OVER (PARTITION BY atdr1.developer_id, atdr2.developer_id, atdr1.limit_date) [CL_dev1],
           SUM(atdr2.contribution_level) OVER (PARTITION BY atdr2.developer_id, atdr1.developer_id, atdr2.limit_date) [CL_dev2],
           COUNT(atdr1.project_id) OVER (PARTITION BY atdr1.limit_date,atdr1.developer_id,atdr2.developer_id) [common_projects],
           atdrel.total_proj_dev1 + atdrel.total_proj_dev2 [total_projects]
--FROM #a_temporal_developer_relationship atdrel
	FROM dbo.a_temporal_developer_relationship atdrel
        INNER JOIN dbo.a_temporal_developer_roles atdr1
            ON atdr1.limit_date = atdrel.limit_date
               AND atdr1.developer_id = atdrel.developer_id_1
               AND atdr1.contribution_level > -0.5
        INNER JOIN dbo.a_temporal_developer_roles atdr2
            ON atdr2.limit_date = atdrel.limit_date
               AND atdr2.developer_id = atdrel.developer_id_2
               AND atdr2.contribution_level > -0.5
    WHERE 1 = 1
          AND atdr1.project_id = atdr2.project_id
) interna
    INNER JOIN dbo.a_temporal_developer_relationship atdrEXT
        ON atdrEXT.developer_id_1 = interna.developer_id_1
           AND atdrEXT.developer_id_2 = interna.developer_id_2
           AND atdrEXT.limit_date = interna.limit_date
		   
SET @message_helper = CONCAT('Done yayyy ', CONVERT(VARCHAR(30), GETDATE(), 120));
RAISERROR(@message_helper, 0, 0) WITH NOWAIT;
DROP TABLE #contributors;
--DROP TABLE #a_temporal_developer_relationship


GO
/****** Object:  StoredProcedure [dbo].[sp_set_temporal_developer_roles]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_set_temporal_developer_roles]
    @project_id AS INT, @limit_date DATE
AS
SET NOCOUNT ON
/*Core Devs*/
SELECT DISTINCT author_id [usr] INTO #coreDevs FROM dbo.commits WHERE project_id =@project_id

/*External*/
SELECT DISTINCT c.author_id [usr] INTO #externalDevs
FROM dbo.project_commits pc
INNER JOIN  dbo.commits c ON pc.commit_id = c.id
WHERE pc.project_id = @project_id
AND pc.project_id <> c.project_id
AND c.created_at < @limit_date

/*Candidate*/
SELECT DISTINCT prh.actor_id [usr] INTO #candidateDevs
FROM dbo.pull_requests pr
INNER JOIN dbo.pull_request_history prh ON pr.id = prh.pull_request_id
WHERE base_repo_id = @project_id
AND prh.action = 'opened'
AND prh.created_at < @limit_date

/*Mutant*/
SELECT DISTINCT c.author_id [usr] INTO #mutantDevs FROM dbo.projects p 
INNER JOIN dbo.commits c ON c.project_id = p.id
WHERE p.forked_from = @project_id
AND c.created_at < @limit_date

/*Only one role for each user*/
DELETE FROM #externalDevs  WHERE usr  IN (SELECT usr FROM #coreDevs)
DELETE FROM #candidateDevs  WHERE usr  IN (SELECT usr FROM #coreDevs)
DELETE FROM #candidateDevs  WHERE usr  IN (SELECT usr FROM #externalDevs)
DELETE FROM #mutantDevs  WHERE usr IN (SELECT usr FROM #coreDevs)
DELETE FROM #mutantDevs  WHERE usr IN (SELECT usr FROM #externalDevs)
DELETE FROM #mutantDevs  WHERE usr IN (SELECT usr FROM #candidateDevs)

/*Store*/
INSERT INTO dbo.a_temporal_developer_roles (developer_id,project_id,role,limit_date)
SELECT usr,@project_id,1,@limit_date FROM #coreDevs
INSERT INTO dbo.a_temporal_developer_roles (developer_id,project_id,role,limit_date)
SELECT usr,@project_id,2,@limit_date FROM #externalDevs
INSERT INTO dbo.a_temporal_developer_roles (developer_id,project_id,role,limit_date)
SELECT usr,@project_id,3,@limit_date FROM #candidateDevs
INSERT INTO dbo.a_temporal_developer_roles (developer_id,project_id,role,limit_date)
SELECT usr,@project_id,4,@limit_date FROM #mutantDevs

/*Drop temp tables*/
DROP TABLE #coreDevs
DROP TABLE #externalDevs
DROP TABLE #candidateDevs
DROP TABLE #mutantDevs
SET NOCOUNT OFF




GO
/****** Object:  StoredProcedure [dbo].[sp_set_temporal_discussion_contributors]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_set_temporal_discussion_contributors]
    @project_id AS INT, @limit_date AS DATE
AS
SET NOCOUNT ON

/*Get all related projects*/
SELECT DISTINCT p.id 
INTO #projects
FROM dbo.projects p
WHERE p.id = @project_id
      OR p.forked_from = @project_id;

/*Store discussion contributors from all comments stored*/
CREATE TABLE #discussion_contributors (usr INT)	  

INSERT INTO #discussion_contributors
SELECT DISTINCT cc.user_id
FROM dbo.commit_comments cc
WHERE EXISTS(SELECT * FROM #projects p INNER JOIN dbo.commits c ON c.project_id = p.id WHERE cc.commit_id = c.id)
      AND NOT EXISTS (SELECT * FROM dbo.a_temporal_developer_roles dr WHERE dr.developer_id = cc.user_id)
	  AND cc.created_at < @limit_date;

INSERT INTO #discussion_contributors
SELECT DISTINCT ic.user_id FROM dbo.issue_comments  ic
	INNER JOIN dbo.issues i ON ic.issue_id = i.id
	INNER JOIN #projects p ON i.repo_id = p.id
WHERE NOT EXISTS (SELECT * FROM dbo.a_temporal_developer_roles dr WHERE dr.developer_id = ic.user_id)
AND ic.created_at < @limit_date

INSERT INTO #discussion_contributors
SELECT DISTINCT prc.user_id FROM dbo.pull_request_comments prc
INNER JOIN dbo.pull_requests pr ON pr.id = prc.pull_request_id
WHERE EXISTS(SELECT * FROM #projects p INNER JOIN dbo.commits c ON pr.base_repo_id= p.id WHERE prc.commit_id = c.id)
      AND NOT EXISTS (SELECT * FROM dbo.a_temporal_developer_roles dr WHERE dr.developer_id = prc.user_id)
	  AND prc.created_at < @limit_date;

/*Insert distinct user contributors*/	  
SELECT * FROM dbo.a_temporal_discussion_contributors
INSERT INTO dbo.a_temporal_discussion_contributors
(
    [user_id],
    [project_id],
    [limit_date]
)
SELECT DISTINCT usr, @project_id,@limit_date FROM #discussion_contributors
DROP TABLE	 #discussion_contributors

SET NOCOUNT OFF



GO
/****** Object:  StoredProcedure [dbo].[sp_set_temporal_user_popularity]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_set_temporal_user_popularity] @periodo_em_mes AS INT
AS

/*
Testing Variables
*/
--DECLARE @periodo_em_mes AS INT = 3

/*Store mentions*/
CREATE TABLE #mentions
(
    mentioned VARCHAR(MAX) COLLATE Latin1_General_CI_AS,
    mention_date DATE
);
INSERT INTO #mentions
SELECT dbo.fn_get_mention(body) [extracted],
       prc.created_at
FROM dbo.pull_request_comments prc
    INNER JOIN dbo.pull_requests pr
        ON prc.pull_request_id = pr.id
WHERE body LIKE '%@%';

INSERT INTO #mentions
SELECT dbo.fn_get_mention(body),
       cc.created_at
FROM dbo.commit_comments cc
    INNER JOIN dbo.commits c
        ON c.id = cc.commit_id
    INNER JOIN dbo.projects p
        ON c.project_id = p.id
WHERE body LIKE '%@%';

WITH total_mentions
AS (SELECT u.id,
           COUNT(*) total,
           mention_date
    FROM #mentions m
        INNER JOIN dbo.users u
            ON u.login = m.mentioned
    GROUP BY u.id,
             m.mention_date),
     total_followers
AS (SELECT f.user_id [id],
           COUNT(*) total,
           atd.final_date
    FROM dbo.followers f
        INNER JOIN dbo.a_temporal_developers atd
            ON f.user_id = atd.developer_id
               AND f.created_at
               BETWEEN DATEADD(MONTH, -@periodo_em_mes, atd.final_date) AND atd.final_date
    GROUP BY f.user_id,
             atd.final_date),
     popularity
AS (SELECT ISNULL(tf.total, 0) + ISNULL(tm.total, 0) [pop],
           atd.developer_id,
           atd.final_date
    FROM dbo.a_temporal_developers atd
        LEFT JOIN total_followers tf
            ON tf.id = atd.developer_id
               AND tf.final_date = atd.final_date
        LEFT JOIN total_mentions tm
            ON tm.id = atd.developer_id
               AND tm.mention_date
               BETWEEN DATEADD(MONTH, -@periodo_em_mes, atd.final_date) AND atd.final_date),
     update_helper
AS (SELECT atd.developer_id,
           atd.final_date,
           SUM(p.pop) [pop],
           SUM(tf.total) [total_follow],
           SUM(tm.total) [total_mention]
    FROM dbo.a_temporal_developers atd
        LEFT JOIN total_mentions tm
            ON 1 = 1
               AND tm.id = atd.developer_id
               AND tm.mention_date
               BETWEEN DATEADD(MONTH, -@periodo_em_mes, atd.final_date) AND atd.final_date
        LEFT JOIN total_followers tf
            ON 1 = 1
               AND tf.id = atd.developer_id
               AND tf.final_date = atd.final_date
        LEFT JOIN popularity p
            ON 1 = 1
               AND p.developer_id = atd.developer_id
               AND p.final_date = atd.final_date
    GROUP BY atd.developer_id,
             atd.final_date)
UPDATE atd
SET atd.popularity = ahui.pop,
    atd.mentions = ahui.total_mention,
    atd.followers = ahui.total_follow
FROM update_helper ahui
    INNER JOIN dbo.a_temporal_developers atd
        ON atd.developer_id = ahui.developer_id
           AND atd.final_date = ahui.final_date;

DROP TABLE #mentions;

GO
/****** Object:  StoredProcedure [dbo].[sp_set_temporal_user_popularity_on_project]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_set_temporal_user_popularity_on_project] 
@periodo_em_mes AS int
AS

/*
Testing Variables
*/
--DECLARE @periodo_em_mes AS INT = 3


/*Store mentions*/
CREATE TABLE #mentions
(
    mentioned VARCHAR(MAX) COLLATE Latin1_General_CI_AS, project_id INT, mention_date date
);
INSERT INTO #mentions
SELECT dbo.fn_get_mention(body) [extracted], pr.head_repo_id, prc.created_at
FROM dbo.pull_request_comments prc
INNER JOIN dbo.pull_requests pr ON prc.pull_request_id =pr.id
WHERE body LIKE '%@%'

INSERT INTO #mentions
SELECT dbo.fn_get_mention(body), CASE p.forked_from WHEN 0 THEN p.id ELSE p.forked_from END, cc.created_at
FROM dbo.commit_comments cc
inner JOIN dbo.commits c ON c.id = cc.commit_id
inner JOIN dbo.projects p ON c.project_id = p.id 
WHERE body LIKE '%@%';


WITH total_mentions
AS (SELECT u.id,
			CASE p.forked_from WHEN 0 THEN p.id ELSE p.forked_from END [project_id],
           COUNT(*) total,
		   mention_date
    FROM #mentions m
        INNER JOIN dbo.users u
            ON u.login = m.mentioned
		INNER JOIN dbo.projects p ON p.id = m.project_id
 GROUP BY CASE p.forked_from
          WHEN 0 THEN
          p.id
          ELSE
          p.forked_from
          END,
          u.id,
		  m.mention_date
),
total_followers
AS (SELECT f.user_id [id],
			dr.project_id,
           COUNT(*) total,
		   dr.limit_date
    FROM dbo.followers f
	INNER JOIN dbo.a_temporal_developer_roles dr ON f.user_id = dr.developer_id
	AND f.created_at BETWEEN DATEADD(MONTH, -@periodo_em_mes,dr.limit_date) AND dr.limit_date
    GROUP BY f.user_id,
             dr.project_id, dr.limit_date),
popularity AS (
SELECT ISNULL(tf.total,0)+ISNULL(tm.total,0) [pop], dr.developer_id,  tm.project_id  FROM  dbo.developer_roles dr 
LEFT JOIN total_followers tf ON tf.id = dr.developer_id
LEFT JOIN total_mentions tm ON tm.id = dr.developer_id
)
,update_helper AS (SELECT atdr.developer_id,
       atdr.project_id,
       atdr.limit_date,
       SUM(tm.total) [total]
FROM total_mentions tm
    INNER JOIN dbo.a_temporal_developer_roles atdr
        ON tm.project_id = atdr.project_id
           AND tm.id = atdr.developer_id
           AND tm.mention_date
           BETWEEN DATEADD(MONTH, -@periodo_em_mes, atdr.limit_date) AND atdr.limit_date
GROUP BY atdr.developer_id,
         atdr.project_id,
         atdr.limit_date)

UPDATE atdr SET atdr.popularity_on_project = ahui.total
 FROM update_helper ahui
INNER JOIN dbo.a_temporal_developer_roles atdr ON atdr.developer_id = ahui.developer_id
AND atdr.limit_date = ahui.limit_date
AND atdr.project_id = ahui.project_id

DROP TABLE #mentions;

GO
/****** Object:  StoredProcedure [dbo].[sp_set_user_popularity]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_set_user_popularity]
AS

/*Store mentions*/
CREATE TABLE #mentions
(
    mentioned VARCHAR(MAX) COLLATE Latin1_General_CI_AS
);
INSERT INTO #mentions
SELECT dbo.fn_get_mention(body) [extracted]
FROM dbo.pull_request_comments
WHERE body LIKE '%@%';
INSERT INTO #mentions
SELECT dbo.fn_get_mention(body)
FROM dbo.commit_comments
WHERE body LIKE '%@%';


WITH total_mentions
AS (SELECT u.id,
           COUNT(*) total
    FROM #mentions m
        INNER JOIN dbo.users u
            ON u.login = m.mentioned
    GROUP BY u.id)
UPDATE u
SET u.mentions = t.total
FROM dbo.users u
    INNER JOIN total_mentions t
        ON t.id = u.id;

WITH total_followers
AS (SELECT f.user_id [id],
           COUNT(*) total
    FROM dbo.followers f
    GROUP BY f.user_id)
UPDATE u
SET u.followers = t.total
FROM dbo.users u
    INNER JOIN total_followers t
        ON t.id = u.id;

UPDATE dbo.users
SET popularity = ISNULL(mentions, 0) + ISNULL(followers, 0);

DROP TABLE #mentions;

GO
/****** Object:  StoredProcedure [dbo].[sp_set_user_popularity_on_project]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_set_user_popularity_on_project]
AS

/*Store mentions*/
CREATE TABLE #mentions
(
    mentioned VARCHAR(MAX) COLLATE Latin1_General_CI_AS, project_id int
);
INSERT INTO #mentions
SELECT dbo.fn_get_mention(body) [extracted], pr.head_repo_id
FROM dbo.pull_request_comments prc
INNER JOIN dbo.pull_requests pr ON prc.pull_request_id =pr.id
WHERE body LIKE '%@%'

INSERT INTO #mentions
SELECT dbo.fn_get_mention(body), CASE p.forked_from WHEN 0 THEN p.id ELSE p.forked_from end
FROM dbo.commit_comments cc
inner JOIN dbo.commits c ON c.id = cc.commit_id
inner JOIN dbo.projects p ON c.project_id = p.id 
WHERE body LIKE '%@%';


WITH total_mentions
AS (SELECT u.id,
			CASE p.forked_from WHEN 0 THEN p.id ELSE p.forked_from END [project_id],
           COUNT(*) total
    FROM #mentions m
        INNER JOIN dbo.users u
            ON u.login = m.mentioned
		INNER JOIN dbo.projects p ON p.id = m.project_id
 GROUP BY CASE p.forked_from
          WHEN 0 THEN
          p.id
          ELSE
          p.forked_from
          END,
          u.id
),
total_followers
AS (SELECT f.user_id [id],
			dr.project_id,
           COUNT(*) total
    FROM dbo.followers f
	INNER JOIN dbo.developer_roles dr ON f.user_id = dr.developer_id
    GROUP BY f.user_id,
             dr.project_id),
popularity AS (
SELECT ISNULL(tf.total,0)+ISNULL(tm.total,0) [pop], dr.developer_id,  tm.project_id  FROM  dbo.developer_roles dr 
LEFT JOIN total_followers tf ON tf.id = dr.developer_id
LEFT JOIN total_mentions tm ON tm.id = dr.developer_id
)

UPDATE dr SET dr.popularity_on_project = p.pop FROM dbo.developer_roles dr
INNER JOIN popularity p ON p.project_id = dr.project_id AND p.developer_id = dr.developer_id


DROP TABLE #mentions;
GO
/****** Object:  StoredProcedure [dbo].[spu_set_metrics]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spu_set_metrics]
    @initial_date AS DATE, @final_date AS DATE, @window_in_months AS int
AS
/*parameters*/
--DECLARE @initial_date DATE = '2016-01-01';
--DECLARE @final_date DATE = '2017-10-01';
--DECLARE @window_in_months INT = 3;

/*variables and temp tables*/
DECLARE @total_periods INT = (SELECT (DATEDIFF(MONTH, @initial_date, @final_date) + 1) / @window_in_months);
DECLARE @window_date DATE = @initial_date;
DECLARE @message_helper AS VARCHAR(500)
DECLARE @window_final_date DATE
DECLARE @i INT = 0;
DECLARE @j INT = 1;
DECLARE @actual_project_id int

SET NOCOUNT ON
/*Projects to be observed*/
CREATE TABLE #projects (temp_id INT IDENTITY(1,1), project_id INT )
INSERT INTO #projects
SELECT base_project_id FROM dbo.a_base_project
DECLARE @total_projects INT = (SELECT COUNT(*)+1 FROM #projects)

/*Get initial data, populate temporal projects and temporal developers*/
--EXEC dbo.sp_project_filters @initial_date,@final_date,@window_in_months

WHILE @i < (@total_periods + 1) /*This loop will get things done for each stint*/
BEGIN
	
	/*Adjust window variables*/	
	SET @window_final_date = DATEADD(MONTH, @window_in_months, @window_date);	

	/*Project specific metrics*/
	WHILE @j < @total_projects 
	BEGIN		
		SET @message_helper =CONCAT('Project ',CAST(@j AS VARCHAR(10)),' of ' ,
		CAST(@total_projects AS VARCHAR(10)),' started at: ',CONVERT(VARCHAR(30),GETDATE(),120),' Iteration ',CAST(@i AS VARCHAR(10)),' of ',CAST(@total_periods AS VARCHAR(10)) )
		RAISERROR(@message_helper, 0, 0) WITH NOWAIT	

		/*Adjust project variables*/
		SET @actual_project_id = (SELECT project_id FROM #projects WHERE temp_id = @j)
		
		
		EXEC dbo.sp_set_temporal_developer_roles @project_id = @actual_project_id,
                                             @limit_date = @window_final_date;
		
		UPDATE dbo.a_temporal_projects SET sticky = dbo.fn_proj_sticky(@actual_project_id,@window_final_date,@window_in_months) WHERE project_id = @actual_project_id AND final_date = @window_final_date
		UPDATE dbo.a_temporal_projects SET magnet = dbo.fn_proj_magnet(@actual_project_id,@window_final_date,@window_in_months) WHERE project_id = @actual_project_id AND final_date = @window_final_date
		
		EXEC dbo.sp_set_temporal_discussion_contributors @project_id = @actual_project_id,
		                                                 @limit_date = @window_final_date
		

		SET @j = @j+1
	END
	
	/*Project independent metrics*/	
	EXEC dbo.spu_temporal_proj_pop_2 @initial_date,
                                 @final_date,
                                 @window_in_months;

	SET @message_helper =CONCAT('Temporal analysis on windown ',@window_date, ' completed in ',CONVERT(VARCHAR(30),GETDATE(),120))
	RAISERROR(@message_helper, 0, 0) WITH NOWAIT
    SET @window_date = DATEADD(MONTH, 3, @window_date);
    SET @i = @i + 1;
	SET @j = 1
	

END;


SET @j = 1
/*Non temporal metrics*/

EXEC dbo.sp_set_project_statistics
SET @message_helper =CONCAT('sp_set_project_statistics completed in ',convert(VARCHAR(30),GETDATE(),120))
RAISERROR(@message_helper, 0, 0) WITH NOWAIT

EXEC dbo.sp_set_user_popularity
SET @message_helper =CONCAT('sp_set_user_popularity completed in ',convert(VARCHAR(30),GETDATE(),120))
RAISERROR(@message_helper, 0, 0) WITH NOWAIT

EXEC dbo.sp_set_user_popularity_on_project
SET @message_helper =CONCAT('sp_set_user_popularity_on_project completed in ',convert(VARCHAR(30),GETDATE(),120))
RAISERROR(@message_helper, 0, 0) WITH NOWAIT

UPDATE dbo.projects SET Pop_2 = dbo.fn_proj_popularity2(id) WHERE forked_from = 0
DROP TABLE #projects







GO
/****** Object:  StoredProcedure [dbo].[spu_set_temporal_developer_contribution_level]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spu_set_temporal_developer_contribution_level] @months AS int
AS
CREATE TABLE #registrosAtualizar (id INT IDENTITY(1,1), project_id INT, developer_id INT)
INSERT INTO #registrosAtualizar
SELECT DISTINCT  project_id, developer_id FROM dbo.a_temporal_developer_roles

DECLARE @i AS INT = 1;
DECLARE @max AS INT = (SELECT COUNT(*)+1 FROM #registrosAtualizar)
DECLARE @SQL AS NVARCHAR(MAX) = N'';
DECLARE @message_helper AS VARCHAR(500);
SET NOCOUNT ON;
WHILE (@i < @max)
BEGIN
    SELECT @SQL
        = CONCAT(
                    'EXEC dbo.sp_set_all_contribution_level ',
                    CAST(developer_id AS VARCHAR(50)),
                    ',',
                    CAST(project_id AS VARCHAR(50)),
					',',
                    CAST(@months AS VARCHAR(50))
                )
    FROM #registrosAtualizar
    WHERE id = @i;
    EXEC sys.sp_executesql @SQL;

    IF (@i % 226) = 0
    BEGIN
        SET @message_helper = CONCAT(CONVERT(VARCHAR(30), GETDATE(), 120), ' - ', CAST(@i/226 AS VARCHAR(20)));
        RAISERROR(@message_helper, 0, 0) WITH NOWAIT;
    END;

    SET @i = @i + 1;
END;
SET NOCOUNT OFF;
DROP TABLE #registrosAtualizar

GO
/****** Object:  StoredProcedure [dbo].[spu_temporal_base_proj_pop_2]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spu_temporal_base_proj_pop_2]
    @initial_date AS DATE,
    @final_date AS DATE,
    @window_in_months AS INT
AS
--/*Parameters*/
--DECLARE @initial_date DATE = '2016-01-01';
--DECLARE @final_date DATE = '2017-10-01';
--DECLARE @window_in_months INT = 3;

/*Procedure Variables*/
DECLARE @total_periods INT = (
                                 SELECT (DATEDIFF(MONTH, @initial_date, @final_date) + 1) / @window_in_months
                             );
DECLARE @i AS INT = 0;
/*Window initial date is set to minimum value*/
DECLARE @window_initial DATE = '1900-01-01'
DECLARE @window_final DATE;
SET @window_final = DATEADD(MONTH, @window_in_months, @initial_date);


WHILE @i < (@total_periods + 1) /*This loop will get things done for each stint*/
BEGIN
	/*Get total watchers, forks and pulls*/
    WITH w_watchers
    AS (SELECT COUNT(*) total_watchers,
               repo_id
        FROM dbo.watchers
        WHERE created_at
        BETWEEN @window_initial AND @window_final
        GROUP BY repo_id),
    w_forks
    AS (SELECT COUNT(*) total_forks,
               forked_from
        FROM dbo.projects
        WHERE created_at
        BETWEEN @window_initial AND @window_final
        GROUP BY forked_from),
    w_pulls
    AS (SELECT COUNT(*) total_pulls,
               pr.base_repo_id
        FROM dbo.pull_requests pr
            INNER JOIN dbo.pull_request_history prh
                ON pr.id = prh.pull_request_id
        WHERE prh.created_at
        BETWEEN @window_initial AND @window_final
		AND prh.action IN ('opened')
        GROUP BY base_repo_id)
    UPDATE p
    SET p.popularity_2 = ISNULL(wf.total_forks, 0) + ISNULL(ww.total_watchers, 0)
                         + ISNULL((wp.total_pulls * wp.total_pulls), 0),
	p.opened_pull_requests = wp.total_pulls,
	p.watchers = ww.total_watchers,
	p.forks = wf.total_forks
	
    FROM dbo.a_base_temporal_project p
        LEFT JOIN w_forks wf
            ON p.project_id = wf.forked_from
        LEFT JOIN w_pulls wp
            ON wp.base_repo_id = p.project_id
        LEFT JOIN w_watchers ww
            ON ww.repo_id = p.project_id
    WHERE p.initial_date = CASE @window_initial WHEN '1900-01-01' THEN @initial_date ELSE @window_initial END
          AND p.final_date = @window_final
		  
    /*Loop Variables*/
    SET @window_initial = @window_final
    SET @window_final = DATEADD(MONTH, @window_in_months, @window_final);
    SET @i = @i + 1;
END;



GO
/****** Object:  StoredProcedure [dbo].[spu_temporal_proj_pop_2]    Script Date: 26/08/2018 16:33:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spu_temporal_proj_pop_2]
    @initial_date AS DATE,
    @final_date AS DATE,
    @window_in_months AS INT
AS
--/*Parameters*/
--DECLARE @initial_date DATE = '2016-01-01';
--DECLARE @final_date DATE = '2017-10-01';
--DECLARE @window_in_months INT = 3;

/*Procedure Variables*/
DECLARE @total_periods INT = (
                                 SELECT (DATEDIFF(MONTH, @initial_date, @final_date) + 1) / @window_in_months
                             );
DECLARE @i AS INT = 0;
/*Window initial date is set to minimum value*/
DECLARE @window_initial DATE = '1900-01-01'
DECLARE @window_final DATE;
SET @window_final = DATEADD(MONTH, @window_in_months, @initial_date);


WHILE @i < (@total_periods + 1) /*This loop will get things done for each stint*/
BEGIN
	/*Get total watchers, forks and pulls*/
    WITH w_watchers
    AS (SELECT COUNT(*) total_watchers,
               repo_id
        FROM dbo.watchers
        WHERE created_at
        BETWEEN @window_initial AND @window_final
        GROUP BY repo_id),
    w_forks
    AS (SELECT COUNT(*) total_forks,
               forked_from
        FROM dbo.projects
        WHERE created_at
        BETWEEN @window_initial AND @window_final
        GROUP BY forked_from),
    w_pulls
    AS (SELECT COUNT(*) total_pulls,
               pr.base_repo_id
        FROM dbo.pull_requests pr
            INNER JOIN dbo.pull_request_history prh
                ON pr.id = prh.pull_request_id
        WHERE prh.created_at
        BETWEEN @window_initial AND @window_final
		AND prh.action IN ('opened')
        GROUP BY base_repo_id)
    UPDATE p
    SET p.popularity_2 = ISNULL(wf.total_forks, 0) + ISNULL(ww.total_watchers, 0)
                         + ISNULL((wp.total_pulls * wp.total_pulls), 0),
	p.opened_pull_requests = wp.total_pulls,
	p.watchers = ww.total_watchers,
	p.forks = wf.total_forks
	
    FROM dbo.a_temporal_projects p
        LEFT JOIN w_forks wf
            ON p.project_id = wf.forked_from
        LEFT JOIN w_pulls wp
            ON wp.base_repo_id = p.project_id
        LEFT JOIN w_watchers ww
            ON ww.repo_id = p.project_id
    WHERE p.initial_date = CASE @window_initial WHEN '1900-01-01' THEN @initial_date ELSE @window_initial END
          AND p.final_date = @window_final
		  
    /*Loop Variables*/
    SET @window_initial = @window_final
    SET @window_final = DATEADD(MONTH, @window_in_months, @window_final);
    SET @i = @i + 1;
END;


GO
USE [master]
GO
ALTER DATABASE [GHT_Blincoe_01] SET  READ_WRITE 
GO
