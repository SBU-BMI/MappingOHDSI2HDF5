--In order to map the tables to JSON and then to HDF5 flatten the table

--create a denormalized tables for the main OHDSI table
--convert date and time separately to date / time

drop table if exists map2_person;
create table map2_person as 
select t.*, cast(to_char(cast(birth_date as date), 'J') as int) as birth_julian_day from (
  select p.*,
    cast(
      cast(p.year_of_birth as varchar(4)) || '-' || 
        right('0' || cast(p.month_of_birth as varchar(2)), 2) || '-' || 
        right('0' || cast(p.day_of_birth as varchar(2)), 2)
      as date) as birth_date,
    c1.concept_name as gender_concept_name,
    c1.concept_code as gender_concept_code,
    c2.concept_name as ethnicity_concept_name,
    c2.concept_code as ethnicity_concept_code,
    c3.concept_name as race_concept_name,
    c3.concept_code as race_concept_code
    from person p
    join concept c1 on c1.concept_id = p.gender_concept_id
    left outer join concept c2 on c2.concept_id = p.ethnicity_concept_id
    left outer join concept c3 on c3.concept_id = p.race_concept_id
    ) t
;

create unique index idx_map2_person_p_id on map2_person(person_id);

drop table if exists map2_observation_period;

create table map2_observation_period as
select *,
  cast(to_char(cast(min_observation_period_start_date as date), 'J') as int) as min_observation_period_start_julian_day,
  cast(to_char(cast(max_observation_period_end_date as date), 'J') as int) as max_observation_period_end_julian_day
from (
select person_id, min(observation_period_start_date) as min_observation_period_start_date,
  max(observation_period_end_date) as max_observation_period_end_date from observation_period op
  group by person_id) t;

create unique index idx_map2_obs_per_p_id on map2_observation_period(person_id);

drop table if exists map2_observation_period_visit_occurrence;
create table map2_observation_period_visit_occurrence as 
  select mop.*, vo.visit_occurrence_id from map2_observation_period mop
    join visit_occurrence vo on mop.person_id = vo.person_id
  ;

--TODO: left outer join provider
--TODO: left outer join location

drop table if exists map2_death;
create table map2_death as
  select d.*, c.concept_name as death_type_concept_name,
    cast(to_char(cast(d.death_date as date), 'J') as int) as death_julian_day
  from death d join concept c on d.death_type_concept_id = c.concept_id
;
create unique index idx_map2_death_p_id on map2_death(person_id);
drop table if exists map2_death_visit_occurrence;
create table map2_death_visit_occurrence as
  select md.*, vo.visit_occurrence_id from map2_death md join visit_occurrence vo on md.person_id = vo.person_id
    where death_datetime >= vo.visit_start_datetime and death_datetime <= vo.visit_end_datetime+ '6 hour'::interval
;


drop table if exists map2_visit_occurrence;
create table map2_visit_occurrence as
select *, cast(floor(age_at_visit_start_in_years_fraction) as int) as age_at_visit_start_in_years_int from (
  select tt.*,
    (visit_start_julian_day - birth_julian_day) / 365.25 as age_at_visit_start_in_years_fraction ,
     visit_start_julian_day - birth_julian_day as age_at_visit_start_in_days
  from (
    select t.*,
      cast(to_char(cast("visit_start_date" as date), 'J') as int) as visit_start_julian_day,
      cast(to_char(cast("visit_end_date" as date), 'J') as int) as visit_end_julian_day from (
      select vo.*,
      c1.concept_name as visit_concept_name,
      c1.concept_code as visit_concept_code,
      c2.concept_name as visit_type_concept_name,
      c2.concept_code as visit_type_concept_code,
      c3.concept_name as admitting_source_concept_name,
      c4.concept_name as discharge_to_concept_name,
      cs.care_site_name
      from visit_occurrence vo
          left outer join care_site cs on cs.care_site_id = vo.care_site_id
          join concept c1 on vo.visit_concept_id = c1.concept_id
          join concept c2 on vo.visit_type_concept_id = c2.concept_id
          left outer join concept c3 on vo.admitting_source_concept_id = c3.concept_id
          left outer join concept c4 on vo.discharge_to_concept_id = c4.concept_id
          ) t) tt
        join map2_person mp on mp.person_id = tt.person_id) ttt
        ;

create unique index idx_map2_visit_occur_id on map2_visit_occurrence(visit_occurrence_id);

drop table if exists map2_person_visit_occurrence;
create table map2_person_visit_occurrence as 
  select vo.visit_occurrence_id, p.* from visit_occurrence vo
    join map2_person p on vo.person_id = p.person_id
;

drop table if exists map2_visit_detail;
create table map2_visit_detail as
select vd.*, c1.concept_name as visit_detail_concept_name, cs.care_site_name
  from visit_detail vd
    join concept c1 on vd.visit_detail_concept_id = c1.concept_id
    left outer join care_site cs on cs.care_site_id = vd.care_site_id
;

drop table if exists map2_visit_occurrence_payer_plan;
create table map2_visit_occurrence_payer_plan as 
  select distinct vo.visit_occurrence_id, ppp.plan_source_value from payer_plan_period ppp
    join visit_occurrence vo on ppp.person_id = vo.person_id
      and vo.visit_start_date = ppp.payer_plan_period_start_date
    order by vo.visit_occurrence_id, ppp.plan_source_value
;

drop table if exists map2_condition_occurrence;
create table map2_condition_occurrence as
select *, cast(floor(tt.condition_start_age_in_years_fraction) as int) as condition_start_age_in_years_int from (
  select t.*,  (condition_start_julian_day - p.birth_julian_day) / 365.25 as condition_start_age_in_years_fraction,
    (condition_start_julian_day - p.birth_julian_day) as condition_start_age_in_days
  from (
    select co.*,
      cast(to_char(cast(co.condition_start_date as date), 'J') as int) as condition_start_julian_day,
      c1.concept_name as condition_source_concept_name,
      c1.concept_code as condition_source_concept_code,
      c1.vocabulary_id as condition_source_vocabulary_id,
      c2.concept_name as condition_concept_name,
      c2.concept_code as condition_concept_code,
      c2.vocabulary_id as condition_vocabulary_id,
      c3.concept_name as condition_type_name,
      c3.concept_code as condition_type_concept_code,
      c4.concept_name as condition_status_concept_name,
      c4.concept_code as condition_status_concept_code
    from condition_occurrence co 
      join concept c1 on c1.concept_id = co.condition_source_concept_id
      join concept c2 on c2.concept_id = co.condition_concept_id
      join concept c3 on c3.concept_id = co.condition_type_concept_id
      left outer join concept c4 on c4.concept_id = co.condition_status_concept_id
      ) t
      join map2_person p on p.person_id = t.person_id) tt
    ;

create index idx_map2_cond_occur on map2_condition_occurrence(visit_occurrence_id);

drop table if exists map2_procedure_occurrence;
create table map2_procedure_occurrence as 
  select tt.*, floor(tt.procedure_age_in_years_fraction) as procedure_age_in_years_int from (
    select t.*, (procedure_julian_day - p.birth_julian_day) / 365.25 as procedure_age_in_years_fraction,
      (procedure_julian_day - p.birth_julian_day) as procedure_age_in_days,
       procedure_julian_day - visit_start_julian_day as procedure_day_of_visit
    from (
      select po.*, 
        cast(to_char(cast(po.procedure_date as date), 'J') as int) as procedure_julian_day,
        c1.concept_name as procedure_source_concept_name, 
        c1.concept_code as procedure_source_concept_code,
        c1.vocabulary_id as procedure_source_vocabulary_id,
        c2.concept_name as procedure_concept_name,
        c2.concept_code as procedure_concept_code,
        c2.vocabulary_id as procedure_vocabulary_id,
        c3.concept_name as procedure_type_concept_name,
        c3.concept_code as procedure_type_concept_code,
        c4.concept_name as modifier_concept_name,
        c4.concept_code as modifier_concept_code,
        c4.vocabulary_id as modifier_concept_vocabulary_id,
        vo.visit_start_julian_day
        from procedure_occurrence po
        join map2_visit_occurrence vo on vo.visit_occurrence_id = po.visit_occurrence_id
        join concept c1 on c1.concept_id = po.procedure_source_concept_id
        join concept c2 on c2.concept_id = po.procedure_concept_id
        join concept c3 on c3.concept_id = po.procedure_type_concept_id
        left outer join concept c4 on c4.concept_id = po.modifier_concept_id) t
        join map2_person p on t.person_id = p.person_id        
        ) tt
        ;
        
create index idx_map2_proc_occur on map2_procedure_occurrence(visit_occurrence_id);

drop table if exists map2_observation;
create table map2_observation as
select tt.*,
  floor(tt.observation_age_in_years_fraction) as observation_age_in_years_int
from (
  select t.*,
    case when has_value_as_number = 0 and has_value_as_concept = 1 then 1 else 0 end as has_value_as_concept_only,
    (t.observation_julian_day - p.birth_julian_day) / 365.25 as observation_age_in_years_fraction, 
    (t.observation_julian_day - p.birth_julian_day) as observation_age_in_days,
    observation_julian_day - visit_start_julian_day as observation_day_of_visit,
    extract(epoch from observation_datetime) as observation_epoch
    from (
    select o.*,
          cast(to_char(cast(o.observation_date as date), 'J') as int) as observation_julian_day,
          c1.concept_name as observation_source_concept_name, 
          c1.concept_code as observation_source_concept_code,
          c1.vocabulary_id as source_vocabulary_id,
          c2.concept_name as observation_concept_name,
          c2.concept_code as observation_concept_code,
          c2.vocabulary_id as concept_vocabulary_id,
          c3.concept_name as value_as_concept_name,
          c3.concept_code as value_as_concept_code,
          c3.vocabulary_id as value_as_concept_vocabulary_id,
          c4.concept_name as unit_concept_name,
          c4.concept_code as unit_concept_code,
          c4.vocabulary_id as unit_concept_vocabulary_id,
          c5.concept_name as qualifier_concept_name,
          vo.visit_start_julian_day,
          case when o.value_as_number is not null then 1 else 0 end has_value_as_number,
          case when c3.concept_code is not null then 1 else 0 end as has_value_as_concept
    from observation o
    join map2_visit_occurrence vo on vo.visit_occurrence_id = o.visit_occurrence_id
    join concept c1 on o.observation_source_concept_id = c1.concept_id
    join concept c2 on o.observation_concept_id = c2.concept_id
    left outer join concept c3 on o.value_as_concept_id = c3.concept_id
    left outer join concept c4 on o.unit_concept_id = c4.concept_id 
    left outer join concept c5 on o.qualifier_concept_id = c5.concept_id) t
   join map2_person p on t.person_id = p.person_id) tt
;

create index idx_map2_observation on map2_observation(visit_occurrence_id);

drop table if exists map2_measurement;
create table map2_measurement as 
select tt.*,
  floor(tt.measurement_age_in_years_fraction) as measurement_age_in_years_int
from (
  select t.*,
   case when has_value_as_number = 0 and has_value_as_concept = 1 then 1 else 0 end as has_value_as_concept_only,
    (t.measurement_julian_day - p.birth_julian_day) / 365.25 as measurement_age_in_years_fraction,
    (t.measurement_julian_day - p.birth_julian_day) as measurement_age_in_days,
     t.measurement_julian_day - visit_start_julian_day as measurement_day_of_visit,
     extract(epoch from measurement_datetime) as measurement_epoch
  from (
  select m.*,
        cast(to_char(cast(m.measurement_date as date), 'J') as int) as measurement_julian_day,
        c1.concept_name as measurement_source_concept_name,
        c1.concept_code as measurement_source_concept_code,
        c1.vocabulary_id as source_vocabulary_id,
        c2.concept_name as measurement_concept_name,
        c2.concept_code as measurement_concept_code,
        c2.vocabulary_id as concept_vocabulary_id,
        c3.concept_name as value_as_concept_name,
        c3.concept_code as value_as_concept_code,
        c3.vocabulary_id as value_as_concept_vocabulary_id,
        c4.concept_name as unit_concept_name,
        c4.concept_code as unit_concept_code,
        c4.vocabulary_id as unit_concept_vocabulary_id,
        c5.concept_name as operator_concept_name,
        vo.visit_start_julian_day,
        case when m.value_as_number is not null then 1 else 0 end has_value_as_number,
        case when c3.concept_code is not null then 1 else 0 end as has_value_as_concept
  from measurement m
  join map2_visit_occurrence vo on vo.visit_occurrence_id = m.visit_occurrence_id
  join concept c1 on m.measurement_source_concept_id = c1.concept_id
  join concept c2 on m.measurement_concept_id = c2.concept_id
  left outer join concept c3 on m.value_as_concept_id = c3.concept_id
  left outer join concept c4 on m.unit_concept_id = c4.concept_id 
  left outer join concept c5 on m.operator_concept_id = c5.concept_id) t
  join map2_person p on p.person_id = t.person_id) tt
  ;

create index idx_map2_measurement on map2_measurement(visit_occurrence_id);
 

drop table if exists map2_atc2_concepts;
create table map2_atc2_concepts as
select
	drug.concept_id as drug_concept_id,
	drug.concept_name as drug_concept_name,
	atc2.concept_id as atc2_concept_id,
	atc2.concept_name as atc2_concept_name,
  atc2.concept_code as atc2_concept_code
from (
	select concept_id, concept_name
	from concept
	where standard_concept = 'S'
	  and domain_id = 'Drug'
	  and invalid_reason is null
) drug
inner join concept_ancestor ca on drug.concept_id = ca.descendant_concept_id
inner join (
	select concept_id, concept_name, concept_code
	from concept
	where vocabulary_id = 'ATC'
	  and concept_class_id = 'ATC 2nd'
	  and invalid_reason is null
)  atc2 on ca.ancestor_concept_id = atc2.concept_id;


drop table if exists map2_atc3_concepts;
create table map2_atc3_concepts as
select
	drug.concept_id as drug_concept_id,
	drug.concept_name as drug_concept_name,
	atc3.concept_id as atc3_concept_id,
	atc3.concept_name as atc3_concept_name,
    atc3.concept_code as atc3_concept_code
from (
	select concept_id, concept_name
	from concept
	where standard_concept = 'S'
	  and domain_id = 'Drug'
	  and invalid_reason is null
) drug
inner join concept_ancestor ca on drug.concept_id = ca.descendant_concept_id
inner join (
	select concept_id, concept_name, concept_code
	from concept
	where vocabulary_id = 'ATC'
	  and concept_class_id = 'ATC 3rd'
	  and invalid_reason is null
)  atc3 on ca.ancestor_concept_id = atc3.concept_id;

drop table if exists map2_atc4_concepts;
create table map2_atc4_concepts as
select
	drug.concept_id as drug_concept_id,
	drug.concept_name as drug_concept_name,
	atc4.concept_id as atc4_concept_id,
	atc4.concept_name as atc4_concept_name,
  atc4.concept_code as atc4_concept_code
from (
	select concept_id, concept_name
	from concept
	where standard_concept = 'S'
	  and domain_id = 'Drug'
	  and invalid_reason is null
) drug
inner join concept_ancestor ca on drug.concept_id = ca.descendant_concept_id
inner join (
	select concept_id, concept_name, concept_code
	from concept
	where vocabulary_id = 'ATC'
	  and concept_class_id = 'ATC 4th'
	  and invalid_reason is null
)  atc4 on ca.ancestor_concept_id = atc4.concept_id;

drop table if exists map2_atc5_concepts;
create table map2_atc5_concepts as
select
	drug.concept_id as drug_concept_id,
	drug.concept_name as drug_concept_name,
	atc5.concept_id as atc5_concept_id,
	atc5.concept_name as atc5_concept_name,
  atc5.concept_code as atc5_concept_code
from (
	select concept_id, concept_name
	from concept
	where standard_concept = 'S'
	  and domain_id = 'Drug'
	  and invalid_reason is null
) drug
inner join concept_ancestor ca on drug.concept_id = ca.descendant_concept_id
inner join (
	select concept_id, concept_name, concept_code
	from concept
	where vocabulary_id = 'ATC'
	  and concept_class_id = 'ATC 5th'
	  and invalid_reason is null
)  atc5 on ca.ancestor_concept_id = atc5.concept_id
;

drop table if exists map2_atc5_flattened;
create table map2_atc5_flattened as
select * from (
    select drug_concept_id, array_agg(distinct atc5_concept_code) as array_atc5_concept_codes,
           string_agg(distinct atc5_concept_code, '||' order by atc5_concept_code) as atc5_concept_codes,
           string_agg(distinct atc5_concept_code || '|' ||  atc5_concept_name, '||'
               order by  atc5_concept_code || '|' ||  atc5_concept_name) as atc5_concept_codes_with_descriptions
    from sbm_covid19_hi_cdm_build.map2_atc5_concepts group by drug_concept_id) t order by atc5_concept_codes
;

drop table if exists map2_drug_exposure;
create table map2_drug_exposure as
  select tt.*, floor(drug_exposure_start_age_in_years_fraction) as drug_exposure_start_age_in_years_int from (
    select t.*,
        (t.drug_exposure_start_julian_day - p.birth_julian_day) / 365.25 as drug_exposure_start_age_in_years_fraction,
        (t.drug_exposure_start_julian_day - p.birth_julian_day) as drug_exposure_start_age_in_days,
        drug_exposure_start_julian_day - visit_start_julian_day as drug_exposure_day_of_visit
    from (
      select de.*,
        cast(to_char(cast(de.drug_exposure_start_date as date), 'J') as int) as drug_exposure_start_julian_day,
        cast(to_char(cast(de.drug_exposure_end_date as date), 'J') as int) as drug_exposure_end_julian_day,
        c1.concept_name as drug_concept_source_name,
        c1.concept_code as drug_concept_source_code,
        c1.vocabulary_id as drug_concept_source_vocabulary_id,
        c2.concept_name as drug_concept_name,
        c2.concept_code as drug_concept_code,
        c2.vocabulary_id as drug_concept_vocabulary_id,
        c3.concept_name as drug_type_concept_name,
        c3.concept_code as drug_type_concept_code,
        c3.vocabulary_id as drug_type_concept_vocabulary_id,
        c4.concept_name as route_concept_name,
        c4.concept_code as route_concept_code,
        c4.vocabulary_id as route_concept_vocabulary_id,
        vo.visit_start_julian_day,
        m2a5f.atc5_concept_codes,
        m2a5f.atc5_concept_codes_with_descriptions
      from drug_exposure de
        join map2_visit_occurrence vo on vo.visit_occurrence_id = de.visit_occurrence_id
        join concept c1 on c1.concept_id = de.drug_source_concept_id
        join concept c2 on c2.concept_id = de.drug_concept_id
        left outer join concept c3 on c3.concept_id = de.drug_type_concept_id
        left outer join concept c4 on c4.concept_id = de.route_concept_id
        left outer join map2_atc5_flattened m2a5f on de.drug_concept_id = m2a5f.drug_concept_id
    ) t join map2_person p on t.person_id = p.person_id) tt
    ;

create index idx_map2_drug_exposure on map2_drug_exposure(visit_occurrence_id);



drop table if exists map2_atc3_drug_exposure;
create table map2_atc3_drug_exposure as
select distinct ac.*, de.person_id, de.visit_occurrence_id from map2_atc3_concepts ac
  join drug_exposure de on ac.drug_concept_id = de.drug_concept_id;

drop table if exists map2_atc4_drug_exposure;
create table map2_atc4_drug_exposure as
select distinct ac.*, de.person_id, de.visit_occurrence_id from map2_atc4_concepts ac
  join drug_exposure de on ac.drug_concept_id = de.drug_concept_id;

drop table if exists map2_atc5_drug_exposure;
create table map2_atc5_drug_exposure as
select distinct ac.*, de.person_id, de.visit_occurrence_id from map2_atc5_concepts ac
  join drug_exposure de on ac.drug_concept_id = de.drug_concept_id;

drop table if exists map2_atc5_flattened_drug_exposure;
create table map2_atc5_flattened_drug_exposure as
select distinct de.person_id, de.visit_occurrence_id, de.atc5_concept_codes, de.atc5_concept_codes_with_descriptions,
                de.drug_exposure_start_datetime
                from map2_drug_exposure de
  where de.atc5_concept_codes is not null;
;

drop table if exists map2_drug_ingredients;
create table map2_drug_ingredients as
with drug_ingredients as (
  select
  	drug.concept_id as drug_concept_id,
  	drug.concept_name as drug_concept_name,
    drug.concept_code as drug_concept_code,
  	ing.concept_id as ingredient_concept_id,
  	ing.concept_name as ingredient_concept_name,
    ing.concept_code as ingredient_concept_code
  from (
  	select concept_id, concept_name, concept_code
  	from concept
  	where standard_concept = 'S'
  	  and domain_id = 'Drug'
  	  and invalid_reason is null
  ) drug
  inner join concept_ancestor ca on drug.concept_id = ca.descendant_concept_id
  inner join (
  	select concept_id, concept_name, concept_code
  	from concept
  	where vocabulary_id = 'RxNorm'
  	  and concept_class_id = 'Ingredient'
  	  and invalid_reason is null
  )  ing on ca.ancestor_concept_id = ing.concept_id)
select drug_concept_id, drug_concept_code,drug_concept_name, count(distinct ingredient_concept_code) as n_ingredients,
  array_agg(distinct ingredient_concept_name) as ingredient_concept_names, array_agg(distinct ingredient_concept_code) as ingredient_concept_codes,
  array_agg(distinct ingredient_concept_id) as ingredient_concept_ids
from drug_ingredients
group by drug_concept_id, drug_concept_code,drug_concept_name;


drop table if exists map2_condition_occurrence_hierarchy;
create table map2_condition_occurrence_hierarchy as
  select distinct visit_occurrence_id, person_id, c.concept_id as condition_concept_id,
    c.concept_name as condition_concept_name,
    c.concept_code as condition_concept_code
    from condition_occurrence co
    join concept_ancestor a on a.descendant_concept_id = co.condition_concept_id
    join concept c on c.concept_id = a.ancestor_concept_id
  ;
  
  
drop table if exists  map2_measurement_numeric;
create table map2_measurement_numeric as
  select * from map2_measurement where has_value_as_number = 1;

drop table if exists  map2_measurement_categorical;
create table map2_measurement_categorical as
  select * from map2_measurement where has_value_as_concept_only = 1;
  

drop table if exists map2_observation_numeric;
create table map2_observation_numeric as
  select * from map2_observation where has_value_as_number = 1;

drop table if exists  map2_observation_categorical;
create table map2_observation_categorical as
  select * from map2_observation where has_value_as_concept_only = 1
  
;
