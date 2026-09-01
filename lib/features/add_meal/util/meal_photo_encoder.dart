import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/photo_metadata.dart';

/// The container a photo is encoded into. **Quality and size are identical
/// either way** — only the container changes.
///
/// It is a per-destination choice because the destinations genuinely
/// disagree, and #747 measured where: llama.cpp decodes with `stb_image`,
/// whose format list has no WebP, and ships a WebP-to-PNG converter in its
/// own web UI to work around exactly that. Ollama accepts WebP but refuses a
/// GIF; vLLM opens whatever Pillow opens.
enum MealPhotoFormat {
  /// What the hosted three get. Anthropic accepts it natively so nothing
  /// transcodes on arrival, and the payload crosses the internet, where the
  /// smaller of two lossy formats is worth having.
  webp(CompressFormat.webp, 'image/webp'),

  /// What a server the user runs gets. **All four runtimes decode JPEG**, so
  /// choosing it removes the incompatibility rather than detecting it.
  ///
  /// It costs roughly 1.5-2x the bytes at the same quality. That is the
  /// cheapest resource in this picture: the request crosses a LAN to hardware
  /// the user owns, to a model that will then spend twenty seconds thinking
  /// about it (#774).
  jpeg(CompressFormat.jpeg, 'image/jpeg');

  final CompressFormat compress;

  final String mediaType;

  const MealPhotoFormat(this.compress, this.mediaType);

  /// Exhaustive on purpose. A fifth provider has to answer this question
  /// rather than inherit whichever answer a wildcard happened to give it.
  static MealPhotoFormat forProvider(AiProvider provider) => switch (provider) {
    AiProvider.anthropic || AiProvider.openrouter || AiProvider.openai => webp,
    AiProvider.ownServer => jpeg,
  };
}

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
/// The encoding — quality 80, shortest edge 1024 px — matches
/// `UserImageStorage` on purpose. It is the pipeline this app already trusts
/// for food photography, and a 1024 px image is about 1400 visual tokens,
/// which is what makes this cost fractions of a cent where anyone is charging
/// for it. Only the container varies, per [MealPhotoFormat].
class MealPhotoEncoder {
  /// Raw bytes we will hand to the provider, before base64 inflates them by
  /// a third. Chosen to stay comfortably inside the per-image limit rather
  /// than to sit on it.
  ///
  /// In practice a 1024 px WebP is 80–200 KB and a JPEG at the same quality
  /// is under half a megabyte, so this never fires on the normal path. It
  /// exists for [_rawBytes], where a device whose encoder failed sends the
  /// camera's original file — which on a recent phone can be eight megabytes
  /// of full-resolution JPEG.
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

  /// Encodes the file at [sourcePath] and then deletes it.
  ///
  /// Use this for anything that came from the image picker. `image_picker`
  /// does not hand back the user's original: it copies the chosen photo into
  /// the app's cache directory and returns that path, and it never cleans the
  /// copy up. Verified on a Pixel 6 — after one pick, the full JPEG was still
  /// sitting in `cache/` byte for byte.
  ///
  /// That copy is what makes "the app keeps no photo" false, so the app
  /// removes it. The deletion runs even when encoding failed, because a photo
  /// the provider rejected is exactly as unwelcome on disk as one it read.
  static Future<MealPhoto?> encodeAndDiscardSource(
    String sourcePath, {
    required MealPhotoFormat format,
  }) async {
    try {
      return await encode(sourcePath, format: format);
    } finally {
      try {
        final file = File(sourcePath);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best effort. A cache file we could not remove is not worth
        // failing the user's meal entry over, and the OS clears it later.
      }
    }
  }

  /// Encodes the file at [sourcePath], or null when it cannot produce
  /// something sendable. Null is a normal outcome the caller shows a message
  /// for — it is not worth an exception, because there is exactly one thing
  /// the user can do about any of its causes: pick a different photo.
  ///
  /// Leaves [sourcePath] alone. Callers holding a picker temp file want
  /// [encodeAndDiscardSource] instead.
  /// [format] has no default. Which container a destination can read is the
  /// whole of what #747 settled, and a default here would quietly become the
  /// answer for a caller that forgot to ask — which is precisely how a
  /// llama.cpp user ends up sent a WebP it cannot decode.
  static Future<MealPhoto?> encode(
    String sourcePath, {
    required MealPhotoFormat format,
  }) async {
    final compressed = await _compress(sourcePath, format);
    if (compressed != null) {
      return _fitting(compressed, format.mediaType);
    }

    // The encoder failed. Send the original if the destination takes that
    // format, rather than failing over an encoder the user has no way to
    // install. Far rarer on the JPEG path — JPEG encoders are universal
    // where WebP's are not — which is why Ollama's refusal of a GIF here
    // stops being a problem worth its own rule (#747).
    final mediaType = mediaTypeForPath(sourcePath);
    if (mediaType == null) return null;
    final raw = await _rawBytes(sourcePath);
    if (raw == null) return null;

    // These bytes have not been through an encoder, so they still carry
    // whatever the camera wrote into them — including the GPS block, which is
    // the one thing in a meal photo that is about the user rather than the
    // meal. The normal path is clean for free, because re-encoding writes a
    // container with no metadata in it; this path has to be cleaned.
    //
    // Null when the file cannot be parsed as the type its extension claims.
    // That narrows the fallback, on purpose: an unreadable file is the one
    // most likely to be carrying something, and "pick another photo" is a
    // better answer than sending bytes we could not account for.
    final stripped = PhotoMetadata.stripped(raw, mediaType);
    if (stripped == null) return null;

    // What survives is still full-resolution — stripping metadata is not
    // resizing, and there is no encoder here to resize with. The size ceiling
    // in [maxBytes] is what bounds it.
    return _fitting(stripped, mediaType);
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

  static Future<Uint8List?> _compress(
    String sourcePath,
    MealPhotoFormat format,
  ) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        sourcePath,
        format: format.compress,
        // Identical for both containers. A photo that reads well at q80 as a
        // WebP is not a different photograph because it went to a machine in
        // the user's house, and varying quality per destination would make
        // "the model misread it" unanswerable.
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
        // The package's default, pinned so it is a decision rather than an
        // inheritance. A meal photo's EXIF is the camera's GPS fix and the
        // body's serial number; none of it helps a model read the plate, and
        // the app promises it asks for no location. [PhotoMetadata] does the
        // same job on the fallback path below, where no encoder runs.
        keepExif: false,
        // `minWidth`/`minHeight` bound the *shortest* edge, not the longest.
        // The compressor takes `min(width/minWidth, height/minHeight)` as its
        // scale factor, so the smaller ratio wins and the edge that lands on
        // 1024 is the short one: a 4080x3072 frame comes out 1360x1024, and a
        // 16:9 frame wider still. Aspect ratio is preserved and an image
        // already smaller than 1024 on both edges passes through untouched.
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _rawBytes(String sourcePath) async {
    try {
      final file = File(sourcePath);
      // Checked before reading, not after. This path exists for a device
      // whose encoder failed, where the file is the camera's own output — a
      // recent phone produces eight megabytes of it, and pulling all of that
      // into memory only to hand it to `_fitting` and have it thrown away is
      // a burst of allocation on the device least able to absorb one.
      if (await file.length() > maxBytes) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
