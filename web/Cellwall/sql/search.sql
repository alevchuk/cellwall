drop table if exists search;
create table search (
	id      integer      not null auto_increment,
	name    varchar(128) not null,
	s_type  varchar(64)  not null,
	genome  integer,
	db      integer,
	query   enum('family', 'nucleotide', 'protein') not null,
	updated timestamp    not null,
	
	primary key (id),
	unique  key (name),
	        key (s_type),
	        key (db),

	foreign key (db)  references db(id)
		on delete cascade
		on update cascade
) type=innodb;
