# CoMLET: Collaborative Machine Learning Exploration Tool

CoMLET is a research tool for iPad that enables groups of people to collaboratively create image classification machine learning (ML) models. It supports an end-to-end, iterative ML modeling workflow that includes data collection and annotation, model training, and multiple methods for model testing. Users can collaborate on ML modeling projects, working together to build datasets that reflect varieties of life experiences and circumstances. Users' project data automatically sync between devices using [end-to-end encryption via Apple CloudKit](https://developer.apple.com/documentation/cloudkit/encrypting-user-data). Training happens on-device using [Create ML](https://developer.apple.com/documentation/createml/).

This code accompanies the following research papers:

**[Co-ML: Collaborative Machine Learning Model Building for Developing Dataset Design Practices](https://machinelearning.apple.com/research/coml)**
> Tseng, T., Davidson, M. J., Morales-Navarro, L., Chen, J. K., Delaney, V., Leibowitz, M., Beason, J. & Shapiro, R. B. (2024). Co-ML: Collaborative machine learning model building for developing dataset design practices. *ACM Transactions on Computing Education*, *24*(2), 1-37.

**[Collaborative Machine Learning Model Building with Families Using Co-ML](https://machinelearning.apple.com/research/collaborative-machine-learning)**
> Tseng, T., King Chen, J., Abdelrahman, M., Kery, M. B., Hohman, F., Hilliard, A., & Shapiro, R. B. (2023). Collaborative machine learning model building with families using Co-ML. In *Proceedings of the 22nd annual ACM interaction design and children conference* (pp. 40-51). **Best paper honorable mention.**


## How to Build and Run this Code

### Requirements

* Use Xcode 26.4 (build 17E192) or later.
* This code has no dependencies other than the iOS SDK.
* It cannot run inside the iOS Simulator and requires an [Apple Developer Account](https://developer.apple.com) and an iPad.

### Build Instructions

1. In Xcode, open `CoML.xcodeproj`
2. Navigate to the Signing and Capabilities tab
    1. Ensure that you have a valid Team selected.
    2. Change the bundle identifier to suit your organization. This must be globally unique (per team), as it is used for CloudKit storage.
3. If you want to use CloudKit sync capabilities (for multi-user or multi-device sync):
    1. Import the CloudKit schema from `ckschema.ckdb` via the [CloudKit Database Dashboard](https://icloud.developer.apple.com) to a container with a name matching the bundle identifier you selected. 
    2. Update `Supporting Files/CoMLApp.entitlements`, `Supporting Files/CoMLApp Release.entitlements`, and `Sources/StorageServices/DatabaseStorageService/CoreDataStorageService/CoreDataStackImpl.swift` with the new bundle id. 
4. Select an iPad (not a simulator) as your target
5. Build and Run

## Contributing

We welcome community-led forks of this project.
As this code is the result of a concluded research project, Apple is unlikely to release further updates to it.

## How to Cite this Code

To cite this tool, please use:

> Tseng, T., Shapiro, R. B., Harper, D., Brown, E., Kery, M. B., Smith, G., Navas, N., Durant, J., Beason, J., Lu, E., & Ralston, S. (2026). *CoMLET: Collaborative Machine Learning Exploration Tool.* [https://github.com/apple/ml-comlet](https://github.com/apple/ml-comlet).

As BibTeX:

```bibtex
@misc{Tseng2026comlet,
  author = {Tiffany Tseng and R. Benjamin Shapiro and Dave Harper and Exandra Brown and Mary Beth Kery and Griffin Smith and Nadiya Navas and John Durant and Jazbo Beason and Elaine Lu and Stuart Ralston},
  title = {CoMLET},
  year  = {2026},
  url   = {https://github.com/apple/ml-comlet},
}
```

## License

This code is released under the [Apple Sample Code License](LICENSE).
