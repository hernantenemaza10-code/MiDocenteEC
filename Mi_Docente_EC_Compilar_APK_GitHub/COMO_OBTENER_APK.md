# Mi Docente EC — obtener un APK compilado por herramientas oficiales

**Este ZIP contiene el proyecto fuente. No es un APK listo para instalar.**

## Opción 1: generar un APK desde GitHub Actions (sin instalar Flutter localmente)

1. Desde una computadora, crea una cuenta en https://github.com si no tienes una.
2. Abre https://github.com/new y crea un repositorio **privado** llamado `MiDocenteEC`.
3. Extrae este ZIP. En tu repositorio, selecciona **Add file → Upload files**, arrastra el **contenido** de la carpeta extraída (no el ZIP comprimido) y confirma **Commit changes**. Asegúrate de que el archivo `.github/workflows/compilar-android.yml` se haya subido, incluida la carpeta oculta `.github`.
4. En GitHub, abre **Actions** → **Compilar Mi Docente EC para Android** → **Run workflow** → **Run workflow**.
5. Cuando el flujo termine con éxito (marca verde), entra a su ejecución y busca **Artifacts** → `MiDocenteEC-APK-Android`.
6. Descarga el ZIP que ofrece GitHub, extráelo y encontrarás `app-debug.apk`.
7. Transfiere ese `app-debug.apk` a tu celular Android e instálalo desde **Archivos**. Android puede solicitar autorización para instalar desde la aplicación que abrió el archivo.

**Si la compilación falla:** abre la ejecución roja en Actions y copia el texto del primer paso fallido. Hay que corregir ese error de compilación, no saltarse las comprobaciones.

**Advertencia:** este flujo automatiza la compilación pero no se ha probado aquí con GitHub Actions, un teléfono o un emulador. El archivo generado se destina exclusivamente a pruebas con datos ficticios. Nunca subas contraseñas, claves, certificados de firma de producción, ni datos personales de estudiantes al repositorio.

## Opción 2: compilar desde computadora con Flutter y Android Studio

```bash
flutter create --platforms android --org ec.midocente .
python3 android_setup/prepare_android.py
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

En Windows usa `py` en lugar de `python3` si corresponde.

El archivo generado estará en:

`build/app/outputs/flutter-apk/app-debug.apk`

## Qué incluye el prototipo

- Inicio y próxima clase según horario.
- Cursos y paralelos con avances de clase.
- Agenda de pendientes y seguimientos sin nombres de alumnos en la notificación.
- Avisos locales y recepción manual de texto compartido desde Android, sujetos a permisos.
- Almacenamiento local protegido.

No incluye todavía integración real de Google Calendar, captura automática de documentos WhatsApp, calificaciones, asistencia o respaldo institucional. No introduzcas datos personales reales de alumnos.

## Evita los APK previos

Los archivos experimentales `MiDocenteEC.apk` y `MiDocenteEC_corregida.apk` que se compartieron anteriormente **no fueron compilados por el sistema de Android y no deben instalarse**. Este proyecto usa la compilación estándar de Flutter y Gradle.
