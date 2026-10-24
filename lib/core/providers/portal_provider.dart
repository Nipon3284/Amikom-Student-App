import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/portal_client.dart';
import '../storage/secure_storage_service.dart';
import '../storage/cache_service.dart';
import '../models/student_profile.dart';
import '../models/jadwal_item.dart';
import '../models/krs_item.dart';
import '../models/khs_item.dart';
import '../models/presensi_model.dart';

// Foundation Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main()');
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CacheService(prefs);
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final portalClientProvider = Provider<PortalClient>((ref) {
  return PortalClient();
});

// Theme Provider
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final CacheService _cache;
  ThemeModeNotifier(this._cache) : super(_loadInitialMode(_cache));

  static ThemeMode _loadInitialMode(CacheService cache) {
    final mode = cache.getThemeMode();
    if (mode == 'light') return ThemeMode.light;
    if (mode == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void setMode(ThemeMode mode) {
    state = mode;
    final str = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    _cache.setThemeMode(str);
  }
}

final themeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return ThemeModeNotifier(cache);
});

// Auth State
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? npm;

  const AuthState({
    required this.status,
    this.errorMessage,
    this.npm,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(String npm) =>
      AuthState(status: AuthStatus.authenticated, npm: npm);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String msg) =>
      AuthState(status: AuthStatus.error, errorMessage: msg);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final PortalClient _client;
  final SecureStorageService _secureStorage;
  final CacheService _cache;
  final Ref _ref;

  AuthNotifier(this._client, this._secureStorage, this._cache, this._ref)
      : super(AuthState.initial());

  Future<void> checkSavedSession() async {
    state = AuthState.loading();
    final savedNpm = await _secureStorage.getNpm();
    final savedPass = await _secureStorage.getPassword();

    if (savedNpm != null && savedPass != null) {
      final success = await _client.login(savedNpm, savedPass);
      if (success) {
        state = AuthState.authenticated(savedNpm);
        // Refresh profile in background
        _ref.read(profileNotifierProvider.notifier).fetch(savedNpm);
        _ref.read(jadwalNotifierProvider.notifier).fetch();
        _ref.read(krsNotifierProvider.notifier).fetch();
        _ref.read(unvalidatedPresensiProvider.notifier).check();
        return;
      }
    }
    state = AuthState.unauthenticated();
  }

  Future<bool> login(String npm, String password, {bool remember = true}) async {
    state = AuthState.loading();
    try {
      final success = await _client.login(npm, password);
      if (success) {
        if (remember) {
          await _secureStorage.saveCredentials(npm, password);
        }
        state = AuthState.authenticated(npm);
        // Trigger data fetch
        await _ref.read(profileNotifierProvider.notifier).fetch(npm);
        _ref.read(jadwalNotifierProvider.notifier).fetch();
        _ref.read(krsNotifierProvider.notifier).fetch();
        await _ref.read(unvalidatedPresensiProvider.notifier).check();
        return true;
      } else {
        state = AuthState.error('NPM atau Password salah. Silakan coba lagi.');
        return false;
      }
    } catch (e) {
      state = AuthState.error('Gagal terhubung ke server Amikom. Periksa koneksi internet.');
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    await _client.logout();
    await _secureStorage.clearAll();
    await _cache.clearAll();
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(portalClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final cache = ref.watch(cacheServiceProvider);
  return AuthNotifier(client, secureStorage, cache, ref);
});

// Profile State
class ProfileNotifier extends StateNotifier<AsyncValue<StudentProfile>> {
  final PortalClient _client;
  final CacheService _cache;

  ProfileNotifier(this._client, this._cache) : super(const AsyncValue.loading()) {
    // Load cached profile immediately
    final cached = _cache.getProfile();
    if (cached != null) {
      state = AsyncValue.data(cached);
    }
  }

  Future<void> fetch(String npm) async {
    try {
      final profile = await _client.fetchProfile(npm);
      await _cache.saveProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<StudentProfile>>((ref) {
  final client = ref.watch(portalClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return ProfileNotifier(client, cache);
});

// Jadwal State
class JadwalNotifier extends StateNotifier<AsyncValue<List<JadwalItem>>> {
  final PortalClient _client;
  final CacheService _cache;

  JadwalNotifier(this._client, this._cache) : super(const AsyncValue.loading()) {
    final cached = _cache.getJadwal();
    if (cached != null) {
      state = AsyncValue.data(cached);
    }
  }

  Future<void> fetch() async {
    try {
      final items = await _client.fetchJadwal();
      await _cache.saveJadwal(items);
      state = AsyncValue.data(items);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final jadwalNotifierProvider =
    StateNotifierProvider<JadwalNotifier, AsyncValue<List<JadwalItem>>>((ref) {
  final client = ref.watch(portalClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return JadwalNotifier(client, cache);
});

// KRS State
class KrsNotifier extends StateNotifier<AsyncValue<List<KrsItem>>> {
  final PortalClient _client;
  final CacheService _cache;

  KrsNotifier(this._client, this._cache) : super(const AsyncValue.loading()) {
    final cached = _cache.getKrs();
    if (cached != null) {
      state = AsyncValue.data(cached);
    }
  }

  Future<void> fetch() async {
    try {
      final items = await _client.fetchKRS();
      await _cache.saveKrs(items);
      state = AsyncValue.data(items);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final krsNotifierProvider =
    StateNotifierProvider<KrsNotifier, AsyncValue<List<KrsItem>>>((ref) {
  final client = ref.watch(portalClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return KrsNotifier(client, cache);
});

// KHS State
class KhsNotifier extends StateNotifier<AsyncValue<KhsResult>> {
  final PortalClient _client;
  final CacheService _cache;

  KhsNotifier(this._client, this._cache) : super(const AsyncValue.loading()) {
    final cached = _cache.getKhs();
    if (cached != null) {
      state = AsyncValue.data(cached);
    }
  }

  Future<void> fetch({required String thn, required int smt}) async {
    state = const AsyncValue.loading();
    try {
      final khs = await _client.fetchKHS(thn: thn, smt: smt);
      await _cache.saveKhs(khs);
      state = AsyncValue.data(khs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final khsNotifierProvider =
    StateNotifierProvider<KhsNotifier, AsyncValue<KhsResult>>((ref) {
  final client = ref.watch(portalClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return KhsNotifier(client, cache);
});

// Unvalidated Presensi State
class UnvalidatedPresensiNotifier
    extends StateNotifier<AsyncValue<List<UnvalidatedCourse>>> {
  final PortalClient _client;
  UnvalidatedPresensiNotifier(this._client) : super(const AsyncValue.data([]));

  Future<List<UnvalidatedCourse>> check() async {
    state = const AsyncValue.loading();
    try {
      final list = await _client.checkUnvalidatedPresensi();
      state = AsyncValue.data(list);
      return list;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  void removeCompleted(String kode) {
    state.whenData((list) {
      final updated = list.where((e) => e.kode != kode).toList();
      state = AsyncValue.data(updated);
    });
  }
}

final unvalidatedPresensiProvider = StateNotifierProvider<
    UnvalidatedPresensiNotifier, AsyncValue<List<UnvalidatedCourse>>>((ref) {
  final client = ref.watch(portalClientProvider);
  return UnvalidatedPresensiNotifier(client);
});
