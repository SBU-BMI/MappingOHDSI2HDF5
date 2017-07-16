# MappingOHDSI2HDF5

## Overview

This project contains JSON mappings for mapping OHDSI (V5.0) tables to HDF5 
for machine learning and data mining applications. The mappings require scripts that
are part of
[https://github.com/jhajagos/TransformDBtoHDF5ML] project. The OHDSI schema data must
be in a PostGreSQL database.
The transformation program requires the h5py library to run which is part of 
the easy to install Anaconda Python distribution.

HDF5 allows numerical matrices to be organized in a hierarchical fashion:
```
/ohdsi/measurement
/ohdsi/observation
```

The mapping of a single table are stored in three separate matrices, as an example,
```
/ohdsi/measurement/core_array
/ohdsi/measurement/column_annotations
/ohdsi/measuremement/colunm_header
```
The first matrix is of a numeric type and contains the encoded data. 
The second matrix contains strings and provides annotations or labels of the 
data, and the third contains the labels for the column annotations. Using the primary 
numeric matrix and labels it is possible to build and train machine learning algorithms.

## Generate map2 tables

The first step is to build additional tables in the PostGreSQL database that will be used for
the mapping. The map2 tables are  denormalized versions of the OHDSI tables that haves primary 
keys of ’visit_occurrence_id’. The SQL script can be executed in an editor or using the program ’execute_sql.py’.

## Mapping to JSON documents

The first mapping step is to save `runtime_config.example.json` as `runtime_config.json`. The file
must be edited to include database connection properties.

```bash
python  ../../TransformDBtoHDF5ML/scripts/build_document_mapping_from_db.py -c ohdsi_db_2_json.json -r runtime_config.json
```

Each visit/encounter document contains information about a visit: conditions, observations, procedures, measurements, and
drug exposures. The document is keyed by the ’visit_occurrence_id’ and each JSON file comtains a subset of documents.

## Mapping to HDF5
