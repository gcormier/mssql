
create table testtable (id int not null);
truncate table testtable;

backup database gregtest to E:\Backups\gregtest\regular-full.bak

insert into testtable values (1);

backup log gregtest to disk ='E:\Backups\gregtest\regular-log1.bak'

insert into testtable values (2);

backup log gregtest to disk ='E:\Backups\gregtest\regular-log2.bak'

insert into testtable values (3);

backup database gregtest to disk= 'E:\Backups\gregtest\regular-full-rogue.bak'

insert into testtable values (5);
insert into testtable values (7);
insert into testtable values (8);

backup log gregtest to disk ='E:\Backups\gregtest\regular-log3.bak'

use master;
go

restore database gregtest from disk='E:\Backups\gregtest\regular-full.bak'
with norecovery;

restore log gregtest from disk ='E:\Backups\gregtest\regular-log1.bak'
with norecovery;

restore log gregtest from disk ='E:\Backups\gregtest\regular-log2.bak'
with norecovery;

restore log gregtest from disk ='E:\Backups\gregtest\regular-log3.bak'
with recovery;

select * from gregtest.dbo.testtable