import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_update_info.dart';
import '../network/app_update_service.dart';

enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  readyToInstall,
  upToDate,
  error,
}

class AppUpdateState {
  final UpdateStatus status;
  final AppUpdateInfo? updateInfo;
  final double downloadProgress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? downloadedFilePath;
  final String? errorMessage;
  final bool isManualCheck;

  const AppUpdateState({
    this.status = UpdateStatus.idle,
    this.updateInfo,
    this.downloadProgress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.downloadedFilePath,
    this.errorMessage,
    this.isManualCheck = false,
  });

  AppUpdateState copyWith({
    UpdateStatus? status,
    AppUpdateInfo? updateInfo,
    double? downloadProgress,
    int? downloadedBytes,
    int? totalBytes,
    String? downloadedFilePath,
    String? errorMessage,
    bool? isManualCheck,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      errorMessage: errorMessage,
      isManualCheck: isManualCheck ?? this.isManualCheck,
    );
  }
}

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  final service = ref.watch(appUpdateServiceProvider);
  return AppUpdateNotifier(service);
});

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  final AppUpdateService _service;
  CancelToken? _cancelToken;

  AppUpdateNotifier(this._service) : super(const AppUpdateState());

  Future<void> checkForUpdate({bool manual = false}) async {
    state = state.copyWith(
      status: UpdateStatus.checking,
      errorMessage: null,
      isManualCheck: manual,
    );

    try {
      final info = await _service.checkForUpdate();
      if (info == null) {
        state = state.copyWith(
          status: manual ? UpdateStatus.error : UpdateStatus.idle,
          errorMessage: manual
              ? 'Tidak dapat terhubung ke server GitHub untuk memeriksa pembaruan.'
              : null,
        );
        return;
      }

      if (info.isUpdateAvailable) {
        // Check if already downloaded
        final existingFile = await _service.getExistingDownloadedApk(info);
        if (existingFile != null) {
          state = state.copyWith(
            status: UpdateStatus.readyToInstall,
            updateInfo: info,
            downloadedFilePath: existingFile.path,
            downloadProgress: 1.0,
          );
        } else {
          state = state.copyWith(
            status: UpdateStatus.available,
            updateInfo: info,
          );
        }
      } else {
        state = state.copyWith(
          status: UpdateStatus.upToDate,
          updateInfo: info,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: manual ? UpdateStatus.error : UpdateStatus.idle,
        errorMessage: manual ? 'Terjadi kesalahan saat memeriksa pembaruan: $e' : null,
      );
    }
  }

  Future<void> startDownloadAndInstall() async {
    final info = state.updateInfo;
    if (info == null || info.downloadUrl.isEmpty) return;

    // If already downloaded and ready to install
    if (state.status == UpdateStatus.readyToInstall &&
        state.downloadedFilePath != null) {
      await installApk();
      return;
    }

    _cancelToken = CancelToken();
    state = state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: 0.0,
      downloadedBytes: 0,
      totalBytes: info.apkSize,
      errorMessage: null,
    );

    try {
      final filePath = await _service.downloadApk(
        info: info,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          state = state.copyWith(
            downloadProgress: progress,
            downloadedBytes: received,
            totalBytes: total > 0 ? total : info.apkSize,
          );
        },
      );

      state = state.copyWith(
        status: UpdateStatus.readyToInstall,
        downloadedFilePath: filePath,
        downloadProgress: 1.0,
      );

      // Automatically trigger package installer upon successful download
      await installApk();
    } catch (e) {
      if (_cancelToken?.isCancelled ?? false) {
        state = state.copyWith(
          status: UpdateStatus.available,
          downloadProgress: 0.0,
        );
      } else {
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: 'Gagal mengunduh pembaruan: $e',
        );
      }
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel('Dibatalkan oleh pengguna');
    state = state.copyWith(
      status: UpdateStatus.available,
      downloadProgress: 0.0,
    );
  }

  Future<void> installApk() async {
    final path = state.downloadedFilePath;
    if (path == null) return;
    await _service.installApk(path);
  }

  void dismissUpdate() {
    state = state.copyWith(status: UpdateStatus.idle);
  }
}
