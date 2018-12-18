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
  select md.*, vo.visit_occurrence_id from map2_death md join visit_occurrence vo on md.person_id = vo.person_id;

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
    (t.observation_julian_day - p.birth_julian_day) / 365.25 as observation_age_in_years_fraction, 
    (t.observation_julian_day - p.birth_julian_day) as observation_age_in_days,
    observation_julian_day - visit_start_julian_day as observation_day_of_visit
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
          vo.visit_start_julian_day
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
    (t.measurement_julian_day - p.birth_julian_day) / 365.25 as measurement_age_in_years_fraction, 
    (t.measurement_julian_day - p.birth_julian_day) as measurement_age_in_days,
     t.measurement_julian_day - visit_start_julian_day as measurement_day_of_visit
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
        vo.visit_start_julian_day
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
        vo.visit_start_julian_day
      from drug_exposure de
        join map2_visit_occurrence vo on vo.visit_occurrence_id = de.visit_occurrence_id
        join concept c1 on c1.concept_id = de.drug_source_concept_id
        join concept c2 on c2.concept_id = de.drug_concept_id
        left outer join concept c3 on c3.concept_id = de.drug_type_concept_id
        left outer join concept c4 on c4.concept_id = de.route_concept_id
    ) t join map2_person p on t.person_id = p.person_id) tt 
    ;

create index idx_map2_drug_exposure on map2_drug_exposure(visit_occurrence_id);

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
  atc4.concept_code as atc4_cocept_code
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


drop table if exists map2_atc3_drug_exposure;
create table map2_atc3_drug_exposure as
select distinct ac.*, de.person_id, de.visit_occurrence_id from map2_atc3_concepts ac
  join drug_exposure de on ac.drug_concept_id = de.drug_concept_id;


create table map2_atc4_drug_exposure as
select distinct ac.*, de.person_id, de.visit_occurrence_id from map2_atc4_concepts ac
  join drug_exposure de on ac.drug_concept_id = de.drug_concept_id;
