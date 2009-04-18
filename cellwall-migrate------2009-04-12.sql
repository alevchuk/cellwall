copy cellwall.from_mysql_dblink ( id, section, sequence, db, href, updated ) from 'c:\\db-dumps/from-mysql-cellwall-dblink.tab';

insert into cellwall.dblink (  id, section, sequence, db, href, updated )
select to_number(id,'99999999999'), section, to_number(sequence,'99999999999'), db, href, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_dblink;

commit;

copy cellwall.from_mysql_db ( id, genome, name, db_type, updated ) from 'c:\\db-dumps/from-mysql-cellwall-db.tab';

insert into cellwall.db (  id, genome, name, db_type, updated )
select to_number(id,'99999999999'), to_number(genome,'99999999999'), name, db_type, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_db;

commit;

copy cellwall.from_mysql_family ( id, grp, rank, name, abrev, updated ) from 'c:\\db-dumps/from-mysql-cellwall-family.tab';

insert into cellwall.family (  id, grp, rank, name, abrev, updated )
select to_number(id,'99999999999'), to_number(grp,'99999999999'), to_number(rank,'99999999999'), name, abrev, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_family;

commit;

copy cellwall.from_mysql_genome ( id, name, updated ) from 'c:\\db-dumps/from-mysql-cellwall-genome.tab';

insert into cellwall.genome (  id, name, updated )
select to_number(id,'99999999999'), name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_genome;

commit;

copy cellwall.from_mysql_groups ( id, parent, rank, name, updated ) from 'c:\\db-dumps/from-mysql-cellwall-groups.tab';

insert into cellwall.groups (  id, parent, rank, name, updated )
select to_number(id,'99999999999'), to_number(case when parent = 'NULL' then null else parent end,'99999999999'), to_number(rank,'99999999999'), name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_groups

commit;

copy cellwall.from_mysql_idxref ( sequence, accession ) from 'c:\\db-dumps/from-mysql-cellwall-idxref.tab';

insert into cellwall.idxref (  sequence, accession )
select to_number(sequence,'99999999999'), accession
from   cellwall.from_mysql_idxref

commit;

copy cellwall.from_mysql_parameters ( id, section, others, reference, name, value, updated ) from 'c:\\db-dumps/from-mysql-cellwall-parameters.tab';

insert into cellwall.parameters (  id, section, others, reference, name, value, updated )
select to_number(id,'99999999999'), section, others, to_number(reference,'99999999999'), name, value, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from cellwall.from_mysql_parameters

commit;

copy cellwall.from_mysql_search ( id, name, s_type, genome, db, query, updated ) from 'c:\\db-dumps/from-mysql-cellwall-search.tab';

insert into cellwall.search (  id, name, s_type, genome, db, query, updated )
select to_number(id,'99999999999'), name, s_type, to_number(case when genome = 'NULL' then null else genome end,'99999999999'), 
       to_number(case when db = 'NULL' then null else db end,'99999999999'), query, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_search

commit;

copy cellwall.from_mysql_species ( id, genus, species, sub_species, common_name, updated ) from 'c:\\db-dumps/from-mysql-cellwall-species.tab';

insert into cellwall.species (  id, genus, species, sub_species, common_name, updated )
select to_number(id,'99999999999'), case when genus = 'NULL' then null else genus end, species, sub_species, common_name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_species

commit;

copy cellwall.from_mysql_subfamily ( id, family, rank, name, updated ) from 'c:\\db-dumps/from-mysql-cellwall-subfamily.tab';

insert into cellwall.subfamily (  id, family, rank, name, updated )
select to_number(id,'99999999999'), to_number(family,'99999999999'), to_number(rank,'99999999999'), name, to_timestamp(updated,'YYYY-MM-DD HH:MI:SS')
from   cellwall.from_mysql_subfamily

commit;

