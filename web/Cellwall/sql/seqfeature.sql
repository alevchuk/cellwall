drop table if exists seqfeature;
create table seqfeature (
	id           integer      not null auto_increment,
	sequence     integer      not null,
	rank         integer      not null,
	primary_tag  varchar(255),
	updated     timestamp    not null,
	
	primary key (id),
	unique  key (sequence, rank),

	foreign key (sequence)  references sequence(id)
		on delete cascade
		on update cascade
) type=innodb;
