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
| Lebensmittel | Kein Supabase-Backend mehr; BLS 4.0 lokal mit Offline-Suche, Open Food Facts bleibt online; `supabase_flutter` und `SpFoodDataSource` bleiben als ungenutzter Upstream-Code für kleine Merges | #17, #51, #79 |
| Infrastruktur | fastlane, Store-Metadaten, Screenshot-Tooling, Upstream-Workflows, Dependabot, Issue-Templates entfernt | #18 |
| Telemetrie | Sentry samt Einwilligungs-UI entfernt, `envied`/`.env` entfallen (nichts liest mehr Secrets) | #19 |
| KI | KI-Mahlzeitenerkennung (externe Anbieter) ausgeblendet; Bulk-Add mit lokalem Parser bleibt | #20 |
| CI | Analyze und Tests auf jedem PR gegen `personal` | #21 |
| Backup | Wasser, eigene Lebensmittel, Profil, Einstellungen, Fasten und alle Profile im JSON-Backup; „Alles ersetzen“; Hinweis auf alte Backups; automatisches WebDAV-Backup | #23–#28, #77, #78 |
| Scanner | Nährwerttabelle fotografieren: Texterkennung auf dem Gerät (Apple Vision, `ios/Runner/NutritionTextRecognizer.swift`), Parser für deutsche Tabellen, vorausgefülltes Formular mit markierten unsicheren Feldern; Einstiege im Dialog „Eigenes Lebensmittel“, im Formular, bei OFF-Produkten ohne Nährwerte und bei unstimmigen Werten. Das Foto wird nach der Erkennung gelöscht | #60–#63 |
| Scanner | 8-stellige Händlercodes mit Präfix 2 (Lidl, Penny …) sind nicht eindeutig: Rückfrage „Ist das dein Produkt?“ einmal pro Code; „Nein“ legt ein eigenes Lebensmittel mit dem Code an (Tabellen-Scan), das beim nächsten Scan gewinnt. Bestätigte Codes: ConfigDBO-Feld 102, im Backup (`app_settings.json`) | #83 |
| Scanner | Nach einem Tabellen-Scan ohne Barcode bietet der Hinweis „Barcode scannen“ an; beim Speichern wird die Prüfziffer aller Barcode-Längen (EAN-8, UPC-A, EAN-13, GTIN-14) geprüft | #64 |
| Open Food Facts | Opt-in „Beiträge an Open Food Facts“: nach dem Speichern eines gescannten Lebensmittels mit Barcode Vorschau der Nährwerte, Senden nur nach Bestätigung, nie über vorhandene Werte; Zugangsdaten nur in der Keychain; Testserver standardmäßig an. Bewusste Ausnahme von „keine externen Dienste“ | #81 |
| Wasser | Schnellbuttons +250 ml, +500 ml und eine eigene Menge (Profil → Eigene Schnellmenge, ConfigDBO-Feld 103, im Backup) im Wasser-Dialog, Snackbar mit Rückgängig | #29 |
| Wasser | Einträge des Tages (Uhrzeit, Menge) im Wasser-Dialog und im Tagebuch, einzeln löschbar nach Bestätigung; Home und Trends aktualisieren sich | #30 |
| Wasser | Fortschrittsbalken in der Kalorien-Karte auf Home (ersetzt den Wasser-Chip, Tap öffnet den Wasser-Dialog) und im Tagebuch gegen das Tagesziel | #31 |
| Ziele | Zielmodell pro Profil: festes Kalorienziel und Makros in Gramm (ConfigDBO-Felder 104–109, `GoalTargets`, `MacroGoalResolver`), im Backup als `goal_targets.json` | #32 |
| Ziele | Kcal- und Makro-Usecases lesen die eigenen Ziele; Home, Tagebuch, neue Tracked Days und Trends folgen ihnen, verbrannte Aktivitäts-kcal kommen auch auf ein festes Ziel | #34 |
| Ziele | Einstellungen → Ziele: Kalorien berechnet oder fest, Makros in Prozent (bestehender Aufteilungs-Dialog) oder Gramm mit Live-Umrechnung und Hinweis, wenn die Makro-kcal vom Ziel abweichen | #33 |
| Ziele | Eigener Zielsatz für Trainingstage, Wochenplan der Trainingstage, Umschalter Trainings-/Ruhetag auf Home und im Tagebuch (rechnet die Ziele des Tages neu); ConfigDBO-Felder 110–112, im Backup als `training_plan.json` | #35 |
| Ziele | Aktivität an einem Ruhetag: nichts / nachfragen / automatisch Trainingstag (Ziele → Trainingstage, ConfigDBO-Feld 113); von Hand gesetzte Tage bleiben; gilt für Schnell-Eintrag, Aktivitäts-Screen und Workout-Import (über `TrainingAwareLogUserActivityUsecase`) | #36 |
| Ziele | Erklär-Screen des Kalorienziels zeigt bei festem Ziel oder Gramm-Makros oben die heute geltenden Werte (inkl. Trainingstag) | #119 |
| Favoriten | Datenmodell: Box `FavoriteBox` pro Profil (JSON-Einträge, keine neue Hive-typeId), Lebensmittel als Snapshot, Rezepte per id (gelöschte fallen heraus), Reihenfolge; im Backup als `favorites.json` | #37 |
| Favoriten | Stern in Mahlzeit- und Rezeptdetail | #38 |
| Favoriten | Chip „Favoriten“ im Mahlzeit-Hinzufügen (mit Suche, leerer Zustand), Favoriten zuerst in Suche und „Alle“, Stern auf den Ergebniskarten auch in „Zuletzt“ | #39 |
| Tagebuch | Einträge, Mahlzeiten, Aktivitäten und ganze Tage (optional mit Aktivitäten und Wasser) auf ein beliebiges Datum kopieren, auch von heute aus; neue IDs, gleiche Uhrzeit im Ziel-Tag (Tagesgrenze beachtet), Summen am Ziel | #40 |
| Lebensmittel | BLS-Säfte, Nektare, Smoothies, Milch, Kefir, Buttermilch und Pflanzendrinks standardmäßig in ml (Regel über die BLS-Codes, `SPConst.isBlsLiquid`) | #104 |
| Suche | Suchregion (Standard Deutschland, Einstellungen → Lebensmitteldatenbanken, ConfigDBO-Feld 114) statt Geräte-Locale; Marken und Märkte in der Eingabe werden erkannt (pflegbare Liste `german_brands.dart`), OFF wird nach `brands_tags` gefiltert (Fallback ohne Filter) und die Marke zuerst gezeigt; in „Alle“ stehen BLS-Lebensmittel bei vergleichbarer Relevanz vor OFF | #41 |
| Gewicht | Profilgewicht folgt immer dem jüngsten Eintrag im Gewichtsverlauf (auch beim Nachtragen, Bearbeiten, Löschen); bei einer Änderung werden Kalorienziel und Ansichten neu berechnet | #42 |
| Gewicht | Tests für Lücken, Einzelwerte, Mehrfachmessungen und Jahreswechsel im 7-Tage-Mittel; Entscheidung gegen EMA in `docs/weight-trend.md` | #45 |
| Körperumfänge | Datenmodell: Box `BodyMeasurementBox` pro Profil (JSON, keine neue Hive-typeId), Taille/Brust/Arm/Oberschenkel/Hüfte in cm, mindestens ein Wert; im Backup als `body_measurements.json` | #43 |
| Körperumfänge | Profil → Körperumfänge: erfassen, bearbeiten, löschen, Verlauf pro Maß; cm oder Zoll nach der Größen-Einstellung | #44 |
| Mikronährstoffe | Fehlende Werte zählen als „unbekannt“: Nährstoff-Panel zeigt „unbekannt“ bzw. „≥ X“ mit Anzahl der Einträge ohne Angabe; Rezepte summieren über dieselbe Logik (`NutrientTotal`, `NutrientField`) | #46 |
| Mikronährstoffe | Mahlzeit-Detail listet alle Nährwerte, fehlende als „—“ statt 0, pro 100 g und für die gewählte Menge; Mikronährstoffe nur mit Einstellung „Mikronährstoffe anzeigen“ | #48 |
| Mikronährstoffe | Tagesübersicht zeigt alle 24 Nährstoffe in einklappbaren Gruppen (Energie & Makros, Fettsäuren & Cholesterin, Mineralstoffe, Vitamine); Sichtbarkeit und eigene Ziele auch für die neuen; Ziele im neuen Feld `TrackedDayDBO.extraNutrientGoals` (Hive-Feld 100, im JSON-Backup) | #47 |
| Mikronährstoffe | Referenzwerte wählbar: IOM oder DGE (DGE/ÖGE, 3. Auflage 2025, nach Alter/Geschlecht) unter Einstellungen → Nährstoffe; wirkt sofort, fehlende DGE-Werte sichtbar als „IOM/FDA“ markiert; Einstellung `nutrientReferenceStandard` (ConfigDBO-Feld 115, geräteweit, im Backup) | #49 |
| Mikronährstoffe | Elf weitere Mikronährstoffe: Vitamin E, K, B1, B2, B5, Biotin, Folat, Jod, Selen, Kupfer, Mangan (`MealNutrimentsDBO`, Hive-Felder 100–110, alte Daten lesen sie als unbekannt); gefüllt aus dem lokalen BLS (ohne Selen) und aus OFF (Gramm in mg/µg umgerechnet); in Tagesübersicht, Mahlzeit-Detail, Zielen, Rezepten sowie JSON- und CSV-Export/-Import (Spalten vor `meal_data_version`) | #50 |
| Mikronährstoffe | Eigene Nährstoffziele gelten ab dem Speichertag weiter: Speichern schreibt sie auf diesen und alle späteren Tage, ein neuer Tag übernimmt die Ziele des letzten früheren Tages; Zurücksetzen löscht alle eigenen Ziele (auch die zehn alten Felder); Upstreams `updateDayNutrientGoals` bleibt für Merges unverändert | #136 |
| Lebensmittel | FDC Foundation + SR Legacy lokal (englische Namen, eigene Schalter, standardmäßig aus); die lokale Suche zählt englische Plurale wie den Singular und hebt „raw“ wie „roh“ | #80 |
| Rezepte | Ein bestehendes Rezept öffnet mit seinem Endgewicht nach dem Kochen (gespeichertes Gewicht ≠ Summe der Zutaten), statt es beim Bearbeiten stillschweigend auf das Rohgewicht zurückzusetzen; Regressionstests für Snapshot, Portionen, Endgewicht und Duplizieren | #52, #142 |

Bewusst behalten, um Upstream-Merges klein zu halten: `android/` (unangetastet),
die Weblate-Übersetzungen in `lib/l10n/`, das PR-Template, die In-App-Hinweise zur
Datenschutzerklärung und der Code der KI-Funktionen (nur die Einstiege sind weg).

## Berechtigungen und Entitlements

| Was | Wofür | Stand |
|---|---|---|
| `NSCameraUsageDescription` | Barcode-Scan, Nährwerttabelle scannen, Fotos für eigene Lebensmittel | aktiv |
| `NSPhotoLibraryUsageDescription` | Nährwerttabelle aus einem Foto lesen, Foto für eigene Lebensmittel, Export | aktiv |
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

- **Open Food Facts**: online, Text- und Barcode-Suche. Marken und Märkte in der
  Eingabe („Paradiso Mango-Maracuja“, „Penny Studentenfutter“) filtern die Suche
  auf die Marke bzw. die Eigenmarken des Markts. Die Liste der Marken, ihrer
  Schreibweisen und der Eigenmarken je Markt steht in
  `lib/features/add_meal/domain/search/german_brands.dart`; fehlt eine Marke,
  gehört sie dort hinein (die `brands_tags` stehen auf der Produktseite von OFF).
  Schreiben nur per Opt-in (#81, Einstellungen → Beiträge an Open Food Facts):
  zuerst mit eingeschaltetem Testserver (`world.openfoodfacts.net`) einen Upload
  ausprobieren, erst danach den Schalter für die echte Datenbank umlegen.
- **BLS 4.0** (Bundeslebensmittelschlüssel, © Max Rubner-Institut,
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)): liegt als
  `assets/bls/bls_4_0.json.gz` in der App (7.140 Lebensmittel, 38 Nährstofffelder,
  ~0,7 MB komprimiert, ~70 ms zum Einlesen auf einem Desktop-Rechner). Erzeugt mit
  `tool/bls/bls_to_asset.py` aus dem offiziellen Download (Anleitung in
  `tool/bls/README.md`). Die Suche (#79) läuft offline auf den deutschen
  Namen. Sie versteht Umlaute und ae/oe/ue, Plural, einen Tippfehler und
  Alltagswörter über die pflegbare Liste
  `lib/features/add_meal/data/data_sources/bls_synonyms.dart` (z. B. Brokkoli →
  Broccoli, Hüttenkäse → Körniger Frischkäse). Kommt bei einer häufigen Suche
  nichts, gehört das Wort dort hinein.
- **USDA FoodData Central** (Foundation Foods und SR Legacy, gemeinfrei/CC0, #80):
  liegt als `assets/fdc/fdc.json.gz` in der App (8.114 Lebensmittel, ~0,55 MB
  komprimiert), erzeugt mit `tool/fdc/fdc_to_asset.py` (Anleitung in
  `tool/fdc/README.md`). Nur englische Namen, daher pro Datensatz ein eigener
  Schalter unter Einstellungen → Lebensmitteldatenbanken, beide standardmäßig
  aus; gedacht für Lücken in BLS und OFF. Die Treffer stehen hinter denen des BLS
  und verlinken auf die FDC-Seite.
- Kein Supabase mehr. Upstream nutzte dafür ein Backend des Maintainers ohne
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
- Neue Texte kommen in `lib/l10n/intl_en.arb` **und** `intl_de.arb`. Der Fork
  hat keine Weblate-Anbindung; die übrigen Sprachen zeigen Englisch.
- Jede neue Hive-Box muss in `test/unit_test/backup_coverage_test.dart`
  eingetragen werden (Backup-Datei oder begründete Ausnahme), sonst schlägt
  der Test fehl.
