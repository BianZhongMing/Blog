-- delete DEMO
use tempdb;
GO

if (object_id('tuser','U') is not null) drop table tuser;
create table tuser(
id int not null identity(1,1) constraint PK_TUSER primary key ,
uid int not null constraint TUSER$UID unique nonclustered(uid),
uname varchar(10) not null
);
if(object_id('torder','U') is not null) drop table torder;
create table torder(
id int not null identity(1,1) constraint PK_TORDER primary key,
oid int not null constraint TORDER$OID UNIQUE NONCLUSTERED (OID),
uid int not null,
pname varchar(100) not null 
);

insert into tuser (uid,uname) values
(101,'Tom'),(102,'Jerry'),(103,'Hurry');

insert into torder(oid,uid,pname) values
(0001,101,'shoes'),(0002,101,'boots'),(0003,102,'desk');

select * from tuser a join torder b on a.uid=b.uid

------------delete truncate 对identity的影响：
delete from tuser ;
insert into tuser (uid,uname) values(101,'Tom');
select max(id) from tuser --4

truncate table tuser;
insert into tuser (uid,uname) values(101,'Tom');
select max(id) from tuser--1
--结论：truncate will reset seed.

insert into tuser (uid,uname) values(102,'Jerry'),(103,'Hurry');

---------foreign key 对truncate的影响
alter table torder add CONSTRAINT FK_torder_uid foreign key(uid) references tuser(uid); 
truncate table torder;
truncate table tuser;
--Cannot truncate table 'tuser' because it is being referenced by a FOREIGN KEY constraint.
--disable foreign key
alter table torder nocheck constraint FK_torder_uid;
truncate table tuser;--the same error 
--restore
alter table torder drop CONSTRAINT FK_torder_uid; 

-------关键业务表禁用truncate 的方式（best practise）
create table testa( id int not null primary key,val varchar(10));
create table testb( id int not null primary key,val varchar(10));
--新建虚拟表，并外键引用主表主键（虚拟表的重用references 多个 table）
create table distruncate(dt int not null primary key);
alter table distruncate add constraint FK_distruncate_dt foreign key(dt) references testa(id);
alter table distruncate add constraint FK_distruncate_dt_2 foreign key(dt) references testb(id);
--禁用外键约束以防影响入库性能
alter table distruncate nocheck constraint FK_distruncate_dt;
alter table distruncate nocheck constraint FK_distruncate_dt_2;
--truncate 
insert into testa values(1,'11');
truncate table testa;--Error
delete from testa;--OK
--clear
drop table distruncate;
truncate table testa;--OK
drop table testa;
drop table testb;

-----------cascade delete(not ANSI SQL standard)
select * from tuser a join torder b on a.uid=b.uid
-- from->where->delete 
delete from O
from tuser u join torder o on (u.uid=o.uid)
where u.uname='Tom';
--2 rows affected
--delete from后的表不能用别名/只能用下面from的别名，不支持table as othername的形式
