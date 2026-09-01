part of 'main.dart';

extension DashDashboardMixin on _DashState {
  Widget _buildDashboardTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xff27272a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isServerOnline
                  ? const Color(0xff15803d)
                  : const Color(0xff991b1b),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isServerOnline
                      ? const Color(0xff22c55e)
                      : const Color(0xffef4444),
                ),
              ),
              const SizedBox(width: 10),
              if (_isRestarting)
                const Text(
                  'SERVER RESTARTING (waiting for game port)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Color(0xfffde68a),
                  ),
                )
              else
                Text(
                  _isServerOnline
                      ? 'SERVER ACTIVE (pzserver.service â€¢ $_serviceState)'
                      : 'SERVER STOPPED (pzserver.service â€¢ $_serviceState)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: _isServerOnline
                        ? const Color(0xff86efac)
                        : const Color(0xfffca5a5),
                  ),
                ),
              const Spacer(),
              Text(
                'Ping: ${_latencyMs}ms (pz-server)',
                style: const TextStyle(
                  color: Color(0xffa1a1aa),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // SUNUCU KONTROLLERÄ° (SERVER CONTROLS)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xff27272a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xff3f3f46), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff18181b),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  size: 18,
                  color: Color(0xff60a5fa),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SERVER CONTROL CENTER',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xfff4f4f5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'pzserver.service â€¢ Systemd Manager',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xffa1a1aa),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (widget.user.canRestartServer) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff382b09),
                    foregroundColor: const Color(0xfffacc15),
                    elevation: 0,
                    side: const BorderSide(
                      color: Color(0xffca8a04),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: _isActionRunning
                      ? null
                      : () => _confirmAction('Restart', 'restart'),
                  icon: const Icon(
                    Icons.replay_rounded,
                    size: 18,
                    color: Color(0xfffacc15),
                  ),
                  label: Text(
                    'Restart Server',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xfffef08a),
                    ),
                  ),
                ),
                if (widget.user.isAdmin) ...[
                  const SizedBox(width: 12),
                  if (_isServerOnline)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff3f1717),
                        foregroundColor: const Color(0xfffca5a5),
                        elevation: 0,
                        side: const BorderSide(
                          color: Color(0xffdc2626),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: _isActionRunning
                          ? null
                          : () => _confirmAction('Stop', 'stop'),
                      icon: const Icon(
                        Icons.stop_circle_rounded,
                        size: 18,
                        color: Color(0xfff87171),
                      ),
                      label: Text(
                        'Stop Server',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xfffecaca),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff14381e),
                        foregroundColor: const Color(0xff86efac),
                        elevation: 0,
                        side: const BorderSide(
                          color: Color(0xff16a34a),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: _isActionRunning
                          ? null
                          : () => _executeServerCommand('start'),
                      icon: const Icon(
                        Icons.play_circle_filled_rounded,
                        size: 18,
                        color: Color(0xff4ade80),
                      ),
                      label: Text(
                        'Start Server',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xffbbf7d0),
                        ),
                      ),
                    ),
                ],
              ] else if (!widget.user.canRestartServer) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff18181b),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xff3f3f46)),
                  ),
                  child: Text(
                    'Controls restricted to ADMIN only.',
                    style: const TextStyle(
                      color: Color(0xffa1a1aa),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // CanlÄ± Metrik Grafikleri
        Row(
          children: [
            LiveMetricChart(
              title: 'CPU KULLANIMI',
              data: cpu,
              color: const Color(0xff22c55e),
              unit: '%',
              maxValue: 100.0,
            ),
            const SizedBox(width: 14),
            LiveMetricChart(
              title: 'RAM KULLANIMI',
              data: ram,
              color: const Color(0xff3b82f6),
              unit: ' GB',
              maxValue: 16.0,
              totalCapacity: '16.0 GB',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 13, color: Color(0xff71717a)),
            const SizedBox(width: 6),
            Text(
              'Live SSH stream â€¢ 1.5s rate â€¢ Last 40s history (Hover over charts to inspect values)',
              style: const TextStyle(color: Color(0xff71717a), fontSize: 11.5),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Sunucu Sistem Ã–zellikleri Paneli
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xff27272a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xff3f3f46), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.computer_rounded,
                      size: 15,
                      color: Color(0xffa1a1aa),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SYSTEM SPECIFICATIONS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xffd4d4d8),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'pz-server (${'Uptime: '}$_serverUptime)',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xff86efac),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xff3f3f46), height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 650;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _specRow(
                                  'OS',
                                  'Ubuntu 24.04.4 LTS',
                                  'Noble Numbat â€¢ x86_64',
                                ),
                                const SizedBox(height: 10),
                                _specRow(
                                  'CPU',
                                  '8 vCPU @ 3.40 GHz',
                                  'KVM Virtualized',
                                ),
                                const SizedBox(height: 10),
                                _specRow(
                                  'RAM',
                                  '16.0 GB DDR4 ECC',
                                  '+ 4.0 GiB Swap Space',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Container(
                            width: 1,
                            height: 75,
                            color: const Color(0xff3f3f46),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                _specRow(
                                  'STORAGE',
                                  '160 GB NVMe SSD',
                                  'PCIe 4.0 â€¢ Ext4',
                                ),
                                const SizedBox(height: 10),
                                _specRow(
                                  'NETWORK',
                                  '1.0 Gbps â€¢ Europe (Berlin)',
                                  'Ping ~24ms',
                                ),
                                const SizedBox(height: 10),
                                _specRow(
                                  'BUILD',
                                  'Project Zomboid v42.20.4',
                                  'pzserver.service â€¢ 32 Slots',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _specRow(
                            'OS',
                            'Ubuntu 24.04.4 LTS',
                            'Noble Numbat â€¢ x86_64',
                          ),
                          const SizedBox(height: 8),
                          _specRow(
                            'CPU',
                            '8 vCPU @ 3.40 GHz',
                            'KVM Virtualized',
                          ),
                          const SizedBox(height: 8),
                          _specRow(
                            'RAM',
                            '16.0 GB DDR4 ECC',
                            '+ 4.0 GiB Swap Space',
                          ),
                          const SizedBox(height: 8),
                          _specRow(
                            'STORAGE',
                            '160 GB NVMe SSD',
                            'PCIe 4.0 â€¢ Ext4',
                          ),
                          const SizedBox(height: 8),
                          _specRow(
                            'NETWORK',
                            '1.0 Gbps â€¢ Europe (Berlin)',
                            'Ping ~24ms',
                          ),
                          const SizedBox(height: 8),
                          _specRow(
                            'BUILD',
                            'Project Zomboid v42.20.4',
                            'pzserver.service â€¢ 32 Slots',
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 1: SUNUCU INI AYARLARI (PZSERVER.INI GENEL AYARLAR)
  Widget _buildIniSettingsTab() {
    final filteredKeys = _iniKeys
        .where((k) => k.toLowerCase().contains(_iniSearchQuery.toLowerCase()))
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: Color(0xff60a5fa),
                ),
                const SizedBox(width: 8),
                Text(
                  'SERVER SETTINGS (pzserver.ini)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  icon: _isLoadingIni
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
                  onPressed: _isLoadingIni ? null : _fetchIniConfig,
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
                    onPressed: _isSavingIni ? null : _saveIniConfig,
                    icon: _isSavingIni
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
                      'Save INI',
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

          // GENEL INI AYARLARI
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                hintText: 'Filter by key (e.g. PVP, Port, Password)...',
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
              onChanged: (val) => setState(() => _iniSearchQuery = val),
            ),
          ),
          const Divider(color: Color(0xff333338), height: 1),

          if (_isLoadingIni)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xff3b82f6)),
              ),
            )
          else if (filteredKeys.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text('No settings found.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredKeys.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Color(0xff333338), height: 1),
              itemBuilder: (ctx, i) {
                final k = filteredKeys[i];
                final v = _iniSettings[k] ?? '';
                final isBool =
                    v.toLowerCase() == 'true' || v.toLowerCase() == 'false';
                final isNumber = int.tryParse(v) != null && !isBool;
                final comment = _iniComments[k]?.trim() ?? '';

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
                              k,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xfff4f4f5),
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                comment,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xffa1a1aa),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: isBool
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Switch(
                                  value: v.toLowerCase() == 'true',
                                  activeThumbColor: const Color(0xff3b82f6),
                                  onChanged: (newVal) {
                                    setState(() {
                                      _iniSettings[k] = newVal
                                          ? 'true'
                                          : 'false';
                                    });
                                  },
                                ),
                              )
                            : TextFormField(
                                initialValue: v,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xfff4f4f5),
                                ),
                                keyboardType: isNumber
                                    ? TextInputType.number
                                    : TextInputType.text,
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
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Color(0xff3b82f6),
                                    ),
                                  ),
                                ),
                                onChanged: (newVal) {
                                  _iniSettings[k] = newVal;
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

  // TAB 11: ZOMBOID SUNUCU OYUNCULARI (IN-GAME PLAYERS & WHITELIST)
}
