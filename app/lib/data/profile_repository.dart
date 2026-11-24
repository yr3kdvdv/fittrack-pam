import 'result.dart';
import 'user_profile.dart';

/// Профиль текущего пользователя, только чтение.
abstract class ProfileRepository {
  /// GET /profile.
  Future<Result<UserProfile>> fetchProfile();
}
