import 'mock_data.dart';
import 'mock_network.dart';
import 'profile_repository.dart';
import 'result.dart';

/// Профиль из seed-а, с задержкой и общей аварией.
class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(this._network);

  final MockNetwork _network;

  @override
  Future<Result<UserProfile>> fetchProfile() async {
    if (await _network.requestFails()) {
      return const Err(MockNetwork.errorMessage);
    }
    return const Ok(mockUser);
  }
}
