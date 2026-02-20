# Galio Electronics — Mobile App

Aplicación móvil IoT de **Galio Electronics**, construida sobre Flutter y conectada al servidor ThingsBoard en [tb.galio.dev](http://tb.galio.dev/).

---

## Tecnologías

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.7+-0175C2?logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-API%2024+-3DDC84?logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-13.0+-000000?logo=apple&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Messaging-FFCA28?logo=firebase&logoColor=black)
![ThingsBoard](https://img.shields.io/badge/ThingsBoard-4.1.0-305680?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0xMiAyTDIgN2wxMCA1IDEwLTV6TTIgMTdsOSA0IDktNE0yIDEybDkgNCA5LTQiLz48L3N2Zz4=&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-2.6-00BCD4?logo=dart&logoColor=white)
![BLoC](https://img.shields.io/badge/BLoC-8.1-6F35A5?logo=dart&logoColor=white)
![GetIt](https://img.shields.io/badge/GetIt-7.6-FF6F00?logo=dart&logoColor=white)
![GoRouter](https://img.shields.io/badge/GoRouter-17.0-02569B?logo=flutter&logoColor=white)
![Hive](https://img.shields.io/badge/Hive-2.2-FFCA28?logo=hive&logoColor=black)

---

## Desarrollo

```bash
# Instalar dependencias
flutter pub get

# Generar código (freezed, riverpod, assets, localización)
flutter pub run build_runner build --delete-conflicting-outputs

# Ejecutar la app
flutter run
```

---

## Guía de Rebranding

Esta sección explica cómo cambiar la identidad visual de la app en el futuro. Todos los cambios son en archivos específicos — no hay magia dispersa por el código.

### 1. Íconos y Splash Screen

Reemplaza los archivos fuente en `assets/branding/`:

| Archivo | Uso | Requisitos |
|---|---|---|
| `logo_icon.png` | Ícono de la app (Android & iOS) | PNG cuadrado, mínimo 1024×1024 px, fondo transparente o blanco |
| `galio_logo_light.png` | Splash screen principal | PNG cuadrado con fondo blanco |

Luego regenera los recursos nativos:

```bash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

> El color de fondo del splash se configura en `flutter_native_splash.yaml` → clave `color`.

---

### 2. Logos dentro de la app

Los logos que aparecen en la UI están en `assets/images/`:

| Archivo | Dónde aparece |
|---|---|
| `galio_logo_with_title.png` | Login header y barra superior de dashboards |
| `galio_logo_big.png` | Pantalla de selección de región (si se activa) |
| `galio_logo_icon.png` | Indicador de carga (spinner) |

Reemplaza los PNG con los nuevos y ejecuta:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

> Las rutas se centralizan en `lib/constants/assets_path.dart` — si cambias el nombre de un archivo, solo actualiza esa constante.

---

### 3. Colores

Archivo único: **`lib/config/themes/app_colors.dart`**

```dart
static const primaryGreen  = Color(0xFF28A745); // Botones, switches, estados Online
static const darkBackground = Color(0xFF343A40); // App Bar y superficies oscuras
```

El swatch de Material se recalcula automáticamente desde `primaryGreen`. Para cambiar el color de énfasis (accent), edita `lib/config/themes/tb_ce_theme.dart`.

---

### 4. Nombre de la App

| Archivo | Clave / Campo | Valor actual |
|---|---|---|
| `android/app/build.gradle` | `customLabel` (default) | `'Galio'` |
| `ios/Flutter/TbDefault.xcconfig` | `IOSAPPLICATIONNAME` | `Galio` |
| `lib/l10n/intl_en.arb` (y otros idiomas) | `"appTitle"` | `"Galio"` |

---

### 5. Application ID (Package Name)

| Archivo | Campo | Valor actual |
|---|---|---|
| `android/app/build.gradle` | `applicationId` (default) | `dev.galio.app` |
| `ios/Flutter/TbDefault.xcconfig` | `IOSAPPLICATIONID` | `dev.galio.app` |

> Cambia el ID **antes** de publicar en tiendas. Una vez publicado, no se puede modificar.

---

### 6. Servidor ThingsBoard

Archivo: **`lib/constants/app_constants.dart`**

```dart
static const thingsBoardApiEndpoint = String.fromEnvironment(
  'thingsboardApiEndpoint',
  defaultValue: 'http://tb.galio.dev/',  // ← Cambia la URL aquí
);
```

Con `defaultValue` configurado, la pantalla de selección de región queda desactivada automáticamente (`ignoreRegionSelection = true`). Si necesitas reactivarla, elimina el `defaultValue`.

---

### 7. Checklist de Rebranding Completo

```
[ ] Reemplazar logo_icon.png en assets/branding/
[ ] Reemplazar galio_logo_light.png en assets/branding/
[ ] Reemplazar logos en assets/images/ (3 archivos)
[ ] Actualizar colores en lib/config/themes/app_colors.dart
[ ] Actualizar app name en build.gradle + TbDefault.xcconfig + intl_*.arb
[ ] Actualizar application ID en build.gradle + TbDefault.xcconfig
[ ] Actualizar URL del servidor en lib/constants/app_constants.dart
[ ] flutter pub run flutter_launcher_icons
[ ] flutter pub run flutter_native_splash:create
[ ] flutter pub run build_runner build --delete-conflicting-outputs
```
