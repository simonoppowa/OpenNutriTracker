<p align="center">
  <img alt="Logo" src="assets/icon/ont_logo_square.png" width="128" />
  <h1 align="center">OpenNutriTracker</h1>
</p>

<p align="center">
  <a href="https://opensource.org/licenses/MIT" alt="License">
        <img src="https://img.shields.io/badge/license-GPLv3-blue" /></a>
  <a href="https://github.com/simonoppowa/OpenNutriTracker/stargazers" alt="GitHub Stars">
        <img src="https://img.shields.io/github/stars/simonoppowa/OpenNutriTracker.svg" /></a>
  <a href="https://github.com/simonoppowa/OpenNutriTracker/issues" alt="GitHub Issues">
        <img src="https://img.shields.io/github/issues/simonoppowa/OpenNutriTracker.svg" /></a>
  <a href="https://github.com/simonoppowa/OpenNutriTracker/pulls" alt="GitHub Pull Requests">
        <img src="https://img.shields.io/github/issues-pr/simonoppowa/OpenNutriTracker.svg" /></a>
</p>

## Description
OpenNutriTracker is an open-source mobile application designed to simplify nutritional tracking and management. Whether you are looking to improve your health, lose weight, or simply maintain a balanced diet, OpenNutriTracker provides a minimalistic interface to easily track and analyze your daily nutrition.

[Website](https://simonoppowa.github.io/OpenNutriTracker/)

## Screenshots
<p align="center">
  <img alt="Logo" src="fastlane/metadata/android/en-US/images/phoneScreenshots/1_en-US.png" width="20%" />
  &nbsp;&nbsp;
  <img alt="Logo" src="fastlane/metadata/android/en-US/images/phoneScreenshots/2_en-US.png" width="20%" />
  &nbsp;&nbsp;
  <img alt="Logo" src="fastlane/metadata/android/en-US/images/phoneScreenshots/3_en-US.png" width="20%" />
  &nbsp;&nbsp;
  <img alt="Logo" src="fastlane/metadata/android/en-US/images/phoneScreenshots/4_en-US.png" width="20%" />
</p>

## Install
[<img src="fastlane/metadata/android/en-US/images/appstore_banner.png" width="30%">](https://apps.apple.com/us/app/opennutritracker/id6451490901)
[<img src="fastlane/metadata/android/en-US/images/playstore_banner.png" width="30%">](https://play.google.com/store/apps/details?id=com.opennutritracker.ont.opennutritracker)

## Key Features
- **🍎 Nutritional Tracking:** Easily log your meals and snacks, and access a vast database of food items and ingredients to get detailed nutritional information.
- **📓 Food Diary:** Maintain a comprehensive food diary to keep track of your daily food consumption, habits, and progress.
- **🍽️ Custom Meals:** Plan your meals in advance, create personalized meal plans, and optimize them according to your dietary goals.
- **📷 Barcode Scanner:** Scan barcodes on packaged food items to instantly retrieve their nutritional information.
- **🔒 Privacy Focused:** OpenNutriTracker prioritizes the privacy its users. It does not collect or share any personal data without your consent.
- **🚫💰 No Subscription, In-App Purchases, or Ads:** OpenNutriTracker is completely free to use, without any subscription fees, in-app purchases, or intrusive advertisements.

## Privacy
See [Data Protection](https://www.iubenda.com/privacy-policy/53501884)
- **Data Encryption**: All collected user data is encrypted and stored locally on your device
- **Minimal Data Collection**: OpenNutriTracker only collects the necessary information required for tracking nutrition and providing personalized insights. Your data will not be shared with third parties without your consent.
- **Open-Source**: OpenNutriTracker is an open-source application

## TODOs
- ~~Add serving sizes to meals~~
- ~~Add Imperial unit support~~
- Add support for Material You themes

## Verifying APK signatures

If you are side-loading an OpenNutriTracker APK from GitHub Releases — or from F-Droid, once the app is published there — you may reasonably want to confirm that the file you downloaded was signed by the same key the maintainer uses for every release, rather than by someone who intercepted the download or repackaged the app. The check below is for anyone who would like that extra reassurance before installing.

The official SHA256 fingerprint of the Android release signing certificate is:

```
TODO(simon): paste fingerprint from release keystore — see "Generating the SHA256 fingerprint" in RELEASE.md
```

To verify a downloaded APK against that fingerprint, run:

```sh
apksigner verify --print-certs /path/to/opennutritracker.apk
```

The `SHA-256` line in the output should match the value above exactly.

## Contribution
Contributions to OpenNutriTracker are welcome! If you find any issues or have suggestions for new features, please open an issue or submit a pull request. See [CONTRIBUTING.md](CONTRIBUTING.md) for the project's conventions — including the requirement to target the `develop` branch and the steps for adding localized strings.

Thanks to all the contributors:
<a href="https://github.com/simonoppowa/OpenNutriTracker/graphs/contributors">
<img src="https://contrib.rocks/image?repo=simonoppowa/OpenNutriTracker" />
</a>

### Getting Started With Development
See the [Getting Started](GettingStarted.md) file for more information.

The data export bundle (Settings → Export / Import App Data → Export) is
documented at [`docs/export-format.md`](docs/export-format.md) — both the
JSON schema and the CSV companion the import / export round-trip uses.

Self-hosting the Supabase FDC database for local development is documented at [`docs/supabase-fdc-self-hosting.md`](docs/supabase-fdc-self-hosting.md).

## Disclaimer
OpenNutriTracker is not a medical application. All data provided is not validated and should be used with caution. Please maintain a healthy lifestyle and consult a professional if you have any problems. Use during illness, pregnancy or lactation is not recommended.

The application is still under construction. Errors, bugs and crashes might occur.

## Acknowledgments
The OpenNutriTracker project was inspired by the need for a simple and effective nutrition tracking tool.
The food database used in OpenNutriTracker is powered by [Open Food Facts](https://world.openfoodfacts.org/) and [Food Data Central](https://fdc.nal.usda.gov/).

## License
This project is licensed under the GNU General Public License v3.0 License. See the [LICENSE](LICENSE) file for more information.

## Contact
For questions, suggestions, or collaborations, feel free to contact the project maintainer:

Simon Oppowa

- GitHub: [@simonoppowa](https://github.com/simonoppowa)
- Email: [opennutritracker-dev@pm.me](mailto:opennutritracker-dev@pm.me)