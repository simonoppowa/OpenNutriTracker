import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/photo_metadata.dart';

import '../fixture/photo_fixtures.dart';

/// The guarantee under test is one sentence: a photo that leaves the device on
/// the fallback path carries pixels and nothing about the person who took it.
void main() {
  group('JPEG', () {
    test('the EXIF block does not survive', () {
      // The whole reason this class exists. A phone geotags by default, so an
      // unprocessed camera original says where the meal was eaten — and the
      // app tells people it asks for no location permission.
      final stripped = PhotoMetadata.stripped(
        jpegWithMetadata(),
        'image/jpeg',
      )!;

      expect(containsBytes(stripped, gpsNeedle), isFalse);
    });

    test('the other metadata segments go with it', () {
      // XMP rides in a second APP1, the IPTC/Photoshop block in APP13, and a
      // comment in COM. None of them is pixels.
      final stripped = PhotoMetadata.stripped(
        jpegWithMetadata(),
        'image/jpeg',
      )!;

      expect(containsBytes(stripped, 'ns.adobe.com'), isFalse);
      expect(containsBytes(stripped, 'Photoshop'), isFalse);
      expect(containsBytes(stripped, 'a comment'), isFalse);
    });

    test('the image itself is left intact', () {
      // Removing too much is the other way to fail: a quantisation table is
      // as close to the pixels as a segment gets, and JFIF is pixel density
      // rather than metadata, so both stay.
      final stripped = PhotoMetadata.stripped(
        jpegWithMetadata(),
        'image/jpeg',
      )!;

      expect(containsBytes(stripped, jpegDqtNeedle), isTrue);
      expect(containsBytes(stripped, jpegJfifNeedle), isTrue);
      expect(stripped.sublist(0, 2), [0xFF, 0xD8]);
      expect(stripped.sublist(stripped.length - 2), [0xFF, 0xD9]);
    });

    test('a block appended after the end marker is dropped', () {
      // Phones append their own trailers past EOI — Samsung writes an SEFH
      // block there, and multi-picture data can hold a second full-size copy
      // of the frame. It is not part of the image and it is not sent.
      final stripped = PhotoMetadata.stripped(
        jpegWithMetadata(
          trailer: [...'SEFH'.codeUnits, ...gpsNeedle.codeUnits],
        ),
        'image/jpeg',
      )!;

      expect(containsBytes(stripped, 'SEFH'), isFalse);
      expect(containsBytes(stripped, gpsNeedle), isFalse);
    });

    test('scan data that looks like a marker is not mistaken for one', () {
      // Entropy-coded data byte-stuffs 0xFF as `FF 00` and may carry restart
      // markers. Copying from the scan to the end marker verbatim is what
      // keeps that from being reinterpreted as segment framing.
      final stripped = PhotoMetadata.stripped(
        jpegWithMetadata(),
        'image/jpeg',
      )!;

      expect(
        containsBytes(stripped, String.fromCharCodes([0xFF, 0x00, 0xFF, 0xD0])),
        isTrue,
      );
    });

    test('bytes that are not a JPEG are refused, not passed through', () {
      // What the encoder's fallback used to send unexamined. Refusing means
      // the user is told to pick another photo; passing it through would mean
      // shipping bytes nothing has accounted for.
      expect(
        PhotoMetadata.stripped(
          Uint8List.fromList(List.filled(2000, 0)),
          'image/jpeg',
        ),
        isNull,
      );
    });

    test('a truncated JPEG is refused', () {
      final full = jpegWithMetadata();
      expect(
        PhotoMetadata.stripped(full.sublist(0, full.length ~/ 2), 'image/jpeg'),
        isNull,
      );
    });

    test('a segment length running past the end is refused', () {
      // A malformed length is how a walk gets led out of bounds, and a parser
      // that resynchronised after one would be guessing at what it skipped.
      final bytes = Uint8List.fromList([
        0xFF, 0xD8,
        0xFF, 0xE1, 0x7F, 0xFF, // APP1 claiming 32 KB in a 6-byte file
      ]);

      expect(PhotoMetadata.stripped(bytes, 'image/jpeg'), isNull);
    });
  });

  group('PNG', () {
    test('the eXIf and text chunks do not survive', () {
      // A screenshot has none of this, but a photo re-saved as PNG by an
      // editor keeps its EXIF in an `eXIf` chunk.
      final stripped = PhotoMetadata.stripped(pngWithMetadata(), 'image/png')!;

      expect(containsBytes(stripped, gpsNeedle), isFalse);
      // The keyword is NUL-separated from the text in a tEXt chunk, so the
      // needle has to span the NUL or the assertion passes for free.
      expect(containsBytes(stripped, 'Comment\x00hello'), isFalse);
      expect(containsBytes(stripped, 'com.adobe.xmp'), isFalse);
    });

    test('the header and pixel chunks are left intact', () {
      final stripped = PhotoMetadata.stripped(pngWithMetadata(), 'image/png')!;

      expect(containsBytes(stripped, 'IHDR'), isTrue);
      expect(containsBytes(stripped, pngIdatNeedle), isTrue);
      expect(stripped.sublist(0, 8), pngSignature);
    });

    test('anything after the end chunk is dropped', () {
      final stripped = PhotoMetadata.stripped(
        pngWithMetadata(trailer: gpsNeedle.codeUnits),
        'image/png',
      )!;

      expect(containsBytes(stripped, gpsNeedle), isFalse);
      expect(containsBytes(stripped, 'IEND'), isTrue);
    });

    test('a chunk length running past the end is refused', () {
      final bytes = Uint8List.fromList([
        ...pngSignature,
        0x7F, 0xFF, 0xFF, 0xFF, // a chunk claiming two gigabytes
        ...'IHDR'.codeUnits,
        0x00, 0x00, 0x00, 0x00,
      ]);

      expect(PhotoMetadata.stripped(bytes, 'image/png'), isNull);
    });

    test('a PNG with no end chunk is refused', () {
      final bytes = Uint8List.fromList([
        ...pngSignature,
        ...pngChunk('IHDR', List.filled(13, 0x01)),
      ]);

      expect(PhotoMetadata.stripped(bytes, 'image/png'), isNull);
    });
  });

  group('WebP', () {
    test('the EXIF and XMP chunks do not survive', () {
      final stripped = PhotoMetadata.stripped(
        webpWithMetadata(),
        'image/webp',
      )!;

      expect(containsBytes(stripped, gpsNeedle), isFalse);
      expect(containsBytes(stripped, 'EXIF'), isFalse);
      expect(containsBytes(stripped, 'XMP '), isFalse);
    });

    test('the frame is left intact', () {
      final stripped = PhotoMetadata.stripped(
        webpWithMetadata(),
        'image/webp',
      )!;

      expect(containsBytes(stripped, webpFrameNeedle), isTrue);
      expect(containsBytes(stripped, 'VP8X'), isTrue);
    });

    test('the flags stop advertising metadata, without losing alpha', () {
      // Dropping a chunk but leaving its bit set produces a file that
      // promises metadata it does not have, which a strict decoder may
      // reject — and this path is already the one where the encoder failed.
      // Clearing the whole byte would lose the alpha channel instead.
      final stripped = PhotoMetadata.stripped(
        webpWithMetadata(),
        'image/webp',
      )!;

      // 'RIFF' + size + 'WEBP' + 'VP8X' + size, then the flags byte.
      const flagsOffset = 12 + 8;
      expect(stripped[flagsOffset] & 0x08, 0, reason: 'EXIF bit still set');
      expect(stripped[flagsOffset] & 0x04, 0, reason: 'XMP bit still set');
      expect(stripped[flagsOffset] & webpAlphaFlag, webpAlphaFlag);
    });

    test('the RIFF size is rewritten to match what is left', () {
      // The container declares its own length. Removing chunks without
      // correcting it leaves a file that runs past its own end.
      final stripped = PhotoMetadata.stripped(
        webpWithMetadata(),
        'image/webp',
      )!;

      final declared =
          stripped[4] |
          (stripped[5] << 8) |
          (stripped[6] << 16) |
          (stripped[7] << 24);

      expect(declared, stripped.length - 8);
    });

    test('an odd-sized chunk keeps its pad byte accounted for', () {
      // RIFF pads chunks to an even length without counting the pad in the
      // size field. Getting that wrong walks the parser off by one and every
      // later chunk reads as garbage.
      final stripped = PhotoMetadata.stripped(webpWithMetadata(), 'image/webp');

      // The fixture's frame payload is odd-length, so a mishandled pad byte
      // would have made the walk fail outright.
      expect(stripped, isNotNull);
      expect(containsBytes(stripped!, webpFrameNeedle), isTrue);
    });

    test('bytes that are not a RIFF/WEBP container are refused', () {
      expect(
        PhotoMetadata.stripped(
          Uint8List.fromList(List.filled(64, 0x41)),
          'image/webp',
        ),
        isNull,
      );
    });
  });

  group('GIF', () {
    test('is returned unchanged, having nowhere to hide a location', () {
      // Comment and Application are its only extensions and neither is a
      // geotag container. Saying so plainly beats rewriting a format no
      // camera produces.
      final gif = gifWithComment();

      expect(PhotoMetadata.stripped(gif, 'image/gif'), gif);
    });
  });

  test('a media type the app does not send is refused', () {
    // HEIC never reaches here — mediaTypeForPath rejects it first — but a
    // stripper that returned bytes for a type it cannot parse would be the
    // silent failure this class is built to avoid.
    expect(PhotoMetadata.stripped(jpegWithMetadata(), 'image/heic'), isNull);
  });

  test('an empty file is refused in every container', () {
    for (final type in const ['image/jpeg', 'image/png', 'image/webp']) {
      expect(PhotoMetadata.stripped(Uint8List(0), type), isNull, reason: type);
    }
  });
}
