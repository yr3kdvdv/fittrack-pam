/// «Сеть» для всех mock repositories: задержка и одна общая авария.
/// Один объект на всё приложение, поэтому выключатель в профиле роняет
/// и каталог, и дневник, и профиль одновременно. Умирает на L5 вместе с mock.
class MockNetwork {
  MockNetwork({this.latency = const Duration(milliseconds: 800)});

  /// Без задержки состояние «грузится» нельзя ни увидеть, ни показать.
  /// Тесты передают Duration.zero.
  final Duration latency;

  /// Авария: включена → любой вызов любого mock repository проваливается.
  bool simulateError = false;

  static const errorMessage = 'Сервер не отвечает — повторите попытку';

  /// Общий пролог каждого метода mock: ждём, как настоящая сеть, затем
  /// проверяем аварию. true — запрос «упал», метод возвращает Err.
  Future<bool> requestFails() async {
    await Future<void>.delayed(latency);
    return simulateError;
  }
}
