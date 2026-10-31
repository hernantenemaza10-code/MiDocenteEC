import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiDocenteApp());
}

class MiDocenteApp extends StatefulWidget {
  const MiDocenteApp({super.key});
  @override
  State<MiDocenteApp> createState()=>_MiDocenteAppState();
}
class _MiDocenteAppState extends State<MiDocenteApp> {
  final controller=AppController();
  @override
  void initState(){super.initState();controller.start();}
  @override
  void dispose(){controller.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>MaterialApp(
    title:'Mi Docente EC',debugShowCheckedModeBanner:false,
    theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF176A69)),
      useMaterial3:true,scaffoldBackgroundColor:const Color(0xFFF4F7F8),
      cardTheme:CardThemeData(color:Colors.white, elevation:0,
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)))),
    home:AnimatedBuilder(animation:controller,builder:(context,_)=>
      !controller.loaded?const Scaffold(body:Center(child:CircularProgressIndicator())):
      MainScreen(controller:controller)));
}

class MainScreen extends StatefulWidget {
  const MainScreen({required this.controller,super.key});
  final AppController controller;
  @override
  State<MainScreen> createState()=>_MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int selected=0;
  AppController get c=>widget.controller;
  static const MethodChannel _share=MethodChannel('ec.midocente/share');
  @override
  void initState(){
    super.initState();
    _share.setMethodCallHandler((call) async {
      if(call.method=='sharedText' && call.arguments is String && mounted){
        await _createTask(defaultKind:'Institucional',sharedText:call.arguments as String);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_)=>_consumeShared());
  }
  Future<void> _consumeShared() async {
    try {
      final text=await _share.invokeMethod<String>('takeSharedText');
      if(mounted && text!=null && text.trim().isNotEmpty){
        await _createTask(defaultKind:'Institucional',sharedText:text);
      }
    } catch (_) {}
  }
  @override
  void dispose(){_share.setMethodCallHandler(null);super.dispose();}
  @override
  Widget build(BuildContext context){
    final pages=[_home,_schedule,_courses,_tasks,_more];
    return Scaffold(
      appBar:AppBar(backgroundColor:const Color(0xFFF4F7F8),title:const Text('Mi Docente EC',style:TextStyle(fontWeight:FontWeight.w800)),
        actions:[IconButton(tooltip:'Google Calendar',icon:const Icon(Icons.event_available_outlined),onPressed:_calendar)]),
      body:SafeArea(child:c.error!=null?Center(child:Padding(padding:const EdgeInsets.all(20),child:Text(c.error!,style:const TextStyle(color:Colors.red)))):
        pages[selected]()),
      bottomNavigationBar:NavigationBar(selectedIndex:selected,onDestinationSelected:(n)=>setState(()=>selected=n),
        destinations:const [
          NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Inicio'),
          NavigationDestination(icon:Icon(Icons.calendar_month_outlined),label:'Horario'),
          NavigationDestination(icon:Icon(Icons.groups_outlined),label:'Cursos'),
          NavigationDestination(icon:Icon(Icons.checklist_outlined),label:'Pendientes'),
          NavigationDestination(icon:Icon(Icons.more_horiz),label:'Más')]),
    );
  }
  Future<void> _calendar() async {
    final url=Uri.parse('https://calendar.google.com/calendar/u/0/r');
    if (!await launchUrl(url,mode:LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('No se pudo abrir Google Calendar.')));
    }
  }
  Widget _content(List<Widget> items)=>ListView(padding:const EdgeInsets.fromLTRB(16,8,16,20),children:items);
  Widget _section(String title,{Widget? action})=>Padding(padding:const EdgeInsets.only(top:14,bottom:8),child:Row(children:[Expanded(child:Text(title,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold))),if(action!=null) action]));
  Widget _card({required Widget child})=>Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(16),child:child));
  Widget _empty(String message)=>Padding(padding:const EdgeInsets.all(18),child:Text(message,style:TextStyle(color:Colors.grey.shade700)));
  Widget _home(){
    final next=c.upcoming();
    final pend=c.data.todos.where((t)=>!t.done).toList();
    final now=DateTime.now();
    return _content([
      Text('Tu agenda y la memoria de tus clases',style:Theme.of(context).textTheme.bodyMedium),
      _section('Próxima clase'),
      if(next.isEmpty)_card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Aún no tienes horario registrado.'),
        TextButton.icon(onPressed:()=>setState(()=>selected=1),icon:const Icon(Icons.add),label:const Text('Agregar una hora de clase'))])),
      if(next.isNotEmpty) Builder(builder:(context){
        final slot=next.first;final course=c.data.courseFor(slot.courseId)!;
        final when=nextOccurrence(slot,now)!;
        final followups=c.outstanding(course.id);
        return _card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(course.label,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w700)),
          Text('${weekdays[slot.weekday-1]} · ${fmtTime(slot.hour,slot.minute)} · ${fmtDate(when)}'),
          const Divider(height:26),
          _noteLine(Icons.menu_book_outlined,'Último tema',course.topic),
          _noteLine(Icons.arrow_forward,'Continuar',course.nextStep),
          _noteLine(Icons.assignment_outlined,'Revisar tarea',course.homework),
          _noteLine(Icons.person_search_outlined,'Seguimientos','${followups.length} pendientes'),
          const SizedBox(height:8),
          FilledButton.icon(onPressed:()=>_openCourse(course),icon:const Icon(Icons.open_in_new),label:const Text('Abrir ficha del paralelo'))]));
      }),
      _section('Pendientes por atender',action:TextButton(onPressed:()=>setState(()=>selected=3),child:const Text('Ver todos'))),
      if(pend.isEmpty)_card(child:const Text('No tienes compromisos pendientes.')),
      for(final item in pend.take(4)) _card(child:Row(children:[const Icon(Icons.circle_outlined,size:18),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.title,style:const TextStyle(fontWeight:FontWeight.w600)),if(item.due.isNotEmpty) Text('Para: ${item.due}',style:const TextStyle(fontSize:12))])),IconButton(tooltip:'Marcar resuelto',icon:const Icon(Icons.check_circle_outline),onPressed:(){item.done=true;c.persist();})])),
      _section('Acciones rápidas'),
      Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()=>_createTask(),icon:const Icon(Icons.add_task),label:const Text('Pendiente'))),const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:()=>setState(()=>selected=2),icon:const Icon(Icons.note_add_outlined),label:const Text('Bitácora')))]),
    ]);
  }
  Widget _noteLine(IconData icon,String title,String value)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,size:18,color:Colors.teal.shade700),const SizedBox(width:10),Expanded(child:Text('$title: ${value.trim().isEmpty?'Sin registrar':value}'))]));
  Widget _schedule(){
    final sorted=[...c.data.slots]..sort((a,b){final d=a.weekday.compareTo(b.weekday);return d!=0?d:(a.hour*60+a.minute).compareTo(b.hour*60+b.minute);});
    return _content([_section('Mi horario semanal',action:IconButton.filledTonal(tooltip:'Agregar clase al horario',onPressed:_createSlot,icon:const Icon(Icons.add))),
      if(sorted.isEmpty)_card(child:_empty('Agrega las horas de tu horario de clases. No se han supuesto paralelos ni horarios.')),
      for(var day=1;day<=7;day++) if(sorted.any((s)=>s.weekday==day)) ...[
        Padding(padding:const EdgeInsets.only(top:8,bottom:6),child:Text(weekdays[day-1],style:const TextStyle(fontWeight:FontWeight.bold))),
        for(final slot in sorted.where((s)=>s.weekday==day))_card(child:Row(children:[
          SizedBox(width:58,child:Text(fmtTime(slot.hour,slot.minute),style:const TextStyle(fontWeight:FontWeight.bold))),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.data.courseFor(slot.courseId)?.label ?? 'Curso eliminado'),if(slot.room.isNotEmpty)Text('Aula: ${slot.room}',style:const TextStyle(fontSize:12))])),
          IconButton(tooltip:'Eliminar hora',icon:const Icon(Icons.delete_outline),onPressed:()=>_confirmDelete('¿Eliminar esta hora del horario?',(){c.data.slots.removeWhere((s)=>s.id==slot.id);c.persist();}))]))],
      const SizedBox(height:12),_card(child:const Text('Los avisos de clases se programan para 10 minutos antes. Se renuevan al abrir o modificar la app; verifica que Android permita notificaciones.')),
    ]);
  }
  Widget _courses()=>_content([_section('Mis cursos',action:IconButton.filledTonal(onPressed:_createCourse,icon:const Icon(Icons.add),tooltip:'Agregar curso')),
    for(final course in c.data.courses)_card(child:ListTile(contentPadding:EdgeInsets.zero,title:Text(course.label,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(course.topic.isEmpty?'Aún sin avance registrado':'Último: ${course.topic}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.chevron_right),onTap:()=>_openCourse(course))),
    if(c.data.courses.isEmpty)_empty('Agrega tu primera asignatura y paralelo.')]);
  Widget _tasks(){
    final active=c.data.todos.where((e)=>!e.done).toList()..sort((a,b){
      if(a.due.isEmpty && b.due.isEmpty)return 0;
      if(a.due.isEmpty)return 1;if(b.due.isEmpty)return -1;return a.due.compareTo(b.due);
    });
    final done=c.data.todos.where((e)=>e.done).toList();
    return _content([_section('Pendientes',action:IconButton.filledTonal(onPressed:()=>_createTask(),icon:const Icon(Icons.add),tooltip:'Nuevo pendiente')),
      if(active.isEmpty)_card(child:const Text('Todo al día. Crea una tarea, cita, seguimiento o compromiso institucional.')),
      for(final item in active)_taskTile(item),
      if(done.isNotEmpty)...[_section('Resueltos (${done.length})'),for(final item in done.reversed.take(8))_taskTile(item)]
    ]);
  }
  Widget _taskTile(TodoItem item){final course=c.data.courseFor(item.courseId);
    final overdue=!item.done&&item.due.isNotEmpty&&item.due.compareTo(fmtDate(DateTime.now()))<0;
    return _card(child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Checkbox(value:item.done,onChanged:(v){item.done=v??false;c.persist();}),
      Expanded(child:InkWell(onTap:()=>_createTask(existing:item),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(item.title,style:TextStyle(fontWeight:FontWeight.bold,decoration:item.done?TextDecoration.lineThrough:null)),
        Text([item.kind,if(course!=null)course.label,if(item.student.isNotEmpty)item.student].join(' · '),style:const TextStyle(fontSize:12)),
        if(item.due.isNotEmpty) Text('Fecha: ${item.due}${overdue?' · VENCIDO':''}',style:TextStyle(fontSize:12,color:overdue?Colors.red.shade700:null)),
        if(item.details.isNotEmpty)Text(item.details,maxLines:3,overflow:TextOverflow.ellipsis)]))),
      IconButton(tooltip:'Eliminar',onPressed:()=>_confirmDelete('¿Eliminar este pendiente?',(){c.data.todos.removeWhere((t)=>t.id==item.id);c.persist();}),icon:const Icon(Icons.delete_outline))]));
  }
  Widget _more()=>_content([
    _section('Herramientas'),
    _card(child:ListTile(leading:const Icon(Icons.notifications_active_outlined),title:const Text('Permitir notificaciones'),subtitle:Text(c.notificationsEnabled?'Recordatorios configurados':'Activa avisos de horarios y tareas'),onTap:() async {await c.askNotifications();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(c.notificationsEnabled?'Solicitud de permiso enviada':'No fue posible activar avisos. Revisa ajustes de Android.'))); })),
    _card(child:ListTile(leading:const Icon(Icons.calendar_month),title:const Text('Abrir Google Calendar'),subtitle:const Text('Acceso externo; no se sincronizan eventos todavía'),onTap:_calendar)),
    _card(child:ListTile(leading:const Icon(Icons.paste_outlined),title:const Text('Crear pendiente de WhatsApp'),subtitle:const Text('Comparte texto con esta app desde WhatsApp o pégalo aquí'),onTap:()=>_createTask(defaultKind:'Institucional'))),
    _card(child:const ListTile(leading:Icon(Icons.lock_outline),title:Text('Datos locales protegidos'),subtitle:Text('Prototipo con almacenamiento cifrado. Sin nube ni registro de usuarios.'))),
    _card(child:const ListTile(leading:Icon(Icons.info_outline),title:Text('Versión 0.1 de prueba'),subtitle:Text('Sin conexión real con Google Calendar, lectura automática de WhatsApp, notas o reportes oficiales.'))),
    _section('Próximas versiones'),
    _card(child:const Text('Integración Google Calendar OAuth, importación Compartir de Android, fichas estudiantiles, calificaciones, exportación segura y respaldos controlados.')),
  ]);
  Future<void> _createCourse() async {
    final subject=TextEditingController();final group=TextEditingController();
    final ok=await _form('Nuevo curso',[
      TextField(controller:subject,decoration:const InputDecoration(labelText:'Asignatura *')),
      TextField(controller:group,decoration:const InputDecoration(labelText:'Paralelo *',hintText:'1.º BGU F'))],()=>subject.text.trim().isNotEmpty&&group.text.trim().isNotEmpty);
    if(ok){c.data.courses.add(Course(id:createId(),subject:subject.text.trim(),group:group.text.trim()));await c.persist();}
    subject.dispose();group.dispose();
  }
  Future<void> _createSlot() async {
    if(c.data.courses.isEmpty){_message('Primero registra al menos un curso.');return;}
    String courseId=c.data.courses.first.id;
    int weekday=1;TimeOfDay time=const TimeOfDay(hour:7,minute:0);
    final room=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('Añadir hora de clase'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(initialValue:courseId,isExpanded:true,decoration:const InputDecoration(labelText:'Curso'),items:[for(final x in c.data.courses)DropdownMenuItem(value:x.id,child:Text(x.label,overflow:TextOverflow.ellipsis))],onChanged:(v)=>refresh(()=>courseId=v??courseId)),
        DropdownButtonFormField<int>(initialValue:weekday,decoration:const InputDecoration(labelText:'Día'),items:[for(var i=1;i<=7;i++)DropdownMenuItem(value:i,child:Text(weekdays[i-1]))],onChanged:(v)=>refresh(()=>weekday=v??weekday)),
        const SizedBox(height:12),OutlinedButton.icon(onPressed:() async {final t=await showTimePicker(context:ctx,initialTime:time);if(t!=null)refresh(()=>time=t);},icon:const Icon(Icons.access_time),label:Text('Hora: ${fmtTime(time.hour,time.minute)}')),
        TextField(controller:room,decoration:const InputDecoration(labelText:'Aula (opcional)'))
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Guardar'))])));
    if(ok==true){c.data.slots.add(ClassSlot(id:createId(),courseId:courseId,weekday:weekday,hour:time.hour,minute:time.minute,room:room.text.trim()));await c.persist();}
    room.dispose();
  }
  Future<void> _openCourse(Course course) async {
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseDetail(controller:c,course:course,onAddFollowup:()=>_createTask(defaultCourseId:course.id))));
    if(mounted)setState((){});
  }
  Future<void> _createTask({TodoItem? existing,String defaultKind='Académico',String? defaultCourseId,String? sharedText}) async {
    final title=TextEditingController(text:existing?.title??'');
    final details=TextEditingController(text:existing?.details??sharedText??'');
    final student=TextEditingController(text:existing?.student??'');
    String kind=existing?.kind??defaultKind;
    String courseId=existing?.courseId??defaultCourseId??'';
    DateTime? due=DateTime.tryParse(existing?.due??'');
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:Text(existing==null?'Nuevo pendiente':'Editar pendiente'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'¿Qué tienes pendiente? *',hintText:'Revisar las tareas de...'),textCapitalization:TextCapitalization.sentences),
        DropdownButtonFormField<String>(initialValue:kind,decoration:const InputDecoration(labelText:'Tipo'),items:const ['Académico','Convivencia','Tarea','Reunión','Institucional','Contingencia','Otro'].map((s)=>DropdownMenuItem(value:s,child:Text(s))).toList(),onChanged:(v)=>refresh(()=>kind=v??kind)),
        DropdownButtonFormField<String>(initialValue:courseId,decoration:const InputDecoration(labelText:'Paralelo'),isExpanded:true,items:[const DropdownMenuItem(value:'',child:Text('General / institucional')),for(final x in c.data.courses)DropdownMenuItem(value:x.id,child:Text(x.label,overflow:TextOverflow.ellipsis))],onChanged:(v)=>refresh(()=>courseId=v??'')),
        TextField(controller:student,decoration:const InputDecoration(labelText:'Estudiante (opcional, dato sensible)')),
        const SizedBox(height:10),OutlinedButton.icon(onPressed:() async {final day=await showDatePicker(context:ctx,initialDate:due??DateTime.now(),firstDate:DateTime(2020),lastDate:DateTime(2100));if(day!=null)refresh(()=>due=day);},icon:const Icon(Icons.event),label:Text(due==null?'Agregar fecha límite':fmtDate(due!))),
        if(due!=null)TextButton(onPressed:()=>refresh(()=>due=null),child:const Text('Quitar fecha')),
        TextField(controller:details,decoration:const InputDecoration(labelText:'Observaciones / texto del documento'),maxLines:3)
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:(){if(title.text.trim().isNotEmpty)Navigator.pop(ctx,true);},child:const Text('Guardar'))])));
    if(ok==true){
      if(existing==null)c.data.todos.add(TodoItem(id:createId(),title:title.text.trim(),kind:kind,courseId:courseId,student:student.text.trim(),due:due==null?'':fmtDate(due!),details:details.text.trim()));
      else {existing.title=title.text.trim();existing.kind=kind;existing.courseId=courseId;existing.student=student.text.trim();existing.due=due==null?'':fmtDate(due!);existing.details=details.text.trim();}
      await c.persist();
    }
    title.dispose();details.dispose();student.dispose();
  }
  Future<bool> _form(String label,List<Widget> widgets,bool Function() validate) async =>await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(label),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:widgets)),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:(){if(validate())Navigator.pop(ctx,true);},child:const Text('Guardar'))]))??false;
  void _confirmDelete(String prompt,VoidCallback action) async {
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Confirmar'),content:Text(prompt),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Eliminar'))]));
    if(ok==true)action();
  }
  void _message(String msg){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(msg)));}
}

class CourseDetail extends StatefulWidget {
  const CourseDetail({required this.controller,required this.course,required this.onAddFollowup,super.key});
  final AppController controller;final Course course;final Future<void> Function() onAddFollowup;
  @override
  State<CourseDetail> createState()=>_CourseDetailState();
}
class _CourseDetailState extends State<CourseDetail> {
  late final TextEditingController topic,nextStep,homework,notes;
  bool saving=false;
  Course get course=>widget.course;
  @override
  void initState(){super.initState();topic=TextEditingController(text:course.topic);nextStep=TextEditingController(text:course.nextStep);homework=TextEditingController(text:course.homework);notes=TextEditingController();}
  @override
  void dispose(){topic.dispose();nextStep.dispose();homework.dispose();notes.dispose();super.dispose();}
  Future<void> _save() async {
    if(saving)return;
    setState(()=>saving=true);
    course.topic=topic.text.trim();course.nextStep=nextStep.text.trim();course.homework=homework.text.trim();course.lastDate=fmtDate(DateTime.now());
    widget.controller.data.logs.add(ClassLog(id:createId(),courseId:course.id,date:course.lastDate,topic:course.topic,nextStep:course.nextStep,homework:course.homework,notes:notes.text.trim()));
    await widget.controller.persist();
    if(mounted){setState(()=>saving=false);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Bitácora guardada para la próxima clase')));notes.clear();}
  }
  @override
  Widget build(BuildContext context){
    final logs=widget.controller.data.logs.where((l)=>l.courseId==course.id).toList().reversed.toList();
    final todos=widget.controller.outstanding(course.id);
    return Scaffold(appBar:AppBar(title:Text(course.label,overflow:TextOverflow.ellipsis)),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Text('Bitácora del paralelo',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
        const SizedBox(height:10),TextField(controller:topic,maxLines:2,decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'¿Qué tema trabajaste?',hintText:'Tema, subtema, página...')),
        const SizedBox(height:12),TextField(controller:nextStep,maxLines:2,decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'¿Dónde continuarás?',hintText:'Página, actividad, pregunta...')),
        const SizedBox(height:12),TextField(controller:homework,maxLines:2,decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'¿Qué tarea revisarás la próxima clase?')),
        const SizedBox(height:12),TextField(controller:notes,maxLines:2,decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'Observaciones de esta clase (opcional)')),
        const SizedBox(height:14),FilledButton.icon(onPressed:saving?null:_save,icon:const Icon(Icons.save_outlined),label:const Text('Finalizar clase y guardar avance')),
        const SizedBox(height:24),Text('Seguimientos pendientes (${todos.length})',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),
        OutlinedButton.icon(onPressed:() async {await widget.onAddFollowup();if(mounted)setState((){});},icon:const Icon(Icons.person_add_alt),label:const Text('Registrar seguimiento del paralelo')),
        for(final t in todos)Card(child:ListTile(title:Text(t.title),subtitle:Text([t.kind,if(t.student.isNotEmpty)t.student].join(' · ')),leading:Icon(t.kind=='Convivencia'?Icons.report_outlined:Icons.assignment_late_outlined))),
        const SizedBox(height:16),Text('Historial de clases (${logs.length})',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),
        if(logs.isEmpty)const Padding(padding:EdgeInsets.all(12),child:Text('Sin registros anteriores.')),
        for(final l in logs.take(30))Card(child:ExpansionTile(title:Text(l.topic.isEmpty?'Clase sin tema especificado':l.topic),subtitle:Text(l.date),children:[ListTile(title:const Text('Continuar'),subtitle:Text(l.nextStep.isEmpty?'Sin dato':l.nextStep)),ListTile(title:const Text('Tarea'),subtitle:Text(l.homework.isEmpty?'Sin tarea':l.homework)),if(l.notes.isNotEmpty)ListTile(title:const Text('Observaciones'),subtitle:Text(l.notes))])),
      ]));
  }
}
