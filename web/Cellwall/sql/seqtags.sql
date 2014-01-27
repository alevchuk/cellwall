drop table if exists seqtags;
create table seqtags (
	id           integer      not null auto_increment,
	feature      integer      not null,
	name         varchar(255) not null,
	value        text         not null,
	updated     timestamp    not null,
	
	primary key (id),
	        key (feature),

	foreign key (feature)  references seqfeature(id)
		on delete cascade
		on update cascade
) type=innodb;
