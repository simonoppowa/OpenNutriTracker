intl_output_dir := "./lib/generated/intl/"

# Install dependencies
install:
  flutter pub get

# Build OpenNutriTracker
build:
  dart run build_runner build

# Format dart code (excludes lib/generated/ — those files are auto-generated with their own style)
format *OPTIONS:
  dart format {{OPTIONS}} ./lib/core ./lib/features ./lib/l10n ./test

# Regenerate intl files
# Note: lib/generated/ files are maintained manually to avoid formatting churn from the generators
run_intl: format

# Check if intl files are correctly generated
check_intl:
  git diff --exit-code {{intl_output_dir}}
  git diff --exit-code lib/generated/l10n.dart

# Run tests
test:
  flutter test

# Run CI checks
ci: install (format "--set-exit-if-changed") check_intl build && test
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