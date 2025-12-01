import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/view_models/job_view_model.dart';
import 'package:app_2jem/views/checklist_page.dart';
import 'package:app_2jem/views/language_selector.dart';

class RegisterCountPage extends StatefulWidget {
  final String storeId;
  final String jobDocId; // Added jobDocId

  const RegisterCountPage({
    super.key,
    required this.storeId,
    required this.jobDocId, // Required in constructor
  });

  @override
  State<RegisterCountPage> createState() => _RegisterCountPageState();
}

class _RegisterCountPageState extends State<RegisterCountPage> {
  final _formKey = GlobalKey<FormState>();
  final _registerCountController = TextEditingController();

  void _startJob(LanguageProvider lang) {
    if (_formKey.currentState!.validate()) {
      final registerCount = int.tryParse(_registerCountController.text) ?? 0;

      if (registerCount > 0) {
        // Now calling startNewJob with the correct 3 arguments
        Provider.of<JobViewModel>(context, listen: false)
            .startNewJob(widget.storeId, registerCount, widget.jobDocId);

        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const ChecklistPage(),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('register_setup')),
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${lang.translate('store')}: ${widget.storeId}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Text(
                  lang.translate('how_many_registers'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
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
                ElevatedButton.icon(
                  onPressed: () => _startJob(lang),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(lang.translate('start_checklist')),
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
