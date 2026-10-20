import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/session_card.dart';
import 'workout_edit_screen.dart';

/// Дневник тренировок. Сессии идут по датам, сначала самые новые:
/// последняя тренировка видна сразу без прокрутки.
class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дневник')),
      body: ListView.separated(
        // Нижний отступ, чтобы кнопка не закрывала последнюю карточку.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: mockSessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final session = mockSessions[index];
          return SessionCard(
            session: session,
            onTap: () => _openForm(context, session),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Новая тренировка'),
      ),
    );
  }

  void _openForm(BuildContext context, WorkoutSession? session) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutEditScreen(session: session)),
    );
  }
}
