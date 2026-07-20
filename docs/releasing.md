# Releasing

## Android Identity

The production application ID remains `de.loicezt.stickers` so existing users
can install updates over the current application. Debug builds use the `.dev`
suffix and isolated data. Changing the production ID later creates a separate
application and requires an explicit data migration; treat that as a release
decision rather than a refactor.

## Signing Secrets

Configure these GitHub repository secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

Encode the keystore as one base64 string. Keep the original keystore and
passwords in an offline backup: losing them prevents updates signed as the same
Android application.

## Publishing

1. Ensure CI is green on the intended commit.
2. Update the version in `pubspec.yaml`.
3. Create and push an annotated `vX.Y.Z` tag.
4. The release workflow runs analysis and tests, builds signed APK and AAB
   artifacts, calculates SHA-256 checksums, and creates the GitHub release.
5. Install the release APK over the previous production version before wider
   publication.

The Gradle release build is unsigned when `android/key.properties` is absent.
The GitHub release workflow deliberately fails unless all signing secrets are
present. Never publish a debug-signed APK as a production update.
