import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'network_service.dart';

class DownloadCancelled implements Exception {
  @override
  String toString() => 'Download cancelled';
}

class ApkUpdateService {
  final NetworkService _network = NetworkService();
  bool _cancelled = false;

  Future<Map<String, dynamic>> getLatestVersion() async {
    final response = await _network.get('/apk/latest');
    if (response is! Map || response['success'] != true) {
      throw Exception('Unable to fetch latest app version.');
    }
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<String> getCurrentVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  Future<int> getCurrentBuildNumber() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  Future<bool> isUpdateAvailable(int latestVersionCode) async =>
      latestVersionCode > await getCurrentBuildNumber();

  /// Returns true if the app may install APKs.
  Future<bool> ensureInstallPermission() async {
    if (!Platform.isAndroid) return true;
    var status = await Permission.requestInstallPackages.status;
    if (!status.isGranted) {
      status = await Permission.requestInstallPackages.request();
    }
    return status.isGranted;
  }

  void cancelDownload() => _cancelled = true;

  Future<String> downloadApk({
    required String apkUrl,
    required int versionCode,
    required void Function(int received, int total) onProgress,
  }) async {
    _cancelled = false;

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/staffsync_v$versionCode.apk';

    final apkUri = Uri.parse(apkUrl);
    final baseUri = Uri.parse(_network.baseUrl);
    final downloadUri = baseUri.replace(
      path: apkUri.path,
      query: apkUri.hasQuery ? apkUri.query : null,
    );

    final client = http.Client();
    final file = File(filePath);
    IOSink? sink;

    try {
      final response = await client.send(http.Request('GET', downloadUri));

      if (response.statusCode != 200) {
        throw Exception('APK download failed (HTTP ${response.statusCode}).');
      }

      final total = response.contentLength ?? 0;
      var received = 0;

      if (await file.exists()) await file.delete();
      sink = file.openWrite();

      await for (final chunk in response.stream) {
        if (_cancelled) throw DownloadCancelled();
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (total > 0 && await file.length() != total) {
        throw Exception('Download incomplete. Please try again.');
      }
      return filePath;
    } catch (_) {
      await sink?.close();
      sink = null;
      if (await file.exists()) await file.delete(); // no partial APKs
      rethrow;
    } finally {
      await sink?.close();
      client.close();
    }
  }

  Future<UpdateStatus> checkForUpdate() async {
    try {
      final results = await Future.wait([
        getCurrentVersion(),
        getLatestVersion(),
      ]);

      final currentVersion = results[0] as String;
      final latest = results[1] as Map<String, dynamic>;
      final available =
      await isUpdateAvailable((latest['versionCode'] as num).toInt());

      return UpdateStatus(
        hasUpdate: available,
        isMandatory: latest['isMandatory'] == true,
        currentVersion: currentVersion,
        latest: latest,
      );
    } catch (_) {
      return UpdateStatus.none;
    }
  }

  Future<void> installApk(String filePath) async {
    final result = await OpenFilex.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw Exception(result.message.isNotEmpty
          ? result.message
          : 'Unable to open APK installer.');
    }
  }

  void dispose() {}
}

class UpdateStatus {
  final bool hasUpdate;
  final bool isMandatory;
  final String currentVersion;
  final Map<String, dynamic>? latest;

  const UpdateStatus({
    required this.hasUpdate,
    this.isMandatory = false,
    required this.currentVersion,
    this.latest,
  });

  static const none = UpdateStatus(hasUpdate: false, currentVersion: '');
}