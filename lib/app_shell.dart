part of 'main.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), _checkForUpdate);
  }

  void _login(AppUser user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _logout() async {
    if (_currentUser != null) {
      final username = _currentUser!.username;
      try {
        Process.run('ssh', [
          '-o',
          'BatchMode=yes',
          '-o',
          'ConnectTimeout=3',
          'pz-vps',
          'python3 /var/lib/zomboclat/db.py log $username LOGOUT "Session Closed"',
        ], runInShell: true);
      } catch (_) {}
    }
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zomboclat Admin Panel',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff18181b),
        cardColor: const Color(0xff27272a),
        dividerColor: const Color(0xff3f3f46),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff3b82f6),
          surface: Color(0xff27272a),
        ),
      ),
      home: _currentUser == null
          ? LoginScreen(onLoginSuccess: _login)
          : Dash(user: _currentUser!, onLogout: _logout),
    );
  }
}

// -------------------------------------------------------------
// LOGIN SCREEN
// -------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  final Function(AppUser) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'Poppolouse');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Please enter your username.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await Process.run('ssh', [
        '-o',
        'BatchMode=yes',
        '-o',
        'ConnectTimeout=4',
        'pz-vps',
        'python3 /var/lib/zomboclat/db.py auth $username',
      ], runInShell: true).timeout(const Duration(seconds: 5));

      if (res.exitCode == 0) {
        final raw = res.stdout.toString().trim();
        final jsonMap = jsonDecode(raw) as Map<String, dynamic>;

        if (jsonMap['status'] == 'ok' && jsonMap['user'] != null) {
          final appUser = AppUser.fromJson(
            jsonMap['user'] as Map<String, dynamic>,
          );
          widget.onLoginSuccess(appUser);
          return;
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'User not registered in database. Please ask the administrator (Poppolouse) to add you.';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Could not reach server database. Check VPS connection.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xff27272a),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xff3f3f46), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.dns_rounded,
                      size: 20,
                      color: Color(0xff3b82f6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zomboclat Admin Panel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xfff4f4f5),
                            ),
                          ),
                          Text(
                            'VPS SQLite Authenticated Login',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xffa1a1aa),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xff3f3f46), height: 1),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff18181b),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xff333338)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storage_outlined,
                        size: 16,
                        color: Color(0xffa1a1aa),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Database: pz-vps (SQLite /var/lib/zomboclat/zomboclat.db)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xffa1a1aa),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
                  controller: _usernameController,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xfff4f4f5),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xff18181b),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      size: 17,
                      color: Color(0xffa1a1aa),
                    ),
                    hintText: 'Enter your username',
                    hintStyle: const TextStyle(
                      color: Color(0xff71717a),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xff3f3f46)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xff3f3f46)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Color(0xff3b82f6),
                        width: 1.2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xff451a1a),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xff7f1d1d)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xfffca5a5),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login_rounded, size: 17),
                              const SizedBox(width: 8),
                              Text(
                                'Sign In to Panel',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Users added to the database by Admin can log in directly.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff71717a),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// DASHBOARD (ANA PANEL)
