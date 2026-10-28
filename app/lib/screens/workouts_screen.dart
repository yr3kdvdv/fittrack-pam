import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../widgets/session_card.dart';

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
            // В адрес передаётся только id; форма сама найдёт сессию.
            onTap: () => context.push('/workouts/${session.id}/edit'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workouts/new'),
        icon: const Icon(Icons.add),
        label: const Text('Новая тренировка'),
      ),
    );
  }
}
