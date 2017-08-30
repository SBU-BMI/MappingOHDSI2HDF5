## Running the notebooks

It is assumed that you have the 
[Anaconda Python distribution](https://www.anaconda.com/download/) installed.
In your commandline shell start the Jupyter notebook server in the `./notebooks/` directory:

```bash
cd ./notebooks/
jupyter notebook
```

First run the notebook  `build_flat_readmission_hdf5.ipnyb` to build the
`inpatient_readmission_analysis.hdf5` file. This file creates two data sets 
`/independent/core_array` and `/dependent/core_array` where the value of `1` 
indicates that the patient was readmitted in 30 days. The second notebook 
`readmission_predictive_model_build.ipynb` builds a predictive data. A third notebook 
explores the content of the HDF5 container: `explore_inpatient_synpuf_analysis.ipynb`

## Steps to generate the HDF5 file used in the example 

This describes the process which was used to build the HDF5 file. You do not need to run this
to run the notebooks. The steps are provided below as a reference.

Steps to generate the HDF5 file `synpuf_inpatient_readmission.hdf5` for the notebook 
examples.  This was run on an Ubuntu Linux virtual machine with the standard PostGreSQL docker image 
with an IP address of `172.17.0.2`. 
The CDM vocabulary files should be in `~/data/ohdsi_synpuf/vocabulary/` and the SYNPUF files
should be in `~/data/ohdsi_synpuf/files/`.

Building the database:
```bash
echo "create schema synpuf5" | psql -h172.17.0.2 -Upostgres
psql -h172.17.0.2 -Upostgres < omop_cdm_schema_localized.sql 
psql -h172.17.0.2 -Upostgres < load_synthetic_data.sql 
psql -h172.17.0.2 -Upostgres < omop_cdm_vocabulary_load.sql 
```

Export inpatient visits to JSON documents:
```bash
cd ~/github/MappingOHDSI2HDF5/mappings
python ~/github/TransformDBtoHDF5ML/scripts/build_document_mapping_from_db.py -r runtime_config.inpatient.json -c ohdsi_db_2_json.json
```

Export JSON documents to HDF5:
```bash
cd ~/github/MappingOHDSI2HDF5/mappings/
python ~/github/TransformDBtoHDF5ML/scripts/build_hdf5_matrix_from_document.py -a synpuf_inpatient -c ohdsi_json_2_hdf5.json -b ~/data/ohdsi2hdf5/ohdsi_mapped_batches.json 
```

Apply the post processing steps:
```bash
cp synpuf_inpatient_combined.hdf5 synpuf_inpatient_combined_readmission.hdf5
python ../post_process/next_visit_occurrence.py -f synpuf_inpatient_combined_readmission.hdf5
python ../post_process/add_past_history.py -f synpuf_inpatient_combined_readmission.hdf5 -p /computed/next/30_days/visit_occurrence/

# Optional for past history
#python ../post_process/add_past_history.py -f synpuf_inpatient_combined_readmission.hdf5 -p /ohdsi/condition_occurrence/
#python ../post_process/add_past_history.py -f synpuf_inpatient_combined_readmission.hdf5 -p /ohdsi/procedure_occurrence/

#python ../post_process/add_past_history.py -f synpuf_inpatient_combined_readmission.hdf5 -p /computed/next/30_days/visit_occurrence/
#python ../post_process/add_past_history.py -f synpuf_inpatient_combined_readmission.hdf5-p /ohdsi/visit_occurrence/
```

