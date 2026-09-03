part of 'main.dart';

class Dash extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const Dash({super.key, required this.user, required this.onLogout});

  @override
  State<Dash> createState() => _DashState();
}

class _DashState extends State<Dash> {
  final cpu = <double>[];
  final ram = <double>[];
  Timer? _metricsTimer;

  // TAB SEÇİMİ:
  // 0: Panel
  // 1: Sunucu INI Ayarları
  // 2: SandboxVars Ayarları
  // 3: Panel Kullanıcıları (SQLite)
  // 4: Panel Denetim Logları (Audit)
  // 5: Konsol - Tüm Loglar
  // 6: Sistem Ayarları
  // 7: Mod & Workshop Galerisi
  // 8: Mod Sıralaması (Mod Order)
  // 9: Konsol - Hatalar & Uyarılar
  // 10: Konsol - Hata Veren Modlar
  // 11: Sunucu Oyuncuları (In-Game Players / Whitelist)
  // 12: Realtime God Actions (Hava & Dünya Olayları)
  int _selectedTab = 0;

  bool _isServerOnline = true;
  bool _isConnecting = false;
  bool _isActionRunning = false;
  bool _isRestarting = false;
  int _latencyMs = 24;
  String _serverUptime = '2 saat 28 dakika';
  String _serviceState = 'active';

  // Sidebar Expand Durumları (start collapsed)
  bool _isConsoleGroupExpanded = false;
  bool _isModsGroupExpanded = false;
  bool _isSandboxGroupExpanded = false;

  // SQLite Panel Kullanıcı Listesi ve Logları
  final List<AppUser> _dbUsers = [];
  bool _isLoadingUsers = false;

  final List<AuditLog> _auditLogs = [];
  bool _isLoadingAuditLogs = false;

  // In-Game Project Zomboid Oyuncuları (pzserver.db)
  final List<GamePlayer> _gamePlayers = [];
  final List<GameUserLog> _gameUserLogs = [];
  bool _isLoadingGamePlayers = false;
  String _gamePlayersError = '';
  String _gamePlayerSearchQuery = '';
  int _gamePlayerSubTab = 0; // 0: Players, 1: Anti-Cheat Logs

  // Oyuncu & Karakter Stüdyosu (Dedicated Full-Page Editor)
  GamePlayer? _editingPlayer;
  int _playerEditorSubTab = 0; // 0: General, 1: Skills, 2: Profession & Traits, 3: Health & Body, 4: Inventory, 5: Item Spawner, 6: Map & Teleport, 7: Live RCON

  final TextEditingController _pCharNameCtrl = TextEditingController();
  final TextEditingController _pSteamIdCtrl = TextEditingController();
  final TextEditingController _pPasswordCtrl = TextEditingController();
  final TextEditingController _pPosXCtrl = TextEditingController();
  final TextEditingController _pPosYCtrl = TextEditingController();
  final TextEditingController _pPosZCtrl = TextEditingController();
  final TextEditingController _pZombieKillsCtrl = TextEditingController(
    text: '0',
  );
  final TextEditingController _pHoursSurvivedCtrl = TextEditingController(
    text: '0',
  );
  final TextEditingController _pWeightCtrl = TextEditingController(text: '80');
  final TextEditingController _pCustomItemCtrl = TextEditingController();
  final TextEditingController _pItemCountCtrl = TextEditingController(
    text: '1',
  );
  final TextEditingController _pServerMsgCtrl = TextEditingController();

  // Eşya Kataloğu ve Envanter Arama
  List<Map<String, dynamic>> _catalogItems = [];
  bool _isLoadingCatalog = false;
  String _catalogError = '';
  String _spawnerSearchQuery = '';
  String _spawnerSelectedCat = 'All';
  String _inventorySearchQuery = '';
  final TextEditingController _spawnerSearchCtrl = TextEditingController();
  final TextEditingController _inventorySearchCtrl = TextEditingController();
  bool _isRefreshingInventory = false;

  // Envanterde acik olan konteynerler (container item id -> open)
  final Set<String> _openInventoryContainers = {};

  int _pSelectedRoleId = 2;
  bool _pIsBanned = false;
  String _pBanReason = 'Banned by Admin Panel';
  bool _pIsDead = false;
  bool _pIsInfected = false;
  bool _pHasGodmode = false;
  bool _pIsInvisible = false;
  double _pHealth = 100.0;
  double _pHunger = 0.0;
  double _pThirst = 0.0;
  double _pFatigue = 0.0;
  double _pStress = 0.0;
  double _pBoredom = 0.0;
  String _pSelectedProfession = 'unemployed';
  final Set<String> _pSelectedPositiveTraits = {};
  final Set<String> _pSelectedNegativeTraits = {};
  final Map<String, int> _pSkills = {};
  bool _isSavingPlayerStudio = false;

  // Realtime God Actions (Hava & Dunya Olaylari)
  double _godRainIntensity = 50;
  double _godStormHours = 4;
  String _godSelectedTarget = 'random';
  List<String> _godOnlinePlayers = [];
  bool _isLoadingGodOnline = false;
  String _godPresetActive = '';
  int _godPresetRemaining = 0;
  Timer? _godPresetTimer;
  final TextEditingController _godHordeCtrl = TextEditingController(
    text: '100',
  );

  // Server Journal Logs & Stream
  final List<String> _serverLogs = [];
  bool _isLoadingServerLogs = false;
  bool _isLiveConsoleStreaming = true;
  bool _autoScrollConsole = true;
  String _consoleSearchQuery = '';
  final ScrollController _consoleScrollController = ScrollController();

  // INI & Mod Ayarları
  final Map<String, String> _iniSettings = {};
  final Map<String, String> _iniComments = {};
  final List<String> _iniKeys = [];
  final List<String> _iniMods = [];
  final List<String> _iniWorkshopItems = [];
  final Map<String, Map<String, dynamic>> _workshopDetails = {};
  final Map<String, Map<String, dynamic>> _modDetails = {};
  bool _isLoadingIni = false;
  bool _isSavingIni = false;
  String _iniSearchQuery = '';
  String _modSearchQuery = '';
  String _modOrderSearchQuery = '';

  // SandboxVars Ayarları
  final Map<String, List<Map<String, dynamic>>> _sandboxCategories = {};
  final Map<String, Map<String, dynamic>> _sandboxCategoryMeta = {};
  String _selectedSandboxCategory = 'General';
  bool _isLoadingSandbox = false;
  bool _isSavingSandbox = false;
  String _sandboxSearchQuery = '';

  final r = Random();

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 20; i++) {
      cpu.add(2.0 + r.nextDouble() * 3.0);
      ram.add(6.1 + r.nextDouble() * 0.4);
    }

    _fetchRealServerMetrics();
    _fetchDbUsers();
    _fetchAuditLogs();
    _fetchGamePlayers();
    _fetchServerLogs();
    _fetchIniConfig();
    _fetchSandboxConfig();

    _metricsTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _fetchRealServerMetrics();
      // Konsol ekranlarından biri açıksa ve canlı akış aktifse arka planda logları güncelle
      if ((_selectedTab == 5 || _selectedTab == 9 || _selectedTab == 10) &&
          _isLiveConsoleStreaming &&
          !_isLoadingServerLogs) {
        _fetchServerLogs(isBackground: true);
      }
    });
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    _godPresetTimer?.cancel();
    _consoleScrollController.dispose();
    super.dispose();
  }

  // Sayfa Değiştirme ve Otomatik Veri Çekme (Auto-fetch)
  void _selectTab(int tabIndex, {String? category}) {
    setState(() {
      _selectedTab = tabIndex;
      if (category != null) _selectedSandboxCategory = category;
    });

    if (tabIndex == 1 || tabIndex == 7 || tabIndex == 8) {
      _fetchIniConfig();
    } else if (tabIndex == 2) {
      _fetchSandboxConfig();
    } else if (tabIndex == 3) {
      _fetchDbUsers();
    } else if (tabIndex == 4) {
      _fetchAuditLogs();
    } else if (tabIndex == 11) {
      _fetchGamePlayers();
    } else if (tabIndex == 12) {
      _fetchGodOnlinePlayers();
    } else if (tabIndex == 5 || tabIndex == 9 || tabIndex == 10) {
      _fetchServerLogs();
    }
  }

  @override
  Widget build(BuildContext context) => _buildLayout(context);

  // In-Game Project Zomboid Oyuncularını Çek (pzserver.db)
}
