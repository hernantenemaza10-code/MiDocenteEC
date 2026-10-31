# Mi Docente EC — primera versión de desarrollo (v0.1.0)

**Estado:** código fuente de un prototipo Android en Flutter. NO es un APK compilado,
NO se ha ejecutado en un dispositivo físico y NO está listo para publicación ni
para introducir registros personales reales de estudiantes hasta completar pruebas
funcionales, auditoría de privacidad y estrategia de respaldo.

## Qué hace ya el código

- Pestañas Inicio, Horario, Cursos, Pendientes y Más.
- Alta de cursos y paralelos, con un curso inicial configurable (Ciudadanía, 1.º BGU F).
- Alta y eliminación de clases semanales (día/hora/aula), más cálculo de próxima clase.
- Bitácora por paralelo: tema trabajado, punto exacto de continuación, tarea a revisar,
  observaciones e historial de clases.
- Pendientes generales o vinculados a un curso: académico, convivencia, tarea,
  institucional, contingencia, reunión u otro; fecha y estado completado.
- Resumen antes de entrar a un paralelo, con temas y cantidad de seguimientos.
- Guardado local cifrado con `flutter_secure_storage` (almacén de prueba, sin nube).
- Programación local de avisos aproximadamente 10 minutos antes de clase y en fechas
  de pendientes. Android puede retrasarlos; la app reprograma los próximos 28 días
  cada vez que se inicia o se modifica información.
- Recepción MANUAL de mensajes de texto desde el menú **Compartir** de WhatsApp,
  mediante un intent Android; abre un formulario para crear el compromiso. No lee
  chats, imágenes, PDF ni mensajes automáticamente.
- Acceso externo a Google Calendar desde la pestaña Más. **No hay sincronización
  OAuth, creación ni lectura de eventos** todavía.

## Qué NO hace esta versión

- No genera calificaciones, informes oficiales, asistencia ni fichas completas.
- No sincroniza Google Calendar, ni analiza automáticamente documentos de WhatsApp.
- No permite importar PDF/Word/imágenes o extraer tareas con IA.
- No tiene respaldo, exportación, cuentas multiusuario ni políticas institucionales.
- No está verificada todavía la compilación: el entorno usado para crear los archivos
  no dispone de Flutter ni Android SDK. Requiere ejecutar las pruebas indicadas abajo.

## Cómo obtener un APK desde Windows, macOS o Linux

1. Instala Android Studio (con Android SDK 36, Java 17) y Flutter estable **3.38.1
   o posterior**, preferiblemente la edición estable más reciente. Ejecuta `flutter doctor`.
2. Extrae este ZIP; abre una terminal dentro de la carpeta `mi_docente_ec`.
3. Ejecuta:

   ```bash
   flutter create --platforms android --org ec.midocente .
   python3 android_setup/prepare_android.py
   flutter pub get
   flutter analyze
   flutter test
   flutter run
   ```

   En Windows, sustituye `python3` por `py` o `python` según tu instalación.
   `flutter run` necesita un teléfono conectado con depuración USB habilitada o
   un emulador Android encendido.

4. Cuando las pruebas salgan correctamente, genera un APK **de prueba**:

   ```bash
   flutter build apk --debug
   ```

   Aparecerá en `build/app/outputs/flutter-apk/app-debug.apk`.
   Este APK está firmado para desarrollo y NO debe distribuirse públicamente.

5. Para generar un paquete de tienda más adelante:

   ```bash
   flutter build appbundle --release
   ```

   Antes del paso 5 **es obligatorio configurar la firma de producción**, verificar
   la identidad del desarrollador, la política de privacidad, `applicationId`,
   los permisos Android y probar la app. Sin esas tareas el `.aab` no está listo
   para cargarse a Google Play.

## Android y privacidad

- `prepare_android.py` inserta permisos y receivers de notificaciones, habilita
  desugaring (necesario para el plugin), fija `compileSdk`/`targetSdk` a 36,
  añade un `intent-filter` para compartir **solo texto** y sustituye `MainActivity`.
- Si Google Play o una versión posterior de Flutter exigen cambios en AGP/Gradle,
  revisa la documentación oficial del plugin de notificaciones.
- No se solicita `SCHEDULE_EXACT_ALARM`: los avisos son **inexactos** por diseño.
- Los contenidos de los avisos no muestran nombres de estudiantes en pantalla
  bloqueada. No se utiliza acceso a contactos, WhatsApp privado, cámara ni nube.
- Los datos JSON se cifran mediante la API de almacenamiento seguro del sistema.
  Este método es apropiado para una prueba de bajo volumen; para desplegar la app
  en producción y manejar registros sensibles debe migrarse a una base de datos
  transaccional cifrada, implementar copias de seguridad, control de acceso,
  retención de datos y pruebas de recuperación ante fallas.
- **No utilices información identificable de estudiantes en esta versión de prueba.**

## Orden recomendado de próximas iteraciones

1. Probar este proyecto en Android y corregir cualquier incompatibilidad de SDK.
2. Construir la ficha de estudiantes y asistencia con control de acceso.
3. Integración real Google Calendar mediante OAuth, de alcance mínimo.
4. Importar documentos PDF/Word compartidos desde Android, con revisión humana.
5. Notificaciones configurables y funcionamiento fiable con cambios de horario.
6. Incorporar calificaciones y reportes, validados contra normativa ecuatoriana.
7. Preparar firma de producción, política de privacidad, pruebas Play Console.

## Referencias técnicas

- https://docs.flutter.dev/reference/create-new-app
- https://pub.dev/packages/flutter_secure_storage
- https://pub.dev/packages/flutter_local_notifications
- https://pub.dev/packages/flutter_timezone
- https://developers.google.com/workspace/calendar/api/guides/overview
