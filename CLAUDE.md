# CLAUDE.md - OpenNutriTracker

This document provides comprehensive guidance for AI assistants working with the OpenNutriTracker codebase.

## Project Overview

**OpenNutriTracker** is an open-source, privacy-focused Flutter application for nutritional tracking. It helps users track daily calories, macronutrients, and physical activities.

- **Version**: 1.0.0+41
- **License**: GPL v3.0
- **Platforms**: Android, iOS, Web, macOS
- **Repository**: https://github.com/simonoppowa/OpenNutriTracker

## Quick Start Commands

```bash
# Install dependencies
flutter pub get

# Generate code (REQUIRED after cloning or modifying DBOs/env)
flutter pub run build_runner build --delete-conflicting-outputs

# Run static analysis
flutter analyze

# Run tests
flutter test

# Run the app
flutter run
```

## Technology Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.27.1+ / Dart 3.0+ |
| State Management | flutter_bloc (BLoC pattern) |
| Dependency Injection | GetIt |
| Local Database | Hive (encrypted) |
| Backend | Supabase |
| Error Tracking | Sentry |
| Food APIs | Open Food Facts, USDA Food Data Central |
| Code Generation | build_runner, json_serializable, hive_generator, envied |

## Architecture

The project follows **Clean Architecture** with a **feature-first modular structure**.

### Directory Structure

```
lib/
├── main.dart                     # App entry point
├── core/                         # Shared functionality
│   ├── data/
│   │   ├── data_source/         # Local data sources (Hive boxes)
│   │   ├── dbo/                 # Data Business Objects (serializable)
│   │   └── repository/          # Repository implementations
│   ├── domain/
│   │   ├── entity/              # Domain entities (pure Dart)
│   │   └── usecase/             # Business logic use cases
│   ├── presentation/
│   │   └── widgets/             # Reusable UI components
│   ├── styles/                  # Theming (colors, fonts)
│   └── utils/
│       ├── calc/                # Nutritional calculations
│       ├── locator.dart         # Dependency injection setup
│       ├── env.dart             # Environment variables
│       └── hive_db_provider.dart
├── features/                     # Feature modules
│   ├── add_meal/                # Food search & meal logging
│   ├── add_activity/            # Physical activity logging
│   ├── diary/                   # Food diary calendar
│   ├── home/                    # Dashboard
│   ├── profile/                 # User profile
│   ├── settings/                # App settings, export/import
│   ├── scanner/                 # Barcode scanning
│   ├── onboarding/              # Initial setup
│   ├── meal_detail/             # Meal details view
│   ├── activity_detail/         # Activity details view
│   └── edit_meal/               # Meal editing
├── l10n/                        # Localization (ARB files)
│   ├── intl_en.arb              # English
│   ├── intl_de.arb              # German
│   └── intl_tr.arb              # Turkish
└── generated/                   # Auto-generated code
```

### Three-Layer Architecture

1. **Domain Layer** (`domain/`)
   - Pure Dart, no framework dependencies
   - Contains entities and use cases
   - Business rules and calculations

2. **Data Layer** (`data/`)
   - Repository implementations
   - Data Business Objects (DBOs) for serialization
   - Data sources (local Hive, remote APIs)

3. **Presentation Layer** (`presentation/`)
   - BLoC classes for state management
   - Screens and widgets
   - UI logic

## Naming Conventions

### Files
- BLoCs: `[feature]_bloc.dart`
- Events: `[feature]_event.dart`
- States: `[feature]_state.dart`
- Entities: `[name]_entity.dart`
- DBOs: `[name]_dbo.dart`
- Repositories: `[name]_repository.dart`
- Use Cases: `[action]_[entity]_usecase.dart`
- Data Sources: `[name]_data_source.dart`

### Classes
- BLoCs: `[Feature]Bloc` (e.g., `HomeBloc`, `AddMealBloc`)
- Events: `[Action]Event` (e.g., `LoadItemsEvent`, `InitializeAddMealEvent`)
- States: `[Feature][Status]State` (e.g., `HomeLoadingState`, `HomeLoadedState`)
- Entities: `[Name]Entity` (e.g., `UserEntity`, `IntakeEntity`)
- DBOs: `[Name]DBO` (e.g., `UserDBO`, `IntakeDBO`)
- Repositories: `[Name]Repository` (e.g., `UserRepository`)
- Use Cases: `[Action][Entity]Usecase` (e.g., `GetUserUsecase`, `AddIntakeUsecase`)

## BLoC Pattern

BLoCs use the `flutter_bloc` package. Each BLoC:
- Extends `Bloc<Event, State>`
- Uses `part` directives for events and states
- Receives use cases via constructor injection
- Registers event handlers in constructor with `on<Event>`

Example structure:
```dart
// home_bloc.dart
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetUserUsecase _getUserUsecase;

  HomeBloc(this._getUserUsecase) : super(HomeInitial()) {
    on<LoadItemsEvent>((event, emit) async {
      emit(HomeLoadingState());
      // ... business logic
      emit(HomeLoadedState(...));
    });
  }
}
```

## Dependency Injection

Dependencies are registered in `lib/core/utils/locator.dart` using GetIt:

```dart
final locator = GetIt.instance;

// Registration patterns:
locator.registerLazySingleton<Type>(() => Implementation());
locator.registerFactory<Type>(() => Implementation());

// Usage:
final bloc = locator<HomeBloc>();
```

Registration order in `initLocator()`:
1. Infrastructure (Hive, Supabase, cache managers)
2. BLoCs
3. Use Cases
4. Repositories
5. Data Sources

## Code Generation

The project uses code generation for:
- **Hive adapters**: Annotate DBOs with `@HiveType()` and fields with `@HiveField(index)`
- **JSON serialization**: Annotate with `@JsonSerializable()`
- **Environment variables**: Uses `envied` with `@Envied()` and `@EnviedField()`

After modifying annotated classes, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Environment Variables

Required environment variables (set via `.env` file or CI secrets):
- `FDC_API_KEY` - USDA Food Data Central API key
- `SENTRY_DNS` - Sentry error tracking DSN
- `SUPABASE_PROJECT_URL` - Supabase project URL
- `SUPABASE_PROJECT_ANON_KEY` - Supabase anonymous key

These are accessed via `lib/core/utils/env.dart` (generated by envied).

## Nutritional Calculations

Key calculation files in `lib/core/utils/calc/`:
- `bmr_calc.dart` - Basal Metabolic Rate (Schofield 1985)
- `tdee_calc.dart` - Total Daily Energy Expenditure (IOM 2005)
- `pal_calc.dart` - Physical Activity Level
- `macro_calc.dart` - Macronutrient goals
- `calorie_goal_calc.dart` - Daily calorie targets
- `bmi_calc.dart` - Body Mass Index
- `unit_calc.dart` - Metric/Imperial conversions

These calculations follow peer-reviewed scientific formulas (documented in code comments).

## Data Persistence

### Hive Boxes
- `userBox` - User profile data
- `intakeBox` - Food intake records
- `userActivityBox` - Activity records
- `configBox` - App configuration
- `trackedDayBox` - Daily summaries

### Encryption
All Hive data is AES encrypted. Keys are stored securely via `flutter_secure_storage`.

## Testing

Test structure:
```
test/
├── unit_test/           # Calculation unit tests
│   ├── tdee_calc_test.dart
│   ├── met_calc_test.dart
│   └── calorie_goal_calc_test.dart
├── widget_test/         # Widget tests
└── fixture/             # Test fixtures
    ├── user_entity_fixtures.dart
    └── meal_entity_fixtures.dart
```

Run tests:
```bash
flutter test                    # All tests
flutter test test/unit_test/    # Unit tests only
```

## Localization

The app supports 3 languages via ARB files in `lib/l10n/`:
- English (`intl_en.arb`)
- German (`intl_de.arb`)
- Turkish (`intl_tr.arb`)

To add a new string:
1. Add to all ARB files
2. Run `flutter pub get` to regenerate

## Styling & Theming

- **Design System**: Material Design 3
- **Primary Font**: Poppins
- **Color Schemes**: Defined in `lib/core/styles/color_schemes.dart`
- **Theme Mode**: Light/Dark/System via `ThemeModeProvider`

Light theme primary: `#006E2B` (green)
Dark theme primary: `#33E36A` (bright green)

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/default_workflow.yml`):
1. Checkout code
2. Setup Java 11 + Flutter 3.27.1
3. Install dependencies (`flutter pub get`)
4. Run code generation with secrets
5. Static analysis (`flutter analyze`)
6. Run tests (`flutter test`)

Triggers: Push/PR to `main` or `develop` branches

## Common Development Tasks

### Adding a New Feature

1. Create feature directory under `lib/features/[feature_name]/`
2. Add subdirectories: `data/`, `domain/`, `presentation/`
3. Create BLoC with events and states
4. Create entities and use cases
5. Register in `locator.dart`
6. Add navigation/routing

### Adding a New API Endpoint

1. Create data source in `data/data_sources/`
2. Add repository method
3. Create use case
4. Register in `locator.dart`

### Adding a New Hive Model

1. Create DBO class with `@HiveType(typeId: N)` annotation
2. Add fields with `@HiveField(index)` annotations
3. Create corresponding entity
4. Run `flutter pub run build_runner build`
5. Register adapter in `hive_db_provider.dart`

## Important Notes

- **Privacy First**: All user data is stored locally and encrypted
- **No Analytics by Default**: Sentry is opt-in
- **Offline-First**: Core functionality works without internet
- **Medical Disclaimer**: This is not a medical application

## External APIs

| API | Purpose | Data Source File |
|-----|---------|------------------|
| Open Food Facts | Food database (barcodes) | `off_data_source.dart` |
| USDA FDC | Nutrition data | `fdc_data_source.dart` |
| Supabase | Backend sync | `sp_fdc_data_source.dart` |

## Key Files Reference

| Purpose | File |
|---------|------|
| App Entry | `lib/main.dart` |
| DI Setup | `lib/core/utils/locator.dart` |
| Database Init | `lib/core/utils/hive_db_provider.dart` |
| Environment | `lib/core/utils/env.dart` |
| Color Themes | `lib/core/styles/color_schemes.dart` |
| Dependencies | `pubspec.yaml` |
| Lint Rules | `analysis_options.yaml` |
| CI/CD | `.github/workflows/default_workflow.yml` |

## Debugging Tips

- Check Hive initialization in `hive_db_provider.dart` for database issues
- Verify environment variables are set for API-related errors
- Use `flutter analyze` before committing
- Check `locator.dart` registration order for DI errors
