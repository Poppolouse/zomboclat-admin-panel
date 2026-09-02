part of 'main.dart';

extension DashConsoleMixin on _DashState {
  Widget _buildConsoleAllLogsView() {
    final displayedLines = _serverLogs.where((line) {
      if (_consoleSearchQuery.isEmpty) return true;
      return line.toLowerCase().contains(_consoleSearchQuery.toLowerCase());
    }).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xff18181b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff3f3f46), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConsoleHeader(
            'LIVE SERVER CONSOLE (ALL LOGS)',
            _serverLogs.length,
            const Color(0xff60a5fa),
          ),
          const Divider(color: Color(0xff27272a), height: 1),

          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(fontSize: 12, color: Color(0xfff4f4f5)),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xff27272a),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Color(0xffa1a1aa),
                ),
                hintText: 'Search logs...',
                hintStyle: const TextStyle(
                  color: Color(0xff71717a),
                  fontSize: 11.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
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
              onChanged: (val) => setState(() => _consoleSearchQuery = val),
            ),
          ),
          const Divider(color: Color(0xff27272a), height: 1),

          // Terminal Akışı
          Container(
            height: 520,
            padding: const EdgeInsets.all(12),
            child: displayedLines.isEmpty
                ? Center(
                    child: Text(
                      'Loading logs...',
                      style: const TextStyle(
                        color: Color(0xff71717a),
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _consoleScrollController,
                    itemCount: displayedLines.length,
                    itemBuilder: (ctx, i) {
                      final line = displayedLines[i];
                      Color textColor = const Color(0xffd4d4d8);
                      if (line.contains('ERROR') ||
                          line.contains('Exception') ||
                          line.contains('FATAL') ||
                          line.contains('Caused by')) {
                        textColor = const Color(0xfff87171);
                      } else if (line.contains('WARN')) {
                        textColor = const Color(0xfffde047);
                      } else if (line.contains('LOG  :')) {
                        textColor = const Color(0xff93c5fd);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: SelectableText(
                          line,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: textColor,
                            height: 1.25,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // TAB 9: KONSOL - HATALAR VE UYARILAR
  Widget _buildConsoleErrorsView() {
    final errorLines = _serverLogs.where((line) {
      final l = line.toLowerCase();
      return l.contains('error') ||
          l.contains('exception') ||
          l.contains('warn') ||
          l.contains('fatal') ||
          l.contains('caused by') ||
          l.contains('stack trace') ||
          l.contains('lua error');
    }).toList();

    final displayedLines = errorLines.where((line) {
      if (_consoleSearchQuery.isEmpty) return true;
      return line.toLowerCase().contains(_consoleSearchQuery.toLowerCase());
    }).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xff18181b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff3f3f46), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConsoleHeader(
            'SERVER ERRORS & WARNINGS',
            errorLines.length,
            const Color(0xfffde047),
          ),
          const Divider(color: Color(0xff27272a), height: 1),

          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(fontSize: 12, color: Color(0xfff4f4f5)),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xff27272a),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Color(0xffa1a1aa),
                ),
                hintText: 'Search errors...',
                hintStyle: const TextStyle(
                  color: Color(0xff71717a),
                  fontSize: 11.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
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
              onChanged: (val) => setState(() => _consoleSearchQuery = val),
            ),
          ),
          const Divider(color: Color(0xff27272a), height: 1),

          Container(
            height: 520,
            padding: const EdgeInsets.all(12),
            child: displayedLines.isEmpty
                ? Center(
                    child: Text(
                      'No errors or warnings found.',
                      style: const TextStyle(
                        color: Color(0xff71717a),
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _consoleScrollController,
                    itemCount: displayedLines.length,
                    itemBuilder: (ctx, i) {
                      final line = displayedLines[i];
                      Color textColor = line.contains('WARN')
                          ? const Color(0xfffde047)
                          : const Color(0xfff87171);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SelectableText(
                          line,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: textColor,
                            height: 1.25,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // TAB 10: KONSOL - HATA VEREN MODLAR (MOD DIAGNOSTICS)
  Widget _buildConsoleModErrorsView() {
    final modErrors = _extractModErrors();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xff18181b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff3f3f46), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConsoleHeader(
            'FAILING MODS DIAGNOSTICS',
            modErrors.length,
            const Color(0xfff87171),
          ),
          const Divider(color: Color(0xff27272a), height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (modErrors.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xff14532d).withAlpha(60),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xff22c55e)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xff4ade80),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Great! No mod errors detected in active server logs.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xff86efac),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff451a1a),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xffdc2626)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Color(0xfff87171),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${modErrors.length} ${'mods threw errors or exceptions in the server logs. Inspect details below.'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xfffca5a5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modErrors.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final errGroup = modErrors[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xff27272a),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xffdc2626).withAlpha(120),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    color: const Color(0xff18181b),
                                    child:
                                        errGroup.previewUrl != null &&
                                            errGroup.previewUrl!.isNotEmpty
                                        ? Image.network(
                                            errGroup.previewUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.extension_rounded,
                                                    size: 20,
                                                    color: Color(0xff71717a),
                                                  ),
                                                ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.extension_rounded,
                                              size: 20,
                                              color: Color(0xff71717a),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        errGroup.modName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xfff4f4f5),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            'ID: ${errGroup.modId}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xff93c5fd),
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          if (errGroup.workshopId != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              'WS: ${errGroup.workshopId}',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: Color(0xff71717a),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff451a1a),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xffdc2626),
                                    ),
                                  ),
                                  child: Text(
                                    '${errGroup.errorLines.length} ${'Error Lines'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xfffca5a5),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xff38bdf8),
                                    side: const BorderSide(
                                      color: Color(0xff0284c7),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {
                                    _selectTab(8);
                                    setState(() {
                                      _modOrderSearchQuery = errGroup.modId;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.reorder_rounded,
                                    size: 14,
                                  ),
                                  label: Text(
                                    'View in Order',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xff18181b),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xff3f3f46),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: errGroup.errorLines.take(5).map((l) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 1.5,
                                    ),
                                    child: SelectableText(
                                      l,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: Color(0xfffca5a5),
                                        height: 1.25,
                                      ),
                                    ),
                                  );
                                }).toList(),
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

  Widget _buildConsoleHeader(String title, int count, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Icon(Icons.terminal_rounded, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accentColor.withAlpha(80)),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          const Spacer(),

          // Canlı Akış Göstergesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _isLiveConsoleStreaming
                  ? const Color(0xff14532d)
                  : const Color(0xff27272a),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isLiveConsoleStreaming
                    ? const Color(0xff22c55e)
                    : const Color(0xff3f3f46),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLiveConsoleStreaming
                        ? const Color(0xff4ade80)
                        : const Color(0xff71717a),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _isLiveConsoleStreaming ? 'CANLI (LIVE)' : 'DURDU (PAUSED)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _isLiveConsoleStreaming
                        ? const Color(0xff86efac)
                        : const Color(0xffa1a1aa),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          IconButton(
            tooltip: _isLiveConsoleStreaming
                ? 'Pause Live Stream'
                : 'Resume Live Stream',
            icon: Icon(
              _isLiveConsoleStreaming
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
              size: 18,
              color: _isLiveConsoleStreaming
                  ? const Color(0xfffacc15)
                  : const Color(0xff4ade80),
            ),
            onPressed: () => setState(
              () => _isLiveConsoleStreaming = !_isLiveConsoleStreaming,
            ),
          ),
          IconButton(
            tooltip: _autoScrollConsole
                ? 'Auto-Scroll: ON'
                : 'Auto-Scroll: OFF',
            icon: Icon(
              Icons.vertical_align_bottom_rounded,
              size: 18,
              color: _autoScrollConsole
                  ? const Color(0xff38bdf8)
                  : const Color(0xff71717a),
            ),
            onPressed: () =>
                setState(() => _autoScrollConsole = !_autoScrollConsole),
          ),
          IconButton(
            tooltip: 'Refresh Logs',
            icon: _isLoadingServerLogs
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
            onPressed: () => _fetchServerLogs(),
          ),
        ],
      ),
    );
  }

  Widget _subTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff3b82f6) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xffa1a1aa),
          ),
        ),
      ),
    );
  }

  // TAB 6: AYARLAR
  Widget _buildSettingsTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff27272a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff3f3f46), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_suggest_rounded,
                size: 17,
                color: Color(0xffa1a1aa),
              ),
              const SizedBox(width: 8),
              Text(
                'MANAGEMENT & SYSTEM SETTINGS',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _specRow(
            'DATABASE',
            'SQLite (45.142.115.19)',
            '/var/lib/zomboclat/zomboclat.db',
          ),
          const SizedBox(height: 10),
          _specRow(
            'ACTIVE USER',
            widget.user.username,
            'ROLE: ${widget.user.role}',
          ),
          const SizedBox(height: 10),
          _specRow(
            'SERVICE NAME',
            'pzserver.service',
            'Project Zomboid Server',
          ),
          const SizedBox(height: 10),
          _specRow('SERVER HOST', '45.142.115.19', 'Europe/Berlin'),
          const SizedBox(height: 10),
          _specRow(
            'INI FILE',
            'pzserver.ini',
            '/home/pzserver/Zomboid/Server/pzserver.ini',
          ),
          const SizedBox(height: 10),
          _specRow(
            'SANDBOX FILE',
            'pzserver_SandboxVars.lua',
            '/home/pzserver/Zomboid/Server/pzserver_SandboxVars.lua',
          ),
          const SizedBox(height: 10),
          _specRow(
            'PLAYER DB',
            'pzserver.db',
            '/home/pzserver/Zomboid/db/pzserver.db',
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value, String details) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xff71717a),
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xfff4f4f5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          details,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xffa1a1aa),
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// LIVE METRIC CHART & INTERACTIVE PAINTER (MAT & SADE)
// -------------------------------------------------------------
