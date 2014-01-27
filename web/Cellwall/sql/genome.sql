drop table if exists genome;
create table genome (
	id      integer      not null auto_increment,
	name    varchar(128) not null,
	updated timestamp    not null,
	
	primary key (id),
	unique  key (name)
) type=innodb;

