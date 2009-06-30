--------------------------------------------------------------------------------------------------------------------------------- 
-- load sequence to stage
---------------------------------------------------------------------------------------------------------------------------------

drop table if exists stage.st_sequence;

create table stage.st_sequence 
(       
       source    varchar,       
       load_date date,       
       header    varchar,       
       sequence  varchar
);

truncate table stage.st_sequence;
-- select * from stage.st_sequence limit 100;

-- PHYPA ------------------------------------------------------------------------------------------------------------------------

alter table stage.st_sequence alter column source set default 'PHYPA';
alter table stage.st_sequence alter column load_date set default '20090418';

copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_jgi-phypa-v1-1_prot--.tab';
copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_jgi-phypa-v1-1_trans-.tab';
-- copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_gff--_jgi-phypa-v1-1_genes-.tab'; does not look like a sequence file

commit;

alter table stage.st_sequence alter column source set default null;
alter table stage.st_sequence alter column load_date set default null;

-- POPTR ------------------------------------------------------------------------------------------------------------------------

alter table stage.st_sequence alter column source set default 'POPTR';
alter table stage.st_sequence alter column load_date set default '20090418';

copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_jgi-poptr-v1-1_prot--.tab';
copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_jgi-poptr-v1-1_trans-.tab';
-- copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_gff--_jgi-poptr-v1-1_genes-.tab'; does not look like a sequence file

commit;

alter table stage.st_sequence alter column source set default null;
alter table stage.st_sequence alter column load_date set default null;

-- TAIR -------------------------------------------------------------------------------------------------------------------------

alter table stage.st_sequence alter column source set default 'TAIR';
alter table stage.st_sequence alter column load_date set default '20090418';

-- copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_tair-v20080228_intron.tab'; empty
copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_tair-v20080229_igenic.tab';
copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_tair-v20080412_cdna--.tab';
copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_tair-v20080412_cds---.tab';
copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_tair-v20080412_pep---.tab';

commit;

alter table stage.st_sequence alter column source set default null;
alter table stage.st_sequence alter column load_date set default null;

-- TIGR -------------------------------------------------------------------------------------------------------------------------

alter table stage.st_sequence alter column source set default 'TIGR';
alter table stage.st_sequence alter column load_date set default '20090418';

copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_tigr-v6-0-all-_pep---.tab';
copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_tigr-v6-0-all-_seq---.tab';
-- copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_gff3-_tigr-v6-0-all-_gff3--.tab'; does not look like a sequence file

commit;

alter table stage.st_sequence alter column source set default null;
alter table stage.st_sequence alter column load_date set default null;

-- UNIPROT ----------------------------------------------------------------------------------------------------------------------

alter table stage.st_sequence alter column source set default 'UNIPROT';
alter table stage.st_sequence alter column load_date set default '20090418';

copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_uniprot-v14-9-_sprot-.tab';
copy stage.st_sequence ( header, sequence ) from 'c:\\db-dumps\\source_downloaded-2009-04-10_fasta_uniprot-v14-9-_tremb-.tab';

commit;

alter table stage.st_sequence alter column source set default null;
alter table stage.st_sequence alter column load_date set default null;

---------------------------------------------------------------------------------------------------------------------------------