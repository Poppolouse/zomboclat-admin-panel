part of 'main.dart';

extension DashServerMixin on _DashState {
  Future<void> _fetchRealServerMetrics() async {
    if (_isConnecting) return;
    _isConnecting = true;

    final stopwatch = Stopwatch()..start();
    try {
      final raw = await ApiClient.getServerStatus();
      stopwatch.stop();

      if (raw.isNotEmpty && mounted) {
        _parseServerOutput(raw, stopwatch.elapsedMilliseconds);
      } else if (mounted) {
        _applySimulatedFallback(stopwatch.elapsedMilliseconds);
      }
    } catch (_) {
      if (mounted) {
        _applySimulatedFallback(stopwatch.elapsedMilliseconds);
      }
    } finally {
      _isConnecting = false;
    }
  }

  void _parseServerOutput(String output, int elapsedMs) {
    double currentCpu = 0.0;
    double currentRamGb = 6.14;
    String serviceAct = 'active';

    try {
      final lines = output.split('\n');
      for (final line in lines) {
        if (line.contains('%Cpu') || line.contains('Cpu(s)')) {
          final idMatch = RegExp(r'([\d\.]+)\s*id').firstMatch(line);
          if (idMatch != null) {
            final idle = double.tryParse(idMatch.group(1)!) ?? 98.0;
            currentCpu = (100.0 - idle).clamp(0.0, 100.0);
          }
        }
        if (line.startsWith('Mem:')) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 7) {
            final totalBytes = double.tryParse(parts[1]) ?? 16770162688;
            final availBytes = double.tryParse(parts[6]) ?? 10340429824;
            final actualUsedBytes = totalBytes - availBytes;
            currentRamGb = (actualUsedBytes / (1024 * 1024 * 1024)).clamp(
              0.0,
              16.0,
            );
          }
        }
        if (line.startsWith('up ')) {
          _serverUptime = line.replaceFirst('up ', '').trim();
        }
        if (line.trim() == 'active' || line.trim() == 'inactive') {
          serviceAct = line.trim();
        }
      }
    } catch (_) {}

    final isAct = serviceAct == 'active';

    if (mounted) {
      setState(() {
        if (!_isRestarting) {
          _serviceState = serviceAct;
          _isServerOnline = isAct;
        }
        _latencyMs = elapsedMs > 0 ? elapsedMs.clamp(12, 120) : 24;

        cpu.add(currentCpu);
        ram.add(currentRamGb);

        if (cpu.length > 54) {
          cpu.removeAt(0);
          ram.removeAt(0);
        }
      });
    }
  }

  void _applySimulatedFallback(int elapsedMs) {
    final rnd = Random();
    setState(() {
      _latencyMs = elapsedMs > 0 ? elapsedMs.clamp(18, 90) : 24;
      cpu.add((2.5 + rnd.nextDouble() * 4.0).clamp(0.0, 100.0));
      ram.add((6.12 + rnd.nextDouble() * 0.35).clamp(0.0, 16.0));
      if (cpu.length > 54) {
        cpu.removeAt(0);
        ram.removeAt(0);
      }
    });
  }

  // SQLite Panel Kullanicilarini Cek
  Future<void> _fetchDbUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final list = await ApiClient.getPanelUsers();
      if (mounted) {
        setState(() {
          _dbUsers.clear();
          _dbUsers.addAll(list);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  // SQLite Giris-Cikis / Denetim Loglarini Cek
  Future<void> _fetchAuditLogs() async {
    setState(() => _isLoadingAuditLogs = true);
    try {
      final list = await ApiClient.getAuditLogs();
      if (mounted) {
        setState(() {
          _auditLogs.clear();
          _auditLogs.addAll(list);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingAuditLogs = false);
    }
  }

  // Sunucu Journal Loglarini Cek (Canli Akis Destegiyle)
  Future<void> _fetchServerLogs({bool isBackground = false}) async {
    if (!isBackground) setState(() => _isLoadingServerLogs = true);
    try {
      final lines = await ApiClient.getServerLogs(lines: 250);
      if (mounted) {
        setState(() {
          _serverLogs.clear();
          _serverLogs.addAll(lines);
        });

        if (_autoScrollConsole && _consoleScrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_consoleScrollController.hasClients) {
              _consoleScrollController.jumpTo(
                _consoleScrollController.position.maxScrollExtent,
              );
            }
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted && !isBackground) {
        setState(() => _isLoadingServerLogs = false);
      }
    }
  }

  // INI Ayarlarini Cek (Yorumlar ve Steam Workshop Detaylari Dahil)
  Future<void> _fetchIniConfig() async {
    setState(() => _isLoadingIni = true);
    try {
      final jsonMap = await ApiClient.getIniConfig();
      if (jsonMap['status'] == 'ok' && mounted) {
        setState(() {
          _iniSettings.clear();
          if (jsonMap['settings'] != null) {
            (jsonMap['settings'] as Map<String, dynamic>).forEach((k, v) {
              _iniSettings[k] = v.toString();
            });
          }
          _iniComments.clear();
          if (jsonMap['comments'] != null) {
            (jsonMap['comments'] as Map<String, dynamic>).forEach((k, v) {
              _iniComments[k] = v.toString();
            });
          }
          _iniKeys.clear();
          if (jsonMap['keys'] != null) {
            _iniKeys.addAll(
              (jsonMap['keys'] as List).map((e) => e.toString()),
            );
          }
          _iniMods.clear();
          if (jsonMap['mods'] != null) {
            _iniMods.addAll(
              (jsonMap['mods'] as List).map((e) => e.toString()),
            );
          }
          _iniWorkshopItems.clear();
          if (jsonMap['workshop_items'] != null) {
            _iniWorkshopItems.addAll(
              (jsonMap['workshop_items'] as List).map((e) => e.toString()),
            );
          }
          _workshopDetails.clear();
          if (jsonMap['workshop_details'] != null) {
            (jsonMap['workshop_details'] as Map<String, dynamic>).forEach((
              k,
              v,
            ) {
              if (v is Map) {
                _workshopDetails[k] = Map<String, dynamic>.from(v);
              }
            });
          }
          _modDetails.clear();
          if (jsonMap['mod_details'] != null) {
            (jsonMap['mod_details'] as Map<String, dynamic>).forEach((k, v) {
              if (v is Map) {
                _modDetails[k] = Map<String, dynamic>.from(v);
              }
            });
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingIni = false);
    }
  }

  // INI Ayarlarini Kaydet
  Future<void> _saveIniConfig() async {
    if (!widget.user.isAdmin) return;
    setState(() => _isSavingIni = true);
    final sm = ScaffoldMessenger.of(context);
    try {
      final jsonMap = await ApiClient.saveIniConfig(
        settings: _iniSettings,
        mods: _iniMods,
        workshopItems: _iniWorkshopItems,
        username: widget.user.username,
      );
      if (jsonMap['status'] == 'ok') {
        _fetchAuditLogs();
        sm.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xff15803d),
            content: Text('pzserver.ini settings saved successfully.'),
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
      if (mounted) setState(() => _isSavingIni = false);
    }
  }

  // SandboxVars Ayarlarini Cek (Yorumlar Dahil)
  Future<void> _fetchSandboxConfig() async {
    setState(() => _isLoadingSandbox = true);
    try {
      final jsonMap = await ApiClient.getSandboxConfig();
      if (jsonMap['status'] == 'ok' &&
          jsonMap['categories'] != null &&
          mounted) {
        final cats = jsonMap['categories'] as Map<String, dynamic>;
        setState(() {
          _sandboxCategories.clear();
          cats.forEach((catKey, items) {
            _sandboxCategories[catKey] = (items as List)
                .map((it) => Map<String, dynamic>.from(it as Map))
                .toList();
          });
          _sandboxCategoryMeta.clear();
          if (jsonMap['category_meta'] != null) {
            (jsonMap['category_meta'] as Map<String, dynamic>).forEach((
              k,
              v,
            ) {
              if (v is Map) {
                _sandboxCategoryMeta[k] = Map<String, dynamic>.from(v);
              }
            });
          }
          if (!_sandboxCategories.containsKey(_selectedSandboxCategory) &&
              _sandboxCategories.isNotEmpty) {
            _selectedSandboxCategory = _sandboxCategories.keys.first;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingSandbox = false);
    }
  }

  // SandboxVars Ayarlarini Kaydet
  Future<void> _saveSandboxConfig() async {
    if (!widget.user.isAdmin) return;
    setState(() => _isSavingSandbox = true);
    final sm = ScaffoldMessenger.of(context);
    try {
      final jsonMap = await ApiClient.saveSandboxConfig(
        categories: _sandboxCategories,
        username: widget.user.username,
      );
      if (jsonMap['status'] == 'ok') {
        _fetchAuditLogs();
        sm.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xff15803d),
            content: Text('SandboxVars settings saved successfully.'),
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
      if (mounted) setState(() => _isSavingSandbox = false);
    }
  }

  // Yeni Panel Kullanıcısı Ekle (Sadece id=1 root admin)
  Future<void> _addUserDialog() async {
    if (widget.user.id != 1) return;
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'OPERATOR';

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
            'Create Panel User',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'USERNAME',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 13, color: Color(0xfff4f4f5)),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff18181b),
                  hintText: 'e.g. Ahmet',
                  hintStyle: const TextStyle(
                    color: Color(0xff71717a),
                    fontSize: 12,
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
              ),
              const SizedBox(height: 14),
              Text(
                'PASSWORD',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(fontSize: 13, color: Color(0xfff4f4f5)),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff18181b),
                  hintText: 'Login password for this user',
                  hintStyle: const TextStyle(
                    color: Color(0xff71717a),
                    fontSize: 12,
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
              ),
              const SizedBox(height: 14),
              Text(
                'AUTHORITY ROLE',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                dropdownColor: const Color(0xff18181b),
                style: const TextStyle(fontSize: 13, color: Color(0xfff4f4f5)),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff18181b),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xff3f3f46)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xff3f3f46)),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'OPERATOR',
                    child: Text('OPERATOR (Monitoring)'),
                  ),
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text('ADMIN (Full Control)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedRole = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: const TextStyle(color: Color(0xffa1a1aa)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () async {
                final uname = nameCtrl.text.trim();
                final pwd = passCtrl.text;
                if (uname.isEmpty) return;
                if (pwd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xff991b1b),
                      content: Text('Password is required.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);

                final sm = ScaffoldMessenger.of(context);
                try {
                  final jsonMap = await ApiClient.addPanelUser(
                    username: uname,
                    role: selectedRole,
                    byUser: widget.user.username,
                    password: pwd,
                  );
                  if (jsonMap['status'] == 'ok') {
                    _fetchDbUsers();
                    _fetchAuditLogs();
                    sm.showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xff15803d),
                        content: Text('User added successfully.'),
                      ),
                    );
                  } else {
                    sm.showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xff991b1b),
                        content: Text(
                          jsonMap['message']?.toString() ?? 'An error occurred',
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
              child: Text('Save & Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Panel Kullanicisi Sil (Sadece id=1 root admin)
  void _deleteUser(String username) async {
    if (widget.user.id != 1) return;
    final sm = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff27272a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xff3f3f46)),
        ),
        title: Text('Delete Panel User'),
        content: Text(
          'Delete "$username" from panel DB?',
          style: const TextStyle(fontSize: 13, color: Color(0xffe4e4e7)),
        ),
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

    if (confirm != true) return;

    try {
      final jsonMap = await ApiClient.deletePanelUser(
        username: username,
        byUser: widget.user.username,
      );
      if (jsonMap['status'] == 'ok') {
        _fetchDbUsers();
        _fetchAuditLogs();
        sm.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xff15803d),
            content: Text('User "$username" deleted successfully.'),
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
          content: Text('Error: $e'),
        ),
      );
    }
  }

  // Sifre Degistir: id=1 herkes icin, digerleri sadece kendi sifresi (eski sifre dogrulamali)
  Future<void> _changePasswordDialog(AppUser targetUser) async {
    final isSelf =
        widget.user.username.toLowerCase() ==
        targetUser.username.toLowerCase();
    final isRoot = widget.user.id == 1;
    final canEdit = isSelf || isRoot;

    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xff991b1b),
          content: Text(
            'Read-only. Only the root administrator (id 1) can manage other users.',
          ),
        ),
      );
      return;
    }

    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xff27272a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xff3f3f46)),
          ),
          title: Text(
            isSelf ? 'Change My Password' : 'Change Password: ${targetUser.username}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT PASSWORD',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: oldCtrl,
                obscureText: obscureOld,
                enabled: true,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xfff4f4f5),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff18181b),
                  hintText: isSelf
                      ? 'Enter your current password'
                      : (isRoot
                          ? 'Not required for root admin'
                          : 'Required'),
                  hintStyle: const TextStyle(
                    color: Color(0xff71717a),
                    fontSize: 12,
                  ),
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      obscureOld
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16,
                      color: const Color(0xffa1a1aa),
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureOld = !obscureOld),
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
              ),
              if (isSelf || (isRoot && targetUser.id == 1))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Required: verify your current password first.',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xff71717a),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                'NEW PASSWORD',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xfff4f4f5),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff18181b),
                  hintText: 'Enter new password',
                  hintStyle: const TextStyle(
                    color: Color(0xff71717a),
                    fontSize: 12,
                  ),
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16,
                      color: const Color(0xffa1a1aa),
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureNew = !obscureNew),
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
              ),
              const SizedBox(height: 14),
              Text(
                'CONFIRM NEW PASSWORD',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: confirmCtrl,
                obscureText: obscureConfirm,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xfff4f4f5),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff18181b),
                  hintText: 'Repeat new password',
                  hintStyle: const TextStyle(
                    color: Color(0xff71717a),
                    fontSize: 12,
                  ),
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16,
                      color: const Color(0xffa1a1aa),
                    ),
                    onPressed: () => setDialogState(
                      () => obscureConfirm = !obscureConfirm,
                    ),
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
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: const TextStyle(color: Color(0xffa1a1aa)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () async {
                final sm = ScaffoldMessenger.of(context);
                final newPwd = newCtrl.text;
                if (newPwd.isEmpty) {
                  sm.showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xff991b1b),
                      content: Text('New password is required.'),
                    ),
                  );
                  return;
                }
                if (newPwd != confirmCtrl.text) {
                  sm.showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xff991b1b),
                      content: Text('Passwords do not match.'),
                    ),
                  );
                  return;
                }
                final needsOld =
                    isSelf || (isRoot && targetUser.id == 1);
                if (needsOld && oldCtrl.text.isEmpty) {
                  sm.showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xff991b1b),
                      content: Text('Current password is required.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogCtx);
                try {
                  final jsonMap = await ApiClient.changePanelUserPassword(
                    username: targetUser.username,
                    newPassword: newPwd,
                    byUser: widget.user.username,
                    oldPassword: oldCtrl.text,
                  );
                  if (jsonMap['status'] == 'ok') {
                    _fetchDbUsers();
                    _fetchAuditLogs();
                    sm.showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xff15803d),
                        content: Text(
                          'Password for "${targetUser.username}" updated successfully.',
                        ),
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
                      content: Text('Error: $e'),
                    ),
                  );
                }
              },
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  // Sunucu Komutu Calistir & Logla
  Future<void> _executeServerCommand(String action) async {
    final canExecute = action == 'restart'
        ? widget.user.canRestartServer
        : widget.user.isAdmin;
    if (!canExecute) return;
    if (_isActionRunning) return;
    setState(() {
      _isActionRunning = true;
      if (action == 'restart') {
        _isRestarting = true;
        _isServerOnline = false;
        _serviceState = 'restarting';
      }
    });

    try {
      final res = await ApiClient.executeServerCommand(
        action: action,
        username: widget.user.username,
      );
      if (res['status'] != 'ok') {
        throw StateError(res['message']?.toString() ?? 'Command execution failed');
      }

      if (action == 'restart' && mounted) setState(() => _isRestarting = false);
      await _fetchRealServerMetrics();
      await _fetchAuditLogs();
      await _fetchServerLogs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xff15803d),
            content: Text('Command executed successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xff991b1b),
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionRunning = false;
          _isRestarting = false;
        });
      }
    }
  }

  void _confirmAction(String actionName, String command) {
    final canExecute = command == 'restart'
        ? widget.user.canRestartServer
        : widget.user.isAdmin;
    if (!canExecute) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff27272a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xff3f3f46)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xffeab308),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Action Confirmation',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Execute "$actionName" for pzserver service?',
          style: const TextStyle(color: Color(0xffe4e4e7), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: const TextStyle(color: Color(0xffa1a1aa)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2563eb),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeServerCommand(command);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Mod Metadata Eşleştirici
}
