cat <<EOF | mysql -p -h $CELLWALL_HOST $CELLWALL_DB
drop table if exists dblink;
drop table if exists comment;
drop table if exists blast_hsp;
drop table if exists subfamily;
drop table if exists idxref;
drop table if exists seqtags;
drop table if exists seqlocation;
drop table if exists seqfeature;
drop table if exists sequence;
drop table if exists family;
drop table if exists blast_hit;
drop table if exists users;
drop table if exists species;
drop table if exists search;
drop table if exists db;
drop table if exists parameters;
drop table if exists groups;
drop table if exists genome;
EOF
