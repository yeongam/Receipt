# app_001

A new Flutter project.

## Supabase configuration

Supabase URL and anon key are not hard-coded in source. Provide them at run or
build time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

For local development, fill `.env` and run:

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

This does not pin the app to a specific device or platform. Select the target
device in your IDE or Flutter's device picker when needed.

Use Flutter 3.38.4 or newer. Generated local files such as `.dart_tool/`,
`build/`, `android/local.properties`, and `ios/Flutter/Generated.xcconfig`
should be recreated on each machine, not copied as source.

The `.env` file is local-only and ignored by git. Keep `.env.example` updated
when required environment keys change.

For release builds, pass the same values to `flutter build`. The Supabase anon
key is a public client key, not a private server secret; protect data with RLS
policies and keep any `service_role` key server-side only.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

0429wed test comp
