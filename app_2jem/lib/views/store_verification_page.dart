import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/views/language_selector.dart';
import 'package:app_2jem/views/register_count_page.dart';

class StoreVerificationPage extends StatefulWidget {
  const StoreVerificationPage({super.key});

  @override
  State<StoreVerificationPage> createState() => _StoreVerificationPageState();
}

class _StoreVerificationPageState extends State<StoreVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _storeIdController = TextEditingController();
  bool _isVerifying = false;

  Future<void> _verifyStore(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);

    try {
      final storeId = _storeIdController.text.trim();

      // --- FIRESTORE QUERY ---
      // Look for a job with this storeId that is currently 'open'
      final querySnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('storeId', isEqualTo: storeId)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // JOB FOUND!
        final jobDocId = querySnapshot.docs.first.id;

        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => RegisterCountPage(
              storeId: storeId,
              jobDocId: jobDocId, // Pass the ID forward
            ),
          ));
        }
      } else {
        // JOB NOT FOUND
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No open job found for this Store ID. Please contact Admin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('store_setup')),
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront,
                    size: 80, color: Color(0xFF006241)),
                const SizedBox(height: 24),
                Text(
                  lang.translate('enter_store'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _storeIdController,
                  decoration: InputDecoration(
                    labelText: lang.translate('store_id_label'),
                    border: const OutlineInputBorder(),
                    helperText: lang.translate('store_id_helper'),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? lang.translate('required')
                      : null,
                ),
                const SizedBox(height: 32),
                if (_isVerifying)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: () => _verifyStore(lang),
                    icon: const Icon(Icons.check),
                    label: Text(lang.translate('verify')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
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
