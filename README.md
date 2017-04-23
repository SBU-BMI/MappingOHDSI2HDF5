# MappingOHDSI2HDF5

## Overview

This project contains  JSON mappings for mapping OHDSI (V5) tables to HDF5 
for machine learning and data mining applications. They use the scripts in
[https://github.com/jhajagos/TransformDBtoHDF5ML]
which requires that your data is in either a SQLite or a PostGreSQL database.
The software requires the h5py library to run which is part of the easy to 
install Anaconda Python distribution.

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
numeric matrix and labels it is possible to build complete health care machine learning
analyses.

## Generate map2 tables

## Mapping to JSON


## Mapping to HDF5
