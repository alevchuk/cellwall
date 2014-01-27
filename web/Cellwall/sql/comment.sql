drop table if exists comment;
create table comment (
	id          integer      not null auto_increment,
	user        integer      not null,
	sequence    integer      not null,
	comment     text         not null,
	ref         text,
	updated     timestamp    not null,

	primary key (id),
	        key (sequence),

	foreign key (sequence) references sequence(id)
		on delete restrict
		on update cascade,
	foreign key (user) references users(id)
		on delete cascade
		on update cascade
) type=innodb;
