drop table if exists blast_hit;
create table blast_hit (
	id          integer      not null auto_increment,
	search      integer      not null,
	accession   varchar(128) not null,
	species     integer      not null,
	description varchar(255) not null,
	updated     timestamp    not null,

	primary key (id),
	unique  key (accession),
	        key (search),

	foreign key (search)  references search(id)
		on delete cascade
		on update cascade,
	foreign key (species) references species(id)
		on delete restrict
		on update cascade
) type=innodb;
