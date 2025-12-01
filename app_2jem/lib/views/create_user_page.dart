import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_2jem/models/user_model.dart';
import 'package:app_2jem/providers/user_provider.dart';
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/views/language_selector.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.technician;
  bool _isLoading = false;

  Future<void> _createUser(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).addUser(
        _emailController.text,
        _passwordController.text,
        _selectedRole,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.translate('user_created')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('create_new_user')),
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.person_add, size: 60, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  lang.translate('new_account'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: lang.translate('email'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (val) => val!.contains('@')
                      ? null
                      : lang.translate('invalid_email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: lang.translate('password'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (val) =>
                      val!.length < 4 ? lang.translate('password_short') : null,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: lang.translate('role'),
                    border: const OutlineInputBorder(),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      // We capitalize only the first letter for display
                      child:
                          Text(role == UserRole.admin ? 'Admin' : 'Technician'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () => _createUser(lang),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                        ),
                        child: Text(lang.translate('create_account')),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
