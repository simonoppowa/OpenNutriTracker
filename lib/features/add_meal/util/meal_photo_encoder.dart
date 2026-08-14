import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';

/// Turns a photo the user just picked into bytes that can be sent, without
/// ever writing it to disk.
///
/// Deliberately not [UserImageStorage], which this otherwise resembles. That
/// class persists a photo the user chose to keep and hands back a path; this
/// one produces bytes that exist for one request and are then gone. Sharing
/// the code would mean sharing the file write, and a meal photo that lands in
/// the documents directory is a photo the export zip picks up and the user
/// never asked to keep.
///
/// The encoding — WebP, quality 80, longest edge 1024 px — matches
/// `UserImageStorage` on purpose. It is the pipeline this app already trusts
/// for food photography, the provider accepts WebP natively so nothing
/// transcodes it on arrival, and a 1024 px image is about 1400 visual tokens,
/// which is what makes this cost fractions of a cent.
class MealPhotoEncoder {
  /// Raw bytes we will hand to the provider, before base64 inflates them by
  /// a third. Chosen to stay comfortably inside the per-image limit rather
  /// than to sit on it.
  ///
  /// In practice a 1024 px WebP is 80–200 KB, so this never fires on the
  /// normal path. It exists for [_rawBytes], where a device with no WebP
  /// encoder sends the camera's original file — which on a recent phone can
  /// be eight megabytes of full-resolution JPEG.
  @visibleForTesting
  static const maxBytes = 3 * 1024 * 1024;

  /// What the provider accepts, keyed by the extension the picker hands us.
  static const _mediaTypes = {
    'webp': 'image/webp',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
  };

  /// Encodes the file at [sourcePath], or null when it cannot produce
  /// something sendable. Null is a normal outcome the caller shows a message
  /// for — it is not worth an exception, because there is exactly one thing
  /// the user can do about any of its causes: pick a different photo.
  static Future<MealPhoto?> encode(String sourcePath) async {
    final compressed = await _compressToWebP(sourcePath);
    if (compressed != null) {
      return _fitting(compressed, 'image/webp');
    }

    // No WebP encoder on this device. Send the original if the provider
    // takes that format, rather than failing over an encoder the user has
    // no way to install.
    final mediaType = mediaTypeForPath(sourcePath);
    if (mediaType == null) return null;
    final raw = await _rawBytes(sourcePath);
    if (raw == null) return null;
    return _fitting(raw, mediaType);
  }

  /// The provider media type for a path's extension, or null when it is one
  /// the provider does not accept — an iPhone `.heic` straight off the
  /// filesystem, say.
  @visibleForTesting
  static String? mediaTypeForPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return null;
    return _mediaTypes[path.substring(dot + 1).toLowerCase()];
  }

  static MealPhoto? _fitting(Uint8List bytes, String mediaType) {
    if (bytes.isEmpty || bytes.length > maxBytes) return null;
    return MealPhoto(bytes: bytes, mediaType: mediaType);
  }

  static Future<Uint8List?> _compressToWebP(String sourcePath) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        sourcePath,
        format: CompressFormat.webp,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
        // `minWidth`/`minHeight` are upper bounds for the *longest* edge
        // when the source exceeds them; the compressor preserves aspect
        // ratio. Shorter-edge images pass through untouched.
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _rawBytes(String sourcePath) async {
    try {
      return await File(sourcePath).readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
