# Contributing to Yawala Browser

Thanks for helping make Yawala Browser better! This project lives under the
[yawala-siwala](https://github.com/orgs/yawala-siwala/repositories) GitHub
organization and is MIT-licensed.

## Ground rules

1. **One codebase, five platforms.** Do not fork per-OS variants. Any change
   must keep Android, iOS, Linux, macOS and Windows building from this single
   project.
2. **Keep the layers clean.**
   - `lib/domain/` holds pure domain models and services (no Flutter imports).
   - `lib/state/` owns state management (`ChangeNotifier` in the boilerplate).
   - `lib/native/` isolates platform bindings behind interfaces.
   - `lib/ui/` contains screens and widgets only; no business logic.
3. **Shared code goes upward.** Anything reusable across the ecosystem belongs
   in the [yawala-core](https://github.com/yawala-siwala/yawala-core) package,
   not here.
4. **Conventional commits.** Use `feat:`, `fix:`, `docs:`, `refactor:`, `ci:`,
   `chore:` prefixes.

## Getting started

```bash
git clone https://github.com/yawala-siwala/yawala-browser.git
cd yawala-browser
git clone https://github.com/yawala-siwala/yawala-core.git ../yawala-core
flutter pub get
flutter test
```

## Pull requests

- Keep PRs focused: one feature or fix per PR.
- Run `flutter analyze` and `flutter test` locally; CI must pass.
- Describe which platforms you verified (device or emulator is fine).
- New user-facing features should update `README.md`.

## Issues

Open bugs with reproduction steps and mention the platform(s) affected.
Feature proposals are welcome - tag them `enhancement`.