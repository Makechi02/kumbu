# Kumbu: setup (Android)

1. Create the project and add packages:

       flutter create --org ke.trendymart --platforms=android kumbu
       cd kumbu
       flutter pub add sqflite path uuid intl google_fonts shared_preferences local_auth:^2.3.0 file_picker:^8.1.0

   `local_auth` (2.x) and `file_picker` (8.x) are pinned because the code is written against
   those APIs. Newer major versions may have changed them.

   Already have the project running? Just add the two new packages:

       flutter pub add shared_preferences file_picker:^8.1.0

2. Delete `test/widget_test.dart` (it references the default app), then copy this
   folder's `lib/` over the generated `lib/`.

3. Android setup for the biometric lock. Check the "Android Integration" section of
   the local_auth page on pub.dev for the current steps. At the time of writing they are:
   - In `android/app/src/main/AndroidManifest.xml`, add above `<application>`:
         <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
   - In `android/app/src/main/kotlin/.../MainActivity.kt`, make `MainActivity` extend
     `FlutterFragmentActivity` (import `io.flutter.embedding.android.FlutterFragmentActivity`).
   - In the same manifest, set `android:label="Kumbu"` on the `<application>` tag, so the app shows that name on your phone.
   - If the build complains about the minimum SDK, raise `minSdk` in `android/app/build.gradle(.kts)`.

4. Run on your phone (USB debugging on): `flutter run`.
   For a standalone install: `flutter build apk --release`, then install the APK from
   `build/app/outputs/flutter-apk/`.

5. Open the app once with internet so Lora and Karla download. `google_fonts` caches them
   after that. To bundle them in the app instead, see the google_fonts README.
