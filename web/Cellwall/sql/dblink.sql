drop table if exists dblink;
create table dblink (
	id          integer      not null auto_increment,
	section     enum( 'annotation', 'literature', 'functional', 'expression', 'knockout', 'other') default 'other',
	sequence    integer      not null,
	db          varchar(255) not null,
	href        varchar(255) not null,
	updated     timestamp    not null,

	primary key (id),
	        key (sequence),
	 unique key (href, sequence),

	foreign key (sequence)  references sequence(id)
		on delete cascade
		on update cascade
) type=innodb;
