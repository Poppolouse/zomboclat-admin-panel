part of 'main.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  AppUser? _currentUser;
  bool _isCheckingForUpdate = true;
  String? _updateCheckError;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  void _retryUpdateCheck() {
    setState(() {
      _isCheckingForUpdate = true;
      _updateCheckError = null;
    });
    _checkForUpdate();
  }

  void _continueWithoutUpdate() {
    setState(() {
      _isCheckingForUpdate = false;
      _updateCheckError = null;
    });
  }

  void _login(AppUser user) {
    setState(() {
      _currentUser = user;
    });
  }
  void _logout() async {
    if (_currentUser != null) {
      ApiClient.logAuditAction(
        username: _currentUser!.username,
        action: 'LOGOUT',
        details: 'Session Closed',
      );
    }
    ApiClient.clearSession();
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
      home: _isCheckingForUpdate
          ? _UpdateCheckScreen(
              error: _updateCheckError,
              onRetry: _retryUpdateCheck,
              onContinue: _continueWithoutUpdate,
            )
          : _currentUser == null
          ? LoginScreen(
              onLoginSuccess: _login,
              onCheckForUpdate: _retryUpdateCheck,
            )
          : Dash(user: _currentUser!, onLogout: _logout),
    );
  }
}

class _UpdateCheckScreen extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  const _UpdateCheckScreen({
    required this.error,
    required this.onRetry,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final failed = error != null;
    return Scaffold(
      body: Center(
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xff27272a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xff3f3f46)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                failed ? Icons.cloud_off_outlined : Icons.system_update,
                size: 32,
                color: failed ? const Color(0xfffbbf24) : const Color(0xff60a5fa),
              ),
              const SizedBox(height: 14),
              Text(
                failed ? 'Could not check for updates' : 'Checking for updates...',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              if (!failed) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xfffca5a5), fontSize: 12),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(onPressed: onContinue, child: const Text('Continue to panel')),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 17),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// LOGIN SCREEN
// -------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  final Function(AppUser) onLoginSuccess;
  final VoidCallback onCheckForUpdate;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onCheckForUpdate,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _storage = FlutterSecureStorage();
  static const _keyRemember = 'remember_me';
  static const _keyUsername = 'remembered_username';
  static const _keyPassword = 'remembered_password';

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final remember = await _storage.read(key: _keyRemember);
      final username = await _storage.read(key: _keyUsername);
      final password = await _storage.read(key: _keyPassword);
      if (!mounted) return;
      setState(() {
        _rememberMe = remember == 'true';
        if (_rememberMe) {
          _usernameController.text = username ?? '';
          _passwordController.text = password ?? '';
        }
      });
    } catch (_) {}
  }

  Future<void> _persistRememberedCredentials(
    String username,
    String password,
  ) async {
    try {
      if (_rememberMe) {
        await _storage.write(key: _keyRemember, value: 'true');
        await _storage.write(key: _keyUsername, value: username);
        await _storage.write(key: _keyPassword, value: password);
      } else {
        await _storage.delete(key: _keyRemember);
        await _storage.delete(key: _keyUsername);
        await _storage.delete(key: _keyPassword);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Please enter your username.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appUser = await ApiClient.login(username, password);
      if (appUser != null) {
        await _persistRememberedCredentials(username, password);
        widget.onLoginSuccess(appUser);
        return;
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'User not registered in database. Please ask the administrator (Poppolouse) to add you.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final err = e.toString();
          if (err.contains('User not registered') ||
              err.contains('Kullanici veritabaninda')) {
            _errorMessage = 'User not registered in database. Please ask the administrator (Poppolouse) to add you.';
          } else if (err.contains('Hatali sifre')) {
            _errorMessage = 'Incorrect password. Please try again.';
          } else if (err.contains('Sifre zorunludur')) {
            _errorMessage = 'Please enter your password.';
          } else {
            _errorMessage =
                'Could not reach server database ($kApiBaseUrl). Check connection.';
          }
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
                            'Password Protected Panel Login',
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
                          'Server: 45.142.115.19:28080 (SQLite Backend)',
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
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xfff4f4f5),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xff18181b),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      size: 17,
                      color: Color(0xffa1a1aa),
                    ),
                    suffixIcon: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 17,
                        color: const Color(0xffa1a1aa),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    hintText: 'Enter your password',
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
                const SizedBox(height: 14),
                SizedBox(
                  height: 26,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: const Color(0xff2563eb),
                          side: const BorderSide(color: Color(0xff3f3f46)),
                          onChanged: (val) =>
                              setState(() => _rememberMe = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: const Text(
                          'Remember me (keeps you signed in on this PC)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xffa1a1aa),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  child: Column(
                    children: [
                      const Text(
                        'Access requires both a registered username and password.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xff71717a),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onCheckForUpdate,
                        icon: const Icon(Icons.system_update_alt, size: 15),
                        label: const Text('Check for updates'),
                      ),
                    ],
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
