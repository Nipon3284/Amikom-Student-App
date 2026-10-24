class AppUpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String releaseTitle;
  final String releaseNotes;
  final String downloadUrl;
  final String apkFileName;
  final int apkSize;
  final DateTime? publishedAt;
  final bool isUpdateAvailable;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.apkFileName,
    required this.apkSize,
    this.publishedAt,
    required this.isUpdateAvailable,
  });

  /// Formatted APK size (e.g. 53.5 MB)
  String get formattedSize {
    if (apkSize <= 0) return '';
    final mb = apkSize / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Parses GitHub release JSON and compares against current installed version
  factory AppUpdateInfo.fromGitHubJson({
    required Map<String, dynamic> json,
    required String currentAppVersion,
  }) {
    final rawTag = (json['tag_name'] as String? ?? '').trim();
    final releaseTitle = (json['name'] as String? ?? rawTag).trim();
    final releaseNotes = (json['body'] as String? ?? '').trim();
    final publishedStr = json['published_at'] as String?;
    final publishedAt = publishedStr != null ? DateTime.tryParse(publishedStr) : null;

    final assets = json['assets'] as List<dynamic>? ?? [];
    Map<String, dynamic>? apkAsset;

    for (final item in assets) {
      if (item is Map<String, dynamic>) {
        final name = (item['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkAsset = item;
          break;
        }
      }
    }

    final downloadUrl = apkAsset?['browser_download_url'] as String? ?? '';
    final apkFileName = apkAsset?['name'] as String? ?? 'app-release.apk';
    final apkSize = apkAsset?['size'] as int? ?? 0;

    final isNewer = isVersionNewer(latest: rawTag, current: currentAppVersion);

    return AppUpdateInfo(
      latestVersion: rawTag,
      currentVersion: currentAppVersion,
      releaseTitle: releaseTitle,
      releaseNotes: releaseNotes,
      downloadUrl: downloadUrl,
      apkFileName: apkFileName,
      apkSize: apkSize,
      publishedAt: publishedAt,
      isUpdateAvailable: isNewer && downloadUrl.isNotEmpty,
    );
  }

  /// Compares semantic version strings.
  /// Returns true if [latest] is strictly greater than [current].
  static bool isVersionNewer({
    required String latest,
    required String current,
  }) {
    final cleanLatest = _cleanVersion(latest);
    final cleanCurrent = _cleanVersion(current);

    if (cleanLatest.isEmpty || cleanCurrent.isEmpty) return false;

    final latestParts = cleanLatest.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final currentParts = cleanCurrent.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    final maxLen = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

    for (int i = 0; i < maxLen; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;

      if (l > c) return true;
      if (l < c) return false;
    }

    return false;
  }

  static String _cleanVersion(String v) {
    var s = v.trim();
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    // Remove build metadata e.g. +1
    if (s.contains('+')) {
      s = s.split('+').first;
    }
    // Remove prerelease suffix e.g. -beta
    if (s.contains('-')) {
      s = s.split('-').first;
    }
    return s.trim();
  }
}
