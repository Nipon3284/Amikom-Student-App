import 'package:flutter_test/flutter_test.dart';
import 'package:amikom_student/core/models/app_update_info.dart';

void main() {
  group('AppUpdateInfo version comparison', () {
    test('isVersionNewer detects newer patch', () {
      expect(AppUpdateInfo.isVersionNewer(latest: 'v1.0.1', current: '1.0.0'), isTrue);
      expect(AppUpdateInfo.isVersionNewer(latest: '1.0.1', current: '1.0.0'), isTrue);
    });

    test('isVersionNewer detects newer minor and major', () {
      expect(AppUpdateInfo.isVersionNewer(latest: 'v1.1.0', current: '1.0.0'), isTrue);
      expect(AppUpdateInfo.isVersionNewer(latest: '2.0.0', current: '1.9.9'), isTrue);
    });

    test('isVersionNewer handles same version and older version', () {
      expect(AppUpdateInfo.isVersionNewer(latest: 'v1.0.0', current: '1.0.0'), isFalse);
      expect(AppUpdateInfo.isVersionNewer(latest: 'v0.9.5', current: '1.0.0'), isFalse);
      expect(AppUpdateInfo.isVersionNewer(latest: '1.0.0+2', current: '1.0.0+1'), isFalse);
    });

    test('AppUpdateInfo.fromGitHubJson parses correct APK download URL and metadata', () {
      final mockJson = {
        'tag_name': 'v1.1.0',
        'name': 'v1.1.0 - Fitur Pembaruan',
        'body': 'Pembaruan sistem dan perbaikan bug.',
        'published_at': '2026-10-25T01:00:00Z',
        'assets': [
          {
            'name': 'amikom-student-v1.1.0.apk',
            'size': 56118197,
            'browser_download_url': 'https://github.com/Nipon3284/Amikom-Student-App/releases/download/v1.1.0/amikom-student-v1.1.0.apk',
          }
        ]
      };

      final info = AppUpdateInfo.fromGitHubJson(json: mockJson, currentAppVersion: '1.0.0');
      expect(info.isUpdateAvailable, isTrue);
      expect(info.latestVersion, 'v1.1.0');
      expect(info.apkFileName, 'amikom-student-v1.1.0.apk');
      expect(info.formattedSize, '53.5 MB');
      expect(info.downloadUrl, contains('.apk'));
    });
  });
}
