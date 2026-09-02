part of 'main.dart';

extension DashPlayersMixin on _DashState {
  Future<void> _fetchGamePlayers() async {
    setState(() {
      _isLoadingGamePlayers = true;
      _gamePlayersError = '';
    });
    try {
      final jsonMap = await ApiClient.getPlayers();
      if (jsonMap['status'] == 'ok' && mounted) {
        setState(() {
          _gamePlayers.clear();
          if (jsonMap['players'] != null) {
            _gamePlayers.addAll(
              (jsonMap['players'] as List).map(
                (e) => GamePlayer.fromJson(e as Map<String, dynamic>),
              ),
            );
          }
          _gameUserLogs.clear();
          final logs = jsonMap['user_logs'] ?? jsonMap['userlogs'];
          if (logs != null) {
            _gameUserLogs.addAll(
              (logs as List).map(
                (e) => GameUserLog.fromJson(e as Map<String, dynamic>),
              ),
            );
          }
          if (_editingPlayer != null) {
            final updated = _gamePlayers
                .where((p) => p.username == _editingPlayer!.username)
                .firstOrNull;
            if (updated != null) {
              _editingPlayer = updated;
            }
          }
        });
      } else if (mounted) {
        setState(() {
          _gamePlayersError =
              jsonMap['message']?.toString() ??
              'Sunucudan oyuncu verisi alınamadı (HTTP hatası).';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gamePlayersError = 'Bağlantı hatası: API sunucusuna ulaşılamadı ($e)';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingGamePlayers = false);
    }
  }

  // Oyuncu Banla / Ban Kaldir
  Future<void> _togglePlayerBan(GamePlayer p) async {
    if (!widget.user.isAdmin) return;
    final sm = ScaffoldMessenger.of(context);
    final isBanned = p.roleId == 1;

    try {
      if (isBanned) {
        await ApiClient.unbanPlayer(
          username: p.username,
          steamid: p.steamid ?? '',
          byUser: widget.user.username,
        );
      } else {
        await ApiClient.banPlayer(
          username: p.username,
          steamid: p.steamid ?? '',
          reason: 'Admin panel yasagi',
          byUser: widget.user.username,
        );
      }
      _fetchGamePlayers();
      _fetchAuditLogs();
      sm.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff15803d),
          content: Text(isBanned ? 'Player unbanned.' : 'Player banned.'),
        ),
      );
    } catch (e) {
      sm.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff991b1b),
          content: Text('Hata: $e'),
        ),
      );
    }
  }

  // Oyuncu Whitelist'ten Sil
  Future<void> _deleteGamePlayer(String username) async {
    if (!widget.user.isAdmin) return;
    final sm = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff27272a),
        title: Text('Delete Player'),
        content: Text('Remove "$username" from game whitelist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff991b1b),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ApiClient.deleteGamePlayer(
        username: username,
        byUser: widget.user.username,
      );
      _fetchGamePlayers();
      _fetchAuditLogs();
      sm.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff15803d),
          content: Text('Player deleted.'),
        ),
      );
    } catch (e) {
      sm.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff991b1b),
          content: Text('Hata: $e'),
        ),
      );
    }
  }

  // Oyuncu & Karakter Studyosunu Ac (Full-Page Studio)
  void _openPlayerEditor(GamePlayer p) {
    setState(() {
      _editingPlayer = p;
      _playerEditorSubTab = 0;
      _pCharNameCtrl.text = p.charName;
      _pSteamIdCtrl.text = p.steamid ?? '';
      _pPasswordCtrl.clear();
      _pPosXCtrl.text = p.posX != null ? p.posX!.toStringAsFixed(1) : '6000.0';
      _pPosYCtrl.text = p.posY != null ? p.posY!.toStringAsFixed(1) : '5000.0';
      _pPosZCtrl.text = (p.posZ ?? 0).toString();
      _pZombieKillsCtrl.text = p.zombieKills.toString();
      _pHoursSurvivedCtrl.text = p.hoursSurvived.toStringAsFixed(1);
      _pWeightCtrl.text = p.weight.toStringAsFixed(1);
      _pCustomItemCtrl.clear();
      _pItemCountCtrl.text = '1';
      _pServerMsgCtrl.clear();

      _pSelectedRoleId = p.roleId;
      _pIsBanned = p.roleId == 1;
      _pIsDead = p.isDead;
      _pIsInfected = p.isInfected;
      _pHasGodmode = p.roleId == 7;
      _pIsInvisible = false;
      _pHealth = p.health;
      _pHunger = p.hunger;
      _pThirst = p.thirst;
      _pFatigue = p.fatigue;
      _pStress = p.stress;
      _pBoredom = p.boredom;
      _pSelectedProfession = p.profession.isNotEmpty
          ? p.profession
          : 'unemployed';

      _pSelectedPositiveTraits.clear();
      for (final t in p.traits) {
        if (_allPzPositiveTraits.any(
          (x) => x.id.toLowerCase() == t.toLowerCase(),
        )) {
          final matched = _allPzPositiveTraits
              .firstWhere((x) => x.id.toLowerCase() == t.toLowerCase())
              .id;
          _pSelectedPositiveTraits.add(matched);
        }
      }

      _pSelectedNegativeTraits.clear();
      for (final t in p.traits) {
        if (_allPzNegativeTraits.any(
          (x) => x.id.toLowerCase() == t.toLowerCase(),
        )) {
          final matched = _allPzNegativeTraits
              .firstWhere((x) => x.id.toLowerCase() == t.toLowerCase())
              .id;
          _pSelectedNegativeTraits.add(matched);
        }
      }

      _pSkills.clear();
      for (final s in _allPzSkills) {
        final id = s.id;
        if (p.skills.containsKey(id)) {
          _pSkills[id] = p.skills[id]!;
        } else if (id == 'Fitness' || id == 'Strength') {
          _pSkills[id] = 5;
        } else {
          _pSkills[id] = 0;
        }
      }
    });

    if (_catalogItems.isEmpty) {
      _loadCatalogFromBundle();
    }
  }

  // Eşya Kataloğunu Bundle'dan Yükle (20,657 Eşya)
  Future<void> _loadCatalogFromBundle() async {
    if (_catalogItems.isNotEmpty) return;
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = '';
    });
    try {
      await ItemDisplayNames.load();
      final jsonStr = await rootBundle.loadString('assets/items_catalog.json');
      final list = jsonDecode(jsonStr) as List;
      if (mounted) {
        setState(() {
          _catalogItems = list
              .map((e) {
                final m = Map<String, dynamic>.from(e as Map);
                final id = (m['id'] ?? '').toString();
                m['display'] = ItemDisplayNames.displayName(
                  id,
                  (m['name'] ?? '').toString(),
                );
                return m;
              })
              .toList();
          _isLoadingCatalog = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCatalog = false;
          _catalogError = 'Eşya kataloğu yüklenemedi: $e';
        });
      }
    }
  }

  // Gerçek Oyun Trait İkonu (Authentic PZ PNG)
  Widget _buildPzTraitIcon(String traitId, {double size = 22}) {
    final cleanId = traitId
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '');
    final p1 = 'assets/pz_traits/trait_$cleanId.png';
    final p2 = 'assets/pz_traits/$cleanId.png';
    final p3 = 'assets/pz_traits/trait_${traitId.toLowerCase()}.png';

    return Image.asset(
      p1,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Image.asset(
        p2,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Image.asset(
          p3,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.star_rounded,
            size: 20,
            color: Color(0xfffacc15),
          ),
        ),
      ),
    );
  }

  // Gerçek Oyun Eşya İkonu (Authentic PZ Item PNG)
  Widget _buildPzItemIcon(
    String? iconFile,
    String itemId, {
    double size = 26,
    bool isMod = false,
    String? modName,
    String? scriptIcon,
  }) {
    Widget assetFallback() => _defaultItemFallbackIcon(itemId, size: size);
    final raw = itemId.contains('.') ? itemId.split('.').last : itemId;

    if (iconFile != null && iconFile.isNotEmpty) {
      final bundled = Image.asset(
        'assets/pz_items_base/$iconFile',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => assetFallback(),
      );
      if (isMod) {
        return ModIconImage(
          modName: modName ?? '',
          iconFile: iconFile,
          itemId: itemId,
          size: size,
          fallback: bundled,
        );
      }
      return bundled;
    }

    // Bundled asset yoksa: script icon adından (Icon= / IconsForTexture=) VPS'ten çek
    if (scriptIcon != null && scriptIcon.isNotEmpty) {
      return RemoteItemIconImage(
        iconName: scriptIcon,
        itemId: itemId,
        size: size,
        fallback: assetFallback(),
      );
    }

    final bundledRaw = Image.asset(
      'assets/pz_items_base/Item_$raw.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Image.asset(
        'assets/pz_items_base/$raw.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => assetFallback(),
      ),
    );
    if (isMod) {
      return ModIconImage(
        modName: modName ?? '',
        iconFile: iconFile ?? '',
        itemId: itemId,
        size: size,
        fallback: bundledRaw,
      );
    }
    return bundledRaw;
  }

  Widget _defaultItemFallbackIcon(String itemId, {double size = 26}) {
    final l = itemId.toLowerCase();
    IconData icon = Icons.inventory_2_rounded;
    Color color = const Color(0xff93c5fd);
    if (l.contains('axe') ||
        l.contains('gun') ||
        l.contains('shotgun') ||
        l.contains('knife') ||
        l.contains('weapon') ||
        l.contains('katana') ||
        l.contains('sword') ||
        l.contains('spear') ||
        l.contains('bat') ||
        l.contains('ammo')) {
      icon = Icons.hardware_rounded;
      color = const Color(0xfff87171);
    } else if (l.contains('bag') ||
        l.contains('pack') ||
        l.contains('vest') ||
        l.contains('shirt') ||
        l.contains('pant') ||
        l.contains('hat') ||
        l.contains('boot') ||
        l.contains('glove') ||
        l.contains('armor')) {
      icon = Icons.checkroom_rounded;
      color = const Color(0xffc084fc);
    } else if (l.contains('food') ||
        l.contains('water') ||
        l.contains('beef') ||
        l.contains('can') ||
        l.contains('meat') ||
        l.contains('apple') ||
        l.contains('bread') ||
        l.contains('drink') ||
        l.contains('bottle')) {
      icon = Icons.restaurant_rounded;
      color = const Color(0xfffacc15);
    } else if (l.contains('pill') ||
        l.contains('bandage') ||
        l.contains('med') ||
        l.contains('cure') ||
        l.contains('disinfect') ||
        l.contains('syringe') ||
        l.contains('vaccine')) {
      icon = Icons.medical_services_rounded;
      color = const Color(0xff4ade80);
    } else if (l.contains('book') ||
        l.contains('mag') ||
        l.contains('map') ||
        l.contains('comic') ||
        l.contains('guide')) {
      icon = Icons.menu_book_rounded;
      color = const Color(0xff38bdf8);
    } else if (l.contains('car') ||
        l.contains('tire') ||
        l.contains('engine') ||
        l.contains('gas') ||
        l.contains('muffler')) {
      icon = Icons.directions_car_rounded;
      color = const Color(0xfffb923c);
    }
    return Icon(icon, size: size * 0.8, color: color);
  }

  // Oyuncu Stüdyosu Verilerini Kaydet
  Future<void> _savePlayerStudio() async {
    if (_editingPlayer == null || !widget.user.isAdmin) return;
    if (_isSavingPlayerStudio) return;
    setState(() => _isSavingPlayerStudio = true);

    final sm = ScaffoldMessenger.of(context);
    final p = _editingPlayer!;

    final updatePayload = {
      'char_name': _pCharNameCtrl.text.trim(),
      'steamid': _pSteamIdCtrl.text.trim(),
      'role_id': _pIsBanned ? 1 : _pSelectedRoleId,
      'password': _pPasswordCtrl.text.trim(),
      'pos_x': double.tryParse(_pPosXCtrl.text.trim()),
      'pos_y': double.tryParse(_pPosYCtrl.text.trim()),
      'pos_z': int.tryParse(_pPosZCtrl.text.trim()) ?? 0,
      'is_dead': _pIsDead,
      'is_banned': _pIsBanned,
      'ban_reason': _pBanReason,
      'profession': _pSelectedProfession,
      'skills': _pSkills,
      'godmode': _pHasGodmode,
      'invisible': _pIsInvisible,
      'heal': _pHealth >= 99.0 && !_pIsInfected,
    };

    try {
      final jsonMap = await ApiClient.updateGamePlayer(
        username: p.username,
        payload: updatePayload,
        byUser: widget.user.username,
      );
      if (jsonMap['status'] == 'ok') {
        _pPasswordCtrl.clear();
        await _fetchGamePlayers();
        await _fetchAuditLogs();
        sm.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xff15803d),
            content: Text('Player and character data saved and applied live!'),
          ),
        );
      } else {
        sm.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xff991b1b),
            content: Text(jsonMap['message']?.toString() ?? 'Error'),
          ),
        );
      }
    } catch (e) {
      sm.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff991b1b),
          content: Text('Hata: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingPlayerStudio = false);
    }
  }

  // Canli RCON Komutu Calistir
  Future<void> _quickSendRcon(String cmd, String successMsg) async {
    if (!widget.user.isAdmin) return;
    final sm = ScaffoldMessenger.of(context);
    try {
      final jsonMap = await ApiClient.sendRcon(
        cmd,
        byUser: widget.user.username,
      );
      if (jsonMap['status'] == 'ok') {
        sm.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xff15803d),
            content: Text(successMsg),
          ),
        );
      } else {
        sm.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xff991b1b),
            content: Text(jsonMap['message']?.toString() ?? 'Error'),
          ),
        );
      }
    } catch (e) {
      sm.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff991b1b),
          content: Text('Hata: $e'),
        ),
      );
    }
  }

  // Hizli Esya Verme
  Future<void> _quickGiveItem(String itemId, int count) async {
    if (_editingPlayer == null || !widget.user.isAdmin) return;
    final uname = _editingPlayer!.username;
    await _quickSendRcon(
      'additem "$uname" "$itemId" $count',
      '$count adet $itemId verildi.',
    );
  }

  // Yeni Oyuncu / Whitelist Ekleme Penceresi
  Future<void> _addGamePlayerDialog() async {
    final nameCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    int selectedRoleId = 2;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xff27272a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xff3f3f46)),
          ),
          title: Text(
            'Add New Game Player',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLAYER USERNAME',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 13, color: Color(0xfff4f4f5)),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff18181b),
                  hintText: 'e.g. survivor99',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'PASSWORD (Optional)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                style: const TextStyle(fontSize: 13, color: Color(0xfff4f4f5)),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff18181b),
                  hintText: 'Can be empty',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'PLAYER ROLE',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                initialValue: selectedRoleId,
                dropdownColor: const Color(0xff18181b),
                style: const TextStyle(fontSize: 13, color: Color(0xfff4f4f5)),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff18181b),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 2,
                    child: Text('User (Normal Oyuncu)'),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text('Priority (Priority Whitelist)'),
                  ),
                  DropdownMenuItem(
                    value: 4,
                    child: Text('Observer (Spectator / GodMode)'),
                  ),
                  DropdownMenuItem(value: 5, child: Text('GM (Game Master)')),
                  DropdownMenuItem(
                    value: 6,
                    child: Text('Moderator (Moderator)'),
                  ),
                  DropdownMenuItem(
                    value: 7,
                    child: Text('Admin (Tam Yetkili)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedRoleId = val);
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
              onPressed: () async {
                final uname = nameCtrl.text.trim();
                final pwd = pwdCtrl.text.trim();
                if (uname.isEmpty) return;
                Navigator.pop(ctx);

                final sm = ScaffoldMessenger.of(context);
                try {
                  final jsonMap = await ApiClient.addGamePlayer(
                    username: uname,
                    password: pwd,
                    roleId: selectedRoleId,
                    byUser: widget.user.username,
                  );
                  if (jsonMap['status'] == 'ok') {
                    _fetchGamePlayers();
                    _fetchAuditLogs();
                    sm.showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xff15803d),
                        content: Text('Player added.'),
                      ),
                    );
                  } else {
                    sm.showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xff991b1b),
                        content: Text(
                          jsonMap['message']?.toString() ?? 'Error',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  sm.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xff991b1b),
                      content: Text('Hata: $e'),
                    ),
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Canlı Metrikleri Çek
}
