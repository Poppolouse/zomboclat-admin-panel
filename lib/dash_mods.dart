part of 'main.dart';

extension DashModsMixin on _DashState {
  Widget _buildStudioLiveCommandsTab() {
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
              Text(
                'LIVE RCON & SERVER ACTIONS',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffeab308),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pHasGodmode
                          ? const Color(0xff16a34a)
                          : const Color(0xff3f3f46),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _pHasGodmode = !_pHasGodmode);
                      _quickSendRcon(
                        'godmode "$uname" -${_pHasGodmode ? "true" : "false"}',
                        'Godmode for $uname: $_pHasGodmode',
                      );
                    },
                    icon: const Icon(Icons.shield_rounded, size: 16),
                    label: Text(
                      _pHasGodmode
                          ? 'Godmode Enabled (Invincible)'
                          : 'Godmode Disabled',
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pIsInvisible
                          ? const Color(0xff16a34a)
                          : const Color(0xff3f3f46),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _pIsInvisible = !_pIsInvisible);
                      _quickSendRcon(
                        'invisible "$uname" -${_pIsInvisible ? "true" : "false"}',
                        'Invisibility for $uname: $_pIsInvisible',
                      );
                    },
                    icon: const Icon(Icons.visibility_off_rounded, size: 16),
                    label: Text(
                      _pIsInvisible
                          ? 'Invisibility Enabled'
                          : 'Invisibility Disabled',
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _quickSendRcon(
                      'heal "$uname"',
                      '$uname restored to full health.',
                    ),
                    icon: const Icon(Icons.healing_rounded, size: 16),
                    label: Text('Full Heal'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff991b1b),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _quickSendRcon(
                      'kick "$uname" "Admin tarafindan atildi"',
                      '$uname kicked from server.',
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: Text('Kick Player'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sunucu İçi Mesaj Gönder
              Text(
                'SEND LIVE SERVER BROADCAST',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffa1a1aa),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pServerMsgCtrl,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xfff4f4f5),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xff27272a),
                        hintText:
                            'Type global server broadcast announcement...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final msg = _pServerMsgCtrl.text.trim();
                      if (msg.isNotEmpty) {
                        _quickSendRcon(
                          'servermsg "$msg"',
                          'Broadcast sent: $msg',
                        );
                        _pServerMsgCtrl.clear();
                      }
                    },
                    icon: const Icon(Icons.campaign_rounded, size: 16),
                    label: Text('Broadcast'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 7: MOD & WORKSHOP GALERİSİ
  Widget _buildModGalleryTab() {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: Color(0xff60a5fa),
                ),
                const SizedBox(width: 8),
                Text(
                  'MODS & STEAM WORKSHOP GALLERY',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _badgeChip(
                      '${_iniMods.length} ${'Active Mod IDs'}',
                      const Color(0xff3b82f6),
                    ),
                    const SizedBox(width: 8),
                    _badgeChip(
                      '${_iniWorkshopItems.length} ${'Steam Workshop Items'}',
                      const Color(0xff10b981),
                    ),
                    const SizedBox(width: 8),
                    _badgeChip(
                      '${_workshopDetails.length} ${'Images Loaded'}',
                      const Color(0xffa855f7),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff27272a),
                        foregroundColor: const Color(0xfff4f4f5),
                        side: const BorderSide(color: Color(0xff3f3f46)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: _showAddModDialog,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        'Add Mod / Workshop',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

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
                    hintText: 'Search Mod ID, Workshop ID, or Title...',
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
                  onChanged: (val) => setState(() => _modSearchQuery = val),
                ),
                const SizedBox(height: 16),

                // MOD KARTLARI (STEAM WORKSHOP FOTOGRAFLI KARTLAR)
                Text(
                  'STEAM WORKSHOP ITEMS & THUMBNAILS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xffa1a1aa),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                if (_iniWorkshopItems.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No Workshop items.'),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossCount = constraints.maxWidth > 900
                          ? 3
                          : (constraints.maxWidth > 600 ? 2 : 1);
                      final filteredWs = _iniWorkshopItems.where((wid) {
                        final q = _modSearchQuery.toLowerCase();
                        if (wid.contains(q)) return true;
                        final details = _workshopDetails[wid];
                        if (details != null &&
                            details['title']?.toString().toLowerCase().contains(
                                  q,
                                ) ==
                                true) {
                          return true;
                        }
                        return false;
                      }).toList();

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 115,
                        ),
                        itemCount: filteredWs.length,
                        itemBuilder: (ctx, i) {
                          final wid = filteredWs[i];
                          final details = _workshopDetails[wid];
                          final title = details?['title'] ?? 'Workshop #$wid';
                          final previewUrl = details?['preview_url'] as String?;
                          final subs = details?['subscriptions'] as int? ?? 0;

                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xff18181b),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xff3f3f46),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    width: 95,
                                    height: 95,
                                    color: const Color(0xff27272a),
                                    child:
                                        previewUrl != null &&
                                            previewUrl.isNotEmpty
                                        ? Image.network(
                                            previewUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const Center(
                                              child: Icon(
                                                Icons
                                                    .image_not_supported_outlined,
                                                size: 24,
                                                color: Color(0xff71717a),
                                              ),
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.extension_rounded,
                                              size: 24,
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
                                        title,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xfff4f4f5),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'ID: $wid',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xffa1a1aa),
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          if (subs > 0)
                                            Text(
                                              '⭐ ${(subs / 1000).toStringAsFixed(0)}k',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: Color(0xfffacc15),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          const Spacer(),
                                          IconButton(
                                            tooltip: 'Open in Steam',
                                            icon: const Icon(
                                              Icons.open_in_new_rounded,
                                              size: 14,
                                              color: Color(0xff60a5fa),
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              Process.run('cmd', [
                                                '/c',
                                                'start',
                                                'https://steamcommunity.com/sharedfiles/filedetails/?id=$wid',
                                              ]);
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Remove',
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 15,
                                              color: Color(0xfff87171),
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              setState(() {
                                                _iniWorkshopItems.remove(wid);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 8: MOD YÜKLEME SIRALAMASI (MOD LOAD ORDER)
  Widget _buildModOrderTab() {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.reorder_rounded,
                  size: 18,
                  color: Color(0xff60a5fa),
                ),
                const SizedBox(width: 8),
                Text(
                  'MOD LOAD ORDER (Mods=...)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff38bdf8),
                    side: const BorderSide(color: Color(0xff0284c7)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: _showModJsonExportDialog,
                  icon: const Icon(Icons.code_rounded, size: 15),
                  label: Text(
                    'Export JSON',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff18181b),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xff0284c7).withAlpha(80),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xff38bdf8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mods load from top to bottom. Drag & drop with handles or click number inputs to reorder priority.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xffbae6fd),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

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
                    hintText: 'Search mod ID or title in load order...',
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
                      setState(() => _modOrderSearchQuery = val),
                ),
                const SizedBox(height: 14),

                if (_iniMods.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No Mod IDs.'),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    buildDefaultDragHandles:
                        false, // Prevents handle collision with number editor
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _iniMods.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final item = _iniMods.removeAt(oldIndex);
                        _iniMods.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (ctx, i) {
                      final modId = _iniMods[i];
                      final meta = _getModMetadata(i, modId);
                      final name = meta?['name'] as String? ?? modId;
                      final workshopTitle =
                          meta?['workshop_title'] as String? ?? '';
                      final title = name.isNotEmpty
                          ? name
                          : (workshopTitle.isNotEmpty ? workshopTitle : modId);
                      final previewUrl = meta?['preview_url'] as String?;
                      final desc = meta?['description'] as String? ?? '';
                      final subs = meta?['subscriptions'] as int? ?? 0;
                      final wid =
                          (meta != null &&
                              meta['workshop_id'] != null &&
                              meta['workshop_id'].toString().isNotEmpty)
                          ? meta['workshop_id'].toString()
                          : null;

                      final isMatch =
                          _modOrderSearchQuery.isEmpty ||
                          modId.toLowerCase().contains(
                            _modOrderSearchQuery.toLowerCase(),
                          ) ||
                          title.toLowerCase().contains(
                            _modOrderSearchQuery.toLowerCase(),
                          ) ||
                          workshopTitle.toLowerCase().contains(
                            _modOrderSearchQuery.toLowerCase(),
                          );
                      if (!isMatch) {
                        return Container(key: ValueKey('hidden-$modId-$i'));
                      }

                      return Container(
                        key: ValueKey('order-$modId-$i'),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff18181b),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xff3f3f46)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Sürükleme Tutamacı (Özel DragStartListener)
                            ReorderableDragStartListener(
                              index: i,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.grab,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  child: const Icon(
                                    Icons.drag_indicator_rounded,
                                    size: 20,
                                    color: Color(0xff71717a),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Sıra Numarası Çipi & Sayı Değiştirme Butonu
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => _showJumpToPositionDialog(i, modId),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xff27272a),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xff3b82f6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '#${i + 1}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff93c5fd),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 11,
                                      color: Color(0xff93c5fd),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Mod Görseli
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                width: 50,
                                height: 50,
                                color: const Color(0xff27272a),
                                child:
                                    previewUrl != null && previewUrl.isNotEmpty
                                    ? Image.network(
                                        previewUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 20,
                                            color: Color(0xff71717a),
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.extension_rounded,
                                          size: 22,
                                          color: Color(0xff71717a),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Mod Başlığı, ID ve Açıklama
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xfff4f4f5),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xff27272a),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xff3f3f46),
                                          ),
                                        ),
                                        child: Text(
                                          modId,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xff93c5fd),
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (wid != null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          'WS: $wid',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Color(0xff71717a),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                      if (subs > 0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '⭐ ${(subs / 1000).toStringAsFixed(0)}k',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Color(0xfffacc15),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      desc,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xffa1a1aa),
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // İşlem Butonları (Tamamen Ayrık ve Net)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Move to Top',
                                  icon: const Icon(
                                    Icons.vertical_align_top_rounded,
                                    size: 16,
                                    color: Color(0xffa1a1aa),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                  onPressed: i > 0
                                      ? () => _moveModToPosition(i, 0)
                                      : null,
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Move Up',
                                  icon: const Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: Color(0xffa1a1aa),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                  onPressed: i > 0
                                      ? () => _moveModToPosition(i, i - 1)
                                      : null,
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Move Down',
                                  icon: const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: Color(0xffa1a1aa),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                  onPressed: i < _iniMods.length - 1
                                      ? () => _moveModToPosition(i, i + 1)
                                      : null,
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Move to Bottom',
                                  icon: const Icon(
                                    Icons.vertical_align_bottom_rounded,
                                    size: 16,
                                    color: Color(0xffa1a1aa),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                  onPressed: i < _iniMods.length - 1
                                      ? () => _moveModToPosition(
                                          i,
                                          _iniMods.length - 1,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: const Color(0xff3f3f46),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 17,
                                    color: Color(0xfff87171),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _iniMods.removeAt(i);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
