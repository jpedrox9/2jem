import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/providers/user_provider.dart';
import 'package:app_2jem/models/user_model.dart';
import 'package:app_2jem/views/admin_page.dart';
import 'package:app_2jem/views/language_selector.dart';
import 'package:app_2jem/views/store_verification_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    if (!mounted) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. Validate Login via Firebase
      final role = await Provider.of<UserProvider>(context, listen: false)
          .validateLogin(email, password);

      if (!mounted) return;

      // 2. Navigate based on role
      if (role == UserRole.admin) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const AdminPage(),
        ));
      } else {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const StoreVerificationPage(),
        ));
      }
    } catch (e) {
      // Show the actual error from Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('2JEM'),
        automaticallyImplyLeading: false,
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 200,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: lang.translate('email'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: lang.translate('password'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _login,
                  icon: const Icon(Icons.login),
                  label: Text(lang.translate('login')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
