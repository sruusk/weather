import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:weather/appwrite_client.dart';

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

  late Account account; // Added: Get account from AppwriteClient

  @override
  void initState() { // Added initState
    super.initState();
    account = AppwriteClient().getAccount; // Initialize account
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
        context.goNamed('settings');
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
      // Use the account instance from AppwriteClient
      await account.create( // Use initialized account
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      // Log in the user after successful sign-up
      await _login(email, password);
      if(mounted) {
        context.goNamed('settings');
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
    if (kIsWeb) {
      return ('${Uri.base.origin}/auth', '${Uri.base.origin}/auth');
    } else if(Platform.isWindows) {
      // Success and failure paths must match the paths here:
      // https://github.com/appwrite/appwrite/blob/507f8c69555e8f5774199b0b44eb9b4b8dbdf985/app/controllers/api/account.php#L58
      return ('http://localhost:8080/console/auth/oauth2/success',
              'http://localhost:8080/console/auth/oauth2/failure');
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
      // Use the account instance from AppwriteClient
      await account.createOAuth2Session( // Use initialized account
        provider: OAuthProvider.google,
        success: _getSuccessFailureUrls().$1,
        failure: _getSuccessFailureUrls().$2,
        scopes: ['email', 'profile'],
      );
      // Appwrite handles redirection. If successful, user session is created.
      // You might need to check session status and navigate accordingly.
      // For Flutter web, this might open a new tab/window.
      // For mobile, you'll need to handle the callback URL.
      // This example assumes a simple scenario where Appwrite redirects back.
      if (mounted) {
        // Potentially check session and navigate
        // Use the account instance from AppwriteClient
        final session = await account.getSession(sessionId: 'current'); // Use initialized account
        if (kDebugMode) {
          print('Signed in with ${session.provider}, user ID: ${session.providerUid}, token: ${session.providerAccessToken}');
        }
        if (!mounted) return; // Re-check mounted after await
        context.goNamed('settings');
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

  @override
  Widget build(BuildContext context) {
    // Access Account instance from AppwriteClient
    // account = Provider.of<AppState>(context, listen: false).account; // Removed

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400), // Max width for the content
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Add the icon here
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Image.asset('assets/icon.png', height: 100, width: 100),
                  ),
                  if (!_isLogin)
                    TextFormField( // Changed to TextFormField for consistency
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter your name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      enabled: !_isLoading,
                    ),
                  if (!_isLogin) const SizedBox(height: 16), // Increased spacing
                  TextFormField( // Changed to TextFormField
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16), // Increased spacing
                  TextFormField( // Changed to TextFormField
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
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
                        minimumSize: const Size(double.infinity, 50), // Make button wider and taller
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: () {
                        if (_isLogin) {
                          _login(_emailController.text, _passwordController.text);
                        } else {
                          _signUp(_emailController.text, _passwordController.text,
                              _nameController.text);
                        }
                      },
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
                    const SizedBox(height: 16), // Increased spacing
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                      ),
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _error = null;
                        });
                      },
                      child: Text(_isLogin
                          ? 'Create an account'
                          : 'Have an account? Login'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Or', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login), // Consider replacing with a Google icon if available
                      label: const Text('Sign in with Google', style: TextStyle(fontSize: 16)),
                      onPressed: _googleSignIn,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.white, // Google's typical button color
                        foregroundColor: Colors.black87, // Text color for Google button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16) // Increased spacing
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
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
