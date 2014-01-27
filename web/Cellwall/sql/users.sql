drop table if exists users;
create table users (
	id          integer      not null auto_increment,
	email       varchar(255) not null,
	password    varchar(255) not null,
	first       varchar(255) not null,
	last        varchar(255) not null,
	institute   varchar(255) not null,
	address     text         not null,
	updated     timestamp    not null,

	primary key (id),
	 unique key (email),
	 unique key (first, last)
) type=innodb;
