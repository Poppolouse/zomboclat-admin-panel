part of 'main.dart';

class _GodPreset {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String desc;
  final List<String> weatherCmds;
  final int thunderEverySec;
  final int durationSec;

  const _GodPreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.desc,
    required this.weatherCmds,
    this.thunderEverySec = 0,
    this.durationSec = 0,
  });
}

const List<_GodPreset> _godPresets = [
  _GodPreset(
    id: 'clear',
    name: 'Clear Skies',
    icon: Icons.wb_sunny_rounded,
    color: Color(0xfffacc15),
    desc: 'stopweather - Stops the whole weather system, sky clears up',
    weatherCmds: ['stopweather'],
  ),
  _GodPreset(
    id: 'light_rain',
    name: 'Light Rain',
    icon: Icons.grain_rounded,
    color: Color(0xff60a5fa),
    desc: 'startrain 25 - Light drizzle (intensity 25/100)',
    weatherCmds: ['startrain 25'],
  ),
  _GodPreset(
    id: 'heavy_rain',
    name: 'Heavy Rain',
    icon: Icons.water_drop_rounded,
    color: Color(0xff3b82f6),
    desc: 'startrain 75 - Pouring rain (intensity 75/100)',
    weatherCmds: ['startrain 75'],
  ),
  _GodPreset(
    id: 'thunderstorm',
    name: 'Thunderstorm',
    icon: Icons.thunderstorm_rounded,
    color: Color(0xff818cf8),
    desc: 'startstorm 4 + thunder every 90 s (20 real min)',
    weatherCmds: ['startstorm 4'],
    thunderEverySec: 90,
    durationSec: 20 * 60,
  ),
  _GodPreset(
    id: 'tropical',
    name: 'Tropical Storm',
    icon: Icons.cyclone_rounded,
    color: Color(0xff22d3ee),
    desc: 'startstorm 8 + thunder every 35 s (30 real min) - Sids-style tropical storm',
    weatherCmds: ['startstorm 8'],
    thunderEverySec: 35,
    durationSec: 30 * 60,
  ),
  _GodPreset(
    id: 'lightning_rain',
    name: 'Heavy Lightning Rain',
    icon: Icons.bolt_rounded,
    color: Color(0xfffde047),
    desc: 'startrain 90 + thunder every 15 s (15 real min) - Constant lightning downpour',
    weatherCmds: ['startrain 90'],
    thunderEverySec: 15,
    durationSec: 15 * 60,
  ),
  _GodPreset(
    id: 'lightning_only',
    name: 'Lightning Only',
    icon: Icons.flash_on_rounded,
    color: Color(0xfffbbf24),
    desc: 'stoprain + thunder every 45 s (10 real min) - No rain, lightning only',
    weatherCmds: ['stoprain'],
    thunderEverySec: 45,
    durationSec: 10 * 60,
  ),
];

extension DashGodActionsMixin on _DashState {
  Future<void> _fetchGodOnlinePlayers() async {
    if (!widget.user.isAdmin) return;
    setState(() => _isLoadingGodOnline = true);
    try {
      final res = await ApiClient.sendRcon(
        'players',
        byUser: widget.user.username,
      );
      final body = res['response']?.toString() ?? '';
      final names = <String>[];
      for (final rawLine in body.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;
        if (line.toLowerCase().contains('player') ||
            line.startsWith('---') ||
            line.contains('connected') ||
            line.contains('Total')) {
          continue;
        }
        if (RegExp(r'^[A-Za-z0-9_\-\.]{2,32}$').hasMatch(line)) {
          names.add(line);
        }
      }
      if (mounted) {
        setState(() {
          _godOnlinePlayers = names;
          if (_godSelectedTarget.isNotEmpty &&
              _godSelectedTarget != 'random' &&
              !names.contains(_godSelectedTarget)) {
            _godSelectedTarget = 'random';
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingGodOnline = false);
    }
  }

  String? _resolveGodTarget() {
    if (_godSelectedTarget == 'random' || _godSelectedTarget.isEmpty) {
      if (_godOnlinePlayers.isEmpty) return null;
      return _godOnlinePlayers[r.nextInt(_godOnlinePlayers.length)];
    }
    return _godSelectedTarget;
  }

  /// Real seconds for a preset based on the user-set in-game duration.
  /// DayLength=4 on this server => one in-game day = 2 real hours,
  /// so 1 in-game hour = 5 real minutes = 300 real seconds.
  int _godPresetDurationSec(_GodPreset preset) {
    final hours = _godPresetHours[preset.id] ?? _defaultHours(preset);
    return (hours * 300).round();
  }

  double _defaultHours(_GodPreset preset) {
    if (preset.durationSec <= 0) return 0;
    return preset.durationSec / 300.0;
  }

  /// Thunder interval: user-set override, otherwise scales with duration
  /// (roughly every `thunderEverySec` at the default duration).
  int _godPresetThunderEverySec(_GodPreset preset) {
    if (preset.thunderEverySec <= 0) return 0;
    final manual = _godPresetIntervalSec[preset.id];
    if (manual != null) return manual.clamp(5, 1800);
    final def = _defaultHours(preset);
    if (def <= 0) return preset.thunderEverySec;
    final hours = _godPresetHours[preset.id] ?? def;
    final scaled = preset.thunderEverySec * (hours / def);
    return scaled.round().clamp(8, 1800);
  }

  TextEditingController _godIntervalCtrl(String presetId, int fallback) {
    final ctrl = _godPresetIntervalCtrls[presetId];
    if (ctrl != null) return ctrl;
    final c = TextEditingController(text: '$fallback');
    _godPresetIntervalCtrls[presetId] = c;
    return c;
  }

  void _godPresetTick() {
    _godPresetRemaining -= 1;
    if (_godPresetRemaining <= 0) {
      _stopGodPreset(showMsg: true);
      return;
    }
    final preset = _godPresets.firstWhere(
      (p) => p.id == _godPresetActive,
      orElse: () => _godPresets.first,
    );
    final every = _godPresetThunderEverySec(preset);
    if (every > 0 && _godPresetRemaining % every == 0) {
      final target = _resolveGodTarget();
      if (target != null) {
        _quickSendRcon(
          'lightning "$target"',
          'Lightning struck: $target (${preset.name})',
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _startGodPreset(_GodPreset preset) async {
    if (!widget.user.isAdmin) return;
    _godPresetTimer?.cancel();
    _godPresetTimer = null;
    for (final cmd in preset.weatherCmds) {
      await _quickSendRcon(cmd, '${preset.name} started: $cmd');
    }
    final durationSec = _godPresetDurationSec(preset);
    if (preset.thunderEverySec > 0 && durationSec > 0) {
      if (mounted) {
        setState(() {
          _godPresetActive = preset.id;
          _godPresetRemaining = durationSec;
        });
      }
      _godPresetTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _godPresetTick();
      });
      final target = _resolveGodTarget();
      if (target != null) {
        _quickSendRcon(
          'lightning "$target"',
          'Lightning struck: $target (${preset.name})',
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _godPresetActive = preset.id;
          _godPresetRemaining = 0;
        });
      }
    }
  }

  void _stopGodPreset({bool showMsg = false}) {
    _godPresetTimer?.cancel();
    _godPresetTimer = null;
    if (mounted) setState(() => _godPresetActive = '');
    if (showMsg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xff3f3f46),
          content: Text('Preset duration ended, stopped automatically'),
        ),
      );
    }
  }

  Widget _buildGodActionsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGodPresetCard(),
        const SizedBox(height: 16),
        _buildGodManualWeatherCard(),
        const SizedBox(height: 16),
        _buildGodTargetCard(),
        const SizedBox(height: 16),
        _buildGodEventsCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _godTimeTooltip(String message) {
    return Tooltip(
      message: message,
      textAlign: TextAlign.justify,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 8),
      textStyle: const TextStyle(
        fontSize: 10.5,
        color: Color(0xfff4f4f5),
        height: 1.4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff18181b),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xff3f3f46)),
      ),
      child: const Icon(
        Icons.info_outline_rounded,
        size: 13,
        color: Color(0xff71717a),
      ),
    );
  }

  Widget _godSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGodPresetCard() {
    final activePreset = _godPresets
        .where((p) => p.id == _godPresetActive)
        .firstOrNull;
    final mins = _godPresetRemaining ~/ 60;
    final secs = _godPresetRemaining % 60;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff18181b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff3f3f46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _godSectionHeader(
            'WEATHER PRESETS - ONE-CLICK WEATHER SCENARIOS',
            Icons.auto_awesome_rounded,
            const Color(0xffeab308),
          ),
          const SizedBox(height: 4),
          Text(
            'Applies RCON commands as combos. Thunder presets automatically strike lightning on the selected target (or a random online player).',
            style: const TextStyle(fontSize: 11, color: Color(0xff71717a)),
          ),
          const SizedBox(height: 12),
          if (activePreset != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: activePreset.color.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: activePreset.color.withAlpha(120)),
              ),
              child: Row(
                children: [
                  Icon(activePreset.icon, size: 18, color: activePreset.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AKTIF: ${activePreset.name}${_godPresetRemaining > 0 ? "  -  ${mins.toString().padLeft(2, "0")}:${secs.toString().padLeft(2, "0")} kaldı" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: activePreset.color,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff991b1b),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => _stopGodPreset(),
                    icon: const Icon(Icons.stop_rounded, size: 15),
                    label: const Text('Stop Preset'),
                  ),
                ],
              ),
            ),
          ],
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cardW = (constraints.maxWidth - 20) / 3;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _godPresets.map((p) {
                  final isActive = _godPresetActive == p.id;
                  final isExpanded = _godPresetExpandedId == p.id;
                  final hasThunder = p.thunderEverySec > 0;
                  final hours = _godPresetHours[p.id] ?? _defaultHours(p);
                  final everySec = _godPresetThunderEverySec(p);
                  return Container(
                    width: cardW > 240 ? cardW : (constraints.maxWidth - 10) / 2,
                    decoration: BoxDecoration(
                      color: isActive
                          ? p.color.withAlpha(35)
                          : const Color(0xff27272a),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive
                            ? p.color
                            : isExpanded
                            ? const Color(0xff52525b)
                            : const Color(0xff3f3f46),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          setState(() {
                            _godPresetExpandedId = isExpanded ? null : p.id;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(p.icon, size: 18, color: p.color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? p.color
                                            : const Color(0xfff4f4f5),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0,
                                    duration: const Duration(
                                      milliseconds: 150,
                                    ),
                                    child: const Icon(
                                      Icons.expand_more_rounded,
                                      size: 16,
                                      color: Color(0xff71717a),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.desc,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xff71717a),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 150),
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                firstChild: const SizedBox(width: 0, height: 0),
                                secondChild: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (hasThunder) ...[
                                        Row(
                                          children: [
                                            Text(
                                              'Duration (in-game hours)',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xffa1a1aa),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            _godTimeTooltip(
                                              'Duration in in-game hours.\n'
                                              'On this server 1 in-game day = 2 real hours '
                                              '(DayLength=4), so 1 in-game hour = '
                                              '5 real minutes.\n'
                                              'Example: 4 in-game hours = 20 real minutes.',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Slider(
                                                value: hours.clamp(0.5, 24.0),
                                                min: 0.5,
                                                max: 24.0,
                                                divisions: 47,
                                                activeColor: p.color,
                                                label:
                                                    '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)} h in-game',
                                                onChanged:
                                                    _godPresetActive == p.id
                                                    ? null
                                                    : (v) => setState(
                                                        () => _godPresetHours[p
                                                            .id] = v,
                                                      ),
                                              ),
                                            ),
                                            Text(
                                              '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)} h\n≈${((hours * 300) / 60).round()} min real',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xff71717a),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Thunder interval (real seconds)',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xffa1a1aa),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            _godTimeTooltip(
                                              'In REAL time (seconds).\n'
                                              'Lightning strikes at players\' positions '
                                              'every interval (visible bolt + thunder sound).\n'
                                              'Type a value and press Enter, or use the slider.\n'
                                              'Leave untouched to auto-scale with duration.',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Slider(
                                                value:
                                                    (_godPresetIntervalSec[p
                                                        .id] ??
                                                    everySec)
                                                    .toDouble()
                                                    .clamp(5.0, 1800.0),
                                                min: 5,
                                                max: 1800,
                                                divisions: 359,
                                                activeColor: p.color,
                                                label:
                                                    '${(_godPresetIntervalSec[p.id] ?? everySec)} sn',
                                                onChanged:
                                                    _godPresetActive == p.id
                                                    ? null
                                                    : (v) => setState(
                                                        () => _godPresetIntervalSec[p
                                                                .id] =
                                                            v.round(),
                                                      ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 64,
                                              child: TextField(
                                                enabled:
                                                    _godPresetActive != p.id,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                                controller: _godIntervalCtrl(
                                                  p.id,
                                                  everySec,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xfff4f4f5),
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  suffixText: 'sec',
                                                  suffixStyle: const TextStyle(
                                                    fontSize: 9,
                                                    color: Color(0xff71717a),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 6,
                                                      ),
                                                  border:
                                                      const OutlineInputBorder(),
                                                ),
                                                onSubmitted: (v) {
                                                  final n =
                                                      int.tryParse(v.trim()) ??
                                                      everySec;
                                                  setState(
                                                    () => _godPresetIntervalSec[p
                                                        .id] = n.clamp(5, 1800),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '(≈${(everySec / 300.0 * 60).toStringAsFixed(0)} in-game minutes)',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xff71717a),
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          'This preset has no duration, it changes the weather instantly.',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xff71717a),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: p.color.withAlpha(
                                              45,
                                            ),
                                            foregroundColor: p.color,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                          ),
                                          onPressed:
                                              _godPresetActive == p.id
                                              ? null
                                              : () => _startGodPreset(p),
                                          icon: const Icon(
                                            Icons.play_arrow_rounded,
                                            size: 15,
                                          ),
                                          label: const Text('Start'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
    );
  }

  Widget _buildGodManualWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff18181b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff3f3f46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _godSectionHeader(
            'MANUAL WEATHER CONTROL',
            Icons.cloud_rounded,
            const Color(0xff60a5fa),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  'Rain Intensity',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xffa1a1aa),
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xff3b82f6),
                    inactiveTrackColor: const Color(0xff3f3f46),
                    thumbColor: const Color(0xff60a5fa),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                  ),
                  child: Slider(
                    value: _godRainIntensity,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: _godRainIntensity.round().toString(),
                    onChanged: (v) => setState(() => _godRainIntensity = v),
                  ),
                ),
              ),
              Container(
                width: 52,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff3b82f6).withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_godRainIntensity.round()}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff93c5fd),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563eb),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _quickSendRcon(
                  'startrain ${_godRainIntensity.round()}',
                  'Rain started (intensity ${_godRainIntensity.round()})',
                ),
                icon: const Icon(Icons.water_drop_rounded, size: 15),
                label: const Text('Start Rain'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  'Storm Duration',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xffa1a1aa),
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xff818cf8),
                    inactiveTrackColor: const Color(0xff3f3f46),
                    thumbColor: const Color(0xff818cf8),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                  ),
                  child: Slider(
                    value: _godStormHours,
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: '${_godStormHours.round()}h',
                    onChanged: (v) => setState(() => _godStormHours = v),
                  ),
                ),
              ),
              Container(
                width: 52,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff818cf8).withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_godStormHours.round()}h',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xffa5b4fc),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4f46e5),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _quickSendRcon(
                  'startstorm ${_godStormHours.round()}',
                  'Storm started (${_godStormHours.round()} in-game hours)',
                ),
                icon: const Icon(Icons.thunderstorm_rounded, size: 15),
                label: const Text('Start Storm'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xffa1a1aa),
                  side: const BorderSide(color: Color(0xff52525b)),
                ),
                onPressed: () => _quickSendRcon(
                  'stoprain',
                  'Yagmur durduruldu',
                ),
                icon: const Icon(Icons.water_drop_outlined, size: 15),
                label: const Text('Stop Rain'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xffa1a1aa),
                  side: const BorderSide(color: Color(0xff52525b)),
                ),
                onPressed: () => _quickSendRcon(
                  'stopweather',
                  'Weather system stopped',
                ),
                icon: const Icon(Icons.wb_sunny_outlined, size: 15),
                label: const Text('Stop Weather'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGodTargetCard() {
    return Container(
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
              _godSectionHeader(
                'THUNDER TARGET',
                Icons.person_pin_circle_rounded,
                const Color(0xfffbbf24),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh online players (RCON players)',
                icon: _isLoadingGodOnline
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: Color(0xffa1a1aa),
                      ),
                onPressed: _isLoadingGodOnline ? null : _fetchGodOnlinePlayers,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _godSelectedTarget.isEmpty
                      ? 'random'
                      : _godSelectedTarget,
                  dropdownColor: const Color(0xff18181b),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xfff4f4f5),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xff27272a),
                    labelText:
                        'Hedef (${_godOnlinePlayers.length} online oyuncu)',
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff71717a),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'random',
                      child: Text('Random (online player)'),
                    ),
                    ..._godOnlinePlayers.map(
                      (u) => DropdownMenuItem(value: u, child: Text(u)),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _godSelectedTarget = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xfffbbf24),
                  foregroundColor: const Color(0xff18181b),
                ),
                onPressed: () {
                  final target = _resolveGodTarget();
                  if (target == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xff991b1b),
                        content: Text(
                          'No online players, no target found for thunder',
                        ),
                      ),
                    );
                    return;
                  }
                  _quickSendRcon(
                    'thunder "$target"',
                    'Lightning struck: $target',
                  );
                },
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: const Text('Thunder'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffeab308),
                  foregroundColor: const Color(0xff18181b),
                ),
                onPressed: () {
                  final target = _resolveGodTarget();
                  if (target == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xff991b1b),
                        content: Text(
                          'No online players, no target found for lightning',
                        ),
                      ),
                    );
                    return;
                  }
                  _quickSendRcon(
                    'lightning "$target"',
                    'Lightning struck: $target',
                  );
                },
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: const Text('Lightning'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGodEventsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff18181b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff3f3f46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _godSectionHeader(
            'WORLD EVENTS - ANLIK OLAYLAR',
            Icons.local_fire_department_rounded,
            const Color(0xfff87171),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff7c3aed),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _quickSendRcon(
                  'chopper',
                  'Helikopter eventi rastgele oyuncuya gonderildi',
                ),
                icon: const Icon(Icons.flight_rounded, size: 16),
                label: const Text('Helicopter Event'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffb45309),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _quickSendRcon(
                  'gunshot',
                  'Silah sesi rastgele oyuncuya gonderildi',
                ),
                icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                label: const Text('Gunshot'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffbe123c),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _quickSendRcon(
                  'alarm',
                  'Alarm caldirildi (admin binasi)',
                ),
                icon: const Icon(Icons.notifications_active_rounded, size: 16),
                label: const Text('Alarm'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1d4ed8),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _quickSendRcon(
                  'removezombies',
                  'Zombiler temizlendi',
                ),
                icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                label: const Text('Remove Zombies'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _godSectionHeader(
            'HORDE SPAWN',
            Icons.groups_rounded,
            const Color(0xfff87171),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _godHordeCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xfff4f4f5),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xff27272a),
                    labelText: 'Zombie count',
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff71717a),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Target: ${_godSelectedTarget == 'random' || _godSelectedTarget.isEmpty ? 'Random' : _godSelectedTarget}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff991b1b),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final count = int.tryParse(_godHordeCtrl.text.trim()) ?? 0;
                  if (count <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xff991b1b),
                        content: Text('Enter a valid zombie count'),
                      ),
                    );
                    return;
                  }
                  final target = _resolveGodTarget();
                  if (target == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xff991b1b),
                        content: Text('No online players, could not spawn horde'),
                      ),
                    );
                    return;
                  }
                  _quickSendRcon(
                    'createhorde $count "$target"',
                    '$count zombie horde spawned: $target',
                  );
                },
                icon: const Icon(Icons.coronavirus_rounded, size: 16),
                label: const Text('Spawn Horde'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}