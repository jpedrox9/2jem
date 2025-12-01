import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/providers/user_provider.dart';
import 'package:app_2jem/view_models/job_view_model.dart';
import 'package:app_2jem/views/checklist_page.dart';
import 'package:app_2jem/views/language_selector.dart';

class JobSetupPage extends StatefulWidget {
  const JobSetupPage({super.key});

  @override
  State<JobSetupPage> createState() => _JobSetupPageState();
}

class _JobSetupPageState extends State<JobSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _storeIdController = TextEditingController();
  final _registerCountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _startJob(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final storeId = _storeIdController.text.trim();
    final int registerCount = int.tryParse(_registerCountController.text) ?? 0;

    try {
      // 1. Check Firestore for an OPEN job for this store
      final querySnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('storeId', isEqualTo: storeId)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No open job found for this Store ID. Ask Admin to create one.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Job found!
        final jobDocId = querySnapshot.docs.first.id;

        if (mounted) {
          // 2. Start job in ViewModel passing the jobDocId (3 arguments)
          Provider.of<JobViewModel>(context, listen: false)
              .startNewJob(storeId, registerCount, jobDocId);

          // 3. Navigate to checklist
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const ChecklistPage(),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('title')),
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: lang.translate('logout'),
          onPressed: () {
            userProvider.logout();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Using Icon as placeholder since we don't have network access to placehold.co for now
                const Icon(Icons.store_mall_directory,
                    size: 120, color: Color(0xFF1565C0)),
                const SizedBox(height: 32),

                // Store ID Field
                TextFormField(
                  controller: _storeIdController,
                  decoration: InputDecoration(
                    labelText: lang.translate('store_id_label'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.storefront),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? lang.translate('required')
                      : null,
                ),
                const SizedBox(height: 16),

                // Register Count Field
                TextFormField(
                  controller: _registerCountController,
                  decoration: InputDecoration(
                    labelText: lang.translate('count_label'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.point_of_sale),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return lang.translate('required');
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return lang.translate('must_be_positive');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Start Button
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _startJob(lang),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        lang.translate('start_checklist'),
                        style: const TextStyle(fontSize: 18),
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
