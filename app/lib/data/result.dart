/// Вердикт операции Repository: значение или сообщение для экрана.
/// Ожидаемый отказ (нет сети, нет записи) — это значение, а не исключение:
/// switch по sealed-классу не скомпилируется, если забыть ветку Err.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.msg);
  final String msg;
}
