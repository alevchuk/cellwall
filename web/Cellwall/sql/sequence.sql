drop table if exists sequence;
create table sequence (
	id            integer      not null auto_increment,
	db            integer      not null,
	family        integer      not null,
	species       integer      not null,
	accession     varchar(128) not null,
	display       varchar(128),
	description   varchar(255) not null,
	length        integer      not null,
	alphabet      varchar(16)  not null,
	sequence      longtext     not null,
	gene_name     varchar(255),
	fullname      varchar(255),
	alt_fullname  varchar(255),
	symbols       varchar(255),
	updated       timestamp    not null,
	
	primary key (id),
	 unique key (accession),
	        key (display),
	        key (family),

	foreign key (db)  references db(id)
		on delete cascade
		on update cascade,
	foreign key (family)  references family(id)
		on delete cascade
		on update cascade,
	foreign key (species) references species(id)
		on delete restrict
		on update cascade
) type=innodb;
