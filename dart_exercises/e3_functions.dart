// E3. Функции с именованными и необязательными параметрами.

// Параметры в {} именованные: при вызове пишется имя (currency: 'EUR'),
// поэтому их можно передавать в любом порядке или не передавать вовсе —
// тогда берутся значения по умолчанию.
String formatPrice(double amount, {String currency = 'MDL', int decimals = 2}) {
  // toStringAsFixed округляет, а не отбрасывает знаки: 99.999 → "100.00".
  return '${amount.toStringAsFixed(decimals)} $currency';
}

void main() {
  print('formatPrice(12.5) → "${formatPrice(12.5)}"');
  print(
    "formatPrice(12.5, currency: 'MDL') → "
    '"${formatPrice(12.5, currency: 'MDL')}"',
  );
  print(
    "formatPrice(99.999, currency: 'EUR') → "
    '"${formatPrice(99.999, currency: 'EUR')}"',
  );
  print(
    "formatPrice(7.5, currency: 'USD', decimals: 1) → "
    '"${formatPrice(7.5, currency: 'USD', decimals: 1)}"',
  );
}
