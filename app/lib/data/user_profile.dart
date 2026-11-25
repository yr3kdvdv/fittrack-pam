/// Профиль пользователя. На L5 часть полей придёт из аутентификации шаблона.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.weeklyTarget,
  });

  final String id;
  final String fullName;
  final String email;
  final int age;
  final int heightCm;
  final double weightKg;
  final String goal;

  /// Сколько тренировок в неделю пользователь планирует.
  final int weeklyTarget;
}
