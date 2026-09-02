part of 'main.dart';

extension DashStudioBodyMixin on _DashState {
  Widget _buildStudioHealthTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hızlı Presetler
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff18181b),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xff3f3f46)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                size: 16,
                color: Color(0xfffacc15),
              ),
              const SizedBox(width: 8),
              Text(
                'STATUS PRESETS: ',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff16a34a),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _pHealth = 100.0;
                    _pIsDead = false;
                    _pIsInfected = false;
                    _pHunger = 0.0;
                    _pThirst = 0.0;
                    _pFatigue = 0.0;
                    _pStress = 0.0;
                    _pBoredom = 0.0;
                  });
                },
                icon: const Icon(Icons.favorite_rounded, size: 14),
                label: Text(
                  'Perfect Health',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffd97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _pHealth = 70.0;
                    _pHunger = 60.0;
                    _pThirst = 50.0;
                    _pFatigue = 40.0;
                    _pStress = 25.0;
                  });
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 14),
                label: Text(
                  'Injured & Hungry',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffdc2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _pHealth = 15.0;
                    _pIsInfected = true;
                    _pHunger = 95.0;
                    _pThirst = 90.0;
                    _pFatigue = 85.0;
                    _pStress = 90.0;
                  });
                },
                icon: const Icon(Icons.coronavirus_rounded, size: 14),
                label: Text(
                  'Critical & Infected',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Genel Sağlık ve Beden Durumu
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
              Text(
                'BODY & HEALTH PARAMETERS',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff60a5fa),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              size: 15,
                              color: Color(0xffef4444),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Overall Health',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xfff4f4f5),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '%${_pHealth.round()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _pHealth > 50
                                    ? const Color(0xff4ade80)
                                    : const Color(0xfff87171),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _pHealth,
                          min: 0,
                          max: 100,
                          activeColor: _pHealth > 50
                              ? const Color(0xff22c55e)
                              : const Color(0xffef4444),
                          onChanged: (v) => setState(() => _pHealth = v),
                        ),
                        Text(
                          'Save dosyasından okunan 17 vücut bölgesi sağlığının ortalaması. '
                          'Değişiklik "Heal" preseti veya RCON ile uygulanır.',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xff71717a),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Gerçek vücut bölgesi sağlıkları (save dosyasından)
              if (_editingPlayer!.bodyParts.isNotEmpty) ...[
                const Divider(color: Color(0xff3f3f46)),
                Text(
                  'BODY PARTS (FROM SAVE FILE)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xffa1a1aa),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _editingPlayer!.bodyParts.map((part) {
                    final name = (part['name'] ?? '').toString();
                    final hp = (part['health'] as num? ?? 100).toDouble();
                    final bitten = part['bitten'] == true;
                    final bleeding = part['bleeding'] == true;
                    final infected = part['infected'] == true;
                    final fractured = ((part['fracture'] as num? ?? 0)) > 0;
                    final bandaged = part['bandaged'] == true;
                    final status = bitten
                        ? 'BITTEN'
                        : fractured
                        ? 'FRACTURE'
                        : infected
                        ? 'INFECTED'
                        : bleeding
                        ? 'BLEEDING'
                        : hp >= 100
                        ? 'OK'
                        : hp > 50
                        ? 'BRUISED'
                        : 'WOUNDED';
                    final color = bitten
                        ? const Color(0xffef4444)
                        : fractured
                        ? const Color(0xfffb923c)
                        : hp >= 100
                        ? const Color(0xff4ade80)
                        : hp > 50
                        ? const Color(0xfffacc15)
                        : const Color(0xfff87171);
                    return Tooltip(
                      message: '$name — $status${bandaged ? ' (bandaged)' : ''}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withAlpha(90)),
                        ),
                        child: Text(
                          '$name ${hp.round()}%${bitten ? ' !' : ''}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  'Not: Vücut bölgesi sağlıkları save dosyasından salt-okunur okunur. '
                  'Değiştirmek için "Full Heal" (RCON heal) kullanın.',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xff71717a),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Zombie Infection',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xfff4f4f5),
                        ),
                      ),
                      subtitle: Text(
                        'Does player carry Knox virus?',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xff71717a),
                        ),
                      ),
                      value: _pIsInfected,
                      activeThumbColor: const Color(0xffef4444),
                      onChanged: (v) => setState(() => _pIsInfected = v),
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Death Status',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xfff4f4f5),
                        ),
                      ),
                      subtitle: Text(
                        'Is player alive or dead?',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xff71717a),
                        ),
                      ),
                      value: _pIsDead,
                      activeThumbColor: const Color(0xffef4444),
                      onChanged: (v) => setState(() => _pIsDead = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // İhtiyaçlar ve Psikolojik Durumlar
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
              Text(
                'NEEDS & PSYCHOLOGICAL STATES',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff60a5fa),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hunger',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffa1a1aa),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '%${_pHunger.round()} • ${_pHunger == 0
                                  ? 'Full'
                                  : _pHunger < 40
                                  ? 'Peckish'
                                  : _pHunger < 80
                                  ? 'Hungry'
                                  : 'Starving'}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _pHunger == 0
                                    ? const Color(0xff4ade80)
                                    : const Color(0xfffacc15),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _pHunger,
                          min: 0,
                          max: 100,
                          activeColor: const Color(0xffeab308),
                          onChanged: (v) => setState(() => _pHunger = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Thirst',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffa1a1aa),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '%${_pThirst.round()} • ${_pThirst == 0
                                  ? 'Hydrated'
                                  : _pThirst < 40
                                  ? 'Slightly Thirsty'
                                  : 'Thirsty'}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _pThirst == 0
                                    ? const Color(0xff4ade80)
                                    : const Color(0xff38bdf8),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _pThirst,
                          min: 0,
                          max: 100,
                          activeColor: const Color(0xff38bdf8),
                          onChanged: (v) => setState(() => _pThirst = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Fatigue',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffa1a1aa),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '%${_pFatigue.round()} • ${_pFatigue == 0
                                  ? 'Rested'
                                  : _pFatigue < 60
                                  ? 'Tired'
                                  : 'Exhausted'}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _pFatigue == 0
                                    ? const Color(0xff4ade80)
                                    : const Color(0xffc084fc),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _pFatigue,
                          min: 0,
                          max: 100,
                          activeColor: const Color(0xffa855f7),
                          onChanged: (v) => setState(() => _pFatigue = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Stress',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffa1a1aa),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '%${_pStress.round()} • ${_pStress == 0
                                  ? 'Calm'
                                  : _pStress < 50
                                  ? 'Agitated'
                                  : 'Panicked'}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _pStress == 0
                                    ? const Color(0xff4ade80)
                                    : const Color(0xfff87171),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _pStress,
                          min: 0,
                          max: 100,
                          activeColor: const Color(0xffef4444),
                          onChanged: (v) => setState(() => _pStress = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Boredom',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffa1a1aa),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '%${_pBoredom.round()} • ${_pBoredom == 0 ? 'Happy' : 'Bored'}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _pBoredom == 0
                                    ? const Color(0xff4ade80)
                                    : const Color(0xfff472b6),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _pBoredom,
                          min: 0,
                          max: 100,
                          activeColor: const Color(0xffec4899),
                          onChanged: (v) => setState(() => _pBoredom = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Sekme 4: Oyuncu Envanteri (Player Inventory)
  Widget _buildStudioInventoryTab() {
    final uname = _editingPlayer!.username;
    final invList = _editingPlayer?.inventory ?? [];
    final q = _inventorySearchQuery.toLowerCase().trim();

    bool matchEntry(Map<String, dynamic> it) {
      if (q.isEmpty) return true;
      final name = (it['name'] ?? '').toString().toLowerCase();
      final raw = (it['raw_name'] ?? it['id'] ?? '').toString().toLowerCase();
      final id = (it['id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q) || raw.contains(q);
    }

    // Konteynerler arama sonucuna gore acilir/kapanir; normal listeleme:
    // konteyner kapali -> sadece baslik satiri; acik -> baslik + cocuklar.
    List<Map<String, dynamic>> buildVisible() {
      final out = <Map<String, dynamic>>[];
      for (final it in invList) {
        final isContainer = it['is_container'] == true;
        final children =
            (it['children'] as List<dynamic>? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
        if (q.isNotEmpty) {
          // Arama modunda: eslesen her seyi duz listeye akit (konteyner eslesirse cocuklariyla)
          if (isContainer) {
            final self = matchEntry(it);
            final kids = children.where(matchEntry).toList();
            if (self || kids.isNotEmpty) {
              out.add({...it, 'children': kids, '_forceOpen': true});
            }
          } else {
            if (matchEntry(it)) out.add(it);
          }
          continue;
        }
        if (isContainer) {
          final cid = it['id'].toString();
          out.add(it);
          if (_openInventoryContainers.contains(cid)) {
            for (final k in children) {
              out.add({...k, '_child_of': cid});
            }
          }
        } else {
          out.add(it);
        }
      }
      return out;
    }

    final filtered = buildVisible();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arama ve Başlık
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inventorySearchCtrl,
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
                  hintText: 'Search player inventory...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xff3f3f46)),
                  ),
                ),
                onChanged: (val) => setState(() => _inventorySearchQuery = val),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onPressed: _isRefreshingInventory
                  ? null
                  : () async {
                      setState(() => _isRefreshingInventory = true);
                      await _fetchGamePlayers();
                      if (mounted) {
                        setState(() => _isRefreshingInventory = false);
                      }
                    },
              icon: _isRefreshingInventory
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                _isRefreshingInventory ? 'Refreshing...' : 'Refresh Inventory',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_gamePlayersError.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff7f1d1d).withValues(alpha: 0.35),
              border: Border.all(color: const Color(0xff991b1b)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xfff87171),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Envanter verisi yenilenemedi: $_gamePlayersError',
                    style: const TextStyle(
                      color: Color(0xfffca5a5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (filtered.isEmpty && _gamePlayersError.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                invList.isEmpty
                    ? 'No items in player inventory.'
                    : 'No matching items.',
                style: const TextStyle(color: Color(0xffa1a1aa)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (ctx, i) {
              final it = filtered[i];
              final rawName = (it['name'] ?? 'Unknown Item').toString();
              final iid = (it['id'] ?? '').toString();
              final iname = ItemDisplayNames.displayName(
                iid,
                rawName,
              );
              final count = it['count'] ?? 1;
              final cat = it['cat'] ?? 'Genel';
              final isMod = it['is_mod'] == true;
              final modName = it['mod_name'];
              final iconFile = it['icon_file'];
              final isChild = it.containsKey('_child_of');
              final isContainer = it['is_container'] == true;
              final children =
                  (it['children'] as List<dynamic>? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();
              final resolved = iid.toString().isNotEmpty;
              final cid = iid.toString();
              final isOpen =
                  it['_forceOpen'] == true ||
                  _openInventoryContainers.contains(cid);

              // Konteyner satiri: butun satir tiklanabilir, acilinca cocuklari listelenir
              if (isContainer && !isChild) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff1e1e21),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isOpen
                          ? const Color(0xff3b82f6).withAlpha(140)
                          : const Color(0xff3f3f46),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        setState(() {
                          if (isOpen) {
                            _openInventoryContainers.remove(cid);
                          } else {
                            _openInventoryContainers.add(cid);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
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
                                scriptIcon:
                                    (it['icon'] as String?) ??
                                    ItemDisplayNames.scriptIcon(
                                      iid.toString(),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedRotation(
                              turns: isOpen ? 0.25 : 0,
                              duration: const Duration(milliseconds: 150),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: Color(0xff71717a),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
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
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xfff4f4f5),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xffeab308,
                                          ).withAlpha(40),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          '${children.length} items',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xfffde047),
                                          ),
                                        ),
                                      ),
                                      if (isMod) ...[
                                        const SizedBox(width: 6),
                                        Tooltip(
                                          message:
                                              'Mod: ${modName ?? "Custom Mod"}',
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 1,
                                                ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xff7c3aed)
                                                  .withAlpha(40),
                                              borderRadius:
                                                  BorderRadius.circular(3),
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
                                    '$iid • $cat',
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
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Container(
                padding: EdgeInsets.only(
                  left: isChild ? 34 : 10,
                  right: 10,
                  top: 6,
                  bottom: 6,
                ),
                margin: isChild
                    ? const EdgeInsets.only(left: 6, bottom: 2)
                    : const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isChild
                      ? const Color(0xff141416)
                      : const Color(0xff18181b),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isChild
                        ? const Color(0xff27272a)
                        : const Color(0xff3f3f46),
                  ),
                ),
                child: Row(
                  children: [
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
                        scriptIcon:
                            (it['icon'] as String?) ??
                            ItemDisplayNames.scriptIcon(iid.toString()),
                      ),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
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
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xfff4f4f5),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if ((count ?? 1) > 1 || !isChild)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff2563eb).withAlpha(
                                      40,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'x$count',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff93c5fd),
                                    ),
                                  ),
                                ),
                              if (isChild && !resolved) ...[
                                const SizedBox(width: 6),
                                Tooltip(
                                  message:
                                      'Bu eşya kayıttan birebir çözümlenemedi (ID bilinmiyor)',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff71717a)
                                          .withAlpha(40),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      '?',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xffa1a1aa),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (isMod) ...[
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: 'Mod: ${modName ?? "Custom Mod"}',
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
                            resolved ? '$iid • $cat' : '$cat',
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

                    // Aksiyonlar: +1 Ekle, +5 Ekle, Envanterden Çıkar
                    if (resolved) ...[
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
                      const SizedBox(width: 5),
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
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: () {
                          _quickSendRcon(
                            'removeitem "$uname" "${iid.toString()}"',
                            '$iname ($iid) silindi.',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff991b1b),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Delete',
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
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // Sekme 5: Eşya Verme (Item Spawner - 20,657 Eşya Kataloğu - Kompakt Liste Modu)
}
