part of 'main.dart';

extension DashStudioItemsMixin on _DashState {
  Widget _buildStudioItemSpawnerTab() {
    final catOptions = [
      'All',
      'Weapons',
      'Clothing & Armor',
      'Medical',
      'Food & Drink',
      'Vehicles & Mechanics',
      'Tools & Crafting',
      'Literature',
      'Mod Items',
      'Other',
    ];

    final q = _spawnerSearchQuery.toLowerCase().trim();
    final isModOnly = _spawnerSelectedCat == 'Mod Items';

    final filteredItems = _catalogItems.where((it) {
      if (isModOnly) {
        if (it['is_mod'] != true) return false;
      } else if (_spawnerSelectedCat != 'All') {
        final itCat = (it['cat'] ?? '').toString().toLowerCase();
        final selCat = _spawnerSelectedCat.toLowerCase();
        if (!itCat.contains(selCat) && !selCat.contains(itCat)) {
          return false;
        }
      }
      if (q.isNotEmpty) {
        final iname = (it['name'] ?? '').toString().toLowerCase();
        final iid = (it['id'] ?? '').toString().toLowerCase();
        final modN = (it['mod_name'] ?? '').toString().toLowerCase();
        return iname.contains(q) || iid.contains(q) || modN.contains(q);
      }
      return true;
    }).toList();

    final displayItems = filteredItems.take(250).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ã–zel ID ile EÅŸya Verme Ã‡ubuÄŸu
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff18181b),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xff3f3f46)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pCustomItemCtrl,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xfff4f4f5),
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xff27272a),
                    hintText: 'e.g. Base.Katana, Base.Bag_ALICEpack_Army, Base.Axe...',
                    labelText: 'Custom Item ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 75,
                child: TextField(
                  controller: _pItemCountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xfff4f4f5),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xff27272a),
                    labelText: 'Count',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563eb),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  final itm = _pCustomItemCtrl.text.trim();
                  final count = int.tryParse(_pItemCountCtrl.text.trim()) ?? 1;
                  if (itm.isNotEmpty) {
                    _quickGiveItem(itm, count);
                  }
                },
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                label: Text(
                  'Give to Player',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Kategori Filtre ButonlarÄ±
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: catOptions.map((c) {
              final isSel = _spawnerSelectedCat == c;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(c),
                  selected: isSel,
                  selectedColor: const Color(0xff2563eb),
                  backgroundColor: const Color(0xff27272a),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : const Color(0xffa1a1aa),
                  ),
                  side: BorderSide(
                    color: isSel
                        ? const Color(0xff3b82f6)
                        : const Color(0xff3f3f46),
                  ),
                  onSelected: (sel) {
                    if (sel) {
                      setState(() => _spawnerSelectedCat = c);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Arama ve SonuÃ§ SayacÄ±
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _spawnerSearchCtrl,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xfff4f4f5),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff18181b),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: Color(0xffa1a1aa),
                  ),
                  suffixIcon: _spawnerSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 16,
                            color: Color(0xffa1a1aa),
                          ),
                          onPressed: () {
                            _spawnerSearchCtrl.clear();
                            setState(() => _spawnerSearchQuery = '');
                          },
                        )
                      : null,
                  hintText: 'Instant search 20,657 items...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xff3f3f46)),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _spawnerSearchQuery = val);
                },
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xff27272a),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xff3f3f46)),
              ),
              child: Text(
                '${filteredItems.length} / ${_catalogItems.length} ${'items'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff93c5fd),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // EÅŸya Kompakt YÃ¼ksek YoÄŸunluklu Liste (High-Density Compact List)
        if (_isLoadingCatalog)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_catalogError.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xfff87171),
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _catalogError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xfffca5a5)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _loadCatalogFromBundle,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (displayItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                'No matching items in catalog.',
                style: const TextStyle(color: Color(0xffa1a1aa)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 3),
            itemBuilder: (ctx, i) {
              final itm = displayItems[i];
              final iname = itm['name'] ?? 'Item';
              final iid = itm['id'] ?? '';
              final cat = itm['cat'] ?? 'Genel';
              final isMod = itm['is_mod'] == true;
              final modName = itm['mod_name'];
              final iconFile = itm['icon_file'];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff18181b),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xff27272a)),
                ),
                child: Row(
                  children: [
                    // Oyun Ä°Ã§i GerÃ§ek EÅŸya Ä°konu
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xff27272a),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _buildPzItemIcon(
                        iconFile,
                        iid.toString(),
                        size: 24,
                        isMod: isMod,
                        modName: modName?.toString(),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Ä°sim & ID
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  iname.toString(),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xfff4f4f5),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMod) ...[
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: 'Mod: ${modName ?? "Custom"}',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff7c3aed)
                                          .withAlpha(40),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'MOD',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xffc4b5fd),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            iid.toString(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xff71717a),
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Kategori Etiketi
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff27272a),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        cat.toString(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xffa1a1aa),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // HÄ±zlÄ± Verme ButonlarÄ±: +1, +5, +20
                    InkWell(
                      onTap: () => _quickGiveItem(iid.toString(), 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff2563eb),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '+1',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _quickGiveItem(iid.toString(), 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff1e3a8a),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '+5',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _quickGiveItem(iid.toString(), 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff312e81),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '+20',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        _pCustomItemCtrl.text = iid.toString();
                        _quickGiveItem(
                          iid.toString(),
                          int.tryParse(_pItemCountCtrl.text.trim()) ?? 1,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff16a34a),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flash_on_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Give',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // Sekme 6: Harita & IÅŸÄ±nlanma
  Widget _buildStudioTeleportTab() {
    final uname = _editingPlayer!.username;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xff18181b),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xff3f3f46)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: Color(0xff86efac),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WORLD COORDINATES & TELEPORT',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff86efac),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff16a34a),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final x = _pPosXCtrl.text.trim();
                      final y = _pPosYCtrl.text.trim();
                      final z = _pPosZCtrl.text.trim();
                      _quickSendRcon(
                        'teleportto "$uname" $x,$y,$z',
                        '$uname teleported to $x, $y, $z.',
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 14),
                    label: Text(
                      'Live Teleport',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pPosXCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xfff4f4f5),
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        labelText: 'X (Longitude)',
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xff27272a),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _pPosYCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xfff4f4f5),
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Y (Latitude)',
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xff27272a),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _pPosZCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xfff4f4f5),
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Z (Floor/Level)',
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xff27272a),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                'QUICK CITY PRESETS',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickLocationChip('Muldraugh Center', 10600.0, 9700.0, 0),
                  _quickLocationChip('West Point', 11800.0, 6800.0, 0),
                  _quickLocationChip('Rosewood', 8100.0, 11600.0, 0),
                  _quickLocationChip('Riverside', 6300.0, 5300.0, 0),
                  _quickLocationChip('Louisville Downtown', 12500.0, 1500.0, 0),
                  _quickLocationChip('March Ridge', 10000.0, 12800.0, 0),
                  _quickLocationChip('Valley Station', 13700.0, 5500.0, 0),
                  _quickLocationChip('Fallas Lake (Ekron)', 7300.0, 8300.0, 0),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickLocationChip(String name, double x, double y, int z) {
    return ActionChip(
      avatar: const Icon(
        Icons.place_rounded,
        size: 14,
        color: Color(0xff60a5fa),
      ),
      label: Text(name),
      backgroundColor: const Color(0xff27272a),
      labelStyle: const TextStyle(fontSize: 11.5, color: Color(0xffe4e4e7)),
      side: const BorderSide(color: Color(0xff3f3f46)),
      onPressed: () {
        setState(() {
          _pPosXCtrl.text = x.toStringAsFixed(1);
          _pPosYCtrl.text = y.toStringAsFixed(1);
          _pPosZCtrl.text = z.toString();
        });
      },
    );
  }

  // Sekme 7: CanlÄ± RCON KomutlarÄ±
}
