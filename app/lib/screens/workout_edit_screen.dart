import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/formatters.dart';
import '../data/workout_session.dart';
import '../models/exercises_model.dart';
import '../models/workouts_model.dart';
import '../widgets/error_view.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/section_title.dart';
import 'not_found_screen.dart';

/// Форма новой тренировки (/workouts/new) или редактирования существующей
/// (/workouts/:id/edit). Получает только [sessionId]; сессию и список
/// упражнений берёт из моделей. Ввод проверяется локально (L3).
class WorkoutEditScreen extends StatefulWidget {
  const WorkoutEditScreen({super.key, this.sessionId});

  /// null — новая тренировка.
  final String? sessionId;

  @override
  State<WorkoutEditScreen> createState() => _WorkoutEditScreenState();
}

/// Дата «ДД.ММ.ГГГГ»: пусто, другой формат или несуществующий день — ошибка.
String? validateWorkoutDate(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Укажите дату';
  final match = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(text);
  if (match == null) return 'Введите дату в формате ДД.ММ.ГГГГ';
  final day = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final year = int.parse(match[3]!);
  // DateTime молча переносит лишнее: 31.02 стал бы 3 марта. Совпадение частей
  // после сборки означает, что такой день в календаре есть.
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return 'Такой даты нет в календаре';
  }
  return null;
}

/// Дата из уже проверенной строки «ДД.ММ.ГГГГ» (validateWorkoutDate == null).
DateTime parseWorkoutDate(String value) {
  final parts = value.trim().split('.').map(int.parse).toList();
  return DateTime(parts[2], parts[1], parts[0]);
}

/// Длительность — положительное целое число минут.
String? validateWorkoutDuration(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Укажите длительность в минутах';
  final minutes = int.tryParse(text);
  // Фильтр пропускает только цифры, поэтому null здесь — число вне диапазона int.
  if (minutes == null) return 'Слишком большое число';
  if (minutes <= 0) return 'Длительность должна быть больше 0';
  return null;
}

class _WorkoutEditScreenState extends State<WorkoutEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Ключи полей нужны, чтобы после проверки прокрутить к первой ошибке.
  final _dateKey = GlobalKey<FormFieldState<String>>();
  final _durationKey = GlobalKey<FormFieldState<String>>();
  final _exercisesKey = GlobalKey<FormFieldState<void>>();

  final _dateController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  /// Выбор упражнений — эфемерное состояние формы, а не модели.
  Set<String> _selectedIds = {};

  /// После первой неудачной попытки ошибки обновляются сразу при исправлении.
  bool _submitted = false;

  /// Поля уже заполнены. Заполняются ровно один раз: следующие извещения
  /// модели (перезагрузка, мутации на других экранах) не стирают ввод.
  bool _filled = false;

  late final WorkoutsModel _workouts;

  bool get _editing => widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    // read, а не watch: подписка на извещения нужна только до заполнения.
    _workouts = context.read<WorkoutsModel>();
    _workouts.addListener(_fillOnce);
    _fillOnce();
  }

  @override
  void didUpdateWidget(WorkoutEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если роутер переиспользует экран для другого id, State остаётся прежним:
    // без перезагрузки форма показала бы поля и ошибки предыдущей сессии.
    if (oldWidget.sessionId != widget.sessionId) {
      _submitted = false;
      _filled = false;
      // reset очищает ошибки и текст полей; новые значения ставит _fillOnce.
      _formKey.currentState?.reset();
      _fillOnce();
    }
  }

  /// Вызывается сразу и при каждом извещении модели, но заполняет поля
  /// только первый раз, когда данные есть. Без setState: экран и так
  /// перестроится — он подписан на модель через watch.
  void _fillOnce() {
    if (_filled) return;
    final sessionId = widget.sessionId;
    if (sessionId == null) {
      // Новая тренировка начинается с настоящей сегодняшней даты.
      _dateController.text = formatNumericDate(DateTime.now());
      _durationController.text = '';
      _notesController.text = '';
      _selectedIds = {};
      _filled = true;
      return;
    }
    if (_workouts.isLoading || _workouts.error != null) return;
    final session = _workouts.byId(sessionId);
    if (session == null) return;
    _dateController.text = formatNumericDate(session.date);
    _durationController.text = '${session.durationMin}';
    _notesController.text = session.notes;
    _selectedIds = {...session.exerciseIds};
    _filled = true;
  }

  @override
  void dispose() {
    _workouts.removeListener(_fillOnce);
    _dateController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleExercise(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  /// Идёт сохранение: кнопка выключена, повторное нажатие не создаст дубль.
  bool _busy = false;

  Future<void> _save() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
      _showFirstError();
      return;
    }
    final model = context.read<WorkoutsModel>();
    final catalog = context.read<ExercisesModel>().exercises;
    // Порядок упражнений — как в каталоге, а не как их отмечали.
    final exerciseIds = [
      for (final e in catalog)
        if (_selectedIds.contains(e.id)) e.id,
      for (final id in _selectedIds)
        if (!catalog.any((e) => e.id == id)) id,
    ];
    final date = parseWorkoutDate(_dateController.text);
    final minutes = int.parse(_durationController.text.trim());
    final notes = _notesController.text.trim();

    final sessionId = widget.sessionId;
    final existing = sessionId == null ? null : model.byId(sessionId);
    if (sessionId != null && existing == null) return; // экран уже «не найдено»

    setState(() => _busy = true);
    final String? error;
    if (existing == null) {
      // Временный id: настоящую идентичность даст хранилище (на L5 — сервер).
      error = await model.add(
        WorkoutSession(
          id: '',
          userId: '',
          date: date,
          exerciseIds: exerciseIds,
          durationMin: minutes,
          notes: notes,
        ),
      );
    } else {
      error = await model.update(
        existing.copyWith(
          date: date,
          exerciseIds: exerciseIds,
          durationMin: minutes,
          notes: notes,
        ),
      );
    }
    // Экран мог закрыться, пока «запрос» летел.
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      // Поля не трогаем: пользователь повторит, ничего не вводя заново.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Тренировка ${formatNumericDate(date)} сохранена: '
            '${formatDuration(minutes)}, упражнений: ${exerciseIds.length}',
          ),
        ),
      );
    // Список позади уже обновлён извещением модели — ничего не передаём.
    _leave();
  }

  /// Форма открыта push-ем и закрывается pop-ом. Если её открыли прямым
  /// адресом и возвращаться некуда, go ведёт в дневник.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/workouts');
    }
  }

  /// Кнопка «Сохранить» внизу длинной формы: ошибка в начале может оказаться
  /// за экраном, поэтому прокручиваем к первому полю с ошибкой.
  void _showFirstError() {
    // Тексты ошибок появятся только в следующем кадре и сдвинут поля ниже;
    // позицию считаем после этой раскладки, иначе цель прокрутки устареет.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final key in [_dateKey, _durationKey, _exercisesKey]) {
        if (key.currentState?.hasError ?? false) {
          _scrollToField(key.currentContext!);
          return;
        }
      }
    });
  }

  /// Как ensureVisible с alignment 0, но с отступом сверху: плавающая подпись
  /// рамки выступает над полем и иначе обрезалась бы краем под AppBar.
  void _scrollToField(BuildContext fieldContext) {
    final field = fieldContext.findRenderObject()!;
    final position = Scrollable.of(fieldContext).position;
    final fieldTop = RenderAbstractViewport.of(field)
        .getOffsetToReveal(field, 0)
        .offset;
    // 16 — тот же отступ, что у прокрутки вокруг формы.
    final target = (fieldTop - 16).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    position.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  String get _title =>
      _editing ? 'Редактирование тренировки' : 'Новая тренировка';

  void _reload() {
    context.read<WorkoutsModel>().load();
    context.read<ExercisesModel>().load();
  }

  /// Экран вместо формы, пока для неё нет данных; null — форму можно
  /// показывать. Как только форма показана, перезагрузки её не прячут:
  /// иначе spinner на месте формы сбросил бы ошибки и прокрутку.
  Widget? _stateView(WorkoutsModel workouts, ExercisesModel exercises) {
    final needsSession = _editing && !_filled;
    if (needsSession || !exercises.hasData) {
      if ((needsSession && workouts.isLoading) || exercises.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      final error = (needsSession ? workouts.error : null) ?? exercises.error;
      if (error != null) return ErrorView(message: error, onRetry: _reload);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final workouts = context.watch<WorkoutsModel>();
    final exercises = context.watch<ExercisesModel>();

    // Данные загружены, а сессии с таким id нет (старая ссылка или запись
    // удалена) — сообщение, а не вечный spinner и не пустая новая форма.
    final sessionId = widget.sessionId;
    final sessionGone =
        sessionId != null &&
        !workouts.isLoading &&
        workouts.error == null &&
        workouts.byId(sessionId) == null;
    if (sessionGone) {
      return const NotFoundScreen(
        title: 'Редактирование тренировки',
        message: 'Тренировка не найдена',
        backLabel: 'К дневнику',
        backPath: '/workouts',
      );
    }

    final stateView = _stateView(workouts, exercises);
    if (stateView != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: stateView,
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      // Не ListView: он строит только видимые элементы, и поле за экраном
      // выпало бы из Form — validate() его бы не проверил. Полей немного,
      // поэтому Column внутри прокрутки строит их все сразу.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: _dateKey,
                controller: _dateController,
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
                // Только цифры и точки, не длиннее «ДД.ММ.ГГГГ».
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Дата',
                  hintText: 'ДД.ММ.ГГГГ',
                  errorMaxLines: 2,
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: validateWorkoutDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: _durationKey,
                controller: _durationController,
                keyboardType: TextInputType.number,
                // После длительности идёт выбор упражнений, а не поле ввода:
                // done закрывает клавиатуру.
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Длительность',
                  hintText: '60',
                  suffixText: 'мин',
                  errorMaxLines: 2,
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: validateWorkoutDuration,
              ),
              // Выбор упражнений — не текстовое поле, поэтому FormField с
              // собственной разметкой: так он участвует в общем validate().
              FormField<void>(
                key: _exercisesKey,
                validator: (_) => _selectedIds.isEmpty
                    ? 'Выберите хотя бы одно упражнение'
                    : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(
                      'Упражнения',
                      icon: Icons.fitness_center,
                    ),
                    // Ошибка у заголовка секции, а не под десятым упражнением.
                    if (field.errorText case final error?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          error,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    for (final exercise in exercises.exercises)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ExerciseTile(
                          exercise: exercise,
                          // Вся карточка переключает отметку: крупная цель
                          // для пальца.
                          onTap: () => _toggleExercise(exercise.id),
                          trailing: Checkbox(
                            value: _selectedIds.contains(exercise.id),
                            onChanged: (_) => _toggleExercise(exercise.id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SectionTitle('Заметки', icon: Icons.sticky_note_2_outlined),
              // Необязательное поле без validator; Enter переносит строку.
              TextFormField(
                controller: _notesController,
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Рабочие веса, подходы, самочувствие',
                  hintMaxLines: 6,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                // null выключает кнопку на время запроса.
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
