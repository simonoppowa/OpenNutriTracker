# Install dependencies
install:
  flutter pub get

# Build OpenNutriTracker
build:
  dart run build_runner build

# Format dart code (excludes lib/generated/ — gitignored gen-l10n output with its own style)
format *OPTIONS:
  dart format {{OPTIONS}} ./lib/core ./lib/features ./lib/l10n ./test

# Generate localizations from lib/l10n/*.arb into lib/generated/ (gitignored)
gen_l10n:
  flutter gen-l10n

# Run tests
test:
  flutter test

# Run CI checks
ci: install (format "--set-exit-if-changed") gen_l10n build && test
  flutter analyze

create_emulator:
  fvm flutter emulators --create --name flutter_emulator

start_emulator:
  fvm flutter emulators --launch flutter_emulator

dev:
  fvm flutter run --flavor develop

# Run with the active profile wiped and reseeded with demo data (skips onboarding)
dev_seed:
  fvm flutter run --flavor develop -t lib/dev/main_dev.dart