# constituency

A new Flutter project.

## Getting Started

2. Configure Firebase:
   - Add `android/app/google-services.json`
   - Add `ios/Runner/GoogleService-Info.plist`
   - Ensure the Firebase project has Auth, Firestore, Storage, and Analytics enabled

3. Install dependencies:

```bash
flutter pub get
```

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Local Development

```bash
flutter analyze
flutter test
flutter run
```

## Firebase Security Rules

Firestore rules are defined in `firestore.rules` and mapped in `firebase.json`.

## Notes

- Android min SDK is set to 21.
- Firestore persistence is enabled in app bootstrap.
- If API keys are missing, the app uses placeholder fallback content for news/nominees.
