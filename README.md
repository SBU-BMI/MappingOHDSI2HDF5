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
numeric matrix and labels it is possible to build and train machine learning.

## Generate map2 tables

## Mapping to JSON


The first step is to save `runtime_config.example.json` as `runtime_config.json`. The file
must be edited to include database connection properties.

```bash
python  ../../TransformDBtoHDF5ML/scripts/build_document_mapping_from_db.py -c ohdsi_db_2_json.json -r runtime_config.json
```

## Mapping to HDF5
