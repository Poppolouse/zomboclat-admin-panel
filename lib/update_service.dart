part of 'main.dart';

const _appVersion = '1.0.18';
const _releaseApi =
    'https://api.github.com/repos/Poppolouse/zomboclat-admin-panel/releases/latest';
const _installerName = 'Zomboclat-Admin-Panel-Setup.exe';
const _signatureName = 'Zomboclat-Admin-Panel-Setup.exe.sig';
const _updatePublicKey =
    'MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA7K6Eas3mqPhOE+Jb4Aq36iKAB5Z88d9kJRaQnFdjKnBhzrYBMNqphrvF3BhW3zKIbNb0YHOLqfJeFCOgZ56VB3d3CWpOQ6AqZUL6aHHQfNNdAlWpIqYsM53hTN2fpvbIvzqrUDoWEI3hH0aD1nw2WIdFEZWtzqlL+XQcyCXPgu+k4GsrvGWMWf6tkmIvW/BUhVNX62jThsj3nrYH+UjjnRd+q/K7A3UBtEgiXhb7Gj+SHThukh8Nkqf8mwbSi9qt6YjZdrGJ5bjW7R1dugQZAk442DhB3x6zdZnxkT4KxeVSOaEi8NwwbeVrUu20WCsPrwVv6FWtGIL0+xqKY20WKwueh2IqD+bPsc+3vWO6r20l5XfVawwDh9j73E/L6HxvZJrG55QaKhmtg39HLXNzXcj7U6StMpgqicKwTNTgbVxDUycy35/suadSU/b8i2S6yUgDZZl6c0CDrPsvP+Vi9hmt1QIWuq2cr9mkym3/G1Gg5sMud97gqHJB8/7eyCVhAgMBAAE=';

class _UpdateState {
  static _UpdateState? _instance;
  factory _UpdateState() => _instance ??= _UpdateState._();
  _UpdateState._();

  final ValueNotifier<_UpdatePhase> phase = ValueNotifier(
    _UpdatePhase.checking,
  );
  final ValueNotifier<double> progress = ValueNotifier(0);
  final ValueNotifier<String> detail = ValueNotifier('');
  final ValueNotifier<String> foundVersion = ValueNotifier('');
}

enum _UpdatePhase {
  checking,
  none,
  found,
  downloading,
  verifying,
  installing,
}

extension AppUpdateService on _AppState {
  Future<void> _checkForUpdate() async {
    final st = _UpdateState();
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
      if (!_isNewerVersion(latest, _appVersion)) {
        st.phase.value = _UpdatePhase.none;
        if (mounted) setState(() => _isCheckingForUpdate = false);
        return;
      }
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
      if (!_trustedReleaseUrl(url) || !_trustedReleaseUrl(signatureUrl)) {
        st.phase.value = _UpdatePhase.none;
        if (mounted) setState(() => _isCheckingForUpdate = false);
        return;
      }
      st.foundVersion.value = latest;
      st.phase.value = _UpdatePhase.found;
      if (mounted) {
        setState(() => _isCheckingForUpdate = false);
        _showUpdatePrompt(url!, signatureUrl!);
      }
    } catch (_) {
      st.phase.value = _UpdatePhase.none;
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

  void _showUpdatePrompt(String downloadUrl, String signatureUrl) {
    final st = _UpdateState();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _UpdateProgressDialog(
          st: st,
          downloadUrl: downloadUrl,
          signatureUrl: signatureUrl,
          onSkip: () {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );
  }
}

class _UpdateHelpers {
  static Future<bool> downloadReleaseFile(
    String url,
    File target,
    _UpdateState st,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(minutes: 5),
      );
      if (response.statusCode != HttpStatus.ok) return false;
      final total = response.contentLength;
      final sink = target.openWrite();
      var received = 0;
      final chunks = <int>[];
      try {
        await for (final chunk in response) {
          chunks.addAll(chunk);
          received += chunk.length;
          if (total > 0) {
            st.progress.value = received / total;
            st.detail.value =
                '${formatBytes(received)} / ${formatBytes(total)}';
          } else {
            st.detail.value = formatBytes(received);
          }
        }
        sink.add(chunks);
        await sink.flush();
      } finally {
        await sink.close();
      }
      return true;
    } finally {
      client.close();
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  static Future<bool> hasValidUpdateSignature(
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

class _UpdateProgressDialog extends StatefulWidget {
  final _UpdateState st;
  final String downloadUrl;
  final String signatureUrl;
  final VoidCallback onSkip;

  const _UpdateProgressDialog({
    required this.st,
    required this.downloadUrl,
    required this.signatureUrl,
    required this.onSkip,
  });

  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  bool _started = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_started) return;
    _started = true;
    final st = widget.st;
    try {
      st.phase.value = _UpdatePhase.downloading;
      final target = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}$_installerName',
      );
      final signature = File('${target.path}.sig');
      if (await target.exists()) await target.delete();
      if (await signature.exists()) await signature.delete();
      if (!await _UpdateHelpers.downloadReleaseFile(
        widget.downloadUrl,
        target,
        st,
      )) {
        throw StateError('Download failed');
      }
      st.phase.value = _UpdatePhase.verifying;
      st.progress.value = 1;
      st.detail.value = 'signature check';
      if (!await _UpdateHelpers.hasValidUpdateSignature(
        target.path,
        signature.path,
      )) {
        await target.delete();
        await signature.delete();
        throw StateError('Signature verification failed');
      }
      await signature.delete();
      st.phase.value = _UpdatePhase.installing;
      st.progress.value = 1;
      st.detail.value = '';
      await Process.start(target.path, [
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
      ]);
      exit(0);
    } catch (e) {
      st.phase.value = _UpdatePhase.none;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    return AlertDialog(
      backgroundColor: const Color(0xff27272a),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          const Icon(Icons.system_update_alt_rounded, color: Color(0xff60a5fa)),
          const SizedBox(width: 10),
          const Text(
            'Update Available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version ${st.foundVersion.value} is available (current: $_appVersion).',
              style: const TextStyle(color: Color(0xffd4d4d8), fontSize: 13),
            ),
            const SizedBox(height: 18),
            ValueListenableBuilder<_UpdatePhase>(
              valueListenable: st.phase,
              builder: (context, phase, _) {
                return ValueListenableBuilder<double>(
                  valueListenable: st.progress,
                  builder: (context, value, _) {
                    final indeterminate = phase == _UpdatePhase.checking;
                    final pct = indeterminate ? null : (value * 100).clamp(0, 100);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: indeterminate ? null : value,
                            minHeight: 10,
                            backgroundColor: const Color(0xff3f3f46),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xff3b82f6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _phaseLabel(phase),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xffa1a1aa),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!indeterminate &&
                                phase != _UpdatePhase.none &&
                                phase != _UpdatePhase.installing)
                              Text(
                                pct == null
                                    ? ''
                                    : '${pct.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xffa1a1aa),
                                  fontFamily: 'monospace',
                                ),
                              ),
                          ],
                        ),
                        ValueListenableBuilder<String>(
                          valueListenable: st.detail,
                          builder: (context, detail, _) {
                            if (detail.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                detail,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xff71717a),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                'Update failed: $_error',
                style: const TextStyle(color: Color(0xffef4444), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _error == null && _started
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Skip (later)'),
        ),
      ],
    );
  }

  String _phaseLabel(_UpdatePhase phase) {
    switch (phase) {
      case _UpdatePhase.checking:
        return 'Preparing...';
      case _UpdatePhase.none:
        return '';
      case _UpdatePhase.found:
        return 'Ready to download';
      case _UpdatePhase.downloading:
        return 'Downloading update...';
      case _UpdatePhase.verifying:
        return 'Verifying signature...';
      case _UpdatePhase.installing:
        return 'Installing... the app will restart automatically.';
    }
  }
}