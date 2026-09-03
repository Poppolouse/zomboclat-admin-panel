part of 'main.dart';

const String kApiBaseUrl = 'http://45.142.115.19:28080';

class ApiClient {
  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 6);

  static Future<Map<String, dynamic>> _get(
    String path, {
    int timeoutSeconds = 6,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl$path');
    final req = await _httpClient
        .getUrl(uri)
        .timeout(Duration(seconds: timeoutSeconds));
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    final resp = await req.close().timeout(Duration(seconds: timeoutSeconds));
    final body = await resp.transform(utf8.decoder).join();
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw StateError('HTTP ${resp.statusCode}: $body');
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data, {
    int timeoutSeconds = 10,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl$path');
    final req = await _httpClient
        .postUrl(uri)
        .timeout(Duration(seconds: timeoutSeconds));
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    final jsonStr = jsonEncode(data);
    req.add(utf8.encode(jsonStr));
    final resp = await req.close().timeout(Duration(seconds: timeoutSeconds));
    final body = await resp.transform(utf8.decoder).join();
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw StateError('HTTP ${resp.statusCode}: $body');
  }

  // Health
  static Future<bool> ping({int timeoutMs = 3000}) async {
    try {
      final res = await _get(
        '/health',
        timeoutSeconds: (timeoutMs / 1000).ceil(),
      );
      return res['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  // Auth
  static Future<AppUser?> login(String username, String password) async {
    final res = await _post('/api/auth/login', {
      'username': username,
      'password': password,
    });
    if (res['status'] == 'ok' && res['user'] != null) {
      return AppUser.fromJson(res['user'] as Map<String, dynamic>);
    }
    final msg = res['message']?.toString() ?? 'Giris basarisiz';
    throw StateError(msg);
  }

  // Server Status
  static Future<String> getServerStatus() async {
    final res = await _get('/api/server/status');
    return res['raw']?.toString() ?? '';
  }

  // Server Logs
  static Future<List<String>> getServerLogs({int lines = 250}) async {
    final res = await _get('/api/server/logs?lines=$lines', timeoutSeconds: 12);
    if (res['status'] == 'ok' && res['lines'] != null) {
      return (res['lines'] as List).map((e) => e.toString()).toList();
    }
    return [];
  }

  // Server Command (restart, start, stop)
  static Future<Map<String, dynamic>> executeServerCommand({
    required String action,
    required String username,
  }) async {
    return await _post('/api/server/command', {
      'action': action,
      'username': username,
    });
  }

  // INI Config
  static Future<Map<String, dynamic>> getIniConfig() async {
    return await _get('/api/server/ini', timeoutSeconds: 12);
  }

  static Future<Map<String, dynamic>> saveIniConfig({
    required Map<String, dynamic> settings,
    required List<String> mods,
    required List<String> workshopItems,
    required String username,
  }) async {
    return await _post('/api/server/ini', {
      'settings': settings,
      'mods': mods,
      'workshop_items': workshopItems,
      'username': username,
    });
  }

  // Sandbox Config
  static Future<Map<String, dynamic>> getSandboxConfig() async {
    return await _get('/api/server/sandbox', timeoutSeconds: 12);
  }

  static Future<Map<String, dynamic>> saveSandboxConfig({
    required Map<String, dynamic> categories,
    required String username,
  }) async {
    return await _post('/api/server/sandbox', {
      'categories': categories,
      'username': username,
    });
  }

  // Players
  static Future<Map<String, dynamic>> getPlayers() async {
    return await _get('/api/players', timeoutSeconds: 15);
  }

  static Future<Map<String, dynamic>> banPlayer({
    required String username,
    String steamid = '',
    String reason = 'Admin panel yasagi',
    required String byUser,
  }) async {
    return await _post('/api/players/ban', {
      'username': username,
      'steamid': steamid,
      'reason': reason,
      'by_user': byUser,
    });
  }

  static Future<Map<String, dynamic>> unbanPlayer({
    required String username,
    String steamid = '',
    required String byUser,
  }) async {
    return await _post('/api/players/unban', {
      'username': username,
      'steamid': steamid,
      'by_user': byUser,
    });
  }

  static Future<Map<String, dynamic>> addGamePlayer({
    required String username,
    String password = '',
    int roleId = 2,
    required String byUser,
  }) async {
    return await _post('/api/players/add', {
      'username': username,
      'password': password,
      'role_id': roleId,
      'by_user': byUser,
    });
  }

  static Future<Map<String, dynamic>> deleteGamePlayer({
    required String username,
    required String byUser,
  }) async {
    return await _post('/api/players/delete', {
      'username': username,
      'by_user': byUser,
    });
  }

  static Future<Map<String, dynamic>> updateGamePlayer({
    required String username,
    required Map<String, dynamic> payload,
    required String byUser,
  }) async {
    return await _post('/api/players/update', {
      'username': username,
      'payload': payload,
      'by_user': byUser,
    }, timeoutSeconds: 15);
  }

  static Future<Map<String, dynamic>> sendRcon(
    String command, {
    String byUser = '',
  }) async {
    return await _post('/api/players/rcon', {
      'command': command,
      'by_user': byUser,
    });
  }

  // Panel Users (SQLite)
  static Future<List<AppUser>> getPanelUsers() async {
    final res = await _get('/api/users');
    if (res['status'] == 'ok' && res['users'] != null) {
      return (res['users'] as List)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> addPanelUser({
    required String username,
    required String role,
    required String byUser,
    String password = '',
  }) async {
    return await _post('/api/users/add', {
      'username': username,
      'role': role,
      'by_user': byUser,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> deletePanelUser({
    required String username,
    required String byUser,
  }) async {
    return await _post('/api/users/delete', {
      'username': username,
      'by_user': byUser,
    });
  }

  static Future<Map<String, dynamic>> changePanelUserPassword({
    required String username,
    required String newPassword,
    required String byUser,
    String oldPassword = '',
  }) async {
    return await _post('/api/users/password', {
      'username': username,
      'new_password': newPassword,
      'by_user': byUser,
      'old_password': oldPassword,
    });
  }

  // Audit Logs
  static Future<List<AuditLog>> getAuditLogs() async {
    final res = await _get('/api/audit-logs');
    if (res['status'] == 'ok' && res['logs'] != null) {
      return (res['logs'] as List)
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<void> logAuditAction({
    required String username,
    required String action,
    required String details,
  }) async {
    try {
      await _post('/api/audit-logs/log', {
        'username': username,
        'action': action,
        'details': details,
      });
    } catch (_) {}
  }
}
