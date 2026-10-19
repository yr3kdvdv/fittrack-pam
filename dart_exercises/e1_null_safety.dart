// E1. Переменные и null safety.

int parseOrDefault(String? input, int fallback) {
  // int.tryParse принимает только String (не String?), поэтому null
  // отсекаем заранее. После этой проверки Dart сам «сужает» тип input
  // до String, и принудительное снятие nullability не нужно.
  if (input == null) return fallback;

  // tryParse не бросает исключение, а возвращает null для строк вроде
  // 'abc' или '7.5' — ?? подставляет fallback именно в этом случае.
  return int.tryParse(input) ?? fallback;
}

void main() {
  print("parseOrDefault('42', 0) → ${parseOrDefault('42', 0)}");
  print("parseOrDefault('abc', 0) → ${parseOrDefault('abc', 0)}");
  print("parseOrDefault(null, 7) → ${parseOrDefault(null, 7)}");
  print("parseOrDefault('7.5', -1) → ${parseOrDefault('7.5', -1)}");
}
