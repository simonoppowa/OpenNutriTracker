import 'dart:typed_data';

/// Minimal, hand-built image containers for testing metadata removal.
///
/// Synthetic rather than a real photograph on purpose. A committed JPEG with
/// a real GPS fix in it is a location in the repository forever, and a
/// checked-in binary is the one fixture nobody can read a diff of. These are
/// structurally valid — the right signatures, real segment and chunk framing,
/// correct padding — which is all the parsers under test look at. They are
/// not decodable images and are not meant to be.
///
/// Each carries [gpsNeedle] where a camera would put the block that matters,
/// so a test can assert on its absence by searching the bytes.

// dart format off
//
// These are byte tables. The formatter breaks a list with a trailing comma
// onto one element per line, which turns a readable segment header into a
// forty-line column and hides the structure the fixtures exist to show.

/// The stand-in for an EXIF GPS fix: a byte run no valid header or framing
/// field can produce, so finding it in an output means the block survived.
const gpsNeedle = 'GPS:52.5200,13.4050';

/// Whether [needle] appears anywhere in [bytes].
bool containsBytes(Uint8List bytes, String needle) {
  final target = needle.codeUnits;
  if (target.isEmpty || target.length > bytes.length) return false;
  for (var i = 0; i <= bytes.length - target.length; i++) {
    var match = true;
    for (var j = 0; j < target.length; j++) {
      if (bytes[i + j] != target[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}

// -----------------------------------------------------------------------------
// JPEG
// -----------------------------------------------------------------------------

/// The marker payload a decoder must keep: a quantisation table is as close
/// to the pixels as a segment gets, and dropping it would break the image.
const jpegDqtNeedle = 'DQT-KEEP-ME';

/// A JFIF density block, which stays because APP0 is not metadata.
const jpegJfifNeedle = 'JFIF';

/// A length-prefixed JPEG segment. The length counts itself and the payload,
/// but not the two marker bytes.
List<int> jpegSegment(int marker, List<int> payload) {
  final length = payload.length + 2;
  return [0xFF, marker, (length >> 8) & 0xFF, length & 0xFF, ...payload];
}

/// A JPEG carrying everything the stripper is supposed to remove — EXIF in
/// APP1, a comment, an XMP-style APP1 and a Photoshop-style APP13 — alongside
/// the JFIF block and quantisation table it must keep.
///
/// [trailer] is appended after the end-of-image marker, the way a phone
/// appends its own block: it should not survive either.
Uint8List jpegWithMetadata({List<int> trailer = const []}) =>
    Uint8List.fromList([
      0xFF, 0xD8, // SOI
      ...jpegSegment(0xE0, [
        ...jpegJfifNeedle.codeUnits,
        0x00, 0x01, 0x02, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00
      ]), // APP0/JFIF — keep
      ...jpegSegment(0xE1, [
        ...'Exif'.codeUnits, 0x00, 0x00, ...gpsNeedle.codeUnits
      ]), // APP1/EXIF — drop
      // The real APP1 XMP identifier is NUL-terminated, as is the APP13
      // Photoshop one and a PNG text chunk's keyword. Written as escapes so
      // the bytes stay authentic without the file reading as binary to git.
      ...jpegSegment(0xE1, 'http://ns.adobe.com/xap/1.0/\x00tagged'.codeUnits),
      ...jpegSegment(0xED, 'Photoshop 3.0\x00IPTC'.codeUnits), // APP13 — drop
      ...jpegSegment(0xFE, 'a comment'.codeUnits), // COM — drop
      ...jpegSegment(0xDB, jpegDqtNeedle.codeUnits), // DQT — keep
      ...jpegSegment(0xDA, [0x01, 0x01, 0x00, 0x00, 0x3F, 0x00]), // SOS
      // Entropy data, including a byte-stuffed 0xFF and a restart marker, so
      // the walk is exercised against bytes that look like markers.
      0x12, 0x34, 0xFF, 0x00, 0xFF, 0xD0, 0x56,
      0xFF, 0xD9, // EOI
      ...trailer,
    ]);

// -----------------------------------------------------------------------------
// PNG
// -----------------------------------------------------------------------------

const pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

/// Payload that must survive, standing in for compressed pixel data.
const pngIdatNeedle = 'IDAT-KEEP-ME';

/// A PNG chunk: big-endian length, four-character type, data, CRC.
///
/// The CRC is a placeholder. Nothing under test validates it — chunks are
/// copied whole, so a real file's CRCs stay correct without being recomputed,
/// and computing one here would only be testing the test.
List<int> pngChunk(String type, List<int> data) => [
  (data.length >> 24) & 0xFF,
  (data.length >> 16) & 0xFF,
  (data.length >> 8) & 0xFF,
  data.length & 0xFF,
  ...type.codeUnits,
  ...data,
  0xDE, 0xAD, 0xBE, 0xEF,
];

/// A PNG with an `eXIf` block and two text chunks to remove, around the
/// header and pixel chunks that have to stay.
Uint8List pngWithMetadata({List<int> trailer = const []}) =>
    Uint8List.fromList([
      ...pngSignature,
      ...pngChunk('IHDR', List.filled(13, 0x01)),
      ...pngChunk('eXIf', gpsNeedle.codeUnits),
      ...pngChunk('tEXt', 'Comment\x00hello'.codeUnits),
      ...pngChunk('iTXt', 'XML:com.adobe.xmp\x00tagged'.codeUnits),
      ...pngChunk('tIME', List.filled(7, 0x02)),
      ...pngChunk('IDAT', pngIdatNeedle.codeUnits),
      ...pngChunk('IEND', const []),
      ...trailer,
    ]);

// -----------------------------------------------------------------------------
// WebP
// -----------------------------------------------------------------------------

/// Payload that must survive, standing in for the compressed frame.
const webpFrameNeedle = 'VP8-KEEP-ME';

/// The alpha bit. Set in the fixture so a test can prove the stripper clears
/// the two metadata bits without flattening the whole flags byte.
const webpAlphaFlag = 0x10;

/// A RIFF chunk: four-character type, little-endian size, payload, and a pad
/// byte when the size is odd.
List<int> webpChunk(String type, List<int> data) => [
  ...type.codeUnits,
  data.length & 0xFF,
  (data.length >> 8) & 0xFF,
  (data.length >> 16) & 0xFF,
  (data.length >> 24) & 0xFF,
  ...data,
  if (data.length.isOdd) 0x00,
];

/// An extended-format WebP whose `VP8X` flags advertise EXIF and XMP, with
/// both chunks present.
Uint8List webpWithMetadata() {
  final chunks = <int>[
    ...webpChunk('VP8X', [
      webpAlphaFlag | 0x08 | 0x04, // alpha + EXIF + XMP
      0x00, 0x00, 0x00, // reserved
      0xFF, 0x00, 0x00, // canvas width - 1
      0xFF, 0x00, 0x00, // canvas height - 1
    ]),
    ...webpChunk('VP8 ', webpFrameNeedle.codeUnits),
    ...webpChunk('EXIF', gpsNeedle.codeUnits),
    ...webpChunk('XMP ', 'tagged'.codeUnits),
  ];
  return Uint8List.fromList([
    ...'RIFF'.codeUnits,
    (4 + chunks.length) & 0xFF,
    ((4 + chunks.length) >> 8) & 0xFF,
    ((4 + chunks.length) >> 16) & 0xFF,
    ((4 + chunks.length) >> 24) & 0xFF,
    ...'WEBP'.codeUnits,
    ...chunks,
  ]);
}

// -----------------------------------------------------------------------------
// GIF
// -----------------------------------------------------------------------------

/// A GIF89a header with a comment extension and a trailer. Nothing in here
/// can hold coordinates, which is the point.
Uint8List gifWithComment() => Uint8List.fromList([
  ...'GIF89a'.codeUnits,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, // logical screen descriptor
  0x21, 0xFE, 0x05, ...'hello'.codeUnits, 0x00, // comment extension
  0x3B, // trailer
]);

// dart format on
