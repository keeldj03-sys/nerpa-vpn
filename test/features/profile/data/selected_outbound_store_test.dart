import 'package:flutter_test/flutter_test.dart';
import 'package:nerpa_vpn/features/profile/data/selected_outbound_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectedOutboundStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('выбор сохраняется отдельно для каждого профиля', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SelectedOutboundStore(preferences);

      expect(store.read('profile-1'), isNull);

      await store.write('profile-1', '🇺🇸 USA 01');
      await store.write('profile-2', '🇩🇪 Germany 02');

      expect(store.read('profile-1'), '🇺🇸 USA 01');
      expect(store.read('profile-2'), '🇩🇪 Germany 02');
    });

    test('пустое значение считается отсутствующим выбором', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SelectedOutboundStore(preferences);

      await store.write('profile-1', '');

      expect(store.read('profile-1'), isNull);
    });
  });
}
