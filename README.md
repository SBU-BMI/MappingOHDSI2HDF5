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
keys of ’visit_occurrence_id’. The SQL script can be executed in an editor or using the 
program ’execute_sql.py’ which requires a SQLAlchemy connection string.

## Mapping to JSON documents

Before running the mapping script the `runtime_config.example.json` needs to copied
to `runtime_config.json`. The filemust be edited to include database connection
properties.

```bash
python  ../../TransformDBtoHDF5ML/scripts/build_document_mapping_from_db.py -c ohdsi_db_2_json.json -r runtime_config.json
```

Each visit/encounter document contains information about a visit: conditions, observations,
procedures, measurements, and drug exposures. The document is keyed by the ’visit_occurrence_id’ and
each JSON file contains a subset of documents. The JSON file is nearly human readable and it is good idea to
review the document to determine if the data is mapped. For large datasets the 
uJSON library should be utilized to optimize file writing. The JSON files can get large and gzip compression will help save 
file storage space. Both these options can be set in the ’runtime_config.json’ file.

In addition to the JSON documents two other type of files are generated. The key order files stores the order of the visit_occurrences. For the OHDSI mappings the order is by ’person_id’ and then by the start date of the visit.



## Mapping to HDF5
