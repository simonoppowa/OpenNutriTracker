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
| Backup | Wasser, eigene Lebensmittel, Profil, Einstellungen, Fasten und alle Profile im JSON-Backup; „Alles ersetzen“; Hinweis auf alte Backups; automatisches WebDAV-Backup | #23–#28, #77, #78 |

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

## Automatisches Backup (FileBrowser Quantum)

Die App hat keine Accounts und kein Backend. Alle Daten liegen nur auf dem
iPhone. Der eigene Ordner der App wird beim Löschen der App mitgelöscht, deshalb
sichert die App automatisch per WebDAV auf den eigenen Server.

Einrichten:

1. In FileBrowser Quantum unter *Einstellungen → API Tokens* einen Token anlegen
   (ohne Anpassung). Den Token-Wert kopieren.
2. Ordner-URL bestimmen: `https://<host>/dav/<source>/<pfad>/`, z. B.
   `https://files.theocloud.dev/dav/backups/nutritracker/`. Prüfen am Rechner:
   `curl -X PROPFIND -u "egal:<TOKEN>" https://<host>/dav/<source>/` (401 =
   Token falsch, 405 = falsche Methode).
3. In der App: *Einstellungen → Automatisches Backup* → Ordner und Token
   eintragen, optional ein Zip-Passwort (AES, lässt sich z. B. mit 7-Zip öffnen),
   *Verbindung testen*, *Automatisch sichern* einschalten.

Ablauf: Beim App-Start und jedes Mal, wenn die App wieder in den Vordergrund
kommt, sichert sie, wenn das letzte erfolgreiche Backup älter als das Intervall
ist (Standard 24 h). Dateien heißen `nutritracker-backup-JJJJMMTT-HHMMSS.zip`; die
neuesten N (Standard 14) bleiben, ältere löscht die App, andere Dateien im Ordner
bleiben unangetastet. Fehler blockieren nichts. Sie stehen mit Zeitpunkt im
Backup-Screen, und beim nächsten Start versucht die App es erneut. Token und
Passwort liegen nur in der Keychain, nie in der Config oder im Export.

Wiederherstellen nach einer Neuinstallation: Onboarding durchlaufen →
*Einstellungen → Automatisches Backup* → Server eintragen →
*Vom Server wiederherstellen* → Backup wählen → *Alles auf diesem Gerät
ersetzen* einschalten → *Importieren*.

Bewusst verschoben: ein Ziel ohne Server über die Dateien-App (iCloud Drive per
Security-Scoped Bookmark, #99) und ein „Backup wiederherstellen“ direkt im
Onboarding (#100).

## Datenquellen

- **Open Food Facts**: online, Text- und Barcode-Suche.
- **BLS 4.0** (Bundeslebensmittelschlüssel, © Max Rubner-Institut,
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)): liegt als
  `assets/bls/bls_4_0.json.gz` in der App (7.140 Lebensmittel, 38 Nährstofffelder,
  ~0,7 MB komprimiert, ~70 ms zum Einlesen auf einem Desktop-Rechner). Erzeugt mit
  `tool/bls/bls_to_asset.py` aus dem offiziellen Download (Anleitung in
  `tool/bls/README.md`). Suche darin: #79.
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
- Neue Hive-Felder des Forks bekommen Indizes **ab 100** (`@HiveField(100)` …)
  und neue Hive-Typen typeIds ab 100. Upstream vergibt fortlaufend weiter;
  eine Kollision beim nächsten Upstream-Merge würde gespeicherte Daten falsch
  lesen.
- Jede neue Hive-Box muss in `test/unit_test/backup_coverage_test.dart`
  eingetragen werden (Backup-Datei oder begründete Ausnahme), sonst schlägt
  der Test fehl.
