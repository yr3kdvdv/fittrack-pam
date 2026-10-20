import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.all(16),
        itemCount: mockSessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            SessionCard(session: mockSessions[index]),
      ),
    );
  }
}
