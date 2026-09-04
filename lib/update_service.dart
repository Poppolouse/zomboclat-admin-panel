part of 'main.dart';

const _appVersion = '1.0.15';
const _releaseApi =
    'https://api.github.com/repos/Poppolouse/zomboclat-admin-panel/releases/latest';
const _installerName = 'Zomboclat-Admin-Panel-Setup.exe';
const _signatureName = 'Zomboclat-Admin-Panel-Setup.exe.sig';
const _updatePublicKey =
    'MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA7K6Eas3mqPhOE+Jb4Aq36iKAB5Z88d9kJRaQnFdjKnBhzrYBMNqphrvF3BhW3zKIbNb0YHOLqfJeFCOgZ56VB3d3CWpOQ6AqZUL6aHHQfNNdAlWpIqYsM53hTN2fpvbIvzqrUDoWEI3hH0aD1nw2WIdFEZWtzqlL+XQcyCXPgu+k4GsrvGWMWf6tkmIvW/BUhVNX62jThsj3nrYH+UjjnRd+q/K7A3UBtEgiXhb7Gj+SHThukh8Nkqf8mwbSi9qt6YjZdrGJ5bjW7R1dugQZAk442DhB3x6zdZnxkT4KxeVSOaEi8NwwbeVrUu20WCsPrwVv6FWtGIL0+xqKY20WKwueh2IqD+bPsc+3vWO6r20l5XfVawwDh9j73E/L6HxvZJrG55QaKhmtg39HLXNzXcj7U6StMpgqicKwTNTgbVxDUycy35/suadSU/b8i2S6yUgDZZl6c0CDrPsvP+Vi9hmt1QIWuq2cr9mkym3/G1Gg5sMud97gqHJB8/7eyCVhAgMBAAE=';

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
      final signature = assets.cast<Map<String, dynamic>>().firstWhere(
        (asset) => asset['name'] == _signatureName,
        orElse: () => <String, dynamic>{},
      );
      final signatureUrl = signature['browser_download_url'] as String?;
      if (!_trustedReleaseUrl(url) || !_trustedReleaseUrl(signatureUrl)) return;
      await _downloadAndLaunchInstaller(url!, signatureUrl!);
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

  bool _trustedReleaseUrl(String? value) {
    if (value == null) return false;
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host == 'github.com';
  }

  Future<void> _downloadAndLaunchInstaller(
    String downloadUrl,
    String signatureUrl,
  ) async {
    try {
      final target = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}$_installerName',
      );
      final signature = File('${target.path}.sig');
      if (!await _downloadReleaseFile(downloadUrl, target)) return;
      if (!await _downloadReleaseFile(signatureUrl, signature)) {
        await target.delete();
        return;
      }
      if (!await _hasValidUpdateSignature(target.path, signature.path)) {
        await target.delete();
        await signature.delete();
        return;
      }
      await signature.delete();
      await Process.start(target.path, [
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
      ]);
      exit(0);
    } catch (_) {}
  }

  Future<bool> _downloadReleaseFile(String url, File target) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(minutes: 5),
      );
      if (response.statusCode != HttpStatus.ok) return false;
      await response.pipe(target.openWrite());
      return true;
    } finally {
      client.close();
    }
  }

  Future<bool> _hasValidUpdateSignature(
    String path,
    String signaturePath,
  ) async {
    final encodedPath = base64Encode(utf8.encode(path));
    final encodedSignaturePath = base64Encode(utf8.encode(signaturePath));
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      "\$target=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$encodedPath')); \$signaturePath=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$encodedSignaturePath')); \$rsa=[Security.Cryptography.RSA]::Create(); \$read=0; \$rsa.ImportSubjectPublicKeyInfo([Convert]::FromBase64String('$_updatePublicKey'),[ref]\$read); \$ok=\$rsa.VerifyData([IO.File]::ReadAllBytes(\$target),[IO.File]::ReadAllBytes(\$signaturePath),[Security.Cryptography.HashAlgorithmName]::SHA256,[Security.Cryptography.RSASignaturePadding]::Pkcs1); if (\$ok) { exit 0 } else { exit 1 }",
    ], runInShell: false);
    return result.exitCode == 0;
  }
}
