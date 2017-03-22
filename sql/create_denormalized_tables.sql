--Inorder to map the tables to JSON and then to HDF5 flatten the table

--create a denormalized tables for the main OHDSI table
--convert date and time separately to date / time
--convert date to Julian day

create table map2_visit_occurrence as 
  select vo.*, c1.concept_name as visit_concept_name, c2.concept_name as visit_type_concept_name,
    cast(cast(vo.visit_start_date as varchar(10)) || ' ' || vo.visit_start_time as timestamp) as visit_start_date_time,
    cast(cast(vo.visit_end_date as varchar(10)) || ' ' || vo.visit_end_time as timestamp) as visit_end_date_time
    from visit_occurrence vo 
      join concept c1 on vo.visit_concept_id = c1.concept_id
      join concept c2 on vo.visit_type_concept_id = c2.concept_id;