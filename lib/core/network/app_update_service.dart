import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_update_info.dart';

class AppUpdateService {
  static const String repoOwner = 'Nipon3284';
  static const String repoName = 'Amikom-Student-App';
  static const String latestReleaseEndpoint =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  final Dio _dio;

  AppUpdateService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent': 'AmikomStudentApp',
                },
              ),
            );

  /// Checks GitHub Releases API for the latest release and compares with installed version
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _dio.get(latestReleaseEndpoint);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return AppUpdateInfo.fromGitHubJson(
          json: data,
          currentAppVersion: currentVersion,
        );
      }
      return null;
    } catch (_) {
      // Offline or release not reachable
      return null;
    }
  }

  /// Target local path for saving downloaded APK
  Future<File> getTargetApkFile(AppUpdateInfo info) async {
    final tempDir = await getTemporaryDirectory();
    final sanitizedFileName = info.apkFileName.isNotEmpty
        ? info.apkFileName
        : 'amikom-student-${info.latestVersion}.apk';
    return File('${tempDir.path}/$sanitizedFileName');
  }

  /// Checks if APK for this version is already completely downloaded locally
  Future<File?> getExistingDownloadedApk(AppUpdateInfo info) async {
    try {
      final file = await getTargetApkFile(info);
      if (await file.exists()) {
        final fileLength = await file.length();
        if (info.apkSize > 0 && fileLength == info.apkSize) {
          return file;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Downloads the release APK with progress tracking
  Future<String> downloadApk({
    required AppUpdateInfo info,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final targetFile = await getTargetApkFile(info);

    // If file already exists and size matches, skip download
    if (await targetFile.exists()) {
      final existingSize = await targetFile.length();
      if (info.apkSize > 0 && existingSize == info.apkSize) {
        onProgress(existingSize, info.apkSize);
        return targetFile.path;
      }
      // Otherwise remove partial/corrupt file
      await targetFile.delete();
    }

    final response = await _dio.download(
      info.downloadUrl,
      targetFile.path,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
      deleteOnError: true,
    );

    if (response.statusCode == 200 || response.statusCode == 206) {
      return targetFile.path;
    } else {
      throw Exception('Gagal mengunduh berkas APK (HTTP ${response.statusCode})');
    }
  }

  /// Triggers Android Package Installer to install downloaded APK
  Future<OpenResult> installApk(String filePath) async {
    return await OpenFilex.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );
  }
}
