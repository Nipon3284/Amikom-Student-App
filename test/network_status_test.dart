import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:amikom_student/core/network/network_status.dart';

void main() {
  group('NetworkStatus Unit Tests', () {
    test('Initial NetworkStatus state', () {
      final initial = NetworkStatus.initial();
      expect(initial.isOnline, isTrue);
      expect(initial.hasChecked, isFalse);
      expect(initial.isReconnecting, isFalse);
      expect(initial.connectionType, equals(NetworkConnectionType.other));
      expect(initial.label, equals('Online'));
    });

    test('NetworkStatus copyWith updates fields correctly', () {
      final initial = NetworkStatus.initial();
      final offline = initial.copyWith(
        isOnline: false,
        hasChecked: true,
        connectionType: NetworkConnectionType.none,
      );

      expect(offline.isOnline, isFalse);
      expect(offline.hasChecked, isTrue);
      expect(offline.connectionType, equals(NetworkConnectionType.none));
      expect(offline.label, equals('Offline'));

      final wifi = offline.copyWith(
        isOnline: true,
        connectionType: NetworkConnectionType.wifi,
      );
      expect(wifi.isOnline, isTrue);
      expect(wifi.label, equals('Online (Wi-Fi)'));

      final cellular = offline.copyWith(
        isOnline: true,
        connectionType: NetworkConnectionType.cellular,
      );
      expect(cellular.label, equals('Online (Seluler)'));
    });

    test('ConnectivityResult enumeration values are accessible', () {
      expect(ConnectivityResult.values, contains(ConnectivityResult.wifi));
      expect(ConnectivityResult.values, contains(ConnectivityResult.mobile));
      expect(ConnectivityResult.values, contains(ConnectivityResult.none));
    });
  });
}
