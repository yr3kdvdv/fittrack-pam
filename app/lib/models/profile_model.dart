import 'package:flutter/foundation.dart';

import '../data/profile_repository.dart';
import '../data/result.dart';
import '../data/user_profile.dart';
import 'safe_notifier.dart';

/// Профиль текущего пользователя. Итоги тренировок профиль берёт из
/// WorkoutsModel, здесь только личные данные.
class ProfileModel extends ChangeNotifier with SafeNotifier {
  ProfileModel(this._repository);

  final ProfileRepository _repository;

  bool _loading = false;
  String? _error;
  UserProfile? _profile;

  bool get isLoading => _loading;
  String? get error => _error;

  /// null, пока профиль ни разу не загрузился.
  UserProfile? get profile => _profile;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.fetchProfile();
    if (isDisposed) return;
    switch (result) {
      case Ok(:final value):
        _profile = value;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners();
  }
}
