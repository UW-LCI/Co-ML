# DatasetsRepository

A repository that provides an interface to underlying storage of the datasets
required for training.

## Dependencies

For now, this repository is leveraged by training coordinators, allowing such
entities to retrieve data sets that are required for training. These data sets
are currently limited to those needed for image classification.

## Future dependencies

This repository may be leveraged by photo capture coordinators and/or image
annotation coordinators, allowing such entities to declare a link between data
and data annotation in preparation for later training.
