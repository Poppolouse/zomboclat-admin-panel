part of 'main.dart';

const _appVersion = '1.0.9';
const _releaseApi =
    'https://api.github.com/repos/Poppolouse/zomboclat-admin-panel/releases/latest';
const _installerName = 'Zomboclat-Admin-Panel-Setup.exe';

extension AppUpdateService on _AppState {
  Future<void> _checkForUpdate() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(_releaseApi));
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Zomboclat-Admin-Panel/$_appVersion',
      );
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      final body = await response.transform(utf8.decoder).join();
      client.close();
      if (response.statusCode != HttpStatus.ok || !mounted) return;

      final release = jsonDecode(body) as Map<String, dynamic>;
      final latest = (release['tag_name'] as String? ?? '').replaceFirst(
        RegExp(r'^v'),
        '',
      );
      if (!_isNewerVersion(latest, _appVersion)) return;
      final assets = (release['assets'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final installer = assets.cast<Map<String, dynamic>>().firstWhere(
        (asset) => asset['name'] == _installerName,
        orElse: () => <String, dynamic>{},
      );
      final url = installer['browser_download_url'] as String?;
      if (url == null || url.isEmpty) return;
      await _downloadAndLaunchInstaller(url);
    } catch (_) {
      // Update checks must never interrupt normal administration work.
    } finally {
      if (mounted) setState(() => _isCheckingForUpdate = false);
    }
  }

  bool _isNewerVersion(String candidate, String current) {
    List<int> parse(String value) =>
        value.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final next = parse(candidate);
    final now = parse(current);
    for (var i = 0; i < 3; i++) {
      final a = i < next.length ? next[i] : 0;
      final b = i < now.length ? now[i] : 0;
      if (a != b) return a > b;
    }
    return false;
  }

  Future<void> _downloadAndLaunchInstaller(String downloadUrl) async {
    try {
      final target = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}$_installerName',
      );
      final request = await HttpClient().getUrl(Uri.parse(downloadUrl));
      final response = await request.close().timeout(
        const Duration(minutes: 5),
      );
      if (response.statusCode != HttpStatus.ok) return;
      await response.pipe(target.openWrite());
      await Process.start(target.path, [
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
      ]);
      exit(0);
    } catch (_) {}
  }
}
