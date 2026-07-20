# Testing

## Local Checks

```sh
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --coverage
cd android
./gradlew :app:testDebugUnitTest
```

Concurrency is fixed at one because parallel `flutter_tester` startup has been
unreliable on some Windows hosts. This does not reduce test isolation.

## Emulator Integration Test

Start `Stickers_API_35`, then run:

```sh
flutter test integration_test/app_smoke_test.dart -d emulator-5554
```

The test launches the real application and persists data inside the `.dev`
package only. Clear that package before tests that require a clean install:

```sh
adb -s emulator-5554 shell pm clear de.loicezt.stickers.dev
```

## Coverage Expectations

- Pure policies and parsers require unit tests for every boundary condition.
- Pack commands require success and persistence-failure rollback tests.
- User workflows require widget tests using stable keys rather than display
  text where possible.
- Platform-channel map contracts require Kotlin unit tests.
- GIF/video encoding changes require an emulator fixture smoke test and output
  validation for dimensions, duration, animation, and file size.

CI runs formatting, analysis, Dart tests, Kotlin tests, a debug APK build, and
the Android emulator smoke test on every push and pull request.
