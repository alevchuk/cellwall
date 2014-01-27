drop table if exists species;
create table species (
	id          integer      not null auto_increment,
	genus       varchar(255) not null,
	species     varchar(255) not null,
	sub_species varchar(255),
	common_name varchar(255),
	updated     timestamp    not null,
	
	primary key(id),
	 unique key(genus, species),
	        key(sub_species)
) type=innodb;
