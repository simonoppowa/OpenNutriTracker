{
  description = "Flutter 3.27.x";
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        androidPkgs = (pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ "27" "29" "31" "33" "34" ];
          buildToolsVersions = [ "30.0.3" ];
          includeEmulator = true;
          includeSystemImages = true;
        });
        # TODO: graphics are a bit weird
        emulator = pkgs.androidenv.emulateApp {
          name = "flutter_emu";
          platformVersion = "27";
          abiVersion = "x86"; # armeabi-v7a, mips, x86_64
          systemImageType = "google_apis_playstore";
          deviceName = "pixel";
        };
      in
      {
        # run once:
        #   avdmanager create avd -n flutter_emulator -k 'system-images;android-27;google_apis_playstore;x86' -d pixel
        #   flutter emulators --launch flutter_emulator
        #   flutter pub run build_runner build --delete-conflicting-outputs
        devShells.default = pkgs.mkShell {
            ANDROID_SDK_ROOT = "${androidPkgs.androidsdk}/libexec/android-sdk";
            buildInputs = [
              pkgs.flutter319
              pkgs.jdk17
              androidPkgs.androidsdk
              emulator  # execute emulator with: run-test-emulator
            ];
          };
      });
}
