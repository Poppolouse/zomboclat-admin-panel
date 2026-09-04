part of 'main.dart';

// -------------------------------------------------------------
// MOD ITEM ICON LOADER (VPS Workshop uzerinden)
// -------------------------------------------------------------
// Mod esyalari icin once paketli base ikonlari denenir (cogu mod vanilla
// ikon adlarini yeniden kullanir). Bulunamazsa VPS'teki /api/mods/icon
// endpoint'inden cekilir ve yerel disk onbelligine yazilir.
class ModIconCache {
  ModIconCache._();
  static final ModIconCache instance = ModIconCache._();

  static const String _cacheDirName = 'zomboclat_icon_cache';

  final Map<String, File> _resolved = {};
  final Set<String> _failed = {};
  final Map<String, Future<File?>> _inflight = {};

  Directory get _cacheDir {
    final base = Directory.systemTemp.path;
    return Directory('$base${Platform.pathSeparator}$_cacheDirName')
      ..createSync(recursive: true);
  }

  String _sanitize(String key) =>
      key.replaceAll(RegExp(r'[^A-Za-z0-9_.\-]'), '_');

  Future<Uint8List?> load(
    String modName,
    String iconFile,
    String itemId,
  ) async {
    final key = '$modName|$iconFile|$itemId';
    final cached = _resolved[key];
    if (cached != null && cached.existsSync()) {
      try {
        return cached.readAsBytesSync();
      } catch (_) {}
    }
    if (_failed.contains(key)) return null;

    final existing = _inflight[key];
    if (existing != null) {
      final f = await existing;
      if (f != null && f.existsSync()) {
        try {
          return f.readAsBytesSync();
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    final fut = _fetch(modName, iconFile, itemId, key);
    _inflight[key] = fut;
    try {
      final f = await fut;
      if (f == null) {
        _failed.add(key);
        return null;
      }
      _resolved[key] = f;
      return f.readAsBytesSync();
    } finally {
      _inflight.remove(key);
    }
  }

  Future<File?> _fetch(
    String modName,
    String iconFile,
    String itemId,
    String key,
  ) async {
    try {
      final raw = itemId.contains('.') ? itemId.split('.').last : itemId;
      final safeName = Uri.encodeComponent(modName);
      final safeIcon = Uri.encodeComponent(iconFile);
      final safeId = Uri.encodeComponent(itemId);
      final uri = Uri.parse(
        '$kApiBaseUrl/api/mods/icon?mod_name=$safeName&icon_file=$safeIcon&item_id=$safeId&fallback_raw=$raw',
      );
      final req = await ApiClient._httpClient
          .getUrl(uri)
          .timeout(const Duration(seconds: 8));
      ApiClient._authorize(req);
      final resp = await req.close().timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final bytes = await resp.fold<List<int>>(
        <int>[],
        (acc, chunk) => acc..addAll(chunk),
      );
      if (bytes.isEmpty || bytes.length > 512 * 1024) return null;
      final target = File(
        '${_cacheDir.path}${Platform.pathSeparator}${_sanitize(key)}.png',
      );
      await target.writeAsBytes(bytes, flush: true);
      return target;
    } catch (_) {
      return null;
    }
  }
}

/// Mod ikonlarini asenkron ceken ImageProvider; disk onbeli destekler.
class ModIconImage extends StatefulWidget {
  final String modName;
  final String iconFile;
  final String itemId;
  final double size;
  final Widget fallback;

  const ModIconImage({
    super.key,
    required this.modName,
    required this.iconFile,
    required this.itemId,
    required this.size,
    required this.fallback,
  });

  @override
  State<ModIconImage> createState() => _ModIconImageState();
}

class _ModIconImageState extends State<ModIconImage> {
  Uint8List? _bytes;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await ModIconCache.instance.load(
      widget.modName,
      widget.iconFile,
      widget.itemId,
    );
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.4),
          ),
        ),
      );
    }
    if (_bytes == null) return widget.fallback;
    return Image.memory(
      _bytes!,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => widget.fallback,
    );
  }
}

/// Script icon adiyla (Icon=/IconsForTexture=) VPS'ten icon ceken widget.
/// `/api/items/icon?icon=name` endpoint'ini kullanir, disk onbeli ile.
class RemoteItemIconImage extends StatefulWidget {
  final String iconName;
  final String itemId;
  final double size;
  final Widget fallback;

  const RemoteItemIconImage({
    super.key,
    required this.iconName,
    required this.itemId,
    required this.size,
    required this.fallback,
  });

  @override
  State<RemoteItemIconImage> createState() => _RemoteItemIconImageState();
}

class _RemoteItemIconImageState extends State<RemoteItemIconImage> {
  Uint8List? _bytes;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await RemoteIconCache.instance.load(widget.iconName);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.4),
          ),
        ),
      );
    }
    if (_bytes == null) return widget.fallback;
    return Image.memory(
      _bytes!,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => widget.fallback,
    );
  }
}

/// /api/items/icon icin basit disk-onbeli'li ceker.
class RemoteIconCache {
  RemoteIconCache._();
  static final RemoteIconCache instance = RemoteIconCache._();

  static const String _cacheDirName = 'zomboclat_item_icon_cache';

  final Map<String, Uint8List?> _mem = {};
  final Map<String, Future<Uint8List?>> _inflight = {};

  Directory get _cacheDir {
    final base = Directory.systemTemp.path;
    return Directory('$base${Platform.pathSeparator}$_cacheDirName')
      ..createSync(recursive: true);
  }

  String _sanitize(String key) =>
      key.replaceAll(RegExp(r'[^A-Za-z0-9_.\-]'), '_');

  Future<Uint8List?> load(String iconName) async {
    final key = _sanitize(iconName.toLowerCase());
    if (_mem.containsKey(key)) return _mem[key];

    final f = File('${_cacheDir.path}${Platform.pathSeparator}$key.png');
    if (f.existsSync()) {
      try {
        final b = f.readAsBytesSync();
        _mem[key] = b;
        return b;
      } catch (_) {}
    }

    final existing = _inflight[key];
    if (existing != null) return existing;

    final fut = _fetch(iconName, f, key);
    _inflight[key] = fut;
    try {
      final b = await fut;
      _mem[key] = b;
      return b;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<Uint8List?> _fetch(String iconName, File target, String key) async {
    try {
      final uri = Uri.parse(
        '$kApiBaseUrl/api/items/icon?icon=${Uri.encodeComponent(iconName)}',
      );
      final req = await ApiClient._httpClient
          .getUrl(uri)
          .timeout(const Duration(seconds: 8));
      ApiClient._authorize(req);
      final resp = await req.close().timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final bytes = await resp.fold<List<int>>(
        <int>[],
        (acc, chunk) => acc..addAll(chunk),
      );
      if (bytes.isEmpty || bytes.length > 512 * 1024) return null;
      try {
        await target.writeAsBytes(bytes, flush: true);
      } catch (_) {}
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }
}
