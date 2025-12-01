import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_2jem/providers/user_provider.dart';
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/views/create_user_page.dart';
import 'package:app_2jem/views/language_selector.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('manage_users')),
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
        ],
      ),
      // Stream Firestore Users collection
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(child: Text(lang.translate('no_users')));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final uid = docs[index].id;
              final email = data['email'] ?? 'Unknown';
              final role = data['role'] ?? 'technician';
              final isActive = data['isActive'] ?? true;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive
                      ? (role == 'admin' ? Colors.purple : Colors.green)
                      : Colors.grey,
                  child: Icon(
                    role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  email,
                  style: TextStyle(
                    decoration: isActive ? null : TextDecoration.lineThrough,
                    color: isActive ? Colors.black : Colors.grey,
                  ),
                ),
                subtitle: Text(
                    '${role.toUpperCase()} • ${isActive ? lang.translate('active') : lang.translate('disabled')}'),
                trailing: Switch(
                  value: isActive,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  onChanged: (bool value) {
                    userProvider.toggleUserStatus(uid, value);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const CreateUserPage(),
          ));
        },
        label: Text(lang.translate('add_user')),
        icon: const Icon(Icons.person_add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
