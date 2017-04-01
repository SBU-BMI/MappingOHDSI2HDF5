# MappingOHDSI2HDF5

This project contains  JSON mappings for mapping OHDSI (V5) tables to HDF5 
for machine learning and data mining applications. They use the tool [https://github.com/jhajagos/TransformDBtoHDF5ML] 
which requires that you have the data in either a SQLite database or a PostGReSQL database.
The software requires the h5py library to run which is part of the easy to 
install Anaconda Python distribution.

HDF5 allows numerical matrices to be organized in a hierarchical fashion:
```
/ohdsi/measurement
/ohdsi/observation
```

The mapping of a table are stored in three separate matrices, as an example,
```
/ohdsi/measurement/core_array
/ohdsi/measurement/column_annotations
/ohdsi/measuremement/colunm_header
```
The first matrix is of a numeric type and contains the encoded data. 
The second matrix contains strings and provides annotations or labels of the 
data, and the third contains the 