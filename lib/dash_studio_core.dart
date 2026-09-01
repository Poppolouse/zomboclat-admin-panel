part of 'main.dart';

extension DashStudioCoreMixin on _DashState {
  Widget _buildPlayerStudioTabContent() {
    switch (_playerEditorSubTab) {
      case 0:
        return _buildStudioAccountTab();
      case 1:
        return _buildStudioSkillsTab();
      case 2:
        return _buildStudioProfessionTraitsTab();
      case 3:
        return _buildStudioHealthTab();
      case 4:
        return _buildStudioInventoryTab();
      case 5:
        return _buildStudioItemSpawnerTab();
      case 6:
        return _buildStudioTeleportTab();
      case 7:
        return _buildStudioLiveCommandsTab();
      default:
        return const SizedBox();
    }
  }

  // Sekme 0: Genel & Hesap
  Widget _buildStudioAccountTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IN-GAME CHARACTER NAME',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffa1a1aa),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _pCharNameCtrl,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xfff4f4f5),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xff18181b),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xff3f3f46)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'STEAM ID (64-bit)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffa1a1aa),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _pSteamIdCtrl,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xfff4f4f5),
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xff18181b),
                      hintText: '76561198...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xff3f3f46)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'NEW PASSWORD (Optional)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffa1a1aa),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _pPasswordCtrl,
                    obscureText: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xfff4f4f5),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xff18181b),
                      hintText: 'Leave blank to keep',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xff3f3f46)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROLE & ACCESS LEVEL',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffa1a1aa),
                    ),
                  ),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<int>(
                    initialValue: _pSelectedRoleId,
                    dropdownColor: const Color(0xff18181b),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xfff4f4f5),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xff18181b),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xff3f3f46)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 7,
                        child: Text('Admin (ðŸ‘‘ Full Administrator)'),
                      ),
                      DropdownMenuItem(
                        value: 6,
                        child: Text('Moderator (ðŸ›¡ï¸ Moderator)'),
                      ),
                      DropdownMenuItem(
                        value: 5,
                        child: Text('GM (ðŸŽ® Game Master / Items & Teleport)'),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text('Observer (ðŸ‘ï¸ Spectator / GodMode)'),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('Priority (â­ Priority Whitelist)'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('User (ðŸ‘¤ Standard Player)'),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Banned (ðŸš« Banned)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _pSelectedRoleId = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff18181b),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xff3f3f46)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _pIsBanned
                                ? 'Banned from Server ðŸš«'
                                : 'Not Banned ðŸ›¡ï¸',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _pIsBanned
                                  ? const Color(0xffef4444)
                                  : const Color(0xffa1a1aa),
                            ),
                          ),
                          subtitle: Text(
                            _pIsBanned
                                ? 'Player cannot join'
                                : 'Access granted',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xff71717a),
                            ),
                          ),
                          value: _pIsBanned,
                          activeThumbColor: const Color(0xffef4444),
                          onChanged: (val) => setState(() => _pIsBanned = val),
                        ),
                        if (_pIsBanned) ...[
                          const SizedBox(height: 8),
                          TextField(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xfff4f4f5),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xff27272a),
                              labelText: 'Ban Reason',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onChanged: (val) => _pBanReason = val,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Sekme 1: Beceriler & Seviyeler (0-10)
  Widget _buildStudioSkillsTab() {
    final categories = [
      'Passive',
      'Agility',
      'Combat',
      'Firearms',
      'Crafting',
      'Survivalist',
      'Build 42 & Mods',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ãœst AraÃ§ Ã‡ubuÄŸu
        Row(
          children: [
            Text(
              'SKILLS & XP LEVELS (0-10)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xffa1a1aa),
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xfffacc15),
                side: const BorderSide(color: Color(0xffeab308)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                setState(() {
                  for (final s in _allPzSkills) {
                    _pSkills[s.id] = 10;
                  }
                });
              },
              icon: const Icon(
                Icons.star_rounded,
                size: 15,
                color: Color(0xfffacc15),
              ),
              label: Text(
                'Max All Skills (10)',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xffa1a1aa),
                side: const BorderSide(color: Color(0xff52525b)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                setState(() {
                  for (final s in _allPzSkills) {
                    final id = s.id;
                    _pSkills[id] = (id == 'Fitness' || id == 'Strength')
                        ? 5
                        : 0;
                  }
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: Text('Reset All', style: const TextStyle(fontSize: 11.5)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Kategori BazlÄ± Beceri Listesi
        ...categories.map((cat) {
          final catSkills = _allPzSkills.where((s) => s.cat == cat).toList();
          if (catSkills.isEmpty) return const SizedBox();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
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
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xff3b82f6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff60a5fa),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final itemWidth = (constraints.maxWidth - 24) / 3;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: catSkills.map((s) {
                        final sid = s.id;
                        final sname = s.name;
                        final lvl = _pSkills[sid] ?? 0;

                        return Container(
                          width: itemWidth > 260
                              ? itemWidth
                              : (constraints.maxWidth - 12) / 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff27272a),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: lvl > 0
                                  ? const Color(0xff3b82f6).withAlpha(120)
                                  : const Color(0xff3f3f46),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    s.icon,
                                    size: 16,
                                    color: lvl > 0
                                        ? const Color(0xff60a5fa)
                                        : const Color(0xffa1a1aa),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      sname,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xfff4f4f5),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (s.isMod) ...[
                                    Tooltip(
                                      message: 'Mod: ${s.modName ?? "Custom"}',
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xff3b82f6)
                                              .withAlpha(40),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: const Text(
                                          'MOD',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff93c5fd),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: lvl >= 10
                                          ? const Color(0xffeab308)
                                                .withAlpha(40)
                                          : (lvl > 0
                                                ? const Color(0xff3b82f6)
                                                      .withAlpha(40)
                                                : const Color(0xff3f3f46)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$lvl / 10',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: lvl >= 10
                                            ? const Color(0xfffacc15)
                                            : (lvl > 0
                                                  ? const Color(0xff93c5fd)
                                                  : const Color(0xffa1a1aa)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (lvl > 0) _pSkills[sid] = lvl - 1;
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(
                                        Icons.remove_circle_outline_rounded,
                                        size: 16,
                                        color: Color(0xffa1a1aa),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: const Color(
                                          0xff3b82f6,
                                        ),
                                        inactiveTrackColor: const Color(
                                          0xff3f3f46,
                                        ),
                                        thumbColor: lvl >= 10
                                            ? const Color(0xfffacc15)
                                            : const Color(0xff60a5fa),
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 5,
                                        ),
                                      ),
                                      child: Slider(
                                        value: lvl.toDouble(),
                                        min: 0,
                                        max: 10,
                                        divisions: 10,
                                        onChanged: (val) {
                                          setState(
                                            () => _pSkills[sid] = val.round(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (lvl < 10) _pSkills[sid] = lvl + 1;
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 16,
                                        color: Color(0xff60a5fa),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Sekme 2: Meslek & Traitler (3 SÃ¼tun, Tek Dil, GerÃ§ek Oyun Ä°konlarÄ± & Mod Bilgisi)
  Widget _buildStudioProfessionTraitsTab() {
    final curProf = _allPzProfessions.firstWhere(
      (p) => p['id'] == _pSelectedProfession,
      orElse: () => _allPzProfessions.first,
    );
    final profDesc = curProf['desc'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meslek SeÃ§imi
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
                'CHARACTER PROFESSION',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff60a5fa),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _pSelectedProfession,
                dropdownColor: const Color(0xff18181b),
                style: const TextStyle(fontSize: 13, color: Color(0xfff4f4f5)),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff27272a),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                items: _allPzProfessions.map((prof) {
                  final title = prof['name'] ?? '';
                  final desc = prof['desc'] ?? '';
                  return DropdownMenuItem(
                    value: prof['id'],
                    child: Text('$title â€” $desc'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _pSelectedProfession = val);
                },
              ),
              const SizedBox(height: 8),
              Text(
                '${'Profession Perks: '}$profDesc',
                style: const TextStyle(fontSize: 12, color: Color(0xff86efac)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pozitif Traitler (3 SÃ¼tunlu Grid Layout & GerÃ§ek Oyun Ä°konlarÄ±)
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
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: Color(0xff4ade80),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'POSITIVE TRAITS',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff4ade80),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff16a34a).withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_pSelectedPositiveTraits.length} ${'selected'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff86efac),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final colWidth = (constraints.maxWidth - 20) / 3;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _allPzPositiveTraits.map((t) {
                      final tid = t.id;
                      final isSelected = _pSelectedPositiveTraits.contains(tid);
                      final label = t.name;

                      return Container(
                        width: colWidth > 220
                            ? colWidth
                            : (constraints.maxWidth - 10) / 2,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff16a34a).withAlpha(35)
                              : const Color(0xff27272a),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xff22c55e)
                                : const Color(0xff3f3f46),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _pSelectedPositiveTraits.remove(tid);
                                } else {
                                  _pSelectedPositiveTraits.add(tid);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: _buildPzTraitIcon(t.id, size: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xff86efac)
                                            : const Color(0xfff4f4f5),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (t.isMod) ...[
                                    Tooltip(
                                      message:
                                          'Mod: ${t.modName ?? "More Traits"}',
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        margin: const EdgeInsets.only(left: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xff3b82f6)
                                              .withAlpha(40),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.info_outline_rounded,
                                          size: 12,
                                          color: Color(0xff60a5fa),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 4),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 15,
                                    color: isSelected
                                        ? const Color(0xff22c55e)
                                        : const Color(0xff52525b),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Negatif Traitler (3 SÃ¼tunlu Grid Layout & GerÃ§ek Oyun Ä°konlarÄ±)
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
                    Icons.remove_circle_outline_rounded,
                    size: 16,
                    color: Color(0xfff87171),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'NEGATIVE TRAITS',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xfff87171),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffdc2626).withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_pSelectedNegativeTraits.length} ${'selected'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xfffca5a5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final colWidth = (constraints.maxWidth - 20) / 3;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _allPzNegativeTraits.map((t) {
                      final tid = t.id;
                      final isSelected = _pSelectedNegativeTraits.contains(tid);
                      final label = t.name;

                      return Container(
                        width: colWidth > 220
                            ? colWidth
                            : (constraints.maxWidth - 10) / 2,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xffdc2626).withAlpha(35)
                              : const Color(0xff27272a),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xffef4444)
                                : const Color(0xff3f3f46),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _pSelectedNegativeTraits.remove(tid);
                                } else {
                                  _pSelectedNegativeTraits.add(tid);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: _buildPzTraitIcon(t.id, size: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xfffca5a5)
                                            : const Color(0xfff4f4f5),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (t.isMod) ...[
                                    Tooltip(
                                      message:
                                          'Mod: ${t.modName ?? "More Traits"}',
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        margin: const EdgeInsets.only(left: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xff3b82f6)
                                              .withAlpha(40),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.info_outline_rounded,
                                          size: 12,
                                          color: Color(0xff60a5fa),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 4),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 15,
                                    color: isSelected
                                        ? const Color(0xffef4444)
                                        : const Color(0xff52525b),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Sekme 3: SaÄŸlÄ±k, Beden & Ä°statistikler
}
