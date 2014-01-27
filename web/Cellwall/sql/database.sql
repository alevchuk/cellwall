drop table if exists db;
create table db (
	id      integer      not null auto_increment,
	genome  integer,
	name    varchar(128) not null,
	db_type varchar(64)  not null,
	updated timestamp    not null,
	
	primary key (id),
	 unique key (name),
	        key (db_type),

	foreign key (genome)  references genome(id)
		on delete cascade
		on update cascade
) type=innodb;
