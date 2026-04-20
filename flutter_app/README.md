## Dungeon Companion (Flutter)

App móvil (Flutter) para llevar hoja de personaje con:

- **Combate**: armas (crear/editar/borrar)
- **Hechizos**: lista + **slots usados** (+/-) + CRUD
- **Inventario**: objetos + **cantidad** (+/-) + **cargas** (+/-) + **equipar** + CRUD
- **Extras**: rasgos/mascotas/notas + CRUD
- **Efectos activos**: buffs/debuffs + toggle + CRUD, modifican **CA / Velocidad / PG máx.**
- **Persistencia local**: guarda automáticamente en el dispositivo

## Requisitos (Windows)

Algunos plugins (ej. `shared_preferences`) requieren symlinks.

1) Activar **Developer Mode**:

- Abrir: `start ms-settings:developers`
- Activar: **Developer Mode**

## Correr la app

```bash
flutter pub get
flutter run
```

## Generar APK (Android)

Verificá toolchain:

```bash
flutter doctor
```

### APK debug

```bash
flutter build apk --debug
```

Salida:
- `build/app/outputs/flutter-apk/app-debug.apk`

### APK release (recomendado)

#### 1) Crear keystore

Desde `flutter_app/`:

```bash
mkdir -p keystore
keytool -genkeypair -v ^
  -keystore keystore/dungeon-companion.jks ^
  -storetype JKS ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -alias dungeon
```

#### 2) Configurar `android/key.properties`

Copiá `android/key.properties.example` a `android/key.properties` y completá:

- `storePassword`
- `keyPassword`
- `storeFile` (ruta al `.jks`)
- `keyAlias`

`android/key.properties` **no se commitea** (está en `.gitignore`).

#### 3) Build release

```bash
flutter build apk --release
```

Salida:
- `build/app/outputs/flutter-apk/app-release.apk`

## Instalar en el dispositivo

Con el móvil conectado (USB debugging):

```bash
flutter install
```

O copiá el `.apk` al teléfono/tablet y abrilo para instalar (puede requerir “Instalar apps desconocidas”).
