/// Thrown when local Hive data cannot be opened safely — most often because
/// the AES key is missing/empty in secure storage while non-empty `*.hive`
/// files still exist, or because the key no longer decrypts the on-disk
/// frames.
///
/// Intentionally distinct from a generic [StateError] so bootstrap can
/// classify key-loss / decrypt failures without mistaking them for ordinary
/// bugs. Callers must not mint a new key or enable Hive crash recovery in
/// response; either would silently wipe user data.
class HiveStorageIntegrityException implements Exception {
  HiveStorageIntegrityException(this.code, this.message, {this.cause});

  /// Stable machine-readable reason for logs and (post-consent) diagnostics.
  final String code;
  final String message;
  final Object? cause;

  factory HiveStorageIntegrityException.emptyKey() =>
      HiveStorageIntegrityException(
        'hive_encryption_key_empty',
        'Hive encryption key is present in secure storage but empty. '
            'Refusing to open or recreate the local database.',
      );

  factory HiveStorageIntegrityException.missingKeyWithExistingData() =>
      HiveStorageIntegrityException(
        'hive_encryption_key_missing_with_existing_data',
        'Hive encryption key is missing from secure storage, but non-empty '
            'Hive database files already exist. Refusing to generate a new key '
            'because that would silently wipe local user data.',
      );

  factory HiveStorageIntegrityException.malformedKey(Object cause) =>
      HiveStorageIntegrityException(
        'hive_encryption_key_malformed',
        'Hive encryption key in secure storage is not valid base64url. '
            'Refusing to open or recreate the local database.',
        cause: cause,
      );

  factory HiveStorageIntegrityException.wrongKeyOrCorrupted(Object cause) =>
      HiveStorageIntegrityException(
        'hive_wrong_key_or_corrupted',
        'Failed to open an encrypted Hive box (wrong key or corrupted frames). '
            'Leaving the on-disk files untouched.',
        cause: cause,
      );

  @override
  String toString() {
    final causeSuffix = cause == null ? '' : ' (cause: $cause)';
    return 'HiveStorageIntegrityException($code): $message$causeSuffix';
  }
}
