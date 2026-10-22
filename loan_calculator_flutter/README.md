# LoanCalcMate

iOS and Android app aligned with the Make prototype `src/prototypes/loan-calculator` and the PRD `src/resources/prd/prd-01-loan-calculator.md`. Light Revolut look, three tabs: Calc, Save, and Me.

## Platforms

- iOS and Android only. `main.dart` refuses web and desktop targets.
- There is no web directory.

## Run

```bash
flutter pub get
flutter devices
flutter run
```

### Stuck on `Launching lib/main.dart…`

The first Gradle download can fail on TLS or a slow network. The debug console may show only one warning.

1. Run `flutter run -v` in a terminal to see the full log.
2. Android dependencies come from Google and Maven Central. Gradle comes from services.gradle.org.
3. Open `loan_calculator_flutter/android` in Android Studio and sync Gradle once.
4. Open the `loan_calculator_flutter` folder in the editor and pick an Android device or an iOS simulator. Do not pick Chrome.
5. An info-level lint does not block the run. A red error does.

## Data

Local `shared_preferences`, key prefix `loan-calc:`. The browser prototype uses the same schema.

## Layout

| Path | Role |
| --- | --- |
| `lib/data/` | Models, calculation, currency, tags, storage |
| `lib/state/app_state.dart` | State and routes |
| `lib/widgets/` | UI pieces aligned with the prototype CSS |
| `lib/screens/` | Screens |

## Brand

- Home-screen icon: `assets/branding/app_icon.png`. Regenerate with `dart run flutter_launcher_icons`.
- Opening screen: system background `#F4F4F8`, then the Flutter animation.
- `BrandLogo` uses the same `app_icon.png`.

Product rules follow the PRD. The web prototype and this app share the same information architecture. Font rendering and the opening screen can differ by platform.
