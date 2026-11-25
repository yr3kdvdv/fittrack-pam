import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/data/mock_network.dart';
import 'package:fittrack/data/mock_profile_repository.dart';
import 'package:fittrack/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('профиль: «грузится», ошибка, retry → данные', () async {
    final network = MockNetwork(latency: Duration.zero)..simulateError = true;
    final model = ProfileModel(MockProfileRepository(network));
    var notifications = 0;
    model.addListener(() => notifications++);

    final loading = model.load();
    expect(model.isLoading, isTrue);
    await loading;
    expect(model.error, MockNetwork.errorMessage);
    expect(model.profile, isNull);
    expect(notifications, 2);

    network.simulateError = false;
    await model.load();
    expect(model.error, isNull);
    expect(model.profile!.fullName, mockUser.fullName);
  });
}
