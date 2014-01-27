drop table if exists subfamily;
create table subfamily (
	id      integer      not null auto_increment,
	family  integer      not null,
	rank    integer      not null,
	name    varchar(255) not null,
	updated timestamp    not null,

	primary key (id),
	unique  key (name),

	foreign key (family)  references family(id)
		on delete cascade
		on update cascade
) type=innodb;

