<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/icon/ont_logo_square_color_white_1024x1024.png">
    <img alt="Logo" src="assets/icon/ont_logo_square_color_back_1024x1024.png" width="128" />
  </picture>
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

- **🍎 Nutritional tracking:** Log meals and snacks against a large food database (Open Food Facts plus a curated subset of USDA FDC). Each entry can be searched, scanned, or added straight as a number when you already know the calorie cost.
- **📓 Food diary:** A calendar-driven diary that breaks the day into Breakfast, Lunch, Dinner, and Snack, with per-meal kcal targets (Standard, OMAD, Five-small, Mediterranean, Two-meal, or a custom share), drag-to-rearrange between meals, and sort by time or by macro contribution.
- **🥕 Micronutrient panel:** Day and week views for fibre, sodium, saturated fat, sugar, calcium, iron, potassium, vitamin D, vitamin B12, and magnesium, with optional Dietary Reference Intake bars from the IOM tables so you can see where you sit against the reference range.
- **🍽️ Custom meals + recipes:** Build a one-off custom meal or save a reusable recipe with photo, brand, and barcode. The recipe builder has its own ingredient picker with barcode scanning so you can compose meals from real products without leaving the screen.
- **⚡ Quick add:** When you already know roughly how much you ate, skip the search flow entirely — Quick add takes a title plus kcal (and optional macros) and logs it straight to the meal section.
- **📷 Barcode scanner:** Scan packaged items for instant lookup, paste a barcode manually when the camera struggles, or attach a barcode to a custom meal so future scans recognise your own foods.
- **🏃 Activities:** Log workouts from a categorised activity catalogue or define your own custom activities with direct kcal entry and reusable templates.
- **💧 Water tracker:** A water chip on the home screen with quick-add increments, an editable goal, and undo for the last entry.
- **⏱️ Fasting timer:** Optional intermittent-fasting timer with content-warning gate, a home chip showing time remaining, and a completion notification when you reach your window.
- **⚖️ Weight history:** Capture weight during onboarding and on demand, see the trend on a chart with a dashed line at your target weight, and optionally taper the calorie goal as you approach it.
- **🎨 Material You + theme picker:** Adopt the system accent colour on Android 12+, or pick from sixteen built-in presets. The app icon adapts to iOS dark and tinted appearances and to Android themed icons.
- **🔢 kcal or kJ:** Switch the energy unit globally; every diary entry, target, and chart reflects the choice.
- **📤 Export and import:** Export your full diary, activities, and custom catalogue to a JSON zip or CSV, paste a JSON blob to import meals, and share a single meal or activity as a QR code another phone can scan.
- **🔒 Privacy first:** All data is AES-encrypted and stored locally. Anonymous crash reporting is opt-in during onboarding, can be turned off at any time, and the App Store privacy manifest declares exactly what the app does and does not collect.
- **🚫💰 No subscriptions, in-app purchases, or ads:** OpenNutriTracker is free, with no paid tier and no advertising.

## Privacy
See [Data Protection](https://www.iubenda.com/privacy-policy/53501884)
- **Data Encryption**: All collected user data is encrypted and stored locally on your device
- **Minimal Data Collection**: OpenNutriTracker only collects the necessary information required for tracking nutrition and providing personalized insights. Your data will not be shared with third parties without your consent.
- **Open-Source**: OpenNutriTracker is an open-source application

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
The food database used in OpenNutriTracker is powered by [Open Food Facts](https://world.openfoodfacts.org/) and [Food Data Central](https://fdc.nal.usda.gov/). A curated subset of FDC is hosted in Supabase to keep search responsive on slow connections; the schema and refresh process are documented in [`docs/supabase-fdc-self-hosting.md`](docs/supabase-fdc-self-hosting.md).

Dietary Reference Intake values for the micronutrient panel come from the U.S. National Academies' Institute of Medicine tables. The in-app **Sources & References** screen (one tap from the home calorie ring or the profile BMI card) lists the peer-reviewed sources used for energy needs, BMI classification, macro distribution, MET activity calories, and non-binary calorie estimation.

## License
This project is licensed under the GNU General Public License v3.0 License. See the [LICENSE](LICENSE) file for more information.

## Contact
For questions, suggestions, or collaborations, feel free to contact the project maintainer:

Simon Oppowa

- GitHub: [@simonoppowa](https://github.com/simonoppowa)
- Email: [opennutritracker-dev@pm.me](mailto:opennutritracker-dev@pm.me)