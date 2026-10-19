// E6. Асинхронное программирование.

Future<String> fetchProfile(String username) async {
  // Future.delayed не блокирует программу, а только планирует
  // продолжение через 2 секунды — так имитируется ответ сервера.
  await Future.delayed(const Duration(seconds: 2));
  return 'Профиль: $username, группа TI-231, решено упражнений: 42';
}

// main объявлен async, иначе внутри него нельзя использовать await.
Future<void> main() async {
  print('Загружается профиль пользователя ana.rusu...');

  // await приостанавливает main до готовности Future, поэтому
  // «Готово.» гарантированно печатается после профиля.
  final profile = await fetchProfile('ana.rusu');
  print(profile);

  print('Готово.');
}
