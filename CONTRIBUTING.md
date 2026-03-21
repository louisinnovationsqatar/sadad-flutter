# Contributing to sadad_flutter

Thank you for your interest in contributing to this project!

## How to Contribute

### Reporting Issues

Before reporting an issue, please check if it already exists in the issue tracker. When reporting a bug, use the provided bug report template and include as much detail as possible — especially the Flutter and Dart SDK versions, the target platform (iOS, Android, Web), and the checkout version (v1.1, v2.1, v2.2).

### Submitting Changes

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/your-username/sadad-flutter.git
   cd sadad-flutter
   ```
3. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/my-new-feature
   ```
   Use descriptive branch names such as `feature/add-apple-pay-fallback` or `fix/webview-callback-interception`.

4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

5. **Make your changes** following the existing code style and conventions.

6. **Write tests** for your changes. Widget tests live in `test/`. All new widgets must include widget tests.

7. **Run the test suite** and ensure all tests pass:
   ```bash
   flutter test
   ```

8. **Run the analyzer** to check for issues:
   ```bash
   flutter analyze
   ```

9. **Format your code**:
   ```bash
   dart format .
   ```

10. **Commit your changes** with a clear, descriptive commit message:
    ```bash
    git commit -m "Add support for custom payment page title"
    ```

11. **Push** to your fork:
    ```bash
    git push origin feature/my-new-feature
    ```

12. **Open a Pull Request** against the `main` branch with a clear title and description.

## Code Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Follow [Flutter widget best practices](https://docs.flutter.dev/development/ui/widgets-intro)
- Use Dart 3.0+ features (records, patterns, switch expressions) where appropriate
- Write clear, self-documenting code with doc comments (`///`) for all public APIs
- Keep widgets focused and composable
- Use `const` constructors wherever possible
- Handle exceptions gracefully and surface meaningful error messages to `onFailure` callbacks

## Platform Testing

Before submitting a PR that touches WebView behaviour, please test on:

- Android (physical device or emulator)
- iOS (physical device or simulator)
- Web (Chrome)

Note any platform-specific behaviour in your PR description.

## Questions

If you have questions or need clarification, feel free to reach out at info@louis-innovations.com.
