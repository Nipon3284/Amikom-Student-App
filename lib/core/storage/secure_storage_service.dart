import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyNpm = 'amikom_npm';
  static const String _keyPassword = 'amikom_password';
  static const String _keyBiometricEnabled = 'amikom_biometric_enabled';

  Future<void> saveCredentials(String npm, String password) async {
    await _storage.write(key: _keyNpm, value: npm);
    await _storage.write(key: _keyPassword, value: password);
  }

  Future<String?> getNpm() async => await _storage.read(key: _keyNpm);
  Future<String?> getPassword() async => await _storage.read(key: _keyPassword);

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled ? '1' : '0');
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == '1';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
