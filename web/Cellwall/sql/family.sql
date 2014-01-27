drop table if exists family;
create table family (
	id      integer      not null auto_increment,
	grp     integer      not null,
	rank    integer      not null,
	name    varchar(255) not null,
	abrev   varchar( 32) not null,
	updated timestamp    not null,

	primary key (id),
	unique  key (name),
	unique  key (abrev),

	foreign key (grp)  references groups(id)
		on delete cascade
		on update cascade
) type=innodb;
