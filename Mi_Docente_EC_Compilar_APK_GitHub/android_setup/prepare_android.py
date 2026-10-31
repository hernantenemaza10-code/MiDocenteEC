#!/usr/bin/env python3
"""Post-bootstrap Android setup for Mi Docente EC.
Run AFTER `flutter create --platforms android --org ec.midocente .`.
Idempotent: does not add duplicate manifest items.
"""
from pathlib import Path
import re, shutil, sys

root=Path(__file__).resolve().parent.parent
android=root/'android'
manifest=android/'app/src/main/AndroidManifest.xml'
appgradle=android/'app/build.gradle.kts'
if not manifest.exists() or not appgradle.exists():
    sys.exit('Primero ejecuta: flutter create --platforms android --org ec.midocente .')

source=manifest.read_text()
if 'RECEIVE_BOOT_COMPLETED' not in source:
    source=re.sub(r'(<manifest[^>]*>)',r'\1\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>',source,count=1)
if 'ScheduledNotificationReceiver' not in source:
    receivers='''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
'''
    source=source.replace('</application>',receivers+'    </application>')
if 'android.intent.action.SEND' not in source:
    share_filter='''
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="text/plain" />
            </intent-filter>
'''
    source=source.replace('</activity>',share_filter+'        </activity>')
source=re.sub(r'android:label="[^"]*"', 'android:label="Mi Docente EC"',source,count=1)
manifest.write_text(source)

src=root/'android_setup/MainActivity.kt'
dst=android/'app/src/main/kotlin/ec/midocente/mi_docente_ec/MainActivity.kt'
dst.parent.mkdir(parents=True,exist_ok=True)
shutil.copyfile(src,dst)

content=appgradle.read_text()
content=re.sub(r'compileSdk\s*=\s*[^\n]+', 'compileSdk = 36',content,count=1)
content=re.sub(r'targetSdk\s*=\s*[^\n]+', 'targetSdk = 36',content,count=1)
content=re.sub(r'minSdk\s*=\s*[^\n]+', 'minSdk = 24',content,count=1)
if 'isCoreLibraryDesugaringEnabled' not in content:
    content=content.replace('compileOptions {','compileOptions {\n        isCoreLibraryDesugaringEnabled = true',1)
if 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:' not in content:
    content+='\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
appgradle.write_text(content)
print('Configuración Android aplicada (avisos y compartir texto).')
