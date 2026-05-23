fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios certs

```sh
[bundle exec] fastlane ios certs
```

Sync certificates and provisioning profiles from match repository

### ios build

```sh
[bundle exec] fastlane ios build
```

Build a signed App Store IPA using Flutter

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload the latest IPA to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Upload the latest IPA to App Store Connect production

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
