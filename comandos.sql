use master;
go
--cria a base de dados
if db_id('deploy') is not null drop database deploy;
go
create database deploy
go

--criaa tabela auxiliar
use deploy;
go
create table dbo.Auxiliar(n int primary key);
insert dbo.Auxiliar(n) select top(1000000) rn = row_number() over(order by(select null)) from master..spt_values v1,master..spt_values v2,master..spt_values v3;
go
--cria a tabela
set nocount on;
go
if object_id('TblDeploy1') is not null drop table TblDeploy1;
if object_id('TblDeploy2') is not null drop table TblDeploy2;
create table TblDeploy1(a int not null, b char(500) not null default(''));
create table TblDeploy2(a int not null, b char(500) not null default(''));
insert TblDeploy1 with(tablockx) (a) select n%1000 from dbo.Auxiliar;
insert TblDeploy2 with(tablockx) (a) select n%1000+1000 from dbo.Auxiliar;
go
dbcc traceon(3604, 7357) with no_infomsgs;
dbcc freeproccache with no_infomsgs;
go
set statistics time, io, xml on;
declare @a1 int, @a2 int;
select
	@a1 = t1.a,
	@a2 = t2.a
from
	TblDeploy1 t1
	inner join TblDeploy2 t2 on t1.a = t2.a
option(maxdop 1)
set statistics time, io, xml off;
go
dbcc traceoff(3604, 7357) with no_infomsgs;
 
 --in memory hash join

/*
Level � recursion level

Part � number of partitions

RowT � estimated number of rows to fit each partition

ERows � estimated number of rows on the build side

BSize � bitmap size

RoleR � role reversal
*/

---um pouco diferente - "enganar SQL" 
update statistics TblDeploy1 with rowcount = 1;
update statistics TblDeploy2 with rowcount = 1;


dbcc traceon(3604, 7357) with no_infomsgs;
dbcc freeproccache with no_infomsgs;
go
set statistics time, io, xml on;
declare @a1 int, @a2 int;
select
	@a1 = t1.a,
	@a2 = t2.a
from
	TblDeploy1 t1
	inner join TblDeploy2 t2 on t1.a = t2.a
option(maxdop 1)
set statistics time, io, xml off;
go
dbcc traceoff(3604, 7357) with no_infomsgs;
go
--RoleR=1 =Reversal hash join / grace hash join


--bailout -- abrir o profile e filtrar a sessao
if object_id('TblDeploy1') is not null drop table TblDeploy1;
if object_id('TblDeploy2') is not null drop table TblDeploy2;
create table TblDeploy1(a int not null, b char(500) not null default(''));
create table TblDeploy2(a int not null, b char(500) not null default(''));


-- %10 gives a lot of duplicates on both sides
insert TblDeploy1 with(tablockx) (a) select n%10 from dbo.Auxiliar; 
insert TblDeploy2 with(tablockx) (a) select n%10 from dbo.Auxiliar;
update statistics TblDeploy1 with rowcount = 10000, pagecount = 10000;
update statistics TblDeploy2 with rowcount = 10000, pagecount = 10000;
go
dbcc traceon(3604, 7357) with no_infomsgs;
dbcc freeproccache with no_infomsgs;
go
set statistics time, io, xml on;
declare @a1 int, @a2 int;
select
	@a1 = t1.a,
	@a2 = t2.a
from
	TblDeploy1 t1
	inner join TblDeploy2 t2 on t1.a = t2.a
option(maxdop 1)
set statistics time, io, xml off;
go
dbcc traceoff(3604, 7357) with no_infomsgs;
go















--error log pra ver o paralele
dbcc traceon(3605,-1);

dbcc traceon(3604, 7357) with no_infomsgs;
dbcc freeproccache with no_infomsgs;
go
set statistics time, io, xml on;
declare @a1 int, @a2 int;
select
	@a1 = t1.a,
	@a2 = t2.a
from
	TblDeploy1 t1
	inner join TblDeploy2 t2 on t1.a = t2.a
option(maxdop 1)
set statistics time, io, xml off;
go
dbcc traceoff(3604, 7357) with no_infomsgs;
go
