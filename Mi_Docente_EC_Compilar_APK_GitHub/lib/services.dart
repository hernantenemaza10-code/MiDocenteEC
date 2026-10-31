import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';

/// Prototype: encrypted small JSON in Android Keystore-backed secure storage.
/// For production scale, replace with an encrypted transactional database.
class AppController extends ChangeNotifier {
  final FlutterSecureStorage _store = const FlutterSecureStorage();
  final ReminderService reminders = ReminderService();
  AppData data = AppData.initial();
  bool loaded = false;
  bool notificationsEnabled = false;
  String? error;
  Future<void> start() async {
    try {
      final content = await _store.read(key: 'app_data_v1');
      if (content != null && content.isNotEmpty) data = AppData.decode(content);
    } catch (e) {
      // Never silently overwrite potentially unreadable data.
      error = 'No se pudo leer el almacenamiento protegido. No ingreses nuevos datos hasta resolverlo: $e';
    }
    try {
      await reminders.init();
      notificationsEnabled = await reminders.hasPermission();
      if (error == null && notificationsEnabled) await reminders.refresh(data);
    } catch (_) {
      notificationsEnabled = false;
    }
    loaded = true;
    notifyListeners();
  }
  Future<void> persist() async {
    if (error != null) return;
    try {
      await _store.write(key: 'app_data_v1', value: data.toEncodedJson());
      notifyListeners();
      if (notificationsEnabled) {
        unawaited(reminders.refresh(data).catchError((Object _) {}));
      }
    } catch (e) {
      error = 'No se pudieron guardar los cambios. $e';
      notifyListeners();
    }
  }
  Future<void> askNotifications() async {
    notificationsEnabled = await reminders.askPermission();
    notifyListeners();
    if (notificationsEnabled) await reminders.refresh(data);
  }
  List<TodoItem> outstanding(String courseId) => data.todos.where((e) => !e.done && e.courseId == courseId).toList();
  List<ClassSlot> upcoming() {
    final now=DateTime.now();
    final result = data.slots.where((s) => nextOccurrence(s,now)!=null && data.courseFor(s.courseId)!=null).toList();
    result.sort((a,b) => nextOccurrence(a,now)!.compareTo(nextOccurrence(b,now)!));
    return result;
  }
}

class ReminderService {
  final FlutterLocalNotificationsPlugin _plugin=FlutterLocalNotificationsPlugin();
  bool available=false;
  Future<void> init() async {
    tzdata.initializeTimeZones();
    final info=await FlutterTimezone.getLocalTimezone();
    try {tz.setLocalLocation(tz.getLocation(info.identifier));} catch (_) {tz.setLocalLocation(tz.getLocation('Etc/UTC'));}
    await _plugin.initialize(settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    available = true;
  }
  Future<bool> hasPermission() async =>
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ?? false;
  Future<bool> askPermission() async {
    final result=await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    return result ?? false;
  }
  static const _details=NotificationDetails(android: AndroidNotificationDetails(
    'agenda_docente', 'Agenda docente', channelDescription: 'Avisos de clases y compromisos',
    importance: Importance.high, priority: Priority.high,
    visibility: NotificationVisibility.private));
  Future<void> refresh(AppData data) async {
    if (!available) return;
    await _plugin.cancelAll();
    // 28-day rolling window: refreshed on every app open/save.
    final now=DateTime.now();
    var id=1000;
    for (var offset=0; offset<28; offset++) {
      final day=DateTime(now.year,now.month,now.day+offset);
      for (final slot in data.slots) {
        if (slot.weekday!=day.weekday || data.courseFor(slot.courseId)==null) continue;
        final at=DateTime(day.year,day.month,day.day,slot.hour,slot.minute).subtract(const Duration(minutes:10));
        if (!at.isAfter(now)) continue;
        await _plugin.zonedSchedule(id:id++,title:'Tu próxima clase',
          body:'Revisa el tema, la tarea y los seguimientos pendientes.',
          scheduledDate:tz.TZDateTime.from(at,tz.local),notificationDetails:_details,
          androidScheduleMode:AndroidScheduleMode.inexact);
      }
    }
    for (final task in data.todos.where((t)=>!t.done && t.due.isNotEmpty)) {
      final due=DateTime.tryParse(task.due);
      if (due==null) continue;
      final at=DateTime(due.year,due.month,due.day,8,0);
      if (!at.isAfter(now)) continue;
      await _plugin.zonedSchedule(id:id++,title:'Tienes un pendiente docente',
        body:'Abre Mi Docente EC para revisar tus compromisos.',
        scheduledDate:tz.TZDateTime.from(at,tz.local),notificationDetails:_details,
        androidScheduleMode:AndroidScheduleMode.inexact);
    }
  }
}
