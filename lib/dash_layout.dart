part of 'main.dart';

extension DashLayoutMixin on _DashState {
  Widget _buildLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sol MenÃ¼ (Modern Ã–zel Sidebar - TÃ¼m Tab GeÃ§iÅŸleri Buradan)
          _buildCustomSidebar(),

          // Ana Panel
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ãœst BaÅŸlÄ±k & Dil SeÃ§ici
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zomboclat Server Control',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xfff4f4f5),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Project Zomboid v42.20.4 â€¢ SQLite Central Auth',
                              style: const TextStyle(
                                color: Color(0xffa1a1aa),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (_selectedTab == 0) ...[
                    _buildDashboardTab(),
                  ] else if (_selectedTab == 1) ...[
                    _buildIniSettingsTab(),
                  ] else if (_selectedTab == 11) ...[
                    _buildGamePlayersTab(),
                  ] else if (_selectedTab == 2) ...[
                    _buildSandboxTab(),
                  ] else if (_selectedTab == 3) ...[
                    _buildUsersTab(),
                  ] else if (_selectedTab == 4) ...[
                    _buildAuditLogsTab(),
                  ] else if (_selectedTab == 5) ...[
                    _buildConsoleAllLogsView(),
                  ] else if (_selectedTab == 9) ...[
                    _buildConsoleErrorsView(),
                  ] else if (_selectedTab == 10) ...[
                    _buildConsoleModErrorsView(),
                  ] else if (_selectedTab == 6) ...[
                    _buildSettingsTab(),
                  ] else if (_selectedTab == 7) ...[
                    _buildModGalleryTab(),
                  ] else if (_selectedTab == 8) ...[
                    _buildModOrderTab(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xff27272a).withAlpha(150),
          onTap: () => _selectTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xff27272a) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: const Color(0xff3f3f46), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? const Color(0xff3b82f6)
                      : const Color(0xffa1a1aa),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xfff4f4f5)
                          : const Color(0xffa1a1aa),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _expandableGroup({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required bool isSelected,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              hoverColor: const Color(0xff27272a).withAlpha(150),
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xff27272a)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: const Color(0xff3f3f46), width: 1)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? const Color(0xff3b82f6)
                          : const Color(0xffa1a1aa),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xfff4f4f5)
                              : const Color(0xffd4d4d8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 17,
                      color: const Color(0xff71717a),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 2),
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xff333338), width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _subNavItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          hoverColor: const Color(0xff27272a).withAlpha(150),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xff27272a) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(color: const Color(0xff3b82f6), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? (iconColor ?? const Color(0xff60a5fa))
                      : const Color(0xff71717a),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xfff4f4f5)
                          : const Color(0xffa1a1aa),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidebarSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 12, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xff71717a),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _sidebarDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Divider(color: Color(0xff27272a), height: 1),
    );
  }

  // Ã–ZEL SOL SIDEBAR WIDGET'I (BÃ–LÃœMLER, SUNUCU OYUNCULARI, EXPANDABLE KONSOL, HOVER & AUTO-FETCH)
  Widget _buildCustomSidebar() {
    final cats = _sandboxCategories.keys.toList();
    final modErrorsCount = _extractModErrors().length;
    final errorsCount = _serverLogs
        .where(
          (l) =>
              l.toLowerCase().contains('error') ||
              l.toLowerCase().contains('exception') ||
              l.toLowerCase().contains('warn'),
        )
        .length;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xff18181b),
        border: Border(right: BorderSide(color: Color(0xff27272a), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xff27272a),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xff3f3f46)),
                  ),
                  child: const Icon(
                    Icons.dns_rounded,
                    size: 20,
                    color: Color(0xff3b82f6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ZOMBOCLAT',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xfff4f4f5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isServerOnline
                                  ? const Color(0xff22c55e)
                                  : const Color(0xffef4444),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isServerOnline ? 'ONLINE' : 'OFFLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _isServerOnline
                                  ? const Color(0xff86efac)
                                  : const Color(0xfffca5a5),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xff27272a), height: 1),

          // MenÃ¼ Ã–ÄŸeleri (BÃ¶lÃ¼mlere AyrÄ±lmÄ±ÅŸ)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                // BÃ–LÃœM 1: CANLI ADMÄ°N YÃ–NETÄ°MÄ° & LOGLAR
                _sidebarSectionHeader('âš¡ LIVE ADMIN & LOGS'),
                _navItem(
                  index: 0,
                  title: 'Dashboard & Control',
                  icon: Icons.dashboard_rounded,
                ),

                // KONSOL LOGLARI (EXPANDABLE KATEGORÄ°)
                _expandableGroup(
                  title: 'Console & Logs',
                  icon: Icons.terminal_rounded,
                  isExpanded: _isConsoleGroupExpanded,
                  onToggle: () => setState(() {
                    _isConsoleGroupExpanded = !_isConsoleGroupExpanded;
                    if (_isConsoleGroupExpanded &&
                        _selectedTab != 5 &&
                        _selectedTab != 9 &&
                        _selectedTab != 10) {
                      _selectTab(5);
                    }
                  }),
                  isSelected:
                      _selectedTab == 5 ||
                      _selectedTab == 9 ||
                      _selectedTab == 10,
                  children: [
                    _subNavItem(
                      title: 'All Live Logs',
                      icon: Icons.article_outlined,
                      isSelected: _selectedTab == 5,
                      onTap: () => _selectTab(5),
                    ),
                    _subNavItem(
                      title: '${'Errors & Warnings'} ($errorsCount)',
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xfffde047),
                      isSelected: _selectedTab == 9,
                      onTap: () => _selectTab(9),
                    ),
                    _subNavItem(
                      title: '${'Failing Mods'} ($modErrorsCount)',
                      icon: Icons.bug_report_rounded,
                      iconColor: const Color(0xfff87171),
                      isSelected: _selectedTab == 10,
                      onTap: () => _selectTab(10),
                    ),
                  ],
                ),
                _sidebarDivider(),

                // BÃ–LÃœM 2: ZOMBOID SUNUCUSU
                _sidebarSectionHeader('ZOMBOID SERVER'),
                _navItem(
                  index: 1,
                  title: 'Server Settings (INI)',
                  icon: Icons.tune_rounded,
                ),
                _navItem(
                  index: 11,
                  title: '${'Players'} (${_gamePlayers.length})',
                  icon: Icons.sports_esports_rounded,
                ),

                // DÄ°NAMÄ°K SANDBOXVARS KATEGORÄ°LERÄ°
                _expandableGroup(
                  title: 'SandboxVars',
                  icon: Icons.view_in_ar_rounded,
                  isExpanded: _isSandboxGroupExpanded,
                  onToggle: () => setState(() {
                    _isSandboxGroupExpanded = !_isSandboxGroupExpanded;
                    if (_isSandboxGroupExpanded && _selectedTab != 2) {
                      _selectTab(2);
                    }
                  }),
                  isSelected: _selectedTab == 2,
                  children: cats.map((catName) {
                    final meta = _getSandboxCategoryMeta(catName);
                    final displayName = meta['displayName'] as String;
                    final isMod = meta['isMod'] as bool;
                    final itemCount = _sandboxCategories[catName]?.length ?? 0;

                    return _subNavItem(
                      title: '$displayName ($itemCount)',
                      icon: isMod
                          ? Icons.extension_rounded
                          : Icons.folder_open_rounded,
                      iconColor: isMod
                          ? const Color(0xffc084fc)
                          : const Color(0xff60a5fa),
                      isSelected:
                          _selectedTab == 2 &&
                          _selectedSandboxCategory == catName,
                      onTap: () => _selectTab(2, category: catName),
                    );
                  }).toList(),
                ),
                _sidebarDivider(),

                // BÃ–LÃœM 3: MOD YÃ–NETÄ°MÄ°
                _sidebarSectionHeader('ðŸ“¦ MOD MANAGEMENT'),
                _expandableGroup(
                  title: 'Mods & Load Order',
                  icon: Icons.extension_rounded,
                  isExpanded: _isModsGroupExpanded,
                  onToggle: () => setState(() {
                    _isModsGroupExpanded = !_isModsGroupExpanded;
                    if (_isModsGroupExpanded &&
                        _selectedTab != 7 &&
                        _selectedTab != 8) {
                      _selectTab(7);
                    }
                  }),
                  isSelected: _selectedTab == 7 || _selectedTab == 8,
                  children: [
                    _subNavItem(
                      title: 'Mod & Workshop Gallery',
                      icon: Icons.grid_view_rounded,
                      isSelected: _selectedTab == 7,
                      onTap: () => _selectTab(7),
                    ),
                    _subNavItem(
                      title: 'Mod Load Order',
                      icon: Icons.reorder_rounded,
                      isSelected: _selectedTab == 8,
                      onTap: () => _selectTab(8),
                    ),
                  ],
                ),
                _sidebarDivider(),

                // BÃ–LÃœM 4: VPS & PANEL YÃ–NETÄ°MÄ°
                _sidebarSectionHeader('ðŸ›¡ï¸ VPS & PANEL AUTH'),
                _navItem(
                  index: 3,
                  title: 'Panel Users (SQLite)',
                  icon: Icons.people_alt_rounded,
                ),
                _navItem(
                  index: 4,
                  title: 'Audit Logs',
                  icon: Icons.receipt_long_rounded,
                ),
                _navItem(
                  index: 6,
                  title: 'System & Settings',
                  icon: Icons.settings_suggest_rounded,
                ),
              ],
            ),
          ),

          // Alt Profil ve Oturum Bilgisi
          const Divider(color: Color(0xff27272a), height: 1),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xff141416),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.user.isAdmin
                            ? const Color(0xff1e3a8a)
                            : const Color(0xff27272a),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.user.isAdmin
                              ? const Color(0xff3b82f6)
                              : const Color(0xff3f3f46),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          widget.user.isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : Icons.person_rounded,
                          size: 17,
                          color: widget.user.isAdmin
                              ? const Color(0xff93c5fd)
                              : const Color(0xffd4d4d8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.username,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xfff4f4f5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.user.role,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.user.isAdmin
                                  ? const Color(0xff60a5fa)
                                  : const Color(0xffa1a1aa),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sign Out',
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 17,
                        color: Color(0xffa1a1aa),
                      ),
                      onPressed: widget.onLogout,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff1c1c1f),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xff27272a)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.speed_rounded,
                        size: 12,
                        color: Color(0xff71717a),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'pz-vps â€¢ ${_latencyMs}ms',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xffa1a1aa),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 0: PANEL (DASHBOARD)
}
