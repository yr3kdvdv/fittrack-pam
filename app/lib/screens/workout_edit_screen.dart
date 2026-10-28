import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/formatters.dart';
import '../data/mock_data.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/section_title.dart';
import 'not_found_screen.dart';

/// Форма новой тренировки (/workouts/new) или редактирования существующей
/// (/workouts/:id/edit). Получает только [sessionId] и сама находит сессию.
/// Ввод проверяется локально; mock-данные не меняются — сохранение придёт на L4.
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

  /// Локальная копия выбора: список exerciseIds в mock остаётся нетронутым.
  Set<String> _selectedIds = {};

  WorkoutSession? _session;

  /// После первой неудачной попытки ошибки обновляются сразу при исправлении.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void didUpdateWidget(WorkoutEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если роутер переиспользует экран для другого id, State остаётся прежним:
    // без перезагрузки форма показала бы поля и ошибки предыдущей сессии.
    if (oldWidget.sessionId != widget.sessionId) {
      _submitted = false;
      // reset очищает ошибки и текст полей; новые значения ставит _loadSession.
      _formKey.currentState?.reset();
      _loadSession();
    }
  }

  void _loadSession() {
    final sessionId = widget.sessionId;
    final session = sessionId == null
        ? null
        : mockSessions.where((s) => s.id == sessionId).firstOrNull;
    _session = session;
    // Новая тренировка начинается с демонстрационной «сегодняшней» даты.
    _dateController.text = formatNumericDate(session?.date ?? mockToday);
    _durationController.text = session == null ? '' : '${session.durationMin}';
    _notesController.text = session?.notes ?? '';
    _selectedIds = {...?session?.exerciseIds};
  }

  @override
  void dispose() {
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

  void _save() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
      _showFirstError();
      return;
    }
    final minutes = int.parse(_durationController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Тренировка ${_dateController.text.trim()} сохранена: '
          '${formatDuration(minutes)}, упражнений: ${_selectedIds.length}',
        ),
      ),
    );
    // Форма открыта push-ем, поэтому закрывается pop-ом.
    context.pop();
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

  @override
  Widget build(BuildContext context) {
    // id есть, но такой сессии нет — не подменяем её пустой новой формой.
    if (widget.sessionId != null && _session == null) {
      return const NotFoundScreen(
        title: 'Редактирование тренировки',
        message: 'Тренировка не найдена',
        backLabel: 'К дневнику',
        backPath: '/workouts',
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _session == null ? 'Новая тренировка' : 'Редактирование тренировки',
        ),
      ),
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
                    for (final exercise in mockExercises)
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
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
