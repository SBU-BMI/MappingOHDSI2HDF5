echo "create schema synpuf5" | psql -h172.17.0.2 -Upostgres
psql -h172.17.0.2 -Upostgres < omop_cdm_schema_localized.sql 
psql -h172.17.0.2 -Upostgres < load_synthetic_data.sql 
psql -h172.17.0.2 -Upostgres < omop_cdm_vocabulary_load.sql 
psql -h172.17.0.2 -Upostgres < omop_cdm_indexes_localized.sql 
