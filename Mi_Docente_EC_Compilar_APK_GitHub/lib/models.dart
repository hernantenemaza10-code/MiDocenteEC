import 'dart:convert';

String createId() => DateTime.now().microsecondsSinceEpoch.toString();

int number(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : (int.tryParse('$value') ?? fallback);

String str(Object? value) => value?.toString() ?? '';

class Course {
  Course({required this.id, required this.subject, required this.group,
    this.topic = '', this.nextStep = '', this.homework = '', this.lastDate = ''});
  final String id;
  String subject, group, topic, nextStep, homework, lastDate;
  factory Course.fromJson(Map<String, dynamic> j) => Course(
    id: str(j['id']), subject: str(j['subject']), group: str(j['group']),
    topic: str(j['topic']), nextStep: str(j['nextStep']),
    homework: str(j['homework']), lastDate: str(j['lastDate']));
  Map<String, dynamic> toJson() => {'id': id, 'subject': subject, 'group': group,
    'topic': topic, 'nextStep': nextStep, 'homework': homework,
    'lastDate': lastDate};
  String get label => '$subject · $group';
}

/// Monday=1 ... Sunday=7. Start hour and minute in local device time.
class ClassSlot {
  ClassSlot({required this.id, required this.courseId,
    required this.weekday, required this.hour, required this.minute, this.room = ''});
  final String id, courseId;
  int weekday, hour, minute;
  String room;
  factory ClassSlot.fromJson(Map<String, dynamic> j) => ClassSlot(
    id: str(j['id']), courseId: str(j['courseId']),
    weekday: number(j['weekday'], 1), hour: number(j['hour'], 7),
    minute: number(j['minute']), room: str(j['room']));
  Map<String, dynamic> toJson() => {'id': id, 'courseId': courseId,
    'weekday': weekday, 'hour': hour, 'minute': minute, 'room': room};
}

class ClassLog {
  ClassLog({required this.id, required this.courseId, required this.date,
    required this.topic, this.nextStep = '', this.homework = '', this.notes = ''});
  final String id, courseId;
  String date, topic, nextStep, homework, notes;
  factory ClassLog.fromJson(Map<String, dynamic> j) => ClassLog(
    id: str(j['id']), courseId: str(j['courseId']), date: str(j['date']),
    topic: str(j['topic']), nextStep: str(j['nextStep']),
    homework: str(j['homework']), notes: str(j['notes']));
  Map<String, dynamic> toJson() => {'id': id, 'courseId': courseId, 'date': date,
    'topic': topic, 'nextStep': nextStep, 'homework': homework, 'notes': notes};
}

/// A follow-up is identified by course and optional student name.
/// Names never appear in lock-screen notifications.
class TodoItem {
  TodoItem({required this.id, required this.title, required this.kind,
    this.courseId = '', this.student = '', this.due = '',
    this.details = '', this.done = false});
  final String id;
  String title, kind, courseId, student, due, details;
  bool done;
  factory TodoItem.fromJson(Map<String, dynamic> j) => TodoItem(
    id: str(j['id']), title: str(j['title']), kind: str(j['kind']),
    courseId: str(j['courseId']), student: str(j['student']),
    due: str(j['due']), details: str(j['details']), done: j['done'] == true);
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'kind': kind,
    'courseId': courseId, 'student': student, 'due': due,
    'details': details, 'done': done};
}

class AppData {
  AppData({required this.courses, required this.slots,
    required this.logs, required this.todos});
  final List<Course> courses;
  final List<ClassSlot> slots;
  final List<ClassLog> logs;
  final List<TodoItem> todos;
  factory AppData.initial() => AppData(
    courses: [Course(id: createId(), subject: 'Educación para la Ciudadanía', group: '1.º BGU F')],
    slots: [], logs: [], todos: []);
  factory AppData.fromJson(Map<String, dynamic> j) => AppData(
    courses: ((j['courses'] as List?) ?? []).map((e) => Course.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    slots: ((j['slots'] as List?) ?? []).map((e) => ClassSlot.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    logs: ((j['logs'] as List?) ?? []).map((e) => ClassLog.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    todos: ((j['todos'] as List?) ?? []).map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e as Map))).toList());
  String toEncodedJson() => jsonEncode({'schema': 1,
    'courses': courses.map((e) => e.toJson()).toList(),
    'slots': slots.map((e) => e.toJson()).toList(),
    'logs': logs.map((e) => e.toJson()).toList(),
    'todos': todos.map((e) => e.toJson()).toList()});
  static AppData decode(String value) => AppData.fromJson(jsonDecode(value) as Map<String, dynamic>);
  Course? courseFor(String id) {
    for (final c in courses) { if (c.id == id) return c; }
    return null;
  }
}

String fmtDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String fmtTime(int h, int m) =>
    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
const weekdays = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];

DateTime? nextOccurrence(ClassSlot slot, DateTime from) {
  if (slot.weekday < 1 || slot.weekday > 7 || slot.hour < 0 || slot.hour > 23 || slot.minute < 0 || slot.minute > 59) return null;
  for (var i=0; i<=7; i++) {
    final day = DateTime(from.year, from.month, from.day + i, slot.hour, slot.minute);
    if (day.weekday == slot.weekday && day.isAfter(from)) return day;
  }
  return null;
}
