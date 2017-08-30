
/*********************************************************************************
# Copyright 2016 Observational Health Data Sciences and Informatics
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
********************************************************************************/

\COPY synpuf5.CARE_SITE FROM '~/data/ohdsi_synpuf/files/care_site_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.CONDITION_OCCURRENCE FROM '~/data/ohdsi_synpuf/files/condition_occurrence_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.DEATH FROM '~/data/ohdsi_synpuf/files/death_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.DEVICE_COST FROM '~/data/ohdsi_synpuf/files/device_cost_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.DRUG_COST FROM '~/data/ohdsi_synpuf/files/drug_cost_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.DRUG_EXPOSURE FROM '~/data/ohdsi_synpuf/files/drug_exposure_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.DEVICE_EXPOSURE FROM '~/data/ohdsi_synpuf/files/device_exposure_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.LOCATION FROM '~/data/ohdsi_synpuf/files/location_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.MEASUREMENT FROM '~/data/ohdsi_synpuf/files/measurement_occurrence_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.OBSERVATION FROM '~/data/ohdsi_synpuf/files/observation_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.PERSON FROM '~/data/ohdsi_synpuf/files/person_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.PROCEDURE_OCCURRENCE FROM '~/data/ohdsi_synpuf/files/procedure_occurrence_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.PROCEDURE_COST FROM '~/data/ohdsi_synpuf/files/procedure_cost_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.PROVIDER FROM '~/data/ohdsi_synpuf/files/provider_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.SPECIMEN FROM '~/data/ohdsi_synpuf/files/specimen_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.VISIT_COST FROM '~/data/ohdsi_synpuf/files/visit_costs_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.VISIT_OCCURRENCE FROM '~/data/ohdsi_synpuf/files/visit_occurrence_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.OBSERVATION_PERIOD FROM '~/data/ohdsi_synpuf/files/observation_period_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
\COPY synpuf5.PAYER_PLAN_PERIOD FROM '~/data/ohdsi_synpuf/files/payer_plan_period_1.csv' WITH DELIMITER E',' CSV HEADER QUOTE E'\b';
