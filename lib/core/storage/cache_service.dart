import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_profile.dart';
import '../models/jadwal_item.dart';
import '../models/krs_item.dart';
import '../models/khs_item.dart';

class CacheService {
  final SharedPreferences _prefs;

  CacheService(this._prefs);

  static const String _keyProfile = 'cache_profile';
  static const String _keyJadwal = 'cache_jadwal';
  static const String _keyKrs = 'cache_krs';
  static const String _keyKhs = 'cache_khs';
  static const String _keyThemeMode = 'app_theme_mode';

  // Profile Cache
  Future<void> saveProfile(StudentProfile profile) async {
    await _prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  StudentProfile? getProfile() {
    final raw = _prefs.getString(_keyProfile);
    if (raw == null) return null;
    try {
      return StudentProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Jadwal Cache
  Future<void> saveJadwal(List<JadwalItem> items) async {
    final list = items.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyJadwal, jsonEncode(list));
  }

  List<JadwalItem>? getJadwal() {
    final raw = _prefs.getString(_keyJadwal);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => JadwalItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // KRS Cache
  Future<void> saveKrs(List<KrsItem> items) async {
    final list = items.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyKrs, jsonEncode(list));
  }

  List<KrsItem>? getKrs() {
    final raw = _prefs.getString(_keyKrs);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => KrsItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // KHS Cache
  Future<void> saveKhs(KhsResult khs) async {
    await _prefs.setString(_keyKhs, jsonEncode(khs.toJson()));
  }

  KhsResult? getKhs() {
    final raw = _prefs.getString(_keyKhs);
    if (raw == null) return null;
    try {
      return KhsResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Theme Mode
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'system';

  Future<void> clearAll() async {
    await _prefs.remove(_keyProfile);
    await _prefs.remove(_keyJadwal);
    await _prefs.remove(_keyKrs);
    await _prefs.remove(_keyKhs);
  }
}
