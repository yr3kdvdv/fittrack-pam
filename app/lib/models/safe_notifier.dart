import 'package:flutter/foundation.dart';

/// Ответ Repository может прийти, когда модель уже уничтожена (Provider
/// вызвал dispose). notifyListeners после dispose бросает ошибку, поэтому
/// поздний ответ тихо игнорируется.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
