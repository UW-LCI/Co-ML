# Services

Services are __stateless__ entities, which may depend on URL sessions or the filesystem, and provide APIs to entities that may depend on them. Services may be depended upon by `Repositories`, or directly by `ViewModels` or other instances.

Services may __publish__ changes to underlying systems they observe, but most of their interfaces will likely be query-based.

Services may or may not include the following:
- ****asynchronous**** APIs which provide on-disk values when available.
- ****asynchronous**** APIs which provide server-side values when available.
- ****published**** properties or callbacks that may be observed or responded to.

## Usage

Services may be directly queried by `ViewModel` entities, but should never be queried directly by `Views`.
