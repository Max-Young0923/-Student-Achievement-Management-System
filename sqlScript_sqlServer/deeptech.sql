USE [master]
GO
/****** Object:  Database [deeptech]    Script Date: 2019/1/22 11:21:39 ******/
CREATE DATABASE [deeptech]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'deeptech', FILENAME = N'C:\deeptech.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'deeptech_log', FILENAME = N'C:\deeptech_log.ldf' , SIZE = 6272KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [deeptech] SET COMPATIBILITY_LEVEL = 120
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [deeptech].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [deeptech] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [deeptech] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [deeptech] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [deeptech] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [deeptech] SET ARITHABORT OFF 
GO
ALTER DATABASE [deeptech] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [deeptech] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [deeptech] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [deeptech] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [deeptech] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [deeptech] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [deeptech] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [deeptech] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [deeptech] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [deeptech] SET  DISABLE_BROKER 
GO
ALTER DATABASE [deeptech] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [deeptech] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [deeptech] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [deeptech] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [deeptech] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [deeptech] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [deeptech] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [deeptech] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [deeptech] SET  MULTI_USER 
GO
ALTER DATABASE [deeptech] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [deeptech] SET DB_CHAINING OFF 
GO
ALTER DATABASE [deeptech] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [deeptech] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [deeptech] SET DELAYED_DURABILITY = DISABLED 
GO
USE [deeptech]
GO
/****** Object:  UserDefinedFunction [dbo].[fun_毕业学生学分统计]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fun_毕业学生学分统计]()
returns @table table(学生学号 varchar(20),学生姓名 varchar(10),学院 varchar(50),专业 varchar(20),学分总数 float,选课门数 int,学时总数 int,是否毕业 varchar(10))
as
begin
  declare @学生学号 varchar(20),@学生姓名 varchar(10),@学院 varchar(50),@专业 varchar(20),@学分总数 float,@选课门数 int,@学时总数 int
  declare @当前学年排序 int,@当前学年代码 varchar(20),@入学学年代码 varchar(20),@是否毕业 varchar(10)
  select @当前学年代码=学年代码 from 学年代码表 where 排序 in (select max(排序) from 学年代码表)
  select @当前学年排序=排序 from 学年代码表 where 学年代码=@当前学年代码
  select @入学学年代码=学年代码 from 学年代码表 where 排序=@当前学年排序-3
  declare cu_毕业学生 cursor for(select 学号,姓名,学院,专业 from 学生表 where 入学学年代码=@入学学年代码)
  open cu_毕业学生
  fetch next from cu_毕业学生 into @学生学号,@学生姓名,@学院,@专业
  while (@@fetch_status=0)
  begin
    select @选课门数=count(*) from 选课表 where 选课表.学号=@学生学号
    select @学时总数=sum(课程学时) from 课程表,选课表,上课表 where 上课表.授课号=选课表.授课号 and 课程表.课程号=上课表.课程号 and 选课表.学号=@学生学号 group by 学号
    select @学分总数=sum(课程学分) from 课程表,选课表,上课表 where 上课表.授课号=选课表.授课号 and 课程表.课程号=上课表.课程号 and 选课表.学号=@学生学号 and 成绩>=60 and 成绩 is not null group by 学号
    if @学分总数>=30 
	begin
	  set @是否毕业='是'
	end
	if @学分总数<30
	begin
		set @是否毕业='否'
	end
	insert into @table (学生学号,学生姓名,学院,专业,学分总数,选课门数,学时总数,是否毕业) 
	  values(@学生学号,@学生姓名,@学院,@专业,@学分总数,@选课门数,@学时总数,@是否毕业)
	fetch next from cu_毕业学生 into @学生学号,@学生姓名,@学院,@专业
  end
  close cu_毕业学生
  return;
end
GO
/****** Object:  UserDefinedFunction [dbo].[fun_单个教师工作量统计]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fun_单个教师工作量统计](@教工号 varchar(20),@学年代码1 varchar(20),@学年代码2 varchar(20))
returns @table table(学年 varchar(50),授课门数 int,学时总数 int)
as
begin
  declare @学年代码 varchar(20),@授课门数 int,@学时总数 int,@i int,@学年排序1 int,@学年排序2 int
  select @学年排序1=排序 from 学年代码表 where 学年代码=@学年代码1
  select @学年排序2=排序 from 学年代码表 where 学年代码=@学年代码2
  set @i=@学年排序2-@学年排序1+1
  while @i!=0
  begin
    select @学年代码=学年代码 from 学年代码表 where 排序=@学年排序1
    select @授课门数=count(*) from 上课表 where 上课表.教工号=@教工号 and 上课表.学年代码=@学年代码
    select @学时总数=sum(课程学时) from 课程表,上课表 where 课程表.课程号=上课表.课程号 and 上课表.教工号=@教工号 and 上课表.学年代码=@学年代码
    if @学时总数 is null
	begin
	  set @学时总数=0
	end
	insert into @table (学年,授课门数,学时总数) values(@学年代码,@授课门数,@学时总数)
	set @学年排序1=@学年排序1+1
	set @i=@i-1
  end
  return;
end
GO
/****** Object:  UserDefinedFunction [dbo].[fun_单个学生学分统计]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fun_单个学生学分统计](@查询学号 varchar(20))
returns @table table(学年代码 varchar(20),学期代码 varchar(10),选课门数  int,学时总数 int,学分总数 float)
as
begin
  declare @学年代码 varchar(20),@学期代码 varchar(10),@选课门数 int,@学时总数 int,@学分总数 float,@i int,@入学学年代码 varchar(20),@当前学年代码 varchar(20),@入学学年排序 int,@当前学年排序 int
  select @入学学年代码=入学学年代码 from 学生表 where 学号=@查询学号
  select @当前学年代码=学年代码 from 学年代码表 where 排序 in (select max(排序) from 学年代码表)
  select @入学学年排序=排序 from 学年代码表 where 学年代码=@入学学年代码
  select @当前学年排序=排序 from 学年代码表 where 学年代码=@当前学年代码
  set @i=@当前学年排序-@入学学年排序+1
  while @i>0
  begin
    select @学年代码=学年代码 from 学年代码表 where 排序=(@入学学年排序+@i-1)  
	set @学期代码='1'
    select @选课门数=count(*) from 选课表,上课表,课程表 where 选课表.学号=@查询学号 and 选课表.授课号=上课表.授课号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='1' 
    select @学时总数=sum(课程学时) from 课程表,选课表,上课表 where 选课表.学号=@查询学号 and 上课表.授课号=选课表.授课号 and 上课表.课程号=课程表.课程号 and 上课表.学期代码='1' and 上课表.学年代码=@学年代码 -- group by 学号
    select @学分总数=sum(课程学分) from 课程表,选课表,上课表 where 选课表.学号=@查询学号 and 上课表.授课号=选课表.授课号 and 上课表.课程号=课程表.课程号 and 上课表.学期代码='1' and 上课表.学年代码=@学年代码 and 成绩>=60 and 成绩 is not null -- group by 学号
    insert into @table (学年代码,学期代码,选课门数,学时总数,学分总数) 
	  values(@学年代码,@学期代码,@选课门数,@学时总数,@学分总数)

	set @学期代码='2'
    select @选课门数=count(*) from 选课表,上课表,课程表 where 选课表.学号=@查询学号 and 选课表.授课号=上课表.授课号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='2' 
    select @学时总数=sum(课程学时) from 课程表,选课表,上课表 where 选课表.学号=@查询学号 and 上课表.授课号=选课表.授课号 and 上课表.课程号=课程表.课程号 and 上课表.学期代码='2' and 上课表.学年代码=@学年代码 -- group by 学号
    select @学分总数=sum(课程学分) from 课程表,选课表,上课表 where 选课表.学号=@查询学号 and 上课表.授课号=选课表.授课号 and 上课表.课程号=课程表.课程号 and 上课表.学期代码='2' and 上课表.学年代码=@学年代码 and 成绩>=60 and 成绩 is not null -- group by 学号
    insert into @table (学年代码,学期代码,选课门数,学时总数,学分总数) 
	  values(@学年代码,@学期代码,@选课门数,@学时总数,@学分总数)
	set @i=@i-1
  end
  return;
end
GO
/****** Object:  UserDefinedFunction [dbo].[fun_教师工作量]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fun_教师工作量](@学年代码 varchar(20))
returns @table table(单位 varchar(20),工号 varchar(20),姓名 varchar(10),上学期授课门数 int,上学期学时总数 int,下学期授课门数 int,下学期学时总数 int,授课门数 int,学时总数 int)
as
begin
  declare @单位 varchar(20),@工号 varchar(20),@姓名 varchar(10),@上学期授课门数 int,@上学期学时总数 int,@下学期授课门数 int,@下学期学时总数 int,@授课门数 int,@学时总数 int
  declare cu_教师 cursor for(select 学院,教工号,姓名 from 教师表)
  open cu_教师
  fetch next from cu_教师 into @单位,@工号,@姓名
  while (@@fetch_status=0)
  begin
    set @单位=@单位 set @工号=@工号 set @姓名=@姓名
    select @上学期授课门数=count(*) from 上课表,课程表 where 上课表.教工号=@工号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='1' 
    select @下学期授课门数=count(*) from 上课表,课程表 where 上课表.教工号=@工号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='2' 
    select @上学期学时总数=sum(课程学时) from 上课表,课程表 where 上课表.教工号=@工号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='1' 
    select @下学期学时总数=sum(课程学时) from 上课表,课程表 where 上课表.教工号=@工号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='2'
	if @上学期学时总数 is null
	begin
	  set @上学期学时总数=0
	end
	if @下学期学时总数 is null
	begin
	  set @下学期学时总数=0
	end
	set @授课门数=@上学期授课门数+@下学期授课门数
	set @学时总数=@上学期学时总数+@下学期学时总数
    insert into @table (单位,工号,姓名,上学期授课门数,上学期学时总数,下学期授课门数,下学期学时总数,授课门数,学时总数) 
	  values(@单位,@工号,@姓名,@上学期授课门数,@上学期学时总数,@下学期授课门数,@下学期学时总数,@授课门数,@学时总数)
    fetch next from cu_教师 into @单位,@工号,@姓名
  end
  close cu_教师
  return;
end
GO
/****** Object:  UserDefinedFunction [dbo].[fun_前三课程]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fun_前三课程]()
returns @table table(课程号 int,课程名 varchar(50),平均分 float,教师姓名 varchar(10),学号 varchar(20),学生姓名 varchar(10),课程总成绩 float)
as
begin
  declare @课程号 int,@课程名 varchar(50),@平均分 float,@教工号 varchar(20),@姓名 varchar(10),@教师姓名 varchar(10),@学号 varchar(20),@学生姓名 varchar(10),@课程总成绩 float
  declare cu_课程排名 cursor for(select 课程号,avg(成绩) 平均分 from 选课表,上课表 where 选课表.授课号=上课表.授课号 group by 课程号)order by 平均分
  declare cu_上课教师 cursor for(select 教工号 from 上课表 where 课程号=@课程号)
  declare cu_学生排名 cursor for(select 学号,成绩 from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 课程号=@课程号) order by 成绩
  declare @i int,@j int
  set @教师姓名=''
  set @i=3
  open cu_课程排名
  fetch next from cu_课程排名 into @课程号,@平均分
  while @i>0
  begin
    set @j=10
	select @课程名=课程表.课程名 from 课程表 where 课程表.课程号=@课程号
--	declare cu_上课教师 cursor for(select 教工号 from 上课表 where 课程号=@课程号)
	open cu_上课教师
	fetch next from cu_上课教师 into @教工号
	while (@@fetch_status=0)
	begin
	  select @姓名=姓名 from 教师表 where 教工号=@教工号
	  set @教师姓名=@姓名
	  fetch next from cu_上课教师 into @教工号
	end
    close cu_上课教师	

--    declare cu_学生排名 cursor for(select 学号,成绩 from 选课表 where 课程号=@课程号) order by 成绩
	open cu_学生排名
	fetch next from cu_学生排名 into @学号,@课程总成绩
    while @j>0
	begin
	  select @学生姓名=姓名 from 学生表 where 学号=@学号
	  select @课程总成绩=成绩 from 选课表,上课表 where 上课表.授课号=选课表.授课号 and 课程号=@课程号 and 学号=@学号
	  set @j=@j-1
	  insert into @table (课程号,课程名,平均分,教师姓名,学号,学生姓名,课程总成绩) 
	    values(@课程号,@课程名,@平均分,@教师姓名,@学号,@学生姓名,@课程总成绩)
	  fetch next from cu_学生排名 into @学号,@课程总成绩
	end
	close cu_学生排名
    
	fetch next from cu_课程排名 into @课程号,@平均分
	set @i=@i-1
  end
  close cu_课程排名
  return;
end
GO
/****** Object:  UserDefinedFunction [dbo].[fun_学年成绩统计]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fun_学年成绩统计](@学年代码 varchar(20),@学期代码 varchar(10))
returns @table table(单位 varchar(20),课程号 int,授课号 int,课程名 varchar(50),选课人数 int,期末卷面最高分 float,期末卷面最低分 float,期末卷面平均分 float,总成绩最高分 float,总成绩最低分 float,总成绩平均分 float)
as
begin
  declare @单位 varchar(20),@课程号 int,@授课号 int,@课程名 varchar(50),@选课人数 int,@期末卷面最高分 float,@期末卷面最低分 float,@期末卷面平均分 float,@总成绩最高分 float,@总成绩最低分 float,@总成绩平均分 float
  declare cu_当前学年学期课程 cursor for(select distinct 学院,上课表.课程号,课程名,上课表.授课号 from 课程表,选课表,上课表 where 课程表.课程号=上课表.课程号 and 选课表.授课号=上课表.授课号 and 上课表.学年代码=@学年代码 and 上课表.学期代码=@学期代码)
  open cu_当前学年学期课程
  fetch next from cu_当前学年学期课程 into @单位,@课程号,@课程名,@授课号
  while (@@fetch_status=0)
  begin
    select @选课人数=count(*) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号
    select @期末卷面最高分=MAX(期末成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 group by 课程号 
	select @期末卷面最低分=MIN(期末成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 group by 课程号
	select @期末卷面平均分=avg(期末成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 group by 课程号
	select @总成绩最高分=MAX(成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 group by 课程号
	select @总成绩最低分=MIN(成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 group by 课程号
	select @总成绩平均分=avg(成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 group by 课程号
	if @期末卷面最高分 is not null
	begin 
    insert into @table (单位,课程号,授课号,课程名,选课人数,期末卷面最高分,期末卷面最低分,期末卷面平均分,总成绩最高分,总成绩最低分,总成绩平均分) 
	  values(@单位,@课程号,@授课号,@课程名,@选课人数,@期末卷面最高分,@期末卷面最低分,@期末卷面平均分,@总成绩最高分,@总成绩最低分,@总成绩平均分)
    end
	fetch next from cu_当前学年学期课程 into @单位,@课程号,@课程名,@授课号
  end
  close cu_当前学年学期课程
  return;
end
GO
/****** Object:  UserDefinedFunction [dbo].[fun_学生学时及学分]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fun_学生学时及学分](@学年代码 varchar(20))
returns @table table(单位 varchar(20),学号 varchar(20),姓名 varchar(10),上学期选课门数 int,上学期学时总数 int,上学期学分总数 float,下学期选课门数 int,下学期学时总数 int,下学期学分总数 float,选课门数 int,学时总数 int,学分总数 float)
as
begin
  declare @单位 varchar(20),@学号 varchar(20),@姓名 varchar(10),@上学期选课门数 int,@上学期学时总数 int,@上学期学分总数 float,@下学期选课门数 int,@下学期学时总数 int,@下学期学分总数 float,@选课门数 int,@学时总数 int,@学分总数 float
  declare cu_学生 cursor for(select 学院,学号,姓名 from 学生表)
  open cu_学生
  fetch next from cu_学生 into @单位,@学号,@姓名
  while (@@fetch_status=0)
  begin
    select @上学期选课门数=count(*) from 选课表,课程表,上课表 where 选课表.学号=@学号 and 选课表.授课号=上课表.授课号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='1' 
    select @下学期选课门数=count(*) from 选课表,课程表,上课表 where 选课表.学号=@学号 and 选课表.授课号=上课表.授课号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='2' 
    select @上学期学时总数=sum(课程学时) from 选课表,课程表,上课表 where 选课表.学号=@学号 and 选课表.授课号=上课表.授课号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='1' 
    select @下学期学时总数=sum(课程学时) from 选课表,课程表,上课表 where 选课表.学号=@学号 and 选课表.授课号=上课表.授课号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='2'
	select @上学期学分总数=sum(课程学分) from 选课表,课程表,上课表 where 选课表.学号=@学号 and 选课表.授课号=上课表.授课号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='1' and 成绩>=60
    select @下学期学分总数=sum(课程学分) from 选课表,课程表,上课表 where 选课表.学号=@学号 and 选课表.授课号=上课表.授课号 and 课程表.课程号=上课表.课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码='2' and 成绩>=60
	set @选课门数=@上学期选课门数+@下学期选课门数
	set @学时总数=@上学期学时总数+@下学期学时总数
	set @学分总数=@上学期学分总数+@下学期学分总数
    insert into @table (单位,学号,姓名,上学期选课门数,上学期学时总数,上学期学分总数,下学期选课门数,下学期学时总数,下学期学分总数,选课门数,学时总数,学分总数) 
	  values(@单位,@学号,@姓名,@上学期选课门数,@上学期学时总数,@上学期学分总数,@下学期选课门数,@下学期学时总数,@下学期学分总数,@选课门数,@学时总数,@学分总数)
	fetch next from cu_学生 into @单位,@学号,@姓名
  end
  close cu_学生
  return;
end
GO
/****** Object:  UserDefinedFunction [dbo].[fun_学院学年成绩统计]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fun_学院学年成绩统计](@学院号 varchar(10))
returns @table table(学年代码 varchar(20),学期代码 varchar(10),课程号 int,授课号 int,课程名 varchar(50),选课人数 int,期末卷面最高分 float,期末卷面最低分 float,期末卷面平均分 float,总成绩最高分 float,总成绩最低分 float,总成绩平均分 float)
as
begin
  declare @学年代码 varchar(20),@学期代码 varchar(10),@课程号 int,@授课号 int,@课程名 varchar(50),@选课人数 int,@期末卷面最高分 float,@期末卷面最低分 float,@期末卷面平均分 float,@总成绩最高分 float,@总成绩最低分 float,@总成绩平均分 float
  declare cu_该学院课程 cursor for(select distinct 上课表.课程号,上课表.授课号,课程名,上课表.学年代码,上课表.学期代码 from 课程表,选课表,上课表 where 上课表.授课号=选课表.授课号 and 课程表.课程号=上课表.课程号 and 课程表.学院号=@学院号)
  open cu_该学院课程
  fetch next from cu_该学院课程 into @课程号,@授课号,@课程名,@学年代码,@学期代码
  while (@@fetch_status=0)
  begin
    select @选课人数=count(*) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号
    select @期末卷面最高分=MAX(期末成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码=@学期代码 group by 课程号
	select @期末卷面最低分=MIN(期末成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码=@学期代码 group by 课程号
	select @期末卷面平均分=avg(期末成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码=@学期代码 group by 课程号
	select @总成绩最高分=MAX(成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码=@学期代码 group by 课程号
	select @总成绩最低分=MIN(成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码=@学期代码 group by 课程号
	select @总成绩平均分=avg(成绩) from 选课表,上课表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=@课程号 and 上课表.学年代码=@学年代码 and 上课表.学期代码=@学期代码 group by 课程号  
    insert into @table (学年代码,学期代码,课程号,授课号,课程名,选课人数,期末卷面最高分,期末卷面最低分,期末卷面平均分,总成绩最高分,总成绩最低分,总成绩平均分) 
	  values(@学年代码,@学期代码,@课程号,@授课号,@课程名,@选课人数,@期末卷面最高分,@期末卷面最低分,@期末卷面平均分,@总成绩最高分,@总成绩最低分,@总成绩平均分)
    fetch next from cu_该学院课程 into @课程号,@授课号,@课程名,@学年代码,@学期代码
  end
  close cu_该学院课程
  return;
end
GO
/****** Object:  Table [dbo].[membership]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[membership](
	[用户名] [varchar](20) NOT NULL,
	[密码] [varchar](50) NOT NULL,
	[用户类型] [varchar](5) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[班级表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[班级表](
	[班级号] [varchar](10) NOT NULL,
	[班级名] [varchar](20) NULL,
	[专业号] [varchar](10) NOT NULL,
	[排序] [int] NULL,
	[是否启用] [varchar](2) NULL,
	[备注] [varchar](50) NULL,
	[预留字段1] [varchar](100) NULL,
	[预留字段2] [varchar](100) NULL,
	[预留字段3] [varchar](100) NULL,
 CONSTRAINT [PK_班级表] PRIMARY KEY CLUSTERED 
(
	[班级号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[班主任表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[班主任表](
	[教工号] [varchar](20) NOT NULL,
	[班级号] [varchar](10) NOT NULL,
 CONSTRAINT [PK_班主任表] PRIMARY KEY CLUSTERED 
(
	[教工号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[城市代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[城市代码表](
	[城市代码] [varchar](10) NOT NULL,
	[城市] [varchar](20) NOT NULL,
	[省份代码] [varchar](10) NOT NULL,
 CONSTRAINT [PK_城市代码表] PRIMARY KEY CLUSTERED 
(
	[城市代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[登陆表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[登陆表](
	[账号] [varchar](20) NOT NULL,
	[密码] [varchar](50) NOT NULL,
	[身份代码] [varchar](5) NOT NULL,
 CONSTRAINT [PK_选课表] PRIMARY KEY CLUSTERED 
(
	[账号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[公告表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[公告表](
	[公告编号] [int] IDENTITY(1,1) NOT NULL,
	[公告标题] [char](50) NOT NULL,
	[公告内容] [varchar](8000) NOT NULL,
	[发布时间] [datetime] NOT NULL,
	[修改时间] [datetime] NULL,
	[预留字段1] [varchar](100) NULL,
	[预留字段2] [varchar](100) NULL,
	[预留字段3] [varchar](100) NULL,
	[预留字段4] [varchar](100) NULL,
	[预留字段5] [varchar](100) NULL,
 CONSTRAINT [PK_公告表] PRIMARY KEY CLUSTERED 
(
	[公告编号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[管理员表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[管理员表](
	[账号] [varchar](20) NOT NULL,
	[密码] [varchar](50) NOT NULL,
	[身份] [varchar](10) NULL,
	[身份代码] [varchar](10) NULL,
	[预留字段1] [varchar](100) NULL,
	[预留字段2] [varchar](100) NULL,
	[预留字段3] [varchar](100) NULL,
	[预留字段4] [varchar](100) NULL,
	[预留字段5] [varchar](100) NULL,
	[预留字段6] [varchar](100) NULL,
	[预留字段7] [varchar](100) NULL,
	[预留字段8] [varchar](100) NULL,
	[预留字段9] [varchar](100) NULL,
	[预留字段10] [varchar](100) NULL,
 CONSTRAINT [PK_管理员表] PRIMARY KEY CLUSTERED 
(
	[账号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[管理员表_旧]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[管理员表_旧](
	[账号] [varchar](20) NOT NULL,
	[密码] [varchar](20) NOT NULL,
 CONSTRAINT [PK_管理员表0] PRIMARY KEY CLUSTERED 
(
	[账号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[教师表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[教师表](
	[教工号] [varchar](20) NOT NULL,
	[密码] [varchar](50) NOT NULL,
	[姓名] [varchar](10) NOT NULL,
	[学院] [varchar](20) NULL,
	[学院号] [varchar](10) NULL,
	[身份] [varchar](10) NULL,
	[身份代码] [varchar](10) NULL,
	[职称] [varchar](20) NULL,
	[职称代码] [varchar](10) NULL,
	[性别代码] [varchar](2) NULL,
	[性别] [varchar](10) NULL,
	[政治面貌] [varchar](20) NULL,
	[政治面貌代码] [varchar](2) NULL,
	[省份] [varchar](20) NULL,
	[省份代码] [varchar](10) NULL,
	[城市] [varchar](20) NULL,
	[城市代码] [varchar](10) NULL,
	[预留字段7] [varchar](100) NULL,
	[预留字段8] [varchar](100) NULL,
	[预留字段9] [varchar](100) NULL,
	[预留字段10] [varchar](100) NULL,
 CONSTRAINT [PK_教师表] PRIMARY KEY CLUSTERED 
(
	[教工号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[教师表_旧]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[教师表_旧](
	[教工号] [varchar](20) NOT NULL,
	[密码] [varchar](20) NULL,
	[姓名] [varchar](10) NOT NULL,
	[学院] [varchar](20) NULL,
	[学院号] [varchar](10) NULL,
	[预留字段1] [varchar](50) NULL,
	[预留字段2] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
	[预留字段4] [varchar](50) NULL,
	[预留字段5] [varchar](50) NULL,
	[预留字段6] [varchar](50) NULL,
	[预留字段7] [varchar](50) NULL,
	[预留字段8] [varchar](50) NULL,
	[预留字段9] [varchar](50) NULL,
	[预留字段10] [varchar](50) NULL,
	[预留字段11] [varchar](50) NULL,
	[预留字段12] [varchar](50) NULL,
	[预留字段13] [varchar](50) NULL,
	[预留字段14] [varchar](50) NULL,
	[预留字段15] [varchar](50) NULL,
	[预留字段16] [varchar](50) NULL,
	[预留字段17] [varchar](50) NULL,
	[预留字段18] [varchar](50) NULL,
	[预留字段19] [varchar](50) NULL,
	[预留字段20] [varchar](50) NULL,
 CONSTRAINT [PK_教师表0] PRIMARY KEY CLUSTERED 
(
	[教工号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[教师私密信息表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[教师私密信息表](
	[教工号] [varchar](20) NOT NULL,
	[身份证号] [varchar](20) NULL,
	[民族] [varchar](20) NULL,
	[民族号] [varchar](2) NULL,
	[政治面貌] [varchar](20) NULL,
	[政治面貌代码] [varchar](2) NULL,
	[省份] [varchar](20) NULL,
	[省份代码] [varchar](10) NULL,
	[城市] [varchar](20) NULL,
	[城市代码] [varchar](10) NULL,
	[照片路径] [varchar](50) NULL,
 CONSTRAINT [PK_教师私密信息表] PRIMARY KEY CLUSTERED 
(
	[教工号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[教室代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[教室代码表](
	[教室代码] [varchar](20) NOT NULL,
	[教室位置] [varchar](20) NULL,
	[教室座位数] [int] NOT NULL,
 CONSTRAINT [PK_教室代码表] PRIMARY KEY CLUSTERED 
(
	[教室代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[课程表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[课程表](
	[课程号] [int] IDENTITY(1,1) NOT NULL,
	[课程名] [varchar](50) NULL,
	[课程学分] [float] NULL,
	[课程学时] [int] NULL,
	[课程类型] [varchar](10) NULL,
	[课程类型代码] [varchar](50) NULL,
	[学院号] [varchar](50) NULL,
	[学院] [varchar](50) NULL,
	[开课时间] [varchar](50) NULL,
	[课程封面] [varchar](50) NULL,
	[备注] [varchar](50) NULL,
	[预留字段1] [varchar](50) NULL,
	[预留字段2] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
	[预留字段4] [varchar](50) NULL,
	[预留字段5] [varchar](50) NULL,
 CONSTRAINT [PK__课程表__B0C6EBD7A6752599] PRIMARY KEY CLUSTERED 
(
	[课程号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[课程类型代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[课程类型代码表](
	[课程类型代码] [varchar](2) NOT NULL,
	[课程类型] [varchar](10) NULL,
	[排序] [int] NULL,
	[是否启用] [varchar](2) NULL,
	[备注] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[课程时间表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[课程时间表](
	[授课号] [int] NOT NULL,
	[上课时间代码] [varchar](20) NULL,
	[上课周次代码] [varchar](20) NULL,
	[教室代码] [varchar](20) NULL,
	[预留字段1] [varchar](50) NULL,
	[预留字段2] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
	[预留字段4] [varchar](50) NULL,
	[预留字段5] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[课程时间表_旧]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[课程时间表_旧](
	[课程号] [int] NOT NULL,
	[上课周次] [varchar](20) NULL,
	[单双周] [int] NULL,
	[上课时间] [varchar](50) NULL,
	[下课时间] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
	[预留字段4] [varchar](50) NULL,
	[预留字段5] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[民族代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[民族代码表](
	[民族号] [varchar](2) NOT NULL,
	[民族] [varchar](20) NOT NULL,
 CONSTRAINT [PK_民族代码表] PRIMARY KEY CLUSTERED 
(
	[民族号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[上课表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[上课表](
	[课程号] [int] NOT NULL,
	[教工号] [varchar](20) NOT NULL,
	[学年代码] [varchar](20) NOT NULL,
	[学期代码] [varchar](10) NOT NULL,
	[授课号] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_上课表] PRIMARY KEY CLUSTERED 
(
	[授课号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[上课表_旧]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[上课表_旧](
	[课程号] [int] NOT NULL,
	[教工号] [varchar](20) NOT NULL,
 CONSTRAINT [PK_上课表0] PRIMARY KEY CLUSTERED 
(
	[课程号] ASC,
	[教工号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[上课时间代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[上课时间代码表](
	[上课时间代码] [varchar](20) NOT NULL,
	[上课时间] [varchar](20) NULL,
 CONSTRAINT [PK_上课时间代码表] PRIMARY KEY CLUSTERED 
(
	[上课时间代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[上课周次代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[上课周次代码表](
	[上课周次代码] [varchar](20) NOT NULL,
	[上课周次] [varchar](20) NOT NULL,
 CONSTRAINT [PK_上课周次代码表] PRIMARY KEY CLUSTERED 
(
	[上课周次代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[身份代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[身份代码表](
	[身份代码] [varchar](10) NOT NULL,
	[身份] [varchar](20) NOT NULL,
 CONSTRAINT [PK_身份代码表] PRIMARY KEY CLUSTERED 
(
	[身份代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[省份代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[省份代码表](
	[省份代码] [varchar](10) NOT NULL,
	[省份] [varchar](20) NOT NULL,
 CONSTRAINT [PK_省份代码表] PRIMARY KEY CLUSTERED 
(
	[省份代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[授课班级表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[授课班级表](
	[授课班级号] [int] NOT NULL,
	[授课类型代码] [int] NOT NULL,
	[授课类型] [varchar](20) NOT NULL,
	[班级号] [varchar](10) NOT NULL,
	[预留字段1] [varchar](50) NULL,
	[预留字段2] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
	[预留字段4] [varchar](50) NULL,
	[预留字段6] [varchar](50) NULL,
	[预留字段7] [varchar](50) NULL,
	[预留字段8] [varchar](50) NULL,
	[预留字段9] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[授课班级号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[授课表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[授课表](
	[授课号] [int] NOT NULL,
	[课程号] [int] NOT NULL,
	[教师编号] [int] NOT NULL,
	[上课时间代码] [varchar](50) NOT NULL,
	[班级号] [varchar](10) NOT NULL,
	[预留字段1] [varchar](50) NULL,
	[预留字段2] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
	[预留字段4] [varchar](50) NULL,
	[预留字段6] [varchar](50) NULL,
	[预留字段7] [varchar](50) NULL,
	[预留字段8] [varchar](50) NULL,
	[预留字段9] [varchar](50) NULL,
 CONSTRAINT [PK__授课表__CCAA326475976BFC] PRIMARY KEY CLUSTERED 
(
	[授课号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[授课类型代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[授课类型代码表](
	[授课类型代码] [int] NOT NULL,
	[授课类型] [varchar](20) NOT NULL,
	[预留字段1] [varchar](50) NULL,
	[预留字段2] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
	[预留字段4] [varchar](50) NULL,
	[预留字段6] [varchar](50) NULL,
	[预留字段7] [varchar](50) NULL,
	[预留字段8] [varchar](50) NULL,
	[预留字段9] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[授课类型代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[系统开关表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[系统开关表](
	[学生选课开关] [varchar](5) NOT NULL,
	[教师打分开关] [varchar](5) NOT NULL,
	[管理员代号] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[新闻表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[新闻表](
	[新闻编号] [int] IDENTITY(1,1) NOT NULL,
	[新闻标题] [char](50) NOT NULL,
	[文章地址] [varchar](50) NULL,
	[新闻内容] [text] NOT NULL,
	[发布时间] [varchar](50) NULL,
	[修改时间] [datetime] NULL,
	[预留字段1] [varchar](100) NULL,
	[预留字段2] [varchar](100) NULL,
	[预留字段3] [varchar](100) NULL,
	[预留字段4] [varchar](100) NULL,
	[预留字段5] [varchar](100) NULL,
 CONSTRAINT [PK_新闻表] PRIMARY KEY CLUSTERED 
(
	[新闻编号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[性别代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[性别代码表](
	[性别代码] [varchar](2) NOT NULL,
	[性别] [varchar](20) NOT NULL,
 CONSTRAINT [PK_性别代码表] PRIMARY KEY CLUSTERED 
(
	[性别代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[修改日志表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[修改日志表](
	[username] [varchar](50) NULL,
	[opttype] [varchar](50) NULL,
	[systime] [varchar](50) NULL,
	[tablename] [varchar](50) NULL,
	[cellname] [varchar](50) NULL,
	[typename] [varchar](50) NULL,
	[newvalue] [varchar](50) NULL,
	[oldvalue] [varchar](50) NULL,
	[ip] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[选课表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[选课表](
	[学号] [varchar](20) NOT NULL,
	[授课号] [int] NOT NULL,
	[成绩] [float] NULL,
	[平时成绩] [float] NULL,
	[期中成绩] [float] NULL,
	[期末成绩] [float] NULL,
	[时间] [datetime] NULL,
 CONSTRAINT [PK_选课表1] PRIMARY KEY CLUSTERED 
(
	[学号] ASC,
	[授课号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[选课表_旧]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[选课表_旧](
	[学号] [varchar](20) NULL,
	[课程号] [int] NULL,
	[学期] [varchar](50) NULL,
	[成绩] [float] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[选课临时表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[选课临时表](
	[学号] [varchar](20) NOT NULL,
	[授课号] [int] NOT NULL,
	[成绩] [float] NULL,
	[平时成绩] [float] NULL,
	[期中成绩] [float] NULL,
	[期末成绩] [float] NULL,
 CONSTRAINT [PK_选课临时表] PRIMARY KEY CLUSTERED 
(
	[学号] ASC,
	[授课号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[学年代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[学年代码表](
	[学年] [varchar](50) NOT NULL,
	[学年代码] [varchar](20) NOT NULL,
	[排序] [int] NULL,
 CONSTRAINT [PK_学年代码表] PRIMARY KEY CLUSTERED 
(
	[学年代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[学期代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[学期代码表](
	[学期] [varchar](50) NOT NULL,
	[学期代码] [varchar](10) NOT NULL,
 CONSTRAINT [PK_学期代码表] PRIMARY KEY CLUSTERED 
(
	[学期代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[学生表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[学生表](
	[学号] [varchar](20) NOT NULL,
	[密码] [varchar](50) NOT NULL,
	[身份] [varchar](10) NULL,
	[身份代码] [varchar](10) NULL,
	[姓名] [varchar](10) NOT NULL,
	[性别代码] [varchar](2) NULL,
	[性别] [varchar](20) NULL,
	[专业] [varchar](20) NULL,
	[专业号] [varchar](10) NULL,
	[学院] [varchar](20) NULL,
	[学院号] [varchar](10) NULL,
	[班级名] [varchar](20) NULL,
	[班级号] [varchar](10) NULL,
	[政治面貌] [varchar](20) NULL,
	[政治面貌代码] [varchar](2) NULL,
	[省份] [varchar](20) NULL,
	[省份代码] [varchar](10) NULL,
	[城市] [varchar](20) NULL,
	[城市代码] [varchar](10) NULL,
	[预留字段7] [varchar](100) NULL,
	[预留字段8] [varchar](100) NULL,
	[预留字段9] [varchar](100) NULL,
	[预留字段10] [varchar](100) NULL,
	[入学学年代码] [varchar](20) NULL,
 CONSTRAINT [PK_学生表] PRIMARY KEY CLUSTERED 
(
	[学号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[学生表_旧]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[学生表_旧](
	[学号] [varchar](20) NOT NULL,
	[姓名] [varchar](10) NOT NULL,
	[性别] [varchar](2) NULL,
	[身份证号] [varchar](20) NULL,
	[民族] [varchar](20) NULL,
	[民族号] [varchar](2) NULL,
	[专业] [varchar](20) NULL,
	[专业号] [varchar](10) NULL,
	[学院号] [varchar](10) NULL,
	[学院] [varchar](20) NULL,
	[密码] [varchar](20) NULL,
	[预留字段1] [varchar](50) NULL,
	[预留字段2] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
	[预留字段4] [varchar](50) NULL,
	[预留字段5] [varchar](50) NULL,
	[预留字段6] [varchar](50) NULL,
	[预留字段7] [varchar](50) NULL,
	[预留字段8] [varchar](50) NULL,
	[预留字段9] [varchar](50) NULL,
	[预留字段10] [varchar](50) NULL,
 CONSTRAINT [PK_学生表0] PRIMARY KEY CLUSTERED 
(
	[学号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[学生上课表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[学生上课表](
	[上课ID] [int] NOT NULL,
	[学号] [varchar](20) NOT NULL,
	[授课号] [int] NOT NULL,
	[预留字段] [varchar](50) NULL,
	[预留字段1] [varchar](50) NULL,
	[预留字段2] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
	[预留字段4] [varchar](50) NULL,
	[预留字段5] [varchar](50) NULL,
	[预留字段6] [varchar](50) NULL,
	[预留字段7] [varchar](50) NULL,
	[预留字段8] [varchar](50) NULL,
 CONSTRAINT [PK_学生上课表] PRIMARY KEY CLUSTERED 
(
	[上课ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[学生私密信息表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[学生私密信息表](
	[学号] [varchar](20) NOT NULL,
	[身份证号] [varchar](20) NULL,
	[民族] [varchar](20) NULL,
	[民族号] [varchar](2) NULL,
	[政治面貌] [varchar](20) NULL,
	[政治面貌代码] [varchar](2) NULL,
	[省份] [varchar](20) NULL,
	[省份代码] [varchar](10) NULL,
	[城市] [varchar](20) NULL,
	[城市代码] [varchar](10) NULL,
	[照片路径] [varchar](50) NULL,
 CONSTRAINT [PK_学生私密信息表] PRIMARY KEY CLUSTERED 
(
	[学号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[学院表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[学院表](
	[学院号] [varchar](10) NOT NULL,
	[学院] [varchar](20) NULL,
	[排序] [int] NULL,
	[是否启用] [varchar](2) NULL,
	[备注] [varchar](50) NULL,
	[预留字段1] [varchar](50) NULL,
	[预留字段2] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
 CONSTRAINT [PK_学院表] PRIMARY KEY CLUSTERED 
(
	[学院号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[政治面貌代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[政治面貌代码表](
	[政治面貌代码] [varchar](2) NOT NULL,
	[政治面貌] [varchar](20) NOT NULL,
 CONSTRAINT [PK_政治面貌表] PRIMARY KEY CLUSTERED 
(
	[政治面貌代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[职称代码表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[职称代码表](
	[职称代码] [varchar](10) NOT NULL,
	[职称] [varchar](20) NOT NULL,
 CONSTRAINT [PK_职称代码表] PRIMARY KEY CLUSTERED 
(
	[职称代码] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[专业表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[专业表](
	[专业号] [varchar](10) NOT NULL,
	[学院号] [varchar](10) NULL,
	[专业] [varchar](20) NULL,
	[排序] [int] NULL,
	[是否启用] [varchar](2) NULL,
	[备注] [varchar](50) NULL,
	[预留字段1] [varchar](50) NULL,
	[预留字段2] [varchar](50) NULL,
	[预留字段3] [varchar](50) NULL,
 CONSTRAINT [PK_专业表] PRIMARY KEY CLUSTERED 
(
	[专业号] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[V_上课时间表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[V_上课时间表]
as
select   上课表.授课号,上课时间,教室位置   from 上课时间代码表,教室代码表,上课表,课程时间表 where 课程时间表.上课时间代码=上课时间代码表.上课时间代码 and 课程时间表.教室代码=教室代码表.教室代码
and 上课表.授课号=课程时间表.授课号
GO
/****** Object:  View [dbo].[V_课程信息12]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_课程信息12]
AS
SELECT   dbo.选课表.学号, dbo.选课表.授课号, dbo.课程表.课程名, dbo.课程表.课程学分, dbo.课程表.课程学时, dbo.课程表.学院, 
                dbo.教师表.姓名 AS 任课教师, dbo.V_上课时间表.上课时间, dbo.V_上课时间表.教室位置
FROM      dbo.课程表 INNER JOIN
                dbo.上课表 ON dbo.课程表.课程号 = dbo.上课表.课程号 INNER JOIN
                dbo.选课表 ON dbo.上课表.授课号 = dbo.选课表.授课号 INNER JOIN
                dbo.教师表 ON dbo.上课表.教工号 = dbo.教师表.教工号 INNER JOIN
                dbo.V_上课时间表 ON dbo.上课表.授课号 = dbo.V_上课时间表.授课号

GO
/****** Object:  View [dbo].[V_学生选课信息表1]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[V_学生选课信息表1]
as
select distinct 上课表.授课号,课程名,课程学分,课程学时,课程类型,课程表.学院,姓名 as 任课教师,上课时间,教室位置 from 课程表,上课表,学年代码表,学期代码表,教师表,V_上课时间表 where
   课程表.课程号=上课表.课程号 and 上课表.学年代码=学年代码表.学年代码 and 上课表.学期代码=学期代码表.学期代码
   and 教师表.教工号=上课表.教工号 and 上课表.授课号= V_上课时间表.授课号
GO
/****** Object:  View [dbo].[V_学生选课信息表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[V_学生选课信息表]
as
select distinct 授课号,课程名,课程学分,课程学时,课程类型,课程表.学院,姓名 as 教师姓名 from 课程表,上课表,学年代码表,学期代码表,教师表 where
   课程表.课程号=上课表.课程号 and 上课表.学年代码=学年代码表.学年代码 and 上课表.学期代码=学期代码表.学期代码
   and 教师表.教工号=上课表.教工号
GO
/****** Object:  View [dbo].[V_学生选课]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 create view [dbo].[V_学生选课]
 as
 SELECT 授课号, 课程名, 课程学分, 课程学时, 课程类型, 学院, 教师姓名 FROM dbo.V_学生选课信息表
 except
 SELECT distinct 选课表.授课号, 课程名, 课程学分, 课程学时, 课程类型, 学院, 教师姓名 
 FROM 选课表,V_学生选课信息表 
 where 选课表.授课号= V_学生选课信息表.授课号
GO
/****** Object:  View [dbo].[V_成绩查询]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[V_成绩查询]
as
select distinct 学号,课程名,成绩,课程学分 from 选课表,上课表,课程表 where 选课表.授课号=上课表.授课号 and 上课表.课程号=课程表.课程号

GO
/****** Object:  View [dbo].[V_打分表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[V_打分表]
as
select 上课表.教工号,选课临时表.授课号,选课临时表.学号,姓名,课程名,专业,选课临时表.平时成绩,选课临时表.期中成绩,选课临时表.期末成绩,选课临时表.成绩 from 选课临时表,学生表,上课表,课程表
where 学生表.学号=选课临时表.学号 and 上课表.授课号=选课临时表.授课号 and 课程表.课程号=上课表.课程号

GO
/****** Object:  View [dbo].[v_教师打分表]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_教师打分表] as
select 上课表.教工号,选课表.授课号,选课表.学号,姓名,课程名,专业,学年,上课表.学年代码,学期,上课表.学期代码 
from 选课表,学生表,上课表,课程表,学年代码表,学期代码表 
where 学生表.学号=选课表.学号 and 上课表.授课号=选课表.授课号 and 课程表.课程号=上课表.课程号 and
上课表.学年代码=学年代码表.学年代码 and 上课表.学期代码=学期代码表.学期代码
GO
/****** Object:  View [dbo].[v_教师课程]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[v_教师课程] as
select distinct 上课表.教工号,姓名,授课号,上课表.课程号,课程名,学年,上课表.学年代码,学期,上课表.学期代码 from 上课表,课程表,教师表,学年代码表,学期代码表
where 上课表.课程号=课程表.课程号 and 上课表.教工号=教师表.教工号 and 上课表.学年代码=学年代码表.学年代码 and 上课表.学期代码=学期代码表.学期代码


GO
/****** Object:  View [dbo].[V_教师信息]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[V_教师信息]
as
select 姓名,性别,学院,身份,身份证号,职称,民族,政治面貌,省份,城市 from 教师表,教师私密信息表 where 教师表.教工号=教师私密信息表.教工号;
GO
/****** Object:  View [dbo].[v_课程分数]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_课程分数] as
select 教工号,选课表.学号,姓名,课程名,专业 from 选课表,学生表,上课表,课程表 
where 学生表.学号=选课表.学号 and 上课表.授课号=选课表.授课号 and 课程表.课程号=上课表.课程号
GO
/****** Object:  View [dbo].[V_课程信息]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[V_课程信息]
as
select 学号,课程名,课程学分,课程学时,课程表.学院,姓名 as 任课教师 from 课程表,教师表,选课表,上课表 where 课程表.课程号=上课表.课程号 
and 选课表.授课号=上课表.授课号 and 上课表.教工号=教师表.教工号
GO
/****** Object:  View [dbo].[V_课程信息1]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[V_课程信息1]
as
select 学号,选课表.授课号,课程名,课程学分,课程学时,课程表.学院,姓名 as 任课教师 from 课程表,教师表,选课表,上课表 where 课程表.课程号=上课表.课程号 
and 选课表.授课号=上课表.授课号 and 上课表.教工号=教师表.教工号
GO
/****** Object:  View [dbo].[V_课程信息11]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[V_课程信息11]
as
select 选课表.学号,选课表.授课号,课程名,课程学分,课程学时,课程表.学院,姓名 as 任课教师,时间  from 课程表,教师表,选课表,上课表 where 课程表.课程号=上课表.课程号 
and 选课表.授课号=上课表.授课号 and 上课表.教工号=教师表.教工号
GO
/****** Object:  View [dbo].[V_老师上课信息]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[V_老师上课信息]
as
select distinct 教工号,课程名,授课号 from 上课表,课程表 where 上课表.课程号=课程表.课程号
GO
/****** Object:  View [dbo].[v_老师上课信息视图]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[v_老师上课信息视图] as
select 上课表.课程号,教工号,学年代码,学期代码,课程名,课程学分,课程学时 from 上课表,课程表
where 上课表.课程号=课程表.课程号

GO
/****** Object:  View [dbo].[v_上课表信息]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_上课表信息] as
select 授课号,上课表.课程号,教工号,学院号,学院,学期,上课表.学期代码,学年,上课表.学年代码 from 上课表,课程表,学期代码表,学年代码表 
where 上课表.课程号=课程表.课程号 and 上课表.学期代码=学期代码表.学期代码 and 上课表.学年代码=学年代码表.学年代码
GO
/****** Object:  View [dbo].[V_新闻表降序排序]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_新闻表降序排序]
AS
SELECT  TOP (4) 新闻编号, 新闻标题, 新闻内容, 发布时间
FROM      dbo.新闻表
ORDER BY 新闻编号 DESC

GO
/****** Object:  View [dbo].[V_学生信息]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[V_学生信息]
as
select 姓名,性别,民族,身份,身份证号,学院,专业,班级名,政治面貌,省份,城市 from 学生表,学生私密信息表 where 学生表.学号=学生私密信息表.学号;
GO
/****** Object:  View [dbo].[成绩统计]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[成绩统计]  as 
select v.学年,v.学期,v.课程号,v.课程名,v.平均成绩,v.姓名 as 教师姓名 ,w.姓名 as 学生姓名,v.成绩 from 
(select * from
(select m.组号,m.学年,m.学期,m.课程号,m.课程名,m.平均成绩,m.姓名,n.学号,成绩,
row_number() over(partition by 组号 order by 成绩 desc)排序 from
(select  k.学年,k.学期,k.课程号,k.课程名,k.平均成绩,l.姓名,k.授课号,
dense_rank() OVER(order by [学年],[学期]desc,[课程号] ) as 组号 from
(select  j.学年,j.学期,j.课程号,j.课程名,j.平均成绩,j.教工号,j.授课号,j.组号 from 
(select *,row_number() over(partition by 组号 order by 平均成绩 desc)as 排名   from
(select dense_rank() OVER(order by [学年],[学期] desc) as 组号 , *  from
(select g.学年,g.学期,g.课程号,g.课程名,avg(成绩)as 平均成绩,g.教工号,g.授课号 from 
(select e.学年,e.学期代码 as 学期,e.课程号,f.课程名,e.成绩,e.教工号,e.授课号　from 
(select d.学年,c.学期代码,c.课程号,c.成绩,c.教工号,c.授课号 from 
(select a.学年代码,a.学期代码,a.课程号,b.成绩,a.教工号,b.授课号　from 
(select *　from 上课表)a
left join
(select * from 选课表)b
on a.授课号=b.授课号)c
left join 
(select * from 学年代码表)d
on c.学年代码=d.学年代码)e
left join 
(select * from 课程表)f
on e.课程号=f.课程号)g
group by g.学年,g.学期,g.课程名,g.课程号,g.教工号,g.授课号)h)i)j
where 排名<=3)k
left join
(select 教工号,姓名 from 教师表)l
on k.教工号=l.教工号)m
left join
(select * from 选课表)n
on m.授课号=n.授课号
group by 组号,学年,学期,课程号,课程名,平均成绩,姓名,学号,成绩)u
where 排序<=10)v
left join 
(select 学号,姓名 from 学生表)w
on v.学号=w.学号
where 成绩 is not null
group by 学年,学期,课程号,课程名,平均成绩,v.姓名 ,w.姓名,v.成绩



GO
/****** Object:  View [dbo].[工作量统计]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[工作量统计] as 
select e.学年代码,e.学期代码,e.学院,e.教工号,e.姓名,count(e.课程名)授课门数,sum(e.课程学时)总学时 from 
(select c.学年代码,c.学期代码,c.学院,c.教工号,c.姓名,d.课程名,d.课程学时 from
(select b.学院,b.姓名,a.* from
(select * from 上课表) a 
left join 
(select * from 教师表 )b
on a.教工号=b.教工号
)c
left join
(select * from 课程表)d
on c.课程号=d.课程号)e
group by e.学年代码,e.学期代码,e.学院,e.教工号,e.姓名
with check option
GO
ALTER TABLE [dbo].[班级表]  WITH CHECK ADD  CONSTRAINT [FK_班级表_REFERENCE_专业表] FOREIGN KEY([专业号])
REFERENCES [dbo].[专业表] ([专业号])
GO
ALTER TABLE [dbo].[班级表] CHECK CONSTRAINT [FK_班级表_REFERENCE_专业表]
GO
ALTER TABLE [dbo].[班主任表]  WITH CHECK ADD  CONSTRAINT [FK_班主任表_REFERENCE_班级代码表] FOREIGN KEY([班级号])
REFERENCES [dbo].[班级表] ([班级号])
GO
ALTER TABLE [dbo].[班主任表] CHECK CONSTRAINT [FK_班主任表_REFERENCE_班级代码表]
GO
ALTER TABLE [dbo].[班主任表]  WITH NOCHECK ADD  CONSTRAINT [FK_班主任表_REFERENCE_教师表] FOREIGN KEY([教工号])
REFERENCES [dbo].[教师表] ([教工号])
GO
ALTER TABLE [dbo].[班主任表] NOCHECK CONSTRAINT [FK_班主任表_REFERENCE_教师表]
GO
ALTER TABLE [dbo].[城市代码表]  WITH CHECK ADD  CONSTRAINT [FK_城市代码表_REFERENCE_省份代码表] FOREIGN KEY([省份代码])
REFERENCES [dbo].[省份代码表] ([省份代码])
GO
ALTER TABLE [dbo].[城市代码表] CHECK CONSTRAINT [FK_城市代码表_REFERENCE_省份代码表]
GO
ALTER TABLE [dbo].[教师表]  WITH CHECK ADD  CONSTRAINT [FK_教师表_REFERENCE_城市代码表] FOREIGN KEY([城市代码])
REFERENCES [dbo].[城市代码表] ([城市代码])
GO
ALTER TABLE [dbo].[教师表] CHECK CONSTRAINT [FK_教师表_REFERENCE_城市代码表]
GO
ALTER TABLE [dbo].[教师表]  WITH CHECK ADD  CONSTRAINT [FK_教师表_REFERENCE_身份代码表] FOREIGN KEY([身份代码])
REFERENCES [dbo].[身份代码表] ([身份代码])
GO
ALTER TABLE [dbo].[教师表] CHECK CONSTRAINT [FK_教师表_REFERENCE_身份代码表]
GO
ALTER TABLE [dbo].[教师表]  WITH CHECK ADD  CONSTRAINT [FK_教师表_REFERENCE_省份代码表] FOREIGN KEY([省份代码])
REFERENCES [dbo].[省份代码表] ([省份代码])
GO
ALTER TABLE [dbo].[教师表] CHECK CONSTRAINT [FK_教师表_REFERENCE_省份代码表]
GO
ALTER TABLE [dbo].[教师表]  WITH CHECK ADD  CONSTRAINT [FK_教师表_REFERENCE_性别代码表] FOREIGN KEY([性别代码])
REFERENCES [dbo].[性别代码表] ([性别代码])
GO
ALTER TABLE [dbo].[教师表] CHECK CONSTRAINT [FK_教师表_REFERENCE_性别代码表]
GO
ALTER TABLE [dbo].[教师表]  WITH CHECK ADD  CONSTRAINT [FK_教师表_REFERENCE_学院表] FOREIGN KEY([学院号])
REFERENCES [dbo].[学院表] ([学院号])
GO
ALTER TABLE [dbo].[教师表] CHECK CONSTRAINT [FK_教师表_REFERENCE_学院表]
GO
ALTER TABLE [dbo].[教师表]  WITH CHECK ADD  CONSTRAINT [FK_教师表_REFERENCE_政治面貌代码表] FOREIGN KEY([政治面貌代码])
REFERENCES [dbo].[政治面貌代码表] ([政治面貌代码])
GO
ALTER TABLE [dbo].[教师表] CHECK CONSTRAINT [FK_教师表_REFERENCE_政治面貌代码表]
GO
ALTER TABLE [dbo].[教师表]  WITH CHECK ADD  CONSTRAINT [FK_教师表_REFERENCE_职称代码表] FOREIGN KEY([职称代码])
REFERENCES [dbo].[职称代码表] ([职称代码])
GO
ALTER TABLE [dbo].[教师表] CHECK CONSTRAINT [FK_教师表_REFERENCE_职称代码表]
GO
ALTER TABLE [dbo].[教师表_旧]  WITH CHECK ADD  CONSTRAINT [FK_教师表0_REFERENCE_学院表] FOREIGN KEY([学院号])
REFERENCES [dbo].[学院表] ([学院号])
GO
ALTER TABLE [dbo].[教师表_旧] CHECK CONSTRAINT [FK_教师表0_REFERENCE_学院表]
GO
ALTER TABLE [dbo].[教师私密信息表]  WITH NOCHECK ADD  CONSTRAINT [FK_教师私密信息表_城市代码外键] FOREIGN KEY([城市代码])
REFERENCES [dbo].[城市代码表] ([城市代码])
GO
ALTER TABLE [dbo].[教师私密信息表] CHECK CONSTRAINT [FK_教师私密信息表_城市代码外键]
GO
ALTER TABLE [dbo].[教师私密信息表]  WITH CHECK ADD  CONSTRAINT [FK_教师私密信息表_民族代码外键] FOREIGN KEY([民族号])
REFERENCES [dbo].[民族代码表] ([民族号])
GO
ALTER TABLE [dbo].[教师私密信息表] CHECK CONSTRAINT [FK_教师私密信息表_民族代码外键]
GO
ALTER TABLE [dbo].[教师私密信息表]  WITH CHECK ADD  CONSTRAINT [FK_教师私密信息表_省份代码外键] FOREIGN KEY([省份代码])
REFERENCES [dbo].[省份代码表] ([省份代码])
GO
ALTER TABLE [dbo].[教师私密信息表] CHECK CONSTRAINT [FK_教师私密信息表_省份代码外键]
GO
ALTER TABLE [dbo].[教师私密信息表]  WITH CHECK ADD  CONSTRAINT [FK_教师私密信息表_政治面貌代码外键] FOREIGN KEY([政治面貌代码])
REFERENCES [dbo].[政治面貌代码表] ([政治面貌代码])
GO
ALTER TABLE [dbo].[教师私密信息表] CHECK CONSTRAINT [FK_教师私密信息表_政治面貌代码外键]
GO
ALTER TABLE [dbo].[课程时间表]  WITH CHECK ADD  CONSTRAINT [FK_课程时间表_REFERENCE_教室代码表] FOREIGN KEY([教室代码])
REFERENCES [dbo].[教室代码表] ([教室代码])
GO
ALTER TABLE [dbo].[课程时间表] CHECK CONSTRAINT [FK_课程时间表_REFERENCE_教室代码表]
GO
ALTER TABLE [dbo].[课程时间表]  WITH CHECK ADD  CONSTRAINT [FK_课程时间表_REFERENCE_上课表] FOREIGN KEY([授课号])
REFERENCES [dbo].[上课表] ([授课号])
GO
ALTER TABLE [dbo].[课程时间表] CHECK CONSTRAINT [FK_课程时间表_REFERENCE_上课表]
GO
ALTER TABLE [dbo].[课程时间表]  WITH CHECK ADD  CONSTRAINT [FK_课程时间表_REFERENCE_上课时间代码表] FOREIGN KEY([上课时间代码])
REFERENCES [dbo].[上课时间代码表] ([上课时间代码])
GO
ALTER TABLE [dbo].[课程时间表] CHECK CONSTRAINT [FK_课程时间表_REFERENCE_上课时间代码表]
GO
ALTER TABLE [dbo].[课程时间表]  WITH CHECK ADD  CONSTRAINT [FK_课程时间表_REFERENCE_上课周次代码表] FOREIGN KEY([上课周次代码])
REFERENCES [dbo].[上课周次代码表] ([上课周次代码])
GO
ALTER TABLE [dbo].[课程时间表] CHECK CONSTRAINT [FK_课程时间表_REFERENCE_上课周次代码表]
GO
ALTER TABLE [dbo].[上课表]  WITH NOCHECK ADD  CONSTRAINT [FK_上课表_REFERENCE_教师表] FOREIGN KEY([教工号])
REFERENCES [dbo].[教师表] ([教工号])
GO
ALTER TABLE [dbo].[上课表] NOCHECK CONSTRAINT [FK_上课表_REFERENCE_教师表]
GO
ALTER TABLE [dbo].[上课表]  WITH CHECK ADD  CONSTRAINT [FK_上课表_REFERENCE_课程表] FOREIGN KEY([课程号])
REFERENCES [dbo].[课程表] ([课程号])
GO
ALTER TABLE [dbo].[上课表] CHECK CONSTRAINT [FK_上课表_REFERENCE_课程表]
GO
ALTER TABLE [dbo].[上课表]  WITH CHECK ADD  CONSTRAINT [FK_上课表_REFERENCE_学年代码表] FOREIGN KEY([学年代码])
REFERENCES [dbo].[学年代码表] ([学年代码])
GO
ALTER TABLE [dbo].[上课表] CHECK CONSTRAINT [FK_上课表_REFERENCE_学年代码表]
GO
ALTER TABLE [dbo].[上课表]  WITH CHECK ADD  CONSTRAINT [FK_上课表_REFERENCE_学期代码表] FOREIGN KEY([学期代码])
REFERENCES [dbo].[学期代码表] ([学期代码])
GO
ALTER TABLE [dbo].[上课表] CHECK CONSTRAINT [FK_上课表_REFERENCE_学期代码表]
GO
ALTER TABLE [dbo].[上课表_旧]  WITH CHECK ADD  CONSTRAINT [FK_上课表0_REFERENCE_教师表] FOREIGN KEY([教工号])
REFERENCES [dbo].[教师表_旧] ([教工号])
GO
ALTER TABLE [dbo].[上课表_旧] CHECK CONSTRAINT [FK_上课表0_REFERENCE_教师表]
GO
ALTER TABLE [dbo].[授课班级表]  WITH CHECK ADD FOREIGN KEY([班级号])
REFERENCES [dbo].[班级表] ([班级号])
GO
ALTER TABLE [dbo].[授课班级表]  WITH CHECK ADD  CONSTRAINT [FK_授课班级表_授课类型代码] FOREIGN KEY([授课类型代码])
REFERENCES [dbo].[授课类型代码表] ([授课类型代码])
GO
ALTER TABLE [dbo].[授课班级表] CHECK CONSTRAINT [FK_授课班级表_授课类型代码]
GO
ALTER TABLE [dbo].[授课表]  WITH CHECK ADD  CONSTRAINT [FK__授课表__班级号__23F3538A] FOREIGN KEY([班级号])
REFERENCES [dbo].[班级表] ([班级号])
GO
ALTER TABLE [dbo].[授课表] CHECK CONSTRAINT [FK__授课表__班级号__23F3538A]
GO
ALTER TABLE [dbo].[授课表]  WITH CHECK ADD  CONSTRAINT [FK_上课时间代码表_上课时间代码] FOREIGN KEY([授课号])
REFERENCES [dbo].[授课表] ([授课号])
GO
ALTER TABLE [dbo].[授课表] CHECK CONSTRAINT [FK_上课时间代码表_上课时间代码]
GO
ALTER TABLE [dbo].[选课表]  WITH CHECK ADD  CONSTRAINT [FK_选课表_REFERENCE_上课表] FOREIGN KEY([授课号])
REFERENCES [dbo].[上课表] ([授课号])
GO
ALTER TABLE [dbo].[选课表] CHECK CONSTRAINT [FK_选课表_REFERENCE_上课表]
GO
ALTER TABLE [dbo].[选课表]  WITH NOCHECK ADD  CONSTRAINT [FK_选课表_REFERENCE_学生表] FOREIGN KEY([学号])
REFERENCES [dbo].[学生表] ([学号])
GO
ALTER TABLE [dbo].[选课表] NOCHECK CONSTRAINT [FK_选课表_REFERENCE_学生表]
GO
ALTER TABLE [dbo].[选课表]  WITH NOCHECK ADD  CONSTRAINT [FK_选课临时表_REFERENCE_学生表] FOREIGN KEY([学号])
REFERENCES [dbo].[学生表] ([学号])
GO
ALTER TABLE [dbo].[选课表] NOCHECK CONSTRAINT [FK_选课临时表_REFERENCE_学生表]
GO
ALTER TABLE [dbo].[选课表]  WITH CHECK ADD  CONSTRAINT [选课表_授课号] FOREIGN KEY([授课号])
REFERENCES [dbo].[上课表] ([授课号])
GO
ALTER TABLE [dbo].[选课表] CHECK CONSTRAINT [选课表_授课号]
GO
ALTER TABLE [dbo].[选课表_旧]  WITH CHECK ADD  CONSTRAINT [FK_选课表0_REFERENCE_学生表] FOREIGN KEY([学号])
REFERENCES [dbo].[学生表_旧] ([学号])
GO
ALTER TABLE [dbo].[选课表_旧] CHECK CONSTRAINT [FK_选课表0_REFERENCE_学生表]
GO
ALTER TABLE [dbo].[选课临时表]  WITH CHECK ADD  CONSTRAINT [FK_选课临时表1_REFERENCE_课程表] FOREIGN KEY([授课号])
REFERENCES [dbo].[上课表] ([授课号])
GO
ALTER TABLE [dbo].[选课临时表] CHECK CONSTRAINT [FK_选课临时表1_REFERENCE_课程表]
GO
ALTER TABLE [dbo].[选课临时表]  WITH NOCHECK ADD  CONSTRAINT [FK_选课临时表1_REFERENCE_学生表] FOREIGN KEY([学号])
REFERENCES [dbo].[学生表] ([学号])
GO
ALTER TABLE [dbo].[选课临时表] NOCHECK CONSTRAINT [FK_选课临时表1_REFERENCE_学生表]
GO
ALTER TABLE [dbo].[学生表]  WITH CHECK ADD  CONSTRAINT [FK_学生表_REFERENCE_城市代码表] FOREIGN KEY([城市代码])
REFERENCES [dbo].[城市代码表] ([城市代码])
GO
ALTER TABLE [dbo].[学生表] CHECK CONSTRAINT [FK_学生表_REFERENCE_城市代码表]
GO
ALTER TABLE [dbo].[学生表]  WITH CHECK ADD  CONSTRAINT [FK_学生表_REFERENCE_身份代码表] FOREIGN KEY([身份代码])
REFERENCES [dbo].[身份代码表] ([身份代码])
GO
ALTER TABLE [dbo].[学生表] CHECK CONSTRAINT [FK_学生表_REFERENCE_身份代码表]
GO
ALTER TABLE [dbo].[学生表]  WITH CHECK ADD  CONSTRAINT [FK_学生表_REFERENCE_省份代码表] FOREIGN KEY([省份代码])
REFERENCES [dbo].[省份代码表] ([省份代码])
GO
ALTER TABLE [dbo].[学生表] CHECK CONSTRAINT [FK_学生表_REFERENCE_省份代码表]
GO
ALTER TABLE [dbo].[学生表]  WITH CHECK ADD  CONSTRAINT [FK_学生表_REFERENCE_性别代码表] FOREIGN KEY([性别代码])
REFERENCES [dbo].[性别代码表] ([性别代码])
GO
ALTER TABLE [dbo].[学生表] CHECK CONSTRAINT [FK_学生表_REFERENCE_性别代码表]
GO
ALTER TABLE [dbo].[学生表]  WITH CHECK ADD  CONSTRAINT [FK_学生表_REFERENCE_学年代码表] FOREIGN KEY([入学学年代码])
REFERENCES [dbo].[学年代码表] ([学年代码])
GO
ALTER TABLE [dbo].[学生表] CHECK CONSTRAINT [FK_学生表_REFERENCE_学年代码表]
GO
ALTER TABLE [dbo].[学生表]  WITH CHECK ADD  CONSTRAINT [FK_学生表_REFERENCE_学院表] FOREIGN KEY([学院号])
REFERENCES [dbo].[学院表] ([学院号])
GO
ALTER TABLE [dbo].[学生表] CHECK CONSTRAINT [FK_学生表_REFERENCE_学院表]
GO
ALTER TABLE [dbo].[学生表]  WITH CHECK ADD  CONSTRAINT [FK_学生表_REFERENCE_政治面貌代码表] FOREIGN KEY([政治面貌代码])
REFERENCES [dbo].[政治面貌代码表] ([政治面貌代码])
GO
ALTER TABLE [dbo].[学生表] CHECK CONSTRAINT [FK_学生表_REFERENCE_政治面貌代码表]
GO
ALTER TABLE [dbo].[学生表]  WITH CHECK ADD  CONSTRAINT [FK_学生表_REFERENCE_专业表] FOREIGN KEY([专业号])
REFERENCES [dbo].[专业表] ([专业号])
GO
ALTER TABLE [dbo].[学生表] CHECK CONSTRAINT [FK_学生表_REFERENCE_专业表]
GO
ALTER TABLE [dbo].[学生表_旧]  WITH CHECK ADD  CONSTRAINT [FK_学生表0_REFERENCE_学院表] FOREIGN KEY([学院号])
REFERENCES [dbo].[学院表] ([学院号])
GO
ALTER TABLE [dbo].[学生表_旧] CHECK CONSTRAINT [FK_学生表0_REFERENCE_学院表]
GO
ALTER TABLE [dbo].[学生表_旧]  WITH CHECK ADD  CONSTRAINT [FK_学生表0_REFERENCE_专业表] FOREIGN KEY([专业号])
REFERENCES [dbo].[专业表] ([专业号])
GO
ALTER TABLE [dbo].[学生表_旧] CHECK CONSTRAINT [FK_学生表0_REFERENCE_专业表]
GO
ALTER TABLE [dbo].[学生上课表]  WITH CHECK ADD  CONSTRAINT [FK__学生上课表__授课号__29AC2CE0] FOREIGN KEY([授课号])
REFERENCES [dbo].[授课表] ([授课号])
GO
ALTER TABLE [dbo].[学生上课表] CHECK CONSTRAINT [FK__学生上课表__授课号__29AC2CE0]
GO
ALTER TABLE [dbo].[学生私密信息表]  WITH CHECK ADD  CONSTRAINT [FK_学生私密信息表_城市代码外键] FOREIGN KEY([城市代码])
REFERENCES [dbo].[城市代码表] ([城市代码])
GO
ALTER TABLE [dbo].[学生私密信息表] CHECK CONSTRAINT [FK_学生私密信息表_城市代码外键]
GO
ALTER TABLE [dbo].[学生私密信息表]  WITH CHECK ADD  CONSTRAINT [FK_学生私密信息表_民族号外键] FOREIGN KEY([民族号])
REFERENCES [dbo].[民族代码表] ([民族号])
GO
ALTER TABLE [dbo].[学生私密信息表] CHECK CONSTRAINT [FK_学生私密信息表_民族号外键]
GO
ALTER TABLE [dbo].[学生私密信息表]  WITH CHECK ADD  CONSTRAINT [FK_学生私密信息表_省份代码外键] FOREIGN KEY([省份代码])
REFERENCES [dbo].[省份代码表] ([省份代码])
GO
ALTER TABLE [dbo].[学生私密信息表] CHECK CONSTRAINT [FK_学生私密信息表_省份代码外键]
GO
ALTER TABLE [dbo].[学生私密信息表]  WITH CHECK ADD  CONSTRAINT [FK_学生私密信息表_政治面貌代码外键] FOREIGN KEY([政治面貌代码])
REFERENCES [dbo].[政治面貌代码表] ([政治面貌代码])
GO
ALTER TABLE [dbo].[学生私密信息表] CHECK CONSTRAINT [FK_学生私密信息表_政治面貌代码外键]
GO
ALTER TABLE [dbo].[专业表]  WITH CHECK ADD  CONSTRAINT [FK_专业表_REFERENCE_学院表] FOREIGN KEY([学院号])
REFERENCES [dbo].[学院表] ([学院号])
GO
ALTER TABLE [dbo].[专业表] CHECK CONSTRAINT [FK_专业表_REFERENCE_学院表]
GO
/****** Object:  StoredProcedure [dbo].[insertGrade]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertGrade](@授课号 int)
as 
begin
declare @学号 varchar(20),@平时成绩 float,@期中成绩 float,@期末成绩 float,@成绩 float
declare cu_临时成绩 cursor for
(select 学号,平时成绩,期中成绩,期末成绩,成绩 from 选课临时表 
where 授课号=@授课号
)
open cu_临时成绩
fetch next from cu_临时成绩 into @学号,@平时成绩,@期中成绩,@期末成绩,@成绩
while(@@FETCH_STATUS=0)
begin
  update 选课表 set 平时成绩=@平时成绩,期中成绩=@期中成绩,期末成绩=@期末成绩,成绩=@成绩 
    where 学号=@学号 and 授课号=@授课号
  fetch next from cu_临时成绩 into @学号,@平时成绩,@期中成绩,@期末成绩,@成绩
end
close cu_临时成绩 
end

GO
/****** Object:  StoredProcedure [dbo].[pr_成绩录入]    Script Date: 2019/1/22 11:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_成绩录入](@课程号 int,@学号 varchar(20),@平时成绩比例 float,@期中成绩比例 float,@期末成绩比例 float)
as
begin
  declare @成绩 float,@平时成绩 float,@期中成绩 float,@期末成绩 float
  select @平时成绩=平时成绩 from 选课表 where 课程号=@课程号 and 学号=@学号
  select @期中成绩=期中成绩 from 选课表 where 课程号=@课程号 and 学号=@学号
  select @期末成绩=期末成绩 from 选课表 where 课程号=@课程号 and 学号=@学号
  if @平时成绩 is null
    set @平时成绩=0
  if @期中成绩 is null
    set @期中成绩=0
  if @期末成绩 is null
    set @期末成绩=0
  set @成绩=@平时成绩*@平时成绩比例+@期中成绩*@期中成绩比例+@期末成绩*@期末成绩比例
  update 选课表 set 成绩=@成绩
end
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "课程表"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 146
               Right = 199
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "上课表"
            Begin Extent = 
               Top = 6
               Left = 237
               Bottom = 146
               Right = 379
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "选课表"
            Begin Extent = 
               Top = 150
               Left = 38
               Bottom = 290
               Right = 180
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "教师表"
            Begin Extent = 
               Top = 150
               Left = 218
               Bottom = 290
               Right = 379
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "V_上课时间表"
            Begin Extent = 
               Top = 294
               Left = 38
               Bottom = 415
               Right = 180
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_课程信息12'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_课程信息12'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_课程信息12'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[42] 4[28] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "新闻表"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 216
               Right = 687
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_新闻表降序排序'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_新闻表降序排序'
GO
USE [master]
GO
ALTER DATABASE [deeptech] SET  READ_WRITE 
GO
