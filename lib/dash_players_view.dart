part of 'main.dart';

extension DashPlayersViewMixin on _DashState {
  Widget _buildGamePlayersTab() {
    if (_editingPlayer != null) {
      return _buildPlayerStudioView();
    }

    final filteredPlayers = _gamePlayers.where((p) {
      if (_gamePlayerSearchQuery.isEmpty) return true;
      final q = _gamePlayerSearchQuery.toLowerCase();
      return p.username.toLowerCase().contains(q) ||
          p.charName.toLowerCase().contains(q) ||
          (p.steamPersona != null &&
              p.steamPersona!.toLowerCase().contains(q)) ||
          (p.steamid != null && p.steamid!.contains(q)) ||
          p.roleName.toLowerCase().contains(q);
    }).toList();

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
          // Header & Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_esports_rounded,
                  size: 18,
                  color: Color(0xff60a5fa),
                ),
                const SizedBox(width: 8),
                Text(
                  'PLAYERS & CHARACTER CONTROL (pzserver.db)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  icon: _isLoadingGamePlayers
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
                  onPressed: _isLoadingGamePlayers ? null : _fetchGamePlayers,
                ),
                if (widget.user.isAdmin) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _addGamePlayerDialog,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                    label: Text(
                      'Add Player',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Color(0xff3f3f46), height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ä°statistik Rozetleri & Alt Sekmeler
                Row(
                  children: [
                    _badgeChip(
                      '${_gamePlayers.length} ${'Registered Players'}',
                      const Color(0xff3b82f6),
                    ),
                    const SizedBox(width: 8),
                    _badgeChip(
                      '${_gamePlayers.where((p) => p.roleId == 7).length} Admin',
                      const Color(0xffef4444),
                    ),
                    const SizedBox(width: 8),
                    _badgeChip(
                      '${_gamePlayers.where((p) => p.roleId == 1).length} ${'Banned'}',
                      const Color(0xffeab308),
                    ),
                    const Spacer(),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff18181b),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xff3f3f46)),
                      ),
                      child: Row(
                        children: [
                          _subTabButton(
                            title: 'Players List',
                            isSelected: _gamePlayerSubTab == 0,
                            onTap: () => setState(() => _gamePlayerSubTab = 0),
                          ),
                          _subTabButton(
                            title:
                                '${'Security Logs'} (${_gameUserLogs.length})',
                            isSelected: _gamePlayerSubTab == 1,
                            onTap: () => setState(() => _gamePlayerSubTab = 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_gamePlayerSubTab == 0) ...[
                  // Arama
                  TextField(
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
                      hintText:
                          'Search by player username, Steam ID, or role...',
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
                    onChanged: (val) =>
                        setState(() => _gamePlayerSearchQuery = val),
                  ),
                  const SizedBox(height: 14),

                  if (_gamePlayersError.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
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
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _gamePlayersError,
                              style: const TextStyle(
                                color: Color(0xfffca5a5),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _fetchGamePlayers,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: Color(0xfff87171),
                            ),
                            label: const Text(
                              'Retry',
                              style: TextStyle(color: Color(0xfff87171)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (filteredPlayers.isEmpty && _gamePlayersError.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text('No players found.'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredPlayers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final p = filteredPlayers[i];
                        Color roleColor = const Color(0xffa1a1aa);
                        if (p.roleId == 7) {
                          roleColor = const Color(0xffef4444); // admin
                        } else if (p.roleId == 6) {
                          roleColor = const Color(0xff22c55e); // moderator
                        } else if (p.roleId == 5 || p.roleId == 4) {
                          roleColor = const Color(0xff38bdf8); // gm / observer
                        } else if (p.roleId == 3) {
                          roleColor = const Color(0xfffacc15); // priority
                        } else if (p.roleId == 1) {
                          roleColor = const Color(0xff71717a); // banned
                        }

                        final hasSteamAvatar =
                            p.steamAvatar != null && p.steamAvatar!.isNotEmpty;
                        final hasPixelAvatar =
                            p.pixelAvatar != null && p.pixelAvatar!.isNotEmpty;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            hoverColor: const Color(0xff27272a).withAlpha(120),
                            onTap: widget.user.isAdmin
                                ? () => _openPlayerEditor(p)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff18181b),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: p.roleId == 7
                                      ? const Color(0xffef4444).withAlpha(80)
                                      : const Color(0xff3f3f46),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Ã‡ift KatmanlÄ± Avatar (Steam Profil Resmi + Oyun Ä°Ã§i Survivor Tipi)
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          color: const Color(0xff27272a),
                                          child: hasSteamAvatar
                                              ? Image.network(
                                                  p.steamAvatar!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      hasPixelAvatar
                                                      ? Image.network(
                                                          p.pixelAvatar!,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : const Icon(
                                                          Icons.person_rounded,
                                                          size: 22,
                                                          color: Color(
                                                            0xffa1a1aa,
                                                          ),
                                                        ),
                                                )
                                              : (hasPixelAvatar
                                                    ? Image.network(
                                                        p.pixelAvatar!,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : const Icon(
                                                        Icons.person_rounded,
                                                        size: 22,
                                                        color: Color(
                                                          0xffa1a1aa,
                                                        ),
                                                      )),
                                        ),
                                      ),
                                      // CanlÄ± / Ã–lÃ¼ / Survivor Rozeti
                                      Positioned(
                                        bottom: -2,
                                        right: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xff18181b),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xff27272a),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: p.isDead
                                                  ? const Color(0xffef4444)
                                                  : const Color(0xff22c55e),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),

                                  // Oyun Ä°Ã§i Karakter ve KullanÄ±cÄ± DetaylarÄ±
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              p.charName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xfff4f4f5),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '@${p.username}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xff93c5fd),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            if (p.steamPersona != null &&
                                                p.steamPersona!.isNotEmpty &&
                                                p.steamPersona !=
                                                    p.username) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '(${p.steamPersona})',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xffa1a1aa),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: roleColor.withAlpha(25),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: roleColor.withAlpha(
                                                    80,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                p.roleName.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: roleColor,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (p.posX != null &&
                                                p.posY != null) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xff27272a,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'ðŸ“ X: ${p.posX!.toStringAsFixed(0)}, Y: ${p.posY!.toStringAsFixed(0)} ${p.posZ != null && p.posZ! > 0 ? '(Z: ${p.posZ})' : ''}',
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    color: Color(0xff86efac),
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                            ],
                                            if (p.steamid != null &&
                                                p.steamid!.isNotEmpty) ...[
                                              Text(
                                                'Steam: ${p.steamid}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xff71717a),
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () {
                                                  Process.run('cmd', [
                                                    '/c',
                                                    'start',
                                                    'https://steamcommunity.com/profiles/${p.steamid}',
                                                  ]);
                                                },
                                                child: const Icon(
                                                  Icons.open_in_new_rounded,
                                                  size: 12,
                                                  color: Color(0xff60a5fa),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                            ],
                                            Text(
                                              '${'Last: '}${p.lastConnection ?? 'Unknown'}',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: Color(0xff71717a),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // DÃ¼zenle & Ä°ÅŸlem ButonlarÄ±
                                  if (widget.user.isAdmin) ...[
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xff2563eb,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => _openPlayerEditor(p),
                                      icon: const Icon(
                                        Icons.tune_rounded,
                                        size: 15,
                                      ),
                                      label: Text(
                                        'Edit & Studio',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Ban/Unban Butonu
                                    IconButton(
                                      tooltip: p.roleId == 1
                                          ? 'Unban'
                                          : 'Ban Player',
                                      icon: Icon(
                                        p.roleId == 1
                                            ? Icons.lock_open_rounded
                                            : Icons.block_rounded,
                                        size: 16,
                                        color: p.roleId == 1
                                            ? const Color(0xff4ade80)
                                            : const Color(0xfff87171),
                                      ),
                                      onPressed: () => _togglePlayerBan(p),
                                    ),

                                    // Sil Butonu
                                    IconButton(
                                      tooltip: 'Remove from Whitelist',
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: Color(0xff71717a),
                                      ),
                                      onPressed: () =>
                                          _deleteGamePlayer(p.username),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ] else ...[
                  // ANTI-CHEAT VE GÃœVENLÄ°K LOGLARI
                  if (_gameUserLogs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text('No security logs found.'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _gameUserLogs.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: Color(0xff333338), height: 1),
                      itemBuilder: (ctx, i) {
                        final log = _gameUserLogs[i];
                        Color tagColor = const Color(0xffeab308);
                        if (log.type.toLowerCase().contains('kick')) {
                          tagColor = const Color(0xffef4444);
                        } else if (log.type.toLowerCase().contains(
                          'suspicious',
                        )) {
                          tagColor = const Color(0xfff97316);
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: tagColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: tagColor.withAlpha(80),
                                  ),
                                ),
                                child: Text(
                                  log.type,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: tagColor,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          log.username,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xfff4f4f5),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'â€¢ ${log.issuedBy} (${log.amount}x)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xffa1a1aa),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      log.text,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xffd4d4d8),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                log.lastUpdate,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xff71717a),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // DEDICATED FULL-PAGE PLAYER & CHARACTER STUDIO (TAB 11 SUB-PAGE)
  // =============================================================
  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color.withAlpha(180),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStudioView() {
    final p = _editingPlayer!;
    final hasSteamAvatar = p.steamAvatar != null && p.steamAvatar!.isNotEmpty;
    final hasPixelAvatar = p.pixelAvatar != null && p.pixelAvatar!.isNotEmpty;

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
          // 1. Ãœst Navigasyon & Aksiyon Ã‡ubuÄŸu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xfff4f4f5),
                    side: const BorderSide(color: Color(0xff52525b)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () => setState(() => _editingPlayer = null),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(
                    'Back to Players',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.manage_accounts_rounded,
                  size: 18,
                  color: Color(0xff60a5fa),
                ),
                const SizedBox(width: 8),
                Text(
                  '${'CHARACTER STUDIO: '}${p.charName}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xfff4f4f5),
                  ),
                ),
                const Spacer(),
                if (widget.user.isAdmin) ...[
                  // HÄ±zlÄ± CanlandÄ±r & Ä°yileÅŸtir Butonu
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff4ade80),
                      side: const BorderSide(color: Color(0xff16a34a)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _pIsDead = false;
                        _pHealth = 100.0;
                        _pIsInfected = false;
                        _pHunger = 0.0;
                        _pThirst = 0.0;
                        _pFatigue = 0.0;
                      });
                      _quickSendRcon(
                        'heal "${p.username}"',
                        '${p.username} resurrected and healed.',
                      );
                    },
                    icon: const Icon(
                      Icons.favorite_rounded,
                      size: 15,
                      color: Color(0xff4ade80),
                    ),
                    label: Text(
                      'Full Heal',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Kaydet Butonu
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _isSavingPlayerStudio ? null : _savePlayerStudio,
                    icon: _isSavingPlayerStudio
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
                      'Save Changes',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Color(0xff3f3f46), height: 1),

          // 2. Hero Oyuncu BaÅŸlÄ±k KartÄ±
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xff18181b),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xff27272a),
                        child: hasSteamAvatar
                            ? Image.network(
                                p.steamAvatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => hasPixelAvatar
                                    ? Image.network(
                                        p.pixelAvatar!,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        size: 30,
                                        color: Color(0xffa1a1aa),
                                      ),
                              )
                            : (hasPixelAvatar
                                  ? Image.network(
                                      p.pixelAvatar!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      size: 30,
                                      color: Color(0xffa1a1aa),
                                    )),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xff18181b),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xff27272a),
                            width: 2,
                          ),
                        ),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _pIsDead
                                ? const Color(0xffef4444)
                                : const Color(0xff22c55e),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            p.charName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xfff4f4f5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '@${p.username}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xff93c5fd),
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (p.steamPersona != null &&
                              p.steamPersona!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              'â€¢ Steam: ${p.steamPersona}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xffa1a1aa),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _badgeChip(
                            _pIsDead ? 'DEAD ðŸ’€' : 'ALIVE ðŸŸ¢',
                            _pIsDead
                                ? const Color(0xffef4444)
                                : const Color(0xff22c55e),
                          ),
                          const SizedBox(width: 8),
                          if (p.posX != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff27272a),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ðŸ“ X: ${_pPosXCtrl.text}, Y: ${_pPosYCtrl.text} (Kat ${_pPosZCtrl.text})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xff86efac),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (p.steamid != null && p.steamid!.isNotEmpty) ...[
                            InkWell(
                              onTap: () => Process.run('cmd', [
                                '/c',
                                'start',
                                'https://steamcommunity.com/profiles/${p.steamid}',
                              ]),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xff27272a),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Steam: ${p.steamid}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xff93c5fd),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 11,
                                      color: Color(0xff60a5fa),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          _statChip(
                            'Zombie Kills',
                            '${p.zombieKills}',
                            const Color(0xfff87171),
                          ),
                          const SizedBox(width: 6),
                          _statChip(
                            'Hours Survived',
                            p.hoursSurvived.toStringAsFixed(1),
                            const Color(0xff93c5fd),
                          ),
                          const SizedBox(width: 6),
                          _statChip(
                            'Weight',
                            '${p.weight.toStringAsFixed(1)} kg',
                            const Color(0xfffacc15),
                          ),
                          if (!p.blobParsed) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message:
                                  'Save dosyası parse edilemedi; bazı alanlar eksik/varsayılan gösteriliyor.',
                              child: _statChip(
                                'DATA WARN',
                                'partial',
                                const Color(0xfffb923c),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xff3f3f46), height: 1),

          // 3. StÃ¼dyo Alt Sekme ButonlarÄ± (8 Kategori)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xff18181b),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _subTabButton(
                    title: 'ðŸ‘¤ General & Role',
                    isSelected: _playerEditorSubTab == 0,
                    onTap: () => setState(() => _playerEditorSubTab = 0),
                  ),
                  _subTabButton(
                    title: 'ðŸ“ˆ Skills & Levels',
                    isSelected: _playerEditorSubTab == 1,
                    onTap: () => setState(() => _playerEditorSubTab = 1),
                  ),
                  _subTabButton(
                    title: 'ðŸŽ–ï¸ Profession & Traits',
                    isSelected: _playerEditorSubTab == 2,
                    onTap: () => setState(() => _playerEditorSubTab = 2),
                  ),
                  _subTabButton(
                    title: 'ðŸ©¸ Health & Body',
                    isSelected: _playerEditorSubTab == 3,
                    onTap: () => setState(() => _playerEditorSubTab = 3),
                  ),
                  _subTabButton(
                    title:
                        '${'ðŸŽ’ Inventory'} (${_editingPlayer?.inventory.length ?? 0})',
                    isSelected: _playerEditorSubTab == 4,
                    onTap: () => setState(() => _playerEditorSubTab = 4),
                  ),
                  _subTabButton(
                    title: 'ðŸ“¦ Item Spawner',
                    isSelected: _playerEditorSubTab == 5,
                    onTap: () => setState(() => _playerEditorSubTab = 5),
                  ),
                  _subTabButton(
                    title: 'ðŸ“ Map & Teleport',
                    isSelected: _playerEditorSubTab == 6,
                    onTap: () => setState(() => _playerEditorSubTab = 6),
                  ),
                  _subTabButton(
                    title: 'âš¡ Live RCON',
                    isSelected: _playerEditorSubTab == 7,
                    onTap: () => setState(() => _playerEditorSubTab = 7),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Color(0xff3f3f46), height: 1),

          // 4. StÃ¼dyo Ä°Ã§eriÄŸi
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPlayerStudioTabContent(),
          ),
        ],
      ),
    );
  }

  // StÃ¼dyo Alt Sekme Ä°Ã§erikleri
}
