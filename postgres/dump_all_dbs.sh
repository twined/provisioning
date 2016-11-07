# Dump all databases
pg_dumpall -U postgres -h localhost -p 5432 --clean | gzip > database_cluster_dump.gz
