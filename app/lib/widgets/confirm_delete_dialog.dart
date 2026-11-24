import 'package:flutter/material.dart';

/// Подтверждение удаления тренировки. true — «Удалить»; false — «Отмена»;
/// null — тап мимо диалога или системное «Назад». Удалять только при true.
Future<bool?> confirmDeleteWorkout(BuildContext context) {
  return showDialog<bool>(
    context: context,
    // Кнопки закрывают диалог через его собственный dialogCtx.
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Удалить тренировку?'),
      content: const Text('Запись исчезнет из дневника и статистики.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
}
