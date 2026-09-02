part of 'main.dart';

extension DashSandboxMixin on _DashState {
  void _showJumpToPositionDialog(int currentIndex, String modId) {
    final posCtrl = TextEditingController(text: '${currentIndex + 1}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff27272a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xff3f3f46)),
        ),
        title: Text(
          'Change Order Position',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mod: $modId',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff93c5fd),
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'New Position (1 - ${_iniMods.length}):',
              style: const TextStyle(fontSize: 11, color: Color(0xffa1a1aa)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: posCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13, color: Color(0xfff4f4f5)),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xff18181b),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onSubmitted: (val) {
                final pos = int.tryParse(val.trim());
                if (pos != null) {
                  _moveModToPosition(currentIndex, pos - 1);
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2563eb),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final pos = int.tryParse(posCtrl.text.trim());
              if (pos != null) {
                _moveModToPosition(currentIndex, pos - 1);
              }
              Navigator.pop(ctx);
            },
            child: Text('Move'),
          ),
        ],
      ),
    );
  }

  // TAB 2: SANDBOXVARS AYARLARI (LUA DİNAMİK KATEGORİLER & SMART ALANLAR & YORUMLAR)
  Widget _buildSandboxTab() {
    final meta = _getSandboxCategoryMeta(_selectedSandboxCategory);
    final displayName = meta['displayName'] as String;
    final previewUrl = meta['previewUrl'] as String?;
    final wid = meta['workshopId'] as String?;
    final isMod = meta['isMod'] as bool;

    final currentItems = (_sandboxCategories[_selectedSandboxCategory] ?? [])
        .where(
          (it) => it['key'].toString().toLowerCase().contains(
            _sandboxSearchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xff27272a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff3f3f46), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Başlık & Kaydet Butonu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                if (previewUrl != null && previewUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      previewUrl,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.extension_rounded,
                        size: 20,
                        color: Color(0xffc084fc),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  Icon(
                    isMod ? Icons.extension_rounded : Icons.view_in_ar_rounded,
                    size: 20,
                    color: isMod
                        ? const Color(0xffc084fc)
                        : const Color(0xffa855f7),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xfff4f4f5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (displayName != _selectedSandboxCategory) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff18181b),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xff3f3f46)),
                          ),
                          child: Text(
                            'Tablo: $_selectedSandboxCategory',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xff93c5fd),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                      if (wid != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'WS: $wid',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xff71717a),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Refresh',
                  icon: _isLoadingSandbox
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 17,
                          color: Color(0xffa1a1aa),
                        ),
                  onPressed: _isLoadingSandbox ? null : _fetchSandboxConfig,
                ),
                if (widget.user.isAdmin) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _isSavingSandbox ? null : _saveSandboxConfig,
                    icon: _isSavingSandbox
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(
                      'Save SandboxVars',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Color(0xff3f3f46), height: 1),

          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              style: const TextStyle(fontSize: 12.5, color: Color(0xfff4f4f5)),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xff18181b),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Color(0xffa1a1aa),
                ),
                hintText: '${'Filter in'} $displayName...',
                hintStyle: const TextStyle(
                  color: Color(0xff71717a),
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xff3f3f46)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xff3f3f46)),
                ),
              ),
              onChanged: (val) => setState(() => _sandboxSearchQuery = val),
            ),
          ),
          const Divider(color: Color(0xff333338), height: 1),

          // Kategori Değişkenleri
          if (_isLoadingSandbox)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xff3b82f6)),
              ),
            )
          else if (currentItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text('No settings found in category.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentItems.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Color(0xff333338), height: 1),
              itemBuilder: (ctx, i) {
                final item = currentItems[i];
                final key = item['key'] as String;
                final val = item['value'];
                final type = item['type'] as String? ?? 'string';
                final comment = (item['comment'] as String? ?? '').trim();

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xfff4f4f5),
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xff141416),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xff333338),
                                  ),
                                ),
                                child: Text(
                                  comment,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xffa1a1aa),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: type == 'bool'
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Switch(
                                  value: val == true,
                                  activeThumbColor: const Color(0xff3b82f6),
                                  onChanged: (newVal) {
                                    setState(() {
                                      item['value'] = newVal;
                                    });
                                  },
                                ),
                              )
                            : (type == 'int' || type == 'float')
                            ? Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 18,
                                      color: Color(0xffa1a1aa),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (type == 'int') {
                                          item['value'] =
                                              (int.tryParse(val.toString()) ??
                                                  0) -
                                              1;
                                        } else {
                                          item['value'] =
                                              (double.tryParse(
                                                    val.toString(),
                                                  ) ??
                                                  0.0) -
                                              0.1;
                                        }
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      key: ValueKey('$key-${item['value']}'),
                                      initialValue: val.toString(),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xfff4f4f5),
                                        fontFamily: 'monospace',
                                      ),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        filled: true,
                                        fillColor: const Color(0xff18181b),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xff3f3f46),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xff3f3f46),
                                          ),
                                        ),
                                      ),
                                      onChanged: (newVal) {
                                        if (type == 'int') {
                                          item['value'] =
                                              int.tryParse(newVal) ?? val;
                                        } else {
                                          item['value'] =
                                              double.tryParse(newVal) ?? val;
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 18,
                                      color: Color(0xffa1a1aa),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (type == 'int') {
                                          item['value'] =
                                              (int.tryParse(val.toString()) ??
                                                  0) +
                                              1;
                                        } else {
                                          item['value'] =
                                              (double.tryParse(
                                                    val.toString(),
                                                  ) ??
                                                  0.0) +
                                              0.1;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              )
                            : TextFormField(
                                key: ValueKey('$key-${item['value']}'),
                                initialValue: val.toString(),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xfff4f4f5),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xff18181b),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Color(0xff3f3f46),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Color(0xff3f3f46),
                                    ),
                                  ),
                                ),
                                onChanged: (newVal) {
                                  item['value'] = newVal;
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddModDialog() {
    final modCtrl = TextEditingController();
    final wsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff27272a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xff3f3f46)),
        ),
        title: Text(
          'Add New Mod / Workshop ID',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOD ID (Zomboid Name)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xffa1a1aa),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: modCtrl,
              style: const TextStyle(fontSize: 12.5, color: Color(0xfff4f4f5)),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xff18181b),
                hintText: 'e.g. Hydrocraft',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'WORKSHOP ID (Steam Number)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xffa1a1aa),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: wsCtrl,
              style: const TextStyle(fontSize: 12.5, color: Color(0xfff4f4f5)),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xff18181b),
                hintText: 'e.g. 2772575623',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2563eb),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final m = modCtrl.text.trim();
              final w = wsCtrl.text.trim();
              if (m.isNotEmpty) _iniMods.add(m);
              if (w.isNotEmpty) _iniWorkshopItems.add(w);
              setState(() {});
              Navigator.pop(ctx);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
