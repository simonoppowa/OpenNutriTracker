import 'dart:typed_data';

/// Removes the metadata blocks a camera writes into a photo, so a picture
/// leaving the device carries the pixels and nothing else.
///
/// This exists for one caller: [MealPhotoEncoder]'s fallback path, where the
/// device encoder failed and the app sends the picked file as it found it.
/// The normal path has never needed it — `flutter_image_compress` defaults to
/// `keepExif: false`, and re-encoding produces a container with no metadata
/// to begin with.
///
/// The block that matters is EXIF GPS. A phone camera geotags by default, so
/// an unprocessed original is a photograph of a meal *and* the coordinates of
/// the room it was eaten in. The app tells people it asks for no location
/// permission (README, "Permissions"), which stops being true the moment it
/// forwards coordinates it read out of a file — the permission it never
/// requested is not the only way to learn where someone is. Everything else
/// in there leaves for the same reason: the maker notes, the body serial
/// number some cameras write, the capture timestamp.
///
/// **Refuses rather than guesses.** Every parser returns null as soon as the
/// bytes stop matching the container they claim to be, and the caller treats
/// that as "pick another photo". Passing along bytes we could not account for
/// is the one outcome this must not have — an unparsed file is exactly the
/// file most likely to be hiding something.
class PhotoMetadata {
  /// [bytes] with every metadata block removed, or null when they cannot be
  /// read as [mediaType].
  ///
  /// [mediaType] is the type the caller intends to *declare*, not a guess
  /// from the bytes: the container has to be the one the provider is being
  /// told to expect, or a decoder rejects it on arrival.
  static Uint8List? stripped(Uint8List bytes, String mediaType) {
    switch (mediaType) {
      case 'image/jpeg':
        return _strippedJpeg(bytes);
      case 'image/png':
        return _strippedPng(bytes);
      case 'image/webp':
        return _strippedWebp(bytes);
      case 'image/gif':
        // A GIF has nowhere to put coordinates. Its only metadata extensions
        // are Comment and Application, neither of which is a geotag
        // container, and no camera writes one anyway. Handing the bytes back
        // unchanged is the accurate answer here, not an omission.
        return bytes;
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // JPEG
  // ---------------------------------------------------------------------------

  static const _jpegSoi = 0xD8;
  static const _jpegEoi = 0xD9;
  static const _jpegSos = 0xDA;
  static const _jpegComment = 0xFE;
  static const _jpegTem = 0x01;
  static const _jpegFirstRestart = 0xD0;
  static const _jpegLastRestart = 0xD7;
  static const _jpegFirstApp = 0xE0;
  static const _jpegLastApp = 0xEF;

  static Uint8List? _strippedJpeg(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != _jpegSoi) {
      return null;
    }

    final out = BytesBuilder(copy: false)..add(const [0xFF, _jpegSoi]);
    var i = 2;

    while (i + 1 < bytes.length) {
      // Every segment starts on an `FF <marker>` pair. Anything else means
      // the file is not the JPEG it claims to be, or that a length we trusted
      // was wrong — either way we stop rather than resynchronise, because
      // guessing where the next marker is means guessing what we skipped.
      if (bytes[i] != 0xFF) return null;
      final marker = bytes[i + 1];

      // A run of FFs before the real marker is legal padding.
      if (marker == 0xFF) {
        i++;
        continue;
      }

      // Standalone markers: no length field, no payload.
      if (marker == _jpegTem ||
          (marker >= _jpegFirstRestart && marker <= _jpegLastRestart)) {
        out.add([0xFF, marker]);
        i += 2;
        continue;
      }

      // Scan data is not segmented, so the walk ends here. From this point
      // the file is entropy-coded image up to the end marker: 0xFF is
      // byte-stuffed as `FF 00` and the only markers that can appear are
      // restarts, so the first `FF D9` really is the end of the image.
      //
      // Whatever follows that is dropped. It is not part of the JPEG, and it
      // is where a phone appends its own trailer — Samsung's SEFH block,
      // multi-picture object data, a second full-size copy of the frame.
      if (marker == _jpegSos) {
        final eoi = _indexOfEoi(bytes, i + 2);
        if (eoi == null) return null;
        out.add(Uint8List.sublistView(bytes, i, eoi + 2));
        return out.toBytes();
      }

      if (marker == _jpegEoi) {
        out.add(const [0xFF, _jpegEoi]);
        return out.toBytes();
      }

      if (i + 3 >= bytes.length) return null;
      // The length counts itself but not the two marker bytes.
      final length = (bytes[i + 2] << 8) | bytes[i + 3];
      if (length < 2) return null;
      final end = i + 2 + length;
      if (end > bytes.length) return null;

      // APP1 through APP15 are where the metadata lives: EXIF and XMP in
      // APP1, the IPTC/Photoshop block in APP13, a maker's own scratch space
      // in most of the rest. COM is free text. APP0 stays — it is JFIF, five
      // bytes of pixel density that some decoders look for, and it holds
      // nothing about the photographer.
      final drop =
          (marker > _jpegFirstApp && marker <= _jpegLastApp) ||
          marker == _jpegComment;
      if (!drop) out.add(Uint8List.sublistView(bytes, i, end));
      i = end;
    }

    // Ran out of bytes without reaching a scan or an end marker.
    return null;
  }

  /// Index of the `FF` in the first end-of-image marker at or after [from].
  static int? _indexOfEoi(Uint8List bytes, int from) {
    for (var i = from; i + 1 < bytes.length; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == _jpegEoi) return i;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // PNG
  // ---------------------------------------------------------------------------

  static const _pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  /// Ancillary chunks that hold metadata rather than pixels. `eXIf` is the
  /// EXIF block proper — a screenshot has none, but a photo re-saved as PNG
  /// by an editor keeps it. The text chunks are where captions and editing
  /// history land, and `tIME` is a modification timestamp.
  static const _pngMetadataChunks = {'eXIf', 'tEXt', 'zTXt', 'iTXt', 'tIME'};

  static Uint8List? _strippedPng(Uint8List bytes) {
    if (bytes.length < _pngSignature.length + 12) return null;
    for (var i = 0; i < _pngSignature.length; i++) {
      if (bytes[i] != _pngSignature[i]) return null;
    }

    final out = BytesBuilder(copy: false)..add(_pngSignature);
    var i = _pngSignature.length;

    while (i + 12 <= bytes.length) {
      final length = _readUint32BigEndian(bytes, i);
      // length field + type + data + CRC
      final end = i + 12 + length;
      if (length > bytes.length || end > bytes.length) return null;
      final type = String.fromCharCodes(bytes, i + 4, i + 8);

      // Chunks are copied whole, so the CRC that follows each one stays
      // correct without being recomputed.
      if (!_pngMetadataChunks.contains(type)) {
        out.add(Uint8List.sublistView(bytes, i, end));
      }
      i = end;

      // Anything after the end chunk is not part of the image.
      if (type == 'IEND') return out.toBytes();
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // WebP
  // ---------------------------------------------------------------------------

  /// Feature bits in the `VP8X` flags byte, as libwebp names them.
  static const _vp8xExifFlag = 0x08;
  static const _vp8xXmpFlag = 0x04;

  /// Flags byte, 3 reserved, 3 canvas width, 3 canvas height.
  static const _vp8xPayloadLength = 10;

  static Uint8List? _strippedWebp(Uint8List bytes) {
    if (bytes.length < 12) return null;
    if (_readFourCc(bytes, 0) != 'RIFF' || _readFourCc(bytes, 8) != 'WEBP') {
      return null;
    }

    final chunks = BytesBuilder(copy: false);
    var i = 12;

    while (i + 8 <= bytes.length) {
      final type = _readFourCc(bytes, i);
      final size = _readUint32LittleEndian(bytes, i + 4);
      // Chunks are padded to an even length, and the pad byte is not counted
      // in the size field.
      final end = i + 8 + size + (size.isOdd ? 1 : 0);
      if (size > bytes.length || end > bytes.length) return null;

      if (type == 'EXIF' || type == 'XMP ') {
        i = end;
        continue;
      }

      if (type == 'VP8X') {
        if (size != _vp8xPayloadLength) return null;
        // The flags byte announces which optional chunks the file contains.
        // Dropping a chunk without clearing its bit leaves a file promising
        // metadata it no longer has, which a strict decoder may reject — and
        // this path is already the one where the encoder let us down.
        final header = Uint8List.fromList(Uint8List.sublistView(bytes, i, end));
        header[8] &= ~(_vp8xExifFlag | _vp8xXmpFlag);
        chunks.add(header);
        i = end;
        continue;
      }

      chunks.add(Uint8List.sublistView(bytes, i, end));
      i = end;
    }

    // A partial chunk at the tail is a file we have not fully read.
    if (i != bytes.length) return null;

    final payload = chunks.toBytes();
    final out = Uint8List(12 + payload.length);
    out.setRange(0, 4, 'RIFF'.codeUnits);
    // The RIFF size counts everything after this field: the 'WEBP' tag and
    // the chunks that survived.
    _writeUint32LittleEndian(out, 4, 4 + payload.length);
    out.setRange(8, 12, 'WEBP'.codeUnits);
    out.setRange(12, out.length, payload);
    return out;
  }

  // ---------------------------------------------------------------------------
  // Byte helpers
  // ---------------------------------------------------------------------------

  static String _readFourCc(Uint8List bytes, int offset) =>
      String.fromCharCodes(bytes, offset, offset + 4);

  static int _readUint32BigEndian(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  static int _readUint32LittleEndian(Uint8List bytes, int offset) =>
      bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);

  static void _writeUint32LittleEndian(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
    bytes[offset + 2] = (value >> 16) & 0xFF;
    bytes[offset + 3] = (value >> 24) & 0xFF;
  }
}
