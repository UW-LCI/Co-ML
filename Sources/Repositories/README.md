# Repositories

Repositories are __stateful__ entities, which may depend on services, and hold in-memory references to the entities managed by those services. Repositories may encapsulate business logic ensuring that the entities they provide remain up to date, but they are not guaranteed to do so.

Repositories manage the two-way communication between view models and services, as well as listen to any updates coming from services like CoreData and CloudKit.

Repositories may or may not include the following:

  - ****synchronous**** APIs which can provide in-memory values that may not be up to date.
- ****asynchronous**** APIs which provide on-disk values when available.
- ****asynchronous**** APIs which provide server-side values when available.


## Usage

Repositories may be directly queried by `ViewModel` entities, but should never be queried directly by `Views`.
