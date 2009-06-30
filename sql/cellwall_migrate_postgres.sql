truncate table cellwall.from_mysql_dblink;
truncate table cellwall.dblink;

copy cellwall.from_mysql_dblink ( id, section, sequence, db, href, updated ) from 'from-mysql-cellwall-dblink.tab';

commit;

insert into cellwall.dblink (  id, section, sequence, db, href, updated ) 
select to_number(id,'99999999999'), section, to_number(sequence,'99999999999'), db, href, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_dblink;

commit;

truncate table cellwall.from_mysql_db;
truncate table cellwall.db;

copy cellwall.from_mysql_db ( id, genome, name, db_type, updated ) from 'from-mysql-cellwall-db.tab';

commit;

insert into cellwall.db (  id, genome, name, db_type, updated )
select to_number(id,'99999999999'), to_number(genome,'99999999999'), name, db_type, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_db;

commit;

truncate table cellwall.from_mysql_family;
truncate table cellwall.family;

copy cellwall.from_mysql_family ( id, grp, rank, name, abrev, updated ) from 'from-mysql-cellwall-family.tab';

commit;

insert into cellwall.family ( id, grp, rank, name, abrev, updated )
select to_number(id,'99999999999'), to_number(grp,'99999999999'), to_number(rank,'99999999999'), name, abrev, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_family;

commit;

truncate table cellwall.from_mysql_genome;
truncate table cellwall.genome;

copy cellwall.from_mysql_genome ( id, name, updated ) from 'from-mysql-cellwall-genome.tab';

commit;

insert into cellwall.genome (  id, name, updated )
select to_number(id,'99999999999'), name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_genome;

commit;

truncate table cellwall.from_mysql_groups;
truncate table cellwall.groups;

copy cellwall.from_mysql_groups ( id, parent, rank, name, updated ) from 'from-mysql-cellwall-groups.tab';

commit;

insert into cellwall.groups (  id, parent, rank, name, updated )
select to_number(id,'99999999999'), to_number(case when parent = 'NULL' then null else parent end,'99999999999'), to_number(rank,'99999999999'), name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_groups

commit;

truncate table cellwall.from_mysql_idxref;
truncate table cellwall.idxref;

copy cellwall.from_mysql_idxref ( sequence, accession ) from 'from-mysql-cellwall-idxref.tab';

commit;

insert into cellwall.idxref ( sequence, accession )
select to_number(sequence,'99999999999'), accession
from   cellwall.from_mysql_idxref

commit;

truncate table cellwall.from_mysql_parameters;
truncate table cellwall.parameters;

copy cellwall.from_mysql_parameters ( id, section, others, reference, name, value, updated ) from 'from-mysql-cellwall-parameters.tab';

commit;

insert into cellwall.parameters ( id, section, others, reference, name, value, updated )
select to_number(id,'99999999999'), section, others,to_number(reference,'99999999999'), name, value, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_parameters

commit;

truncate table cellwall.from_mysql_search;
truncate table cellwall.search;

copy cellwall.from_mysql_search ( id, name, s_type, genome, db, query, updated ) from 'from-mysql-cellwall-search.tab';

commit;

insert into cellwall.search ( id, name, s_type, genome, db, query, updated )
select to_number(id,'99999999999'), name, s_type, to_number(case when genome = 'NULL' then null else genome end,'99999999999'),
       to_number(case when db = 'NULL' then null else db end,'99999999999'), query, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_search;

commit;

truncate table cellwall.from_mysql_species;
truncate table cellwall.species;

copy cellwall.from_mysql_species ( id, genus, species, sub_species, common_name, updated ) from 'from-mysql-cellwall-species.tab';

commit;

insert into cellwall.species ( id, genus, species, sub_species, common_name, updated )
select to_number(id,'99999999999'), case when genus = 'NULL' then null else genus end, species, sub_species, common_name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_species;

commit;

truncate table cellwall.from_mysql_subfamily;
truncate table cellwall.subfamily;

copy cellwall.from_mysql_subfamily ( id, family, rank, name, updated ) from 'from-mysql-cellwall-subfamily.tab';

commit;

insert into cellwall.subfamily ( id, family, rank, name, updated )
select to_number(id,'99999999999'), to_number(family,'99999999999'), to_number(rank,'99999999999'), name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_subfamily;

commit;


truncate table cellwall.from_mysql_users;
truncate table cellwall.users;

copy cellwall.from_mysql_subfamily ( id, family, rank, name, updated ) from 'from-mysql-cellwall-subfamily.tab';

insert into cellwall.users ( id, email, password, first, last, institute, address, updated )
select to_number(id,'99999999999'), to_number(family,'99999999999'), to_number(rank,'99999999999'), name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_users;
commit;
