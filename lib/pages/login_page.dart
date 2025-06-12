import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/appwrite_client.dart';
import 'package:weather/data/ui_stub.dart' // Stub implementation
    if (dart.library.ui_web) 'dart:ui_web';
import 'package:weather/l10n/app_localizations.g.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController =
      TextEditingController(); // For sign-up

  bool _isLoading = false;
  String? _error;
  bool _isLogin = true;

  late Account account;

  @override
  void initState() {
    super.initState();
    account = AppwriteClient().getAccount;
  }

  Future<void> _login(String email, String password) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      if (mounted) {
        _finishLogin();
      }
    } on AppwriteException catch (e) {
      setState(() {
        _error = e.message ?? 'An unknown error occurred';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUp(String email, String password, String name) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      // Log in the user after successful sign-up
      await _login(email, password);
      if (mounted) {
        _finishLogin();
      }
    } on AppwriteException catch (e) {
      setState(() {
        _error = e.message ?? 'An unknown error occurred';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  (String?, String?) _getSuccessFailureUrls() {
    if (kIsWeb || kIsWasm) {
      final String href = BrowserPlatformLocation().getBaseHref()!;
      return ('${href}auth', '${href}auth');
    } else if (Platform.isWindows) {
      // Success and failure paths must match the paths here:
      // https://github.com/appwrite/appwrite/blob/507f8c69555e8f5774199b0b44eb9b4b8dbdf985/app/controllers/api/account.php#L58
      return (
        'http://localhost:8080/console/auth/oauth2/success',
        'http://localhost:8080/console/auth/oauth2/failure'
      );
    } else {
      return (null, null);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: _getSuccessFailureUrls().$1,
        failure: _getSuccessFailureUrls().$2,
        scopes: ['email', 'profile'],
      );
      // Appwrite handles redirection. If successful, user session is created.
      if (mounted) {
        final session = await account.getSession(sessionId: 'current');
        if (kDebugMode) {
          print(
              'Signed in with ${session.provider}, user ID: ${session.providerUid}, token: ${session.providerAccessToken}');
        }
        if (!mounted) return;
        _finishLogin();
      }
    } on AppwriteException catch (e) {
      setState(() {
        _error = e.message ?? 'An unknown error occurred with Google Sign-In';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _finishLogin() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.syncFavouritesToAppwrite) {
      final client = AppwriteClient();
      client
          .syncFavourites(appState, direction: SyncDirection.fromAppwrite)
          .then((_) {
        client.subscribe();
      });
    }
    context.goNamed('settings');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isLogin ? localizations.login : localizations.signUp),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child:
                        Image.asset('assets/icon.png', height: 100, width: 100),
                  ),
                  if (!_isLogin)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: localizations.name,
                        hintText: localizations.enterYourName,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      enabled: !_isLoading,
                    ),
                  if (!_isLogin) const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: localizations.email,
                      hintText: localizations.enterYourEmail,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: localizations.password,
                      hintText: localizations.enterYourPassword,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 24.0),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: () {
                        if (_isLogin) {
                          _login(
                              _emailController.text, _passwordController.text);
                        } else {
                          _signUp(_emailController.text,
                              _passwordController.text, _nameController.text);
                        }
                      },
                      child: Text(_isLogin
                          ? localizations.login
                          : localizations.signUp),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _error = null;
                        });
                      },
                      child: Text(_isLogin
                          ? localizations.createAccount
                          : localizations.haveAccountLogin),
                    ),
                    const SizedBox(height: 20),
                    Text(localizations.or,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: Text(localizations.signInWithGoogle,
                          style: const TextStyle(fontSize: 16)),
                      onPressed: _googleSignIn,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16)
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error == 'An unknown error occurred'
                          ? localizations.unknownError
                          : _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
