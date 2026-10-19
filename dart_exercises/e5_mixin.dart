// E5. Mixin.

// Mixin, а не базовый класс: у класса в Dart может быть только один
// родитель, а mixin-ов можно подключить сколько угодно. Так сервисы
// получают логирование, не тратя на него своё наследование.
mixin Loggable {
  // runtimeType — реальный класс объекта во время выполнения, поэтому
  // один и тот же код печатает CartService или AuthService.
  void log(String msg) => print('[$runtimeType] $msg');
}

class CartService with Loggable {
  void addItem(String item) => log('товар добавлен: $item');
}

class AuthService with Loggable {
  void login(String username) => log('пользователь вошёл: $username');
}

void main() {
  CartService().addItem('Paracetamol');
  AuthService().login('ana.rusu');
}
