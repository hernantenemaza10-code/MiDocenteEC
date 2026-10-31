import 'package:flutter_test/flutter_test.dart';
import 'package:mi_docente_ec/models.dart';

void main() {
  test('Guarda y recupera un registro de clase con caracteres españoles', () {
    final data = AppData.initial();
    data.courses.first.topic='El cristianismo y el islam';
    data.courses.first.nextStep='Actividad página 12';
    data.todos.add(TodoItem(id:'t1',title:'Seguimiento de convivencia',kind:'Convivencia',courseId:data.courses.first.id));
    final restored=AppData.decode(data.toEncodedJson());
    expect(restored.courses.single.nextStep,'Actividad página 12');
    expect(restored.todos.single.done,isFalse);
    expect(restored.todos.single.kind,'Convivencia');
  });
  test('Próxima clase respeta día y hora y omite horario pasado', () {
    final slot=ClassSlot(id:'1',courseId:'c',weekday:1,hour:8,minute:30);
    final from=DateTime(2026,10,26,9); // Lunes, pasó la clase de hoy.
    final next=nextOccurrence(slot,from)!;
    expect(next,DateTime(2026,11,2,8,30));
  });
  test('Una hora inválida no produce aviso', () {
    final slot=ClassSlot(id:'1',courseId:'c',weekday:9,hour:8,minute:0);
    expect(nextOccurrence(slot,DateTime(2026,10,26)),isNull);
  });
}
