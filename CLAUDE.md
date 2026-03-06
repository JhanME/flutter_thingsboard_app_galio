# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ThingsBoard Mobile Application (Community Edition) — an open-source Flutter IoT platform mobile client for Android and iOS. **Web platform is not supported.** Built on the `thingsboard_client` Dart package to communicate with ThingsBoard server. This fork is rebranded for **Galio Electronics** (primary color: `#28A745` Galio Green).

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (freezed, json_serializable, riverpod_generator, flutter_gen)
dart run build_runner build --delete-conflicting-outputs

# Run the app (requires config file — see Environment Config below)
flutter run --dart-define-from-file=config/dev.json

# Run with individual dart-defines (alternative to config file)
flutter run --dart-define=thingsboardApiEndpoint=https://tb.galio.dev \
            --dart-define=thingsboardOAuth2CallbackUrlScheme=dev.galio.app.auth \
            --dart-define=appLinksUrlHost=tb.galio.dev \
            --dart-define=androidApplicationId=dev.galio.app \
            --dart-define=androidApplicationName="Galio"

# Run tests
flutter test
flutter test test/widget_test.dart   # single test file

# Regenerate launcher icons and splash screen
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# Analyze code
flutter analyze
```

A basic `test/widget_test.dart` smoke test exists. No unit or integration tests are written yet. Test dependencies (`flutter_test`, `mocktail`, `bloc_test`, `integration_test`) are configured in pubspec.yaml.

## Environment Config

The app **requires** `thingsboardApiEndpoint` to be set at build time. If empty, `main()` renders a `_MissingConfigApp` error screen instead of launching.

The preferred local dev approach uses per-environment JSON files:

```bash
flutter run --dart-define-from-file=config/dev.json
flutter run --dart-define-from-file=config/stage.json
flutter run --dart-define-from-file=config/prod.json
```

These files are `.gitignore`'d. Copy `config/config.example.json` to get started. Available keys:

| Key | Description |
|---|---|
| `thingsboardApiEndpoint` | ThingsBoard server URL (required) |
| `thingsboardOAuth2CallbackUrlScheme` | OAuth2 redirect scheme |
| `appLinksUrlHost` | Deep link host |
| `androidApplicationId` | Android package name |
| `androidApplicationName` | Android app label |
| `thingsboardIosAppSecret` | iOS OAuth app secret |
| `thingsboardAndroidAppSecret` | Android OAuth app secret |
| `navigationType` | `push` (default) or `mixed` — controls bottom-nav routing behavior |
| `API_CALLS` | `"true"` to log HTTP traffic |
| `VERBOSE` | `"true"` for verbose logging |
| `showAppVersion` | `"true"` to display version in UI |

`ignoreRegionSelection` is automatically `true` when `thingsboardApiEndpoint` is non-empty (region picker is hidden).

## Architecture

### Clean Architecture with Hybrid State Management

The app follows **Clean Architecture** per module. Each feature module in `lib/modules/` is organized as:

```
modules/<feature>/
├── data/
│   ├── datasource/     # I*Datasource interface + implementation (raw API/DB calls)
│   └── repository/     # I*Repository implementation (delegates to datasource)
├── domain/
│   ├── entities/       # Data models
│   ├── repository/     # I*Repository interfaces
│   └── usecases/       # *Usecase extends UseCase<Output, Input>
├── di/                 # GetIt scope setup (*_di.dart)
└── presentation/
    ├── bloc/           # BLoC state management (events, states, bloc)
    ├── view/           # Screen-level widgets
    └── widgets/        # Feature-specific components
```

**Data flow:** User action → BLoC event → UseCase → Repository → Datasource → `ThingsboardClient` API call → emit new state → rebuild UI.

### State Management — BLoC (feature modules)

Events and states use **sealed classes** for exhaustive switch coverage:

```dart
sealed class AlarmEvent extends Equatable { const AlarmEvent(); }
final class AlarmFiltersResetEvent extends AlarmEvent { ... }

sealed class AlarmsState extends Equatable { const AlarmsState(); }
final class AlarmsLoadedState extends AlarmsState { ... }
```

BLoC uses a single handler that switches on event type:

```dart
class AlarmBloc extends Bloc<AlarmEvent, AlarmsState> {
  AlarmBloc(...) : super(const AlarmsInitialState()) {
    on(_onEvent);
  }
  Future<void> _onEvent(AlarmEvent event, Emitter<AlarmsState> emit) async {
    switch (event) {
      case AlarmFiltersResetEvent(): ...
    }
  }
}
```

### State Management — Riverpod (routing and newer code)

Uses `@riverpod` annotations; widgets extend `HookConsumerWidget`. Key providers: `routerProvider`, `loginProvider`, `oauthProvider`, `navigationProvider`, `errorProvider`.

### Dependency Injection (GetIt)

**Root services** are registered in `lib/locator.dart` → `setUpRootDependencies()` (called from `main()`).

**Module-level DI** uses isolated scopes that are created on feature entry and dropped on exit:

```dart
// di/alarms_di.dart
static void init(String scopeName, ...) {
  getIt.pushNewScope(
    scopeName: scopeName,
    init: (locator) {
      locator.registerFactory<IAlarmsDatasource>(() => AlarmsDatasource(...));
      locator.registerFactory<IAlarmsRepository>(() => AlarmsRepository(...));
      locator.registerLazySingleton<AlarmBloc>(() => AlarmBloc(...));
    },
  );
}
static void dispose(String scopeName) {
  getIt<AlarmBloc>().close();
  getIt.dropScope(scopeName);
}
```

All services use the `I*` interface / `*` implementation naming convention.

### Routing

- **Primary:** GoRouter at `lib/config/routes/v2/router_2.dart` — Riverpod-provided, deep linking, auth redirects via ordered `Redirect` implementations (`AuthRedirect` → `TwoFactorAuthConfirmRedirect` → `TwoFactorAuthSetupRedirect` → `VersionRedirect`). Returns `null` to pass through or a path string to redirect.
- **Legacy:** Fluro router at `lib/config/routes/router.dart` — still used for some dashboard navigation. The project is mid-migration from Fluro → GoRouter; prefer GoRouter for new routes.

`RefreshListenable` triggers GoRouter redirect re-evaluation when auth state changes.

Two-factor authentication has its own confirm and setup flows integrated into the redirect chain above (`lib/core/auth/2FA/`).

### Legacy TbContext

`lib/core/context/tb_context.dart` is a legacy class managing auth state, user details, and routing via `ValueNotifier` and `StreamSubscription`. New code uses Riverpod providers (`loginProvider`, `routerProvider`). Legacy screens still depend on `TbContext` — do not remove it. When adding new features, prefer Riverpod over `TbContext`.

### Pagination

Two patterns coexist:
- **New:** `PaginationRepository<T, B>` abstract base class + `PagingController` (preferred for new features)
- **Legacy:** `BaseEntitiesWidget<T, P>` / `BaseEntitiesState<T, P>` using the `EntitiesBase<T, P>` mixin — older widget-based approach still used in most modules

A UseCase fetches each page; the bloc emits filter/state changes that reset or refresh the `PagingController`.

### Cross-Module Communication

`ICommunicationService` wraps EventBus (`lib/utils/services/communication/`). Key events in `events/`: `UserLoadedEvent`, `UserLoggedInEvent`, `AlarmAssigneeUpdatedEvent`, `DeviceProvisioningStatusChangedEvent`. Add new events here; fire via the service to decouple modules.

### Key Entry Points

- `lib/main.dart` — App initialization: Hive → GetIt services → Firebase → app links → ProviderScope. Exits early with `_MissingConfigApp` if `thingsboardApiEndpoint` is empty.
- `lib/locator.dart` — All root service registrations (GetIt)
- `lib/thingsboard_app_ce.dart` — CE edition root widget (`HookConsumerWidget`, watches `routerProvider`)
- `lib/core/entity/entities_base.dart` — `EntitiesBase<T, P>` mixin shared by list-based feature screens
- `lib/utils/usecase.dart` — `UseCase<Output, Input>` base class

### Services Layer (`lib/utils/services/`)

Registered via GetIt with interface/implementation pairs. Key services: TbClient, Firebase, LocalDatabase (Hive), Endpoint, User, Communication, Overlay, Notification, DeviceInfo, Layout, Storage (secure), Version.

- **Overlay service** — centralized hub for toasts, dialogs, snackbars. Used by the global error provider; prefer it over direct `ScaffoldMessenger` calls.
- **Local database (Hive)** — stores endpoint selection, initial deep links, and user preferences. Cache lifecycle is managed per-service.
- **Mobile actions** (`mobile_actions/actions/`) — device provisioning (BLE + WiFi), QR scanning, location, phone calls, maps. These require platform permissions configured in `AndroidManifest.xml` / `Info.plist`.

### Theme System (`lib/config/themes/`)

- `tb_ce_theme.dart` — CE edition light theme entry point; passes `AppColors` values into `tbTheme()`. Edit accent color here.
- `tb_theme.dart` — `tbTheme(primarySwatch, primaryColor, accentColor)` factory configures all Material components
- `dark_theme.dart` — Dark theme (`tbDarkTheme`) used when system is in dark mode
- `app_colors.dart` — Galio brand colors (primary: `#28A745` Galio Green, surface/app bar: `#343A40` dark gray) and semantic color constants
- `design_tokens.dart` — Spacing, border radius, icon size, button height constants
- `tb_text_styles.dart` — Semantic typography definitions

### Constants (`lib/constants/`)

- `app_constants.dart` — ThingsBoard endpoint, OAuth config, `navigationType` (reads dart-define flags). `ignoreRegionSelection` is `true` when endpoint is non-empty.
- `assets_path.dart` — Centralized image/SVG asset paths. **Always use `ThingsboardImage.*` constants from this file; never inline asset path strings**, as they are regenerated by `flutter_gen` and inline references will break.
- `enviroment_variables.dart` — `API_CALLS`, `VERBOSE`, `showAppVersion` flag parsing

### Logging

`lib/core/logger/tb_logger.dart` uses the `logger` package with custom `TbLogsFilter` and `TbLogOutput`. Log verbosity is controlled by `--dart-define=VERBOSE=true` (all logs) and `--dart-define=API_CALLS=true` (HTTP traffic). `AppBlocObserver` (`lib/app_bloc_observer.dart`) logs all BLoC events and state changes in debug/verbose mode.

### Error Handling

Global errors flow through the Riverpod `errorProvider` (`lib/utils/providers/error_provider/`), which wraps `IOverlayService` and logs via `TbLogger`. `ThingsboardError` is the standard error type from `thingsboard_client`. BLoCs should catch exceptions and route them to `errorProvider` or emit an error state rather than handling UI directly.

### Localization

ARB files in `lib/l10n/` (en, zh, zh_CN, zh_TW, ar). Access strings via `S.of(context)`. Generated output in `lib/generated/`.

## Code Generation

Generated files (`*.g.dart`, `*.freezed.dart`, `*.gform.dart`) are excluded from analysis. Always run `dart run build_runner build --delete-conflicting-outputs` after modifying:
- Freezed data classes
- JSON serializable models
- Riverpod providers with `@riverpod`
- Asset references (flutter_gen)

## Lint Rules

Uses `package:lint/strict.yaml` with `custom_lint`. Notable overrides:
- `sort_constructors_first: true` — constructors must be first in classes
- `avoid_classes_with_only_static_members: false` — static utility classes allowed
- `require_trailing_commas: false`

## Platform Configuration

- **Android:** minSdk 24, targetSdk 36, compileSdk 35, Java 17, default application ID `dev.galio.app`; app name in `android/app/build.gradle` → `customLabel`
- **iOS:** iOS 13.0+, Swift 5.0, permissions configured for Camera/Location/Notifications/Bluetooth, default bundle ID `dev.galio.app`; app name/ID in `ios/Flutter/TbDefault.xcconfig` → `IOSAPPLICATIONNAME` / `IOSAPPLICATIONID`
- Build-time customization via `--dart-define` flags or `--dart-define-from-file=config/<env>.json`

## Branding Assets

- `assets/branding/logo_icon.png` — App icon (Android & iOS), min 1024×1024 px
- `assets/branding/galio_logo_light.png` — Splash screen image
- `assets/images/galio_logo_with_title.png` — Login header and dashboard top bar
- `assets/images/galio_logo_big.png` — Region selection screen
- `assets/images/galio_logo_icon.png` — Loading spinner

After replacing any asset PNG, run `dart run build_runner build --delete-conflicting-outputs` to update `flutter_gen` references. After replacing splash/icon source files, re-run the launcher icons and splash generators.
