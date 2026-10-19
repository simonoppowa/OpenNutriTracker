# Nutrition label scan: text recognition (spike #60)

Epic 7 reads a photographed nutrition table on the device, offline, and
pre-fills the custom food form. This note records which text recognizer the
fork uses and the format the label parser (#62) consumes.

## Options

| | Apple Vision (`VNRecognizeTextRequest`) | Google ML Kit (`google_mlkit_text_recognition`) |
|---|---|---|
| Offline | yes, on-device | yes, bundled Latin model |
| German | `de-DE` with `.accurate` from iOS 14 (revision 2); the fork targets iOS 15.5 | Latin script, no language setting |
| App size | nothing added, part of iOS | adds the MLKit pods (several MB) |
| Simulator | runs in the iOS simulator | MLKit pods ship no arm64 simulator slice; simulator builds need `EXCLUDED_ARCHS` workarounds |
| Platforms | iOS only | iOS and Android |
| Output | observations with text candidates, confidence and a normalized bounding box | blocks/lines/elements with bounding boxes |
| Integration | a small Swift handler behind a `MethodChannel` | a Flutter plugin |

## Decision

**Apple Vision via an own MethodChannel** (#61). The app runs on one iPhone
only, so the Android advantage of ML Kit does not count, while Vision adds no
dependency, keeps the app small, supports German explicitly and works in the
simulator and CI builds. Android, if it ever matters, would get an ML Kit
implementation behind the same Dart interface.

Settings: `recognitionLevel = .accurate`, `recognitionLanguages = ["de-DE",
"en-US"]`, `usesLanguageCorrection = false` (language correction "fixes"
numbers and units into words), revision: the newest available.

## Format handed to the parser

The Swift side returns one entry per recognized text observation, top
candidate only, coordinates normalized to the image with the origin at the
**top left** (Vision's own origin is bottom left; the handler flips it):

```json
[{"text": "Fett", "x": 0.08, "y": 0.31, "w": 0.10, "h": 0.03, "confidence": 0.98}]
```

Vision usually returns a table row as separate observations per column (label,
"pro 100 g" value, "pro Portion" value) at nearly the same `y`; short labels
sometimes come as one line ("Fett 0,5 g"). The parser has to handle both.

## Fixtures

`test/fixtures/nutrition_labels/*.json` hold OCR outputs with the values the
parser must find. The first set is **synthetic**: modeled on Vision's
row-and-column output for the products from the phase-1 barcode test (values
from their Open Food Facts entries), including typical recognition errors
(`O` for `0`, missing spaces, `Eiweiss`, kJ only, two columns, `<0,5 g`).
Real outputs from the device are added as `real_*.json` once the scan flow
runs on the iPhone; the parser tests pick up every file in the folder.
