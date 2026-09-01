part of 'main.dart';

extension DashSupportMixin on _DashState {
  Map<String, dynamic>? _getModMetadata(int index, String modId) {
    if (_modDetails.containsKey(modId)) {
      return _modDetails[modId];
    }
    return null;
  }

  // Sandbox Kategori BaÅŸlÄ±ÄŸÄ± ve Mod EÅŸleÅŸtirici
  Map<String, dynamic> _getSandboxCategoryMeta(String catKey) {
    if (_sandboxCategoryMeta.containsKey(catKey)) {
      final m = _sandboxCategoryMeta[catKey]!;
      final dName = m['display_name']?.toString() ?? catKey;
      return {
        'displayName': dName.isNotEmpty ? dName : catKey,
        'previewUrl': m['preview_url'] as String?,
        'workshopId':
            (m['workshop_id'] != null && m['workshop_id'].toString().isNotEmpty)
            ? m['workshop_id'].toString()
            : null,
        'isMod': m['is_mod'] == true,
      };
    }

    if (catKey == 'General') {
      return {
        'displayName': 'General Settings',
        'previewUrl': null,
        'workshopId': null,
        'isMod': false,
      };
    }
    if (catKey == 'ZombieLore') {
      return {
        'displayName': 'Zombie Lore & Behavior',
        'previewUrl': null,
        'workshopId': null,
        'isMod': false,
      };
    }
    if (catKey == 'ZombieConfig') {
      return {
        'displayName': 'Zombie Population & Spawns',
        'previewUrl': null,
        'workshopId': null,
        'isMod': false,
      };
    }
    if (catKey == 'MultiplierConfig') {
      return {
        'displayName': 'XP & Multiplier Settings',
        'previewUrl': null,
        'workshopId': null,
        'isMod': false,
      };
    }
    if (catKey == 'Vehicle') {
      return {
        'displayName': 'Vehicle Settings',
        'previewUrl': null,
        'workshopId': null,
        'isMod': false,
      };
    }
    if (catKey == 'Map') {
      return {
        'displayName': 'Map & World Settings',
        'previewUrl': null,
        'workshopId': null,
        'isMod': false,
      };
    }

    return {
      'displayName': catKey,
      'previewUrl': null,
      'workshopId': null,
      'isMod': false,
    };
  }

  // Mod SÄ±rasÄ± Konumu DeÄŸiÅŸtir
  void _moveModToPosition(int currentIndex, int targetIndex) {
    if (targetIndex < 0) targetIndex = 0;
    if (targetIndex >= _iniMods.length) targetIndex = _iniMods.length - 1;
    if (currentIndex == targetIndex) return;

    setState(() {
      final item = _iniMods.removeAt(currentIndex);
      _iniMods.insert(targetIndex, item);
    });
  }

  // Loglardaki Mod HatalarÄ±nÄ± Ã‡Ä±kar
  List<ModErrorGroup> _extractModErrors() {
    final Map<String, List<String>> modErrors = {};

    for (final line in _serverLogs) {
      final lower = line.toLowerCase();
      final isError =
          lower.contains('error') ||
          lower.contains('exception') ||
          lower.contains('caused by') ||
          lower.contains('fatal') ||
          lower.contains('stack trace') ||
          lower.contains('lua error') ||
          lower.contains('filenotfoundexception') ||
          lower.contains('pzxmlparserexception');

      if (!isError) continue;

      String? matchedModId;

      // 1. Mod ID eÅŸleÅŸmesi
      for (final modId in _iniMods) {
        if (modId.length >= 3 && lower.contains(modId.toLowerCase())) {
          matchedModId = modId;
          break;
        }
      }

      // 2. Workshop ID eÅŸleÅŸmesi
      if (matchedModId == null) {
        for (final wid in _iniWorkshopItems) {
          if (line.contains(wid)) {
            for (final m in _iniMods) {
              if (_modDetails[m]?['workshop_id'] == wid) {
                matchedModId = m;
                break;
              }
            }
            matchedModId ??= 'Workshop_$wid';
            break;
          }
        }
      }

      if (matchedModId != null) {
        modErrors.putIfAbsent(matchedModId, () => []).add(line);
      }
    }

    return modErrors.entries.map((e) {
      final meta = _modDetails[e.key];
      return ModErrorGroup(
        modId: e.key,
        modName: meta?['name'] ?? meta?['workshop_title'] ?? e.key,
        workshopId: meta?['workshop_id'],
        previewUrl: meta?['preview_url'],
        errorLines: e.value,
      );
    }).toList();
  }

  // Mod & Workshop JSON Ã‡Ä±ktÄ± Penceresi
  void _showModJsonExportDialog() {
    final Map<String, dynamic> exportData = {
      'server': 'Zomboclat Project Zomboid Dedicated',
      'exported_at': DateTime.now().toIso8601String(),
      'total_mods': _iniMods.length,
      'total_workshop_items': _iniWorkshopItems.length,
      'mods_load_order': _iniMods,
      'workshop_items': _iniWorkshopItems,
      'mods_raw_ini_string': 'Mods=${_iniMods.join(';')}',
      'workshop_raw_ini_string': 'WorkshopItems=${_iniWorkshopItems.join(';')}',
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff27272a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xff3f3f46)),
        ),
        title: Row(
          children: [
            const Icon(Icons.code_rounded, color: Color(0xff38bdf8), size: 20),
            const SizedBox(width: 10),
            Text(
              'Mod & Workshop JSON Export',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 620,
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active mod load order and Workshop items compiled in JSON format:',
                style: const TextStyle(fontSize: 12, color: Color(0xffa1a1aa)),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff18181b),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xff3f3f46)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xff86efac),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: const TextStyle(color: Color(0xffa1a1aa)),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2563eb),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xff15803d),
                  content: Text('JSON exported and copied to clipboard!'),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text('Copy JSON'),
          ),
        ],
      ),
    );
  }
}
