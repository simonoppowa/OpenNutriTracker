# Getting started

## Android development with Windows 11

This IDE setup is tested on Windows 11.

For setup first you need the following things:

- Android SDK and Android Emulator
- Flutter
- IDE like Android Studio or VS Code with Flutter Plugin installed.

Use paths for SDKs without spaces and special characters.

### Setup Android SDK and Emulator

1. Download Android Studio from https://developer.android.com/studio and install. Keep "Android Virtual Device" checked. Start Android Studio after installation.

2. Install the Android SDK when asked.

3. After finishing the SDK installation you should the "Welcome to Android Studio" Screen. Click on "More Actions" -> "SDK Manager", switch to "SDK Tools" tab and check "Android SDK Command-line Tools (latest)", click "OK" and install the tools.

4. Check under "More Actions" -> "Virtual Device Manager" if a virtual phone was set up, if not create one, e.g. a Medium Phone with Default Settings.

5. Close Android Studio.

### Setup Flutter SDK

This project uses [FVM](https://fvm.app/) to pin the Flutter version. FVM reads `.fvmrc` in the repo root and installs the correct SDK automatically.

1. Install FVM by following the instructions at [fvm.app/documentation/getting-started/installation](https://fvm.app/documentation/getting-started/installation).

2. In the cloned repository folder, run:

```sh
fvm install
```

This downloads the pinned Flutter version (defined in `.fvmrc`) and creates a `.fvm/flutter_sdk` symlink in the project folder. VS Code picks this up automatically via the `dart.flutterSdkPath` setting in `.vscode/settings.json`.

### Setup the Workspace in Visual Studio Code (VSC)

1. Create a new folder, open the folder in VSC.

2. Configure the Android SDK path for Flutter:

`flutter config --android-sdk "e:\path\to\androidSDK"`

3.⁠ ⁠Clone the repository with git in a VSC terminal (make sure the active folder in the terminal is your created folder from step 1):

`git clone https://github.com/simonoppowa/OpenNutriTracker.git .`

4.⁠ ⁠Create your local environment file from the template:

`cp .env.example .env`

`.env` is gitignored. Edit it to fill in real values (or leave the placeholders for a debug build that doesn't need the live backend — see `docs/supabase-self-hosting.md` for pointing the app at your own Supabase food database).

5.⁠ ⁠Get Dependencies.

`flutter pub get`

6.⁠ ⁠Run Build Runner to generate Files.

`dart run build_runner build`

At the best revert all the visible generated files now, only env.g.dart is needed, it is not checked in because it is in .gitignore.

7.⁠ ⁠Restart VSC, VSC detects now that this is a flutter project. On the Bottom Right "No Device" ist displayed, click on it, then select "Start Medium Phone" on the command Palette on the top. Wait for the phone to boot up.

8. Press F5 to start a debug session (may take a while on the first time). Keep the virtual phone running all the time, just start and stop Debugging.
