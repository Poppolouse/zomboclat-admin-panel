part of 'main.dart';

extension DashUsersMixin on _DashState {
  String _auditDetailsInEnglish(String details) {
    return details
        .replaceAll(
          'pzserver.service restart calistirildi',
          'pzserver.service restart executed',
        )
        .replaceAll(
          'pzserver.service start calistirildi',
          'pzserver.service start executed',
        )
        .replaceAll(
          'pzserver.service stop calistirildi',
          'pzserver.service stop executed',
        )
        .replaceAll(
          'Sunucu komutu uygulandi ancak islem gunluge yazilamadi.',
          'Server command succeeded but could not be written to the audit log.',
        );
  }

  Widget _badgeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // TAB 3: PANEL KULLANICILARI (SQLITE USERS)
  Widget _buildUsersTab() {
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
                Icons.manage_accounts_rounded,
                size: 18,
                color: Color(0xffa1a1aa),
              ),
              const SizedBox(width: 8),
              Text(
                'PANEL USERS (SQLite)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                icon: _isLoadingUsers
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
                onPressed: _isLoadingUsers ? null : _fetchDbUsers,
              ),
              if (widget.user.isAdmin) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2563eb),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: _addUserDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                  label: Text(
                    'Add Panel User',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xff3f3f46), height: 1),
          const SizedBox(height: 12),

          if (_dbUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No users found.',
                  style: const TextStyle(color: Color(0xff71717a)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dbUsers.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Color(0xff333338), height: 1),
              itemBuilder: (ctx, i) {
                final u = _dbUsers[i];
                final isCurrent =
                    u.username.toLowerCase() ==
                    widget.user.username.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xff18181b),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          u.isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : Icons.person_rounded,
                          size: 16,
                          color: u.isAdmin
                              ? const Color(0xff60a5fa)
                              : const Color(0xffa1a1aa),
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
                                  u.username,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xfff4f4f5),
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff1e3a8a),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'You',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xff93c5fd),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${u.id} • ${u.role}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff71717a),
                                fontFamily: 'monospace',
                              ),
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
                          color: u.isAdmin
                              ? const Color(0xff1e3a8a)
                              : const Color(0xff18181b),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: u.isAdmin
                                ? const Color(0xff3b82f6)
                                : const Color(0xff3f3f46),
                          ),
                        ),
                        child: Text(
                          u.role,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: u.isAdmin
                                ? const Color(0xff93c5fd)
                                : const Color(0xffa1a1aa),
                          ),
                        ),
                      ),
                      if (widget.user.isAdmin &&
                          u.username.toLowerCase() != 'poppolouse') ...[
                        const SizedBox(width: 10),
                        IconButton(
                          tooltip: 'Delete User',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xfff87171),
                          ),
                          onPressed: () => _deleteUser(u.username),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // TAB 4: PANEL DENETİM & GİRİŞ-ÇIKIŞ LOGLARI (SQLITE AUDIT LOGS)
  Widget _buildAuditLogsTab() {
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
                Icons.history_rounded,
                size: 18,
                color: Color(0xffa1a1aa),
              ),
              const SizedBox(width: 8),
              Text(
                'ACCESS & ACTION AUDIT LOGS',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                icon: _isLoadingAuditLogs
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
                onPressed: _isLoadingAuditLogs ? null : _fetchAuditLogs,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xff3f3f46), height: 1),
          const SizedBox(height: 10),

          if (_auditLogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No audit logs found.',
                  style: const TextStyle(color: Color(0xff71717a)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _auditLogs.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Color(0xff333338), height: 1),
              itemBuilder: (ctx, i) {
                final log = _auditLogs[i];
                Color actionColor = const Color(0xffa1a1aa);
                if (log.action == 'LOGIN') {
                  actionColor = const Color(0xff22c55e);
                } else if (log.action == 'LOGOUT') {
                  actionColor = const Color(0xff71717a);
                } else if (log.action.startsWith('SERVER')) {
                  actionColor = const Color(0xffeab308);
                } else if (log.action.startsWith('USER') ||
                    log.action.startsWith('PLAYER')) {
                  actionColor = const Color(0xffa855f7);
                } else if (log.action.contains('INI') ||
                    log.action.contains('SANDBOX')) {
                  actionColor = const Color(0xff38bdf8);
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
                          color: const Color(0xff18181b),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: actionColor.withAlpha(80)),
                        ),
                        child: Text(
                          log.action,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: actionColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${log.username} - ${_auditDetailsInEnglish(log.details)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xfff4f4f5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        log.createdAt,
                        style: const TextStyle(
                          fontSize: 11,
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
      ),
    );
  }

  // TAB 5: KONSOL - TÜM LOGLAR (CANLI STREAM)
}
