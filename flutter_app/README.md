## Dungeon Companion (Flutter)

App móvil (Flutter) para llevar hoja de personaje con:

- **Combate**: armas (crear/editar/borrar)
- **Hechizos**: lista + **slots usados** (+/-) + CRUD
- **Inventario**: objetos + **cantidad** (+/-) + **cargas** (+/-) + **equipar** + CRUD
- **Extras**: rasgos/mascotas/notas + CRUD
- **Efectos activos**: buffs/debuffs + toggle + CRUD, modifican **CA / Velocidad / PG máx.**
- **Persistencia local**: guarda automáticamente en el dispositivo
- **Backup en la nube (opcional, gratis)**: subir/restaurar backup JSON usando **Firebase** (si lo configurás)

## Backup en la nube (Firebase, opcional)

La app funciona 100% offline con Hive. Si querés que tus datos no se pierdan aunque se rompa/cambies el teléfono (y para usarlo en más de un dispositivo), podés activar **backup en la nube**.

### Qué hace

- **Subir**: exporta tu backup (JSON) y lo guarda en Firestore asociado a tu usuario.
- **Restaurar**: baja el último backup y lo importa (mezclar o reemplazar).

### Activación (gratis)

1) Instalar FlutterFire CLI (una vez):

```bash
dart pub global activate flutterfire_cli
```

2) Desde `flutter_app/`, configurar Firebase:

```bash
flutterfire configure
```

Esto genera `lib/firebase_options.dart` y agrega los archivos de configuración por plataforma, por ejemplo:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

3) Crear Firestore en tu proyecto Firebase (modo producción o test).

4) En la app, tocar **Backup** → **Subir backup a la nube (Firebase)**.

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
