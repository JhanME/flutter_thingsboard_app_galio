# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ThingsBoard Mobile Application (Community Edition) — an open-source Flutter IoT platform mobile client for Android and iOS. **Web platform is not supported.** Built on the `thingsboard_client` Dart package to communicate with ThingsBoard server.

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (freezed, json_serializable, riverpod_generator, flutter_gen)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run with debug/verbose logging
flutter run --dart-define=API_CALLS=true --dart-define=VERBOSE=true --dart-define=showAppVersion=true

# Run with custom server/branding configuration
flutter run --dart-define=thingsboardOAuth2CallbackUrlScheme=org.thingsboard.app.auth \
            --dart-define=appLinksUrlHost=demo.thingsboard.io \
            --dart-define=androidApplicationId=org.thingsboard.app \
            --dart-define=androidApplicationName="Thingsboard app"

# Analyze code
flutter analyze
```

No test directory exists currently. Test dependencies (`flutter_test`, `mocktail`, `bloc_test`, `integration_test`) are configured in pubspec.yaml.

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
- **Legacy:** Fluro router at `lib/config/routes/router.dart` — still used for some dashboard navigation.

`RefreshListenable` triggers GoRouter redirect re-evaluation when auth state changes.

### Pagination

Features use `PaginationRepository<PageKey, Item>` base class together with `infinite_scroll_pagination`'s `PagingController`. A UseCase fetches each page; the bloc emits filter/state changes that reset or refresh the `PagingController`.

### Cross-Module Communication

`ICommunicationService` wraps EventBus. Fire events (e.g., `UserLoadedEvent`) to notify other modules without direct imports.

### Key Entry Points

- `lib/main.dart` — App initialization: Hive → GetIt services → Firebase → app links → ProviderScope
- `lib/locator.dart` — All root service registrations (GetIt)
- `lib/thingsboard_app_ce.dart` — CE edition root widget (`HookConsumerWidget`, watches `routerProvider`)
- `lib/core/entity/entities_base.dart` — `EntitiesBase<T, P>` mixin shared by list-based feature screens
- `lib/utils/usecase.dart` — `UseCase<Output, Input>` base class

### Services Layer (`lib/utils/services/`)

Registered via GetIt with interface/implementation pairs. Key services: TbClient, Firebase, LocalDatabase (Hive), Endpoint, User, Communication, Overlay, Notification, DeviceInfo, Layout, Storage (secure), Version.

### Theme System (`lib/config/themes/`)

- `tb_theme.dart` — `tbTheme(primarySwatch, primaryColor, accentColor)` factory configures all Material components
- `app_colors.dart` — Brand colors (primary: `0xFF305680`) and semantic color constants
- `design_tokens.dart` — Spacing, border radius, icon size, button height constants
- `tb_text_styles.dart` — Semantic typography definitions

### Localization

ARB files in `lib/l10n/` (en, zh, zh_CN, zh_TW, ar). Access strings via `S.of(context)`. Generated output in `lib/generated/`.

## Code Generation

Generated files (`*.g.dart`, `*.freezed.dart`, `*.gform.dart`) are excluded from analysis. Always run `build_runner build` after modifying:
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

- **Android:** minSdk 24, targetSdk 36, compileSdk 35, Java 17, namespace `org.thingsboard.app`
- **iOS:** iOS 13.0+, Swift 5.0, permissions configured for Camera/Location/Notifications/Bluetooth
- Build-time customization via `--dart-define` flags (OAuth callback scheme, app links host, application ID, application name)
