# URL Generator

This service generates URLs corresponding to on-disk file locations as required
for training and data storage.

## Dependencies

This service is leveraged by `TrainingServiceImpl` and
`DatasetsRepositoryImpl`. The training service uses this to access files that
have been stored in preparation for training, while the datasets repository
uses this service to perform such preparation.
