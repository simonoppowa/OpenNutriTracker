# NutriTracker Personal

Persönlicher Fork von [OpenNutriTracker](https://github.com/simonoppowa/OpenNutriTracker)
(GPLv3) für genau ein iPhone, per Sideloading installiert. Kein App Store, kein
Android, keine Accounts, keine Analytics.

- Fork: <https://github.com/theoleuthardt/OpenNutriTracker>, Arbeitsbranch und
  Default-Branch ist `personal`.
- Planung und Status: GitHub Project
  [NutriTracker Personal](https://github.com/users/theoleuthardt/projects/3).
- Basis: Upstream-Release `main` 2.4.0+66 (8d2420f0).

Dieses Dokument wächst mit jedem Epic mit und wird am Ende von Phase 2
vervollständigt.

## Änderungen gegenüber Upstream

| Bereich | Änderung | Issue |
|---|---|---|
| Build | Unsignierte IPA per GitHub Actions (macOS-Runner), Artefakt auf jedem PR und jedem Push auf `personal` | #14 |
| iOS | Bundle IDs `dev.theocloud.nutritracker` (Flavor `full`, „NutriTracker“) und `dev.theocloud.nutritracker.dev` (Flavor `develop`, „NutriTracker Dev“); Upstream-Team und match-Profile entfernt | #15 |
| Lebensmittel | Kein Supabase-Backend mehr; FDC/BLS über Supabase entfallen, Open Food Facts bleibt online, BLS kommt lokal | #17, #51, #79 |
| Infrastruktur | fastlane, Store-Metadaten, Screenshot-Tooling, Upstream-Workflows, Dependabot, Issue-Templates entfernt | #18 |
| Telemetrie | Sentry samt Einwilligungs-UI entfernt, `envied`/`.env` entfallen (nichts liest mehr Secrets) | #19 |
| KI | KI-Mahlzeitenerkennung (externe Anbieter) ausgeblendet; Bulk-Add mit lokalem Parser bleibt | #20 |
| CI | Analyze und Tests auf jedem PR gegen `personal` | #21 |

Bewusst behalten, um Upstream-Merges klein zu halten: `android/` (unangetastet),
die Weblate-Übersetzungen in `lib/l10n/`, das PR-Template, die In-App-Hinweise zur
Datenschutzerklärung und der Code der KI-Funktionen (nur die Einstiege sind weg).

## Berechtigungen und Entitlements

| Was | Wofür | Stand |
|---|---|---|
| `NSCameraUsageDescription` | Barcode-Scan, Fotos für eigene Lebensmittel (später: Nährwerttabelle scannen, #60–#64) | aktiv |
| `NSPhotoLibraryUsageDescription` | Foto für eigene Lebensmittel, Export | aktiv |
| `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` | Workout-Import aus Apple Health (Upstream); Ausbau in Epic 9 | aktiv |
| `com.apple.developer.healthkit` | HealthKit | hängt vom KravaSigner-Profil ab, wird in #16 geprüft |
| App Groups | Widget (Epic 11) | noch nicht vorhanden, Prüfung in #73 |

Regel: Erlaubt das Provisioning-Profil des Zertifikats ein Entitlement nicht, fällt
das Feature weg (Epic 9 bzw. 11 werden dann als „not planned“ geschlossen). Es gibt
keine Workarounds.

## Build

Ein Mac ist nicht nötig. Der Workflow **iOS IPA (unsigned, for sideloading)**
(`.github/workflows/ios-ipa.yml`) baut bei jedem Push auf `personal` eine
unsignierte IPA:

1. GitHub → Actions → *iOS IPA (unsigned, for sideloading)* → letzter Lauf auf
   `personal` (oder *Run workflow* mit einem Branch/Tag/SHA).
2. Artefakt `nutritracker-ipa-unsigned-<run>` herunterladen (30 Tage gültig) und
   entpacken: darin liegt `NutriTracker-unsigned.ipa`.

Lokal (optional, macOS mit Xcode und CocoaPods):

```sh
fvm install               # Flutter-Version aus .fvmrc (3.44.6)
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
cd ios && pod install && cd ..
fvm flutter build ios --no-codesign --release --flavor full
```

Tests und Analyse laufen auch unter Linux: `flutter analyze`,
`flutter test --concurrency=4`.

## Sideloading mit KravaSigner

1. IPA aufs iPhone holen (z. B. über die Dateien-App) und in KravaSigner
   importieren.
2. Mit dem eigenen Zertifikat signieren. **Bundle ID beibehalten**
   (`dev.theocloud.nutritracker`), nicht vom Signer ändern lassen: Nur so landet
   jedes Update im selben App-Container mit denselben Keychain-Einträgen.
3. Installieren. Ein Update über eine bestehende Installation behält die Daten.

**Vor jedem Neusignieren und vor jedem Zertifikatswechsel ein Backup machen**
(Einstellungen → Export, JSON). Die lokale Datenbank ist mit einem Schlüssel aus der
Keychain verschlüsselt. Ändert sich die Team-ID des Zertifikats (Widerruf, neues
Zertifikat) oder die Bundle ID, kommt die App nicht mehr an den Schlüssel, und die
Daten auf dem Gerät sind unlesbar. Das automatische Backup auf FileBrowser Quantum
(#77) ist genau dafür geplant.

## Datenquellen

- **Open Food Facts**: online, Text- und Barcode-Suche.
- **BLS 4.0** (Bundeslebensmittelschlüssel, © Max Rubner-Institut, CC BY 4.0):
  wird lokal in die App gepackt (#51, #79), damit generische Lebensmittel offline
  mit allen Nährstoffen verfügbar sind.
- Kein Supabase/FDC mehr. Upstream nutzte dafür ein Backend des Maintainers ohne
  öffentliche Zugangsdaten.

## Upstream-Updates übernehmen

```sh
git fetch upstream main
git switch personal
git merge upstream/main     # Konflikte auflösen, Tests laufen lassen
git push
```

Upstream entwickelt auf `develop` und veröffentlicht über `main`. Für den Fork wird
nur `main` gemerged. Einzelne Fixes von `develop` werden per
`git cherry-pick -x <sha>` übernommen (z. B. #78).

## Arbeitsweise

- Ein Issue = ein Branch `feature/<nr>-kurzname` = ein PR gegen `personal` mit
  `Closes #<nr>`.
- Board-Status: In Progress → Review → Done.
- Vor jedem PR `flutter analyze` und `flutter test`; Review mit CodeRabbit; erst
  mergen, wenn CI (Linux-Tests + iOS-Build) grün ist.
- `dart format` nur auf neue Dateien anwenden: Upstream-Dateien sind nicht
  durchgängig formatiert, ein Formatieren ganzer Ordner erzeugt fremde Diffs.
