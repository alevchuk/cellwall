-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Table definitions
-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.blast_hit;
drop sequence if exists cellwall.blast_hit_id_seq;

drop index    if exists cellwall.blast_hit_search;
drop index    if exists cellwall.blast_hit_species;

create sequence cellwall.blast_hit_id_seq;

create table  cellwall.blast_hit 
(  
       id          integer      not null default nextval('cellwall.blast_hit_id_seq') ,  
       search      integer      not null default '0',  
       accession   varchar(128) not null default '',  
       species     integer      not null default '0',  
       description varchar(255) not null default '',  
       updated     timestamp    not null default current_timestamp
);

alter table cellwall.blast_hit add constraint pk_blast_hit primary key(id);
alter table cellwall.blast_hit add constraint uk_blast_hit_accession unique(accession);

create index blast_hit_search on cellwall.blast_hit(search);
create index blast_hit_species on cellwall.blast_hit(species);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.blast_hsp;
drop sequence if exists cellwall.blast_hsp_id_seq;

drop index if exists cellwall.blast_hsp_query;
drop index if exists cellwall.blast_hsp_hit;
drop index if exists cellwall.blast_hsp_e;
drop index if exists cellwall.blast_hsp_score;
drop index if exists cellwall.blast_hsp_bits;
drop index if exists cellwall.blast_hsp_hit_length;
drop index if exists cellwall.blast_hsp_total_length;

create sequence cellwall.blast_hsp_id_seq;

create table  cellwall.blast_hsp 
(
       id               integer   not null default nextval('cellwall.blast_hsp_id_seq'),
       query            integer   not null default '0',
       hit              integer   not null default '0',
       e                real      not null default '0',
       score            real      not null default '0',
       bits             real      not null default '0',
       query_start      integer   not null default '0',
       query_stop       integer   not null default '0',
       hit_start        integer   not null default '0',
       hit_stop         integer   not null default '0',
       query_length     integer   not null default '0',
       hit_length       integer   not null default '0',
       total_length     integer   not null default '0',
       query_identity   real      not null default '0',
       hit_identity     real      not null default '0',
       total_identity   real      not null default '0',
       percent_identity real      not null default '0',
       query_conserved  real      not null default '0',
       hit_conserved    real      not null default '0',
       total_conserved  real      not null default '0',
       updated          timestamp not null default current_timestamp
);

alter table cellwall.blast_hsp add constraint pk_blast_hsp primary key(id);
alter table cellwall.blast_hsp add constraint uk_blast_hsp_query_hit unique (query,hit);

create index blast_hsp_query on cellwall.blast_hsp(query);
create index blast_hsp_hit on cellwall.blast_hsp(hit);
create index blast_hsp_e on cellwall.blast_hsp(e);
create index blast_hsp_score on cellwall.blast_hsp(score);
create index blast_hsp_bits on cellwall.blast_hsp(bits);
create index blast_hsp_hit_length on cellwall.blast_hsp(hit_length);
create index blast_hsp_total_length on cellwall.blast_hsp(total_length);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.comment;
drop sequence if exists cellwall.comment_id_seq;

drop index if exists cellwall.comment_sequence_id;
drop index if exists cellwall.comment_user_id;

create sequence cellwall.comment_id_seq;

create table cellwall.comment 
(
       id          integer not null default nextval('cellwall.comment_id_seq'),
       user_id     integer not null default '0',
       sequence_id integer not null default '0',
       comment     varchar not null,
       ref         varchar,
       updated     timestamp not null default current_timestamp
);

alter table cellwall.comment add constraint pk_comment primary key(id);

create index comment_sequence_id on cellwall.comment(sequence_id);
create index comment_user_id on cellwall.comment(user_id);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.db;
drop sequence if exists cellwall.db_id_seq;

drop index if exists cellwall.db_db_type;
drop index if exists cellwall.db_genome;

create sequence cellwall.db_id_seq;

create table cellwall.db 
(
       id      integer      not null default nextval('cellwall.db_id_seq'),
       genome  integer               default null,
       name    varchar(128) not null default '',
       db_type varchar(64)  not null default '',
       updated timestamp    not null default current_timestamp
);

alter table cellwall.db add constraint pk_db primary key(id);
alter table cellwall.db add constraint uk_db_name unique (name);

create index db_db_type on cellwall.db(db_type);
create index db_genome on cellwall.db(genome);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.dblink;
drop sequence if exists cellwall.dblink_id_seq;

drop index if exists cellwall.dblink_sequence;

create sequence cellwall.dblink_id_seq;

create table  cellwall.dblink 
(
       id       integer      not null default nextval('cellwall.dblink_id_seq'),
       section  varchar               default 'other',
       sequence integer      not null default '0',
       db       varchar(255) not null default '',
       href     varchar(255) not null default '',
       updated  timestamp    not null default current_timestamp
);

alter table cellwall.dblink add constraint pk_dblink primary key(id);
alter table cellwall.dblink add constraint uk_dblink_href_sequence unique (href,sequence);
alter table cellwall.dblink add constraint c_dblink_section check(section in ('annotation','literature','functional','expression','knockout','other'));

create index dblink_sequence on cellwall.dblink(sequence);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.family;
drop sequence if exists cellwall.family_id_seq;

drop index if exists cellwall.family_grp;

create sequence cellwall.family_id_seq;

create table cellwall.family 
(
       id      integer      not null default nextval('cellwall.family_id_seq'),
       grp     integer      not null default '0',
       rank    integer      not null default '0',
       name    varchar(255) not null default '',
       abrev   varchar(32)  not null default '',
       updated timestamp    not null default current_timestamp
);

alter table cellwall.family add constraint pk_family primary key(id);
alter table cellwall.family add constraint uk_family_name unique (name);
alter table cellwall.family add constraint uk_family_abrev unique (abrev);

create index family_grp on cellwall.family(grp);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.genome;
drop sequence if exists cellwall.genome_id_seq;

create sequence cellwall.genome_id_seq;

create table cellwall.genome 
(
       id      integer      not null default nextval('cellwall.genome_id_seq'),
       name    varchar(128) not null default '',
       updated timestamp    not null default current_timestamp
);

alter table cellwall.genome add constraint pk_genome primary key(id);
alter table cellwall.genome add constraint uk_genome_name unique (name);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists cellwall.groups;
drop sequence if exists cellwall.groups_id_seq;

drop index if exists cellwall.groups_parent;

create sequence cellwall.groups_id_seq;

create table cellwall.groups 
(
       id      integer      not null default nextval('cellwall.groups_id_seq'),
       parent  integer               default null,
       rank    integer      not null default '0',
       name    varchar(128) not null default '',
       updated timestamp    not null default current_timestamp
);

alter table cellwall.groups add constraint pk_groups primary key(id);
alter table cellwall.groups add constraint uk_groups_name unique (name);

create index groups_parent on cellwall.groups(parent);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists cellwall.idxref;

drop index if exists cellwall.idxref_sequence;

create table  cellwall.idxref 
(
       sequence  integer      not null default '0',
       accession varchar(255) not null default ''
);

alter table cellwall.idxref add constraint uk_accession unique (accession);

create index idxref_sequence on cellwall.idxref(sequence);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.parameters;
drop sequence if exists cellwall.parameters_id_seq;

drop index    if exists cellwall.parameters_section_others_reference_name;

create sequence cellwall.parameters_id_seq;

create table  cellwall.parameters 
(
       id        integer      not null default nextval('cellwall.parameters_id_seq'),
       section   varchar      not null default 'genome',
       others    varchar(128)          default null,
       reference integer not  null     default '0',
       name      varchar(64)  not null default '',
       value     varchar(255)          default null,
       updated   timestamp    not null default current_timestamp
);

alter table cellwall.parameters add constraint pk_parameters primary key(id);
alter table cellwall.parameters add constraint c_parameters_section check(section in ('genome','database','search','group','family','sequence','species','other') );

create index parameters_section_others_reference_name on cellwall.parameters(section,others,reference,name);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.search;
drop sequence if exists cellwall.searc_id_seq;

drop index if exists cellwall.search_s_type;
drop index if exists cellwall.search_db;

create sequence cellwall.search_id_seq;

create table  cellwall.search 
(
       id      integer      not null default nextval('cellwall.search_id_seq'),
       name    varchar(128) not null default '',
       s_type  varchar(64)  not null default '',
       genome  integer               default null,
       db      integer               default null,
       query   varchar      not null default 'family',
       updated timestamp    not null default current_timestamp
);

alter table cellwall.search add constraint pk_search primary key(id);
alter table cellwall.search add constraint uk_search_name unique(name);
alter table cellwall.search add constraint c_search_query check(query in ('family','nucleotide','protein')); 

create index search_s_type on cellwall.search(s_type);
create index search_db on cellwall.search(db);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.seqfeature;
drop sequence if exists cellwall.seqfeature_id_seq;

create sequence cellwall.seqfeature_id_seq;

create table  cellwall.seqfeature 
(
       id          integer      not null default nextval('cellwall.seqfeature_id_seq'),
       sequence    integer      not null default '0',
       rank        integer      not null default '0',
       primary_tag varchar(255)          default null,
       updated     timestamp    not null default current_timestamp
);

alter table cellwall.seqfeature add constraint pk_seqfeature primary key(id);
alter table cellwall.seqfeature add constraint uk_seqfeature_sequence_rank unique(sequence,rank);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists cellwall.seqlocation;
drop sequence if exists cellwall.seqloacation_id_seq;

create sequence cellwall.seqlocation_id_seq;

create table  cellwall.seqlocation 
(
       id         integer    not null default nextval('cellwall.seqlocation_id_seq'),
       seqfeature integer    not null default '0',
       rank       integer    not null default '0',
       start_pos  integer    not null default '0',
       end_pos    integer    not null default '0',
       strand     integer    not null default '0',
       updated    timestamp  not null default current_timestamp
);

alter table cellwall.seqlocation add constraint pk_seqlocation primary key(id);
alter table cellwall.seqlocation add constraint uk_seqlocation_seqfeature_rank unique(seqfeature,rank);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists cellwall.seqtags;
drop sequence if exists cellwall.seqtags_id_seq;

create sequence cellwall.seqtags_id_seq;

create table  cellwall.seqtags 
(
       id      integer      not null default nextval('cellwall.seqtags_id_seq'),
       feature integer      not null default '0',
       name    varchar(255) not null default '',
       value   text         not null,
       updated timestamp    not null default current_timestamp
);

alter table cellwall.seqtags add constraint pk_segtags primary key(id);

create index seqtags_feature on cellwall.seqtags(feature);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.species;
drop sequence if exists cellwall.species_id_seq;

drop index if exists cellwall.species_sub_species;

create sequence cellwall.species_id_seq;

create table  cellwall.species 
(
       id          integer      not null default nextval('cellwall.species_id_seq'),
       genus       varchar(255) not null default '',
       species     varchar(255) not null default '',
       sub_species varchar(255) default null,
       common_name varchar(255) default null,
       updated     timestamp    not null default current_timestamp
);

alter table cellwall.species add constraint pk_species primary key(id);
alter table cellwall.species add constraint uk_species_genus_species unique(genus,species);

create index species_sub_species on cellwall.species(sub_species);  

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.subfamily;
drop sequence if exists cellwall.subfamily_id_seq;

drop index if exists cellwall.subfamily_family;

create sequence cellwall.subfamily_id_seq;

create table  cellwall.subfamily 
(
       id      integer      not null default nextval('cellwall.subfamily_id_seq'),
       family  integer      not null default '0',
       rank    integer      not null default '0',
       name    varchar(255) not null default '',
       updated timestamp    not null default current_timestamp
);

alter table cellwall.subfamily add constraint pk_subfamily primary key(id);
alter table cellwall.subfamily add constraint uk_subfamily_name unique(name);

create index subfamily_family on cellwall.subfamily(family);

-------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table    if exists cellwall.users;
drop sequence if exists cellwall.users_id_seq;

create sequence cellwall.users_id_seq;

create table cellwall.users 
(
       id        integer      not null default nextval('cellwall.users_id_seq'),
       email     varchar(255) not null default '',
       password  varchar(255) not null default '',
       first     varchar(255) not null default '',
       last      varchar(255) not null default '',
       institute varchar(255) not null default '',
       address   text         not null,
       updated   timestamp    not null default current_timestamp
);

alter table cellwall.users add constraint pk_users primary key(id);
alter table cellwall.users add constraint uk_users_email unique(email);
alter table cellwall.users add constraint uk_users_first_last unique(first,last);

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Foreign key definitions
-------------------------------------------------------------------------------------------------------------------------------------------------------------

alter table cellwall.blast_hit add constraint fk_blast_hit_search foreign key (search) references search(id) on update cascade on delete cascade;
alter table cellwall.blast_hit add constraint fk_blast_hit_species foreign key (species) references species(id) on update cascade;

alter table cellwall.blast_hsp add constraint blast_hsp_ibfk_1 foreign key (query) references sequence (id) on delete cascade on update cascade;
alter table cellwall.blast_hsp add constraint blast_hsp_ibfk_2 foreign key (hit) references blast_hit (id) on delete cascade on update cascade;

alter table cellwall.comment add constraint comment_ibfk_1 foreign key (sequence) references sequence(id) on update cascade;
alter table cellwall.comment add constraint comment_ibfk_2 foreign key (user) references users(id) on delete cascade on update cascade;

alter table cellwall.db add constraint db_ibfk_1 foreign key (genome) references genome(id) on delete cascade on update cascade;

alter table cellwall.dblink add constraint dblink_ibfk_1 foreign key (sequence) references sequence (id) on delete cascade on update cascade;

alter table cellwall.family add constraint family_ibfk_1 foreign key (grp) references groups (id) on delete cascade on update cascade;

alter table cellwall.groups add constraint groups_ibfk_1 foreign key(parent) references groups(id) on delete cascade on update cascade;

alter table cellwall.idxref add  constraint idxref_ibfk_1 foreign key (sequence) references sequence (id) on delete cascade on update cascade;

alter table cellwall.search add constraint search_ibfk_1 foreign key(db) references db(id) on delete cascade on update cascade;

alter table cellwall.seqfeature add constraint seqfeature_ibfk_1 foreign key (sequence) references sequence (id) on delete cascade on update cascade;

alter table cellwall.seqlocation add constraint seqlocation_ibfk_1 foreign key (seqfeature) references seqfeature (id) on delete cascade on update cascade;

alter table cellwall.seqtags add constraint seqtags_ibfk_1 foreign key(feature) references seqfeature(id) on delete cascade on update cascade;

alter table cellwall.subfamily add constraint subfamily_ibfk_1 foreign key (family) references family (id) on delete cascade on update cascade;

-------------------------------------------------------------------------------------------------------------------------------------------------------------
