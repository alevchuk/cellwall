-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- gfam table definitions
-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- family_tree ----------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.family_tree cascade;
drop sequence if exists gfam.family_tree_seq;

create sequence gfam.family_tree_seq;

create table gfam.family_tree (
       family_tree_id          integer not null default nextval('gfam.family_tree_seq'),
       family_tree_name        varchar, 
       family_tree_description varchar 
) tablespace gfam_ts;

alter table gfam.family_tree add constraint pk_family_tree primary key(family_tree_id);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- family_tree_node -----------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.family_tree_node cascade;
drop sequence if exists gfam.family_tree_node_seq;

create sequence gfam.family_tree_node_seq;

create table gfam.family_tree_node ( 
       family_tree_node_id    integer not null default nextval('gfam.family_tree_node_seq'), 
       family_tree_node_name  varchar, 
       family_tree_node_abrev varchar 
) tablespace gfam_ts;
 
alter table gfam.family_tree_node add constraint pk_family_tree_node primary key(family_tree_node_id);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- family_tree_instance -------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.family_tree_instance cascade;
drop sequence if exists gfam.family_tree_instance_seq;

create sequence gfam.family_tree_instance_seq;

create table gfam.family_tree_instance ( 
       instance_node_id    integer not null default nextval('gfam.family_tree_instance_seq'), 
       parent_node_id      integer, 
       family_tree_node_id integer not null, 
       rank                integer not null, 
       family_tree_id      integer not null,
       preorder_code       varchar
) tablespace gfam_ts;

alter table gfam.family_tree_instance add constraint pk_family_tree_instance primary key(instance_node_id);
alter table gfam.family_tree_instance add constraint uk_family_tree_instance unique(parent_node_id, rank);

alter table gfam.family_tree_instance add constraint fk_family_tree_instance_family_tree 
      foreign key (family_tree_id) references gfam.family_tree(family_tree_id) on update cascade on delete cascade;

alter table gfam.family_tree_instance add constraint fk_family_tree_instance_family_tree_instance 
      foreign key (parent_node_id) references gfam.family_tree_instance(instance_node_id) on update cascade on delete cascade;

alter table gfam.family_tree_instance add constraint fk_family_tree_instance_family_tree_node 
      foreign key (family_tree_node_id) references gfam.family_tree_node(family_tree_node_id) on update cascade on delete cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- family_build_method --------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.family_build_method cascade;
drop sequence if exists gfam.family_build_method_seq;

create sequence gfam.family_build_method_seq;

create table gfam.family_build_method (
       family_build_method_id   integer not null default nextval('gfam.family_build_method_seq'),
       family_build_method_name varchar,
       family_build_method_desc varchar
) tablespace gfam_ts;

alter table gfam.family_build_method add constraint pk_family_build_method primary key(family_build_method_id);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- family_build ---------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.family_build cascade;
drop sequence if exists gfam.family_build_seq;

create sequence gfam.family_build_seq;

create table gfam.family_build (
       family_build_id        integer  not null default nextval('gfam.family_build_seq'),
       famaily_build_name     varchar,
       family_build_desc      varchar,
       family_build_method_id integer,
       family_build_timestamp timestamp
) tablespace gfam_ts;

alter table gfam.family_build add constraint pk_family_build primary key(family_build_id);

alter table gfam.family_build add constraint fk_family_build_family_build_method 
      foreign key (family_build_method_id) references gfam.family_build_method(family_build_method_id) on update cascade on delete cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- sequence -------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.sequence cascade;
drop sequence if exists gfam.sequence_seq;

create sequence gfam.sequence_seq;

create table gfam.sequence (
       sequence_id integer not null default nextval('gfam.sequence_seq'),
       seguid      varchar,
       alphabet    varchar,
       length      integer,
       sequence    varchar
) tablespace gfam_ts;

alter table gfam.sequence add constraint pk_sequence primary key(sequence_id);
alter table gfam.sequence add constraint uk_sequence unique(seguid);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- family_member --------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.family_member cascade;
drop sequence if exists gfam.family_member_seq;

create sequence gfam.family_member_seq;

create table gfam.family_member ( 
       family_member_id integer not null default nextval('gfam.family_member_seq'),
       family_build_id  integer not null,
       instance_node_id integer not null,
       sequence_id      integer not null
) tablespace gfam_ts;

alter table gfam.family_member add constraint pk_family_member primary key(family_member_id);
alter table gfam.family_member add constraint uk_family_member unique(family_build_id, instance_node_id, sequence_id);

alter table gfam.family_member add constraint fk_family_member_family_build
      foreign key (family_build_id) references gfam.family_build(family_build_id) on update cascade on delete cascade;

alter table gfam.family_member add constraint fk_family_member_family_tree_instance
      foreign key (instance_node_id) references gfam.family_tree_instance(instance_node_id) on update cascade on delete cascade;

alter table gfam.family_member add constraint fk_family_member_sequence
      foreign key (sequence_id) references gfam.sequence(sequence_id) on update cascade on delete cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- genome ---------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.genome cascade;
drop sequence if exists gfam.genome_seq;

create sequence gfam.genome_seq;

create table gfam.genome (
       genome_id      integer not null default nextval('gfam.genome_seq'),
       genome_name    varchar not null
) tablespace gfam_ts;

alter table gfam.genome add constraint pk_genome primary key(genome_id);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- species --------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.species cascade;
drop sequence if exists gfam.species_seq;

create sequence gfam.species_seq;

create table gfam.species (
       species_id  integer not null default nextval('gfam.species_seq'),
       genus       varchar not null,
       species     varchar not null,
       sub_species varchar,
       common_name varchar
) tablespace gfam_ts;

alter table gfam.species add constraint pk_species primary key(species_id);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- db -------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.db cascade;
drop sequence if exists gfam.db_seq;

create sequence gfam.db_seq;

create table gfam.db (
       db_id      integer not null default nextval('gfam.db_seq'),
       genome_id  integer,
       db_name    varchar not null,
       db_type    varchar not null
) tablespace gfam_ts;

alter table gfam.db add constraint pk_db primary key(db_id);

alter table gfam.db add constraint fk_db_genome
      foreign key (genome_id) references gfam.genome(genome_id) on update cascade on delete cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- sequence_information -------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.sequence_information cascade;
drop sequence if exists gfam.sequence_information_seq;

create sequence gfam.sequence_information_seq;

create table gfam.sequence_information (
       sequence_information_id integer not null default nextval('gfam.sequence_information_seq'),
       sequence_id             integer not null,
       accession               varchar not null,        
       db_id                   integer not null,
       species_id              integer not null,
       display                 varchar,
       description             varchar not null,
       gene_name               varchar,
       fullname                varchar,
       alt_fullname            varchar,
       symbols                 varchar 
) tablespace gfam_ts;

alter table gfam.sequence_information add constraint pk_sequence_information primary key(sequence_information_id );
alter table gfam.sequence_information add constraint uk_sequence_information unique(sequence_id, accession, db_id );

alter table gfam.sequence_information add constraint fk_sequence_information_sequence
      foreign key (sequence_id) references gfam.sequence(sequence_id) on update cascade on delete cascade;

alter table gfam.sequence_information add constraint fk_sequence_information_db
      foreign key (db_id) references gfam.db(db_id) on update cascade on delete cascade;

alter table gfam.sequence_information add constraint fk_sequence_information_species
      foreign key (species_id) references gfam.species(species_id) on update cascade on delete cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- source_file ----------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.source_file cascade;

create table gfam.source_file (
       file_name          varchar not null,
       path               varchar,
       sequence_file_desc varchar,
       file_type          varchar
) tablespace gfam_ts;

alter table gfam.source_file add constraint pk_source_file primary key(file_name);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- sequence_file --------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.sequence_source_file cascade;
drop sequence if exists gfam.sequence_source_file_seq;

create sequence gfam.sequence_source_file_seq;

create table gfam.sequence_source_file (
       sequence_source_file_id integer not null default nextval('gfam.sequence_source_file_seq'),
       sequence_id             integer not null,
       file_name               varchar not null
) tablespace gfam_ts;

alter table gfam.sequence_source_file add constraint pk_sequence_source_file unique(sequence_source_file_id);
alter table gfam.sequence_source_file add constraint uk_sequence_source_file unique(sequence_id, file_name);

alter table gfam.sequence_source_file add constraint fk_sequence_source_file_sequence
      foreign key (sequence_id) references gfam.sequence(sequence_id) on update cascade on delete cascade;

alter table gfam.sequence_source_file add constraint fk_sequence_source_file_name
      foreign key (file_name) references gfam.source_file(file_name) on update cascade on delete cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- sequence_feature -----------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.sequence_feature cascade;
drop sequence if exists gfam.sequence_feature_seq;

create sequence gfam.sequence_feature_seq;

create table gfam.sequence_feature (
       sequence_feature_id integer not null default nextval('gfam.sequence_feature_seq'),
       sequence_id         integer not null,
       rank                integer,
       primary_tag         varchar
) tablespace gfam_ts;

alter table gfam.sequence_feature add constraint pk_sequence_feature primary key(sequence_feature_id);
alter table gfam.sequence_feature add constraint uk_sequence_feature unique(sequence_id, rank);

alter table gfam.sequence_feature add constraint fk_sequence_feature_sequence
      foreign key (sequence_id) references gfam.sequence(sequence_id) on update cascade on delete cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- sequence_tag ---------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.sequence_tag cascade;
drop sequence if exists gfam.sequence_tag_seq;

create sequence gfam.sequence_tag_seq;

create table gfam.sequence_tag (
       sequence_tag_id      integer not null default nextval('gfam.sequence_tag_seq'),
       sequence_feature_id  integer not null,
       name                 varchar not null,
       value                varchar not null
) tablespace gfam_ts;

alter table gfam.sequence_tag add constraint pk_sequence_tag primary key(sequence_tag_id);

alter table gfam.sequence_tag add constraint fk_sequence_tag_sequence_feature
      foreign key (sequence_feature_id) references gfam.sequence_feature(sequence_feature_id) on update cascade on delete cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- sequence_location ----------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.sequence_location cascade;
drop sequence if exists gfam.sequence_location_seq;

create sequence gfam.sequence_location_seq;

create table gfam.sequence_location (
       sequence_location_id  integer not null default nextval('gfam.sequence_location_seq'),
       sequence_feature_id   integer not null,
       rank                  integer not null,
       start_pos             integer not null,
       end_pos               integer not null,
       strand                integer not null
) tablespace gfam_ts;

alter table gfam.sequence_location add constraint pk_sequence_location primary key(sequence_location_id);
alter table gfam.sequence_location add constraint uk_sequence_location unique(sequence_feature_id, rank);

alter table gfam.sequence_location add constraint fk_sequence_location_sequence_feature
      foreign key (sequence_feature_id) references gfam.sequence_feature(sequence_feature_id) on update cascade on delete cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- db_link --------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists gfam.dblink cascade;
drop sequence if exists gfam.dblink_seq;

create sequence gfam.dblink_seq;

create table  gfam.dblink (
       dblink_id   integer not null default nextval('gfam.dblink_seq'),
       section     varchar,
       sequence_id integer not null,
       db          varchar not null,
       href        varchar not null
) tablespace gfam_ts;

alter table gfam.dblink add constraint pk_dblink primary key(dblink_id);

alter table gfam.dblink add constraint fk_dblink_sequence
      foreign key (sequence_id) references gfam.sequence(sequence_id) on update cascade on delete cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

