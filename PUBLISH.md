# Publishing headphones_detection to pub.dev

## Prerequisites

1. Create a pub.dev account at https://pub.dev
2. Verify your email address
3. Get your API key from https://pub.dev/account/api

## Publishing Steps

### 1. Update version in pubspec.yaml
```yaml
version: 1.0.0  # Update this version number
```

### 2. Update CHANGELOG.md
Add your changes to the changelog with the new version.

### 3. Test the package
```bash
cd packages/headphones_detection
flutter pub get
flutter test
```

### 4. Check package health
```bash
flutter pub publish --dry-run
```

### 5. Publish to pub.dev
```bash
flutter pub publish
```

## After Publishing

1. The package will be available at: https://pub.dev/packages/headphones_detection
2. Update the main project to use the published version instead of local path
3. Update documentation with the published package URL

## Updating the Main Project

After publishing, update the main project's pubspec.yaml:

```yaml
dependencies:
  headphones_detection: ^1.0.0  # Use published version
```

Instead of:
```yaml
dependencies:
  headphones_detection:
    path: ./packages/headphones_detection  # Local path
```