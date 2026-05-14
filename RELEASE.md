# Release notes for maintainers

This file collects small, practical notes for cutting an OpenNutriTracker release. It is aimed at Simon and anyone helping him with the release pipeline, rather than at people installing the app.

## Generating the SHA256 fingerprint

When publishing a new APK to GitHub Releases (and in future to F-Droid), a security-conscious person installing the build may want to verify that it was signed by the same release key as every other official build. The README has a `Verifying APK signatures` section that points them at the canonical SHA256 fingerprint of the release certificate — this section is the reference for keeping that value accurate.

The fingerprint comes straight from the release keystore. With the keystore path and alias from `android/key.properties`, run:

```sh
keytool -list -v -keystore /path/to/release.keystore -alias <alias>
```

Look for the `SHA256:` line under `Certificate fingerprints`. The value is stable for the lifetime of the keystore — it only changes if the signing key itself is rotated, which would also force every existing installation to uninstall before upgrading — so once the README has the right value, it should not need to be touched again on routine releases.

If the key is ever rotated, update the fingerprint in `README.md` in the same commit as the key change, so that anyone verifying a freshly downloaded APK against the README sees the new value as soon as the new build is published.
