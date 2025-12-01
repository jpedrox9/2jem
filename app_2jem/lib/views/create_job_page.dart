import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_2jem/models/installation_models.dart';
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/views/language_selector.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final TextEditingController _storeController = TextEditingController();
  final List<JobItem> _selectedItems = [];

  void _addItem(MaterialDefinition template) {
    setState(() {
      int count =
          _selectedItems.where((i) => i.name.startsWith(template.name)).length;

      _selectedItems.add(JobItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: "${template.name} ${count + 1}",
        requiredPhotos: template.requiredPhotos,
      ));
    });
  }

  Future<void> _createJob(LanguageProvider lang) async {
    if (_storeController.text.isEmpty || _selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('enter_store_items'))));
      return;
    }

    final jobData = {
      'storeId': _storeController.text.trim(),
      'status': 'open',
      'startTime': DateTime.now().toIso8601String(),
      'technicianEmail': null,
      'items': _selectedItems.map((i) => i.toMap()).toList(),
    };

    await FirebaseFirestore.instance.collection('jobs').add(jobData);

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.translate('job_created'))));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('create_new_job')),
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // --- LEFT: SELECTION PANEL ---
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _storeController,
                    decoration: InputDecoration(
                        labelText: lang.translate('store_id_label'),
                        border: const OutlineInputBorder()),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(lang.translate('available_materials'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('material_definitions')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final mat = MaterialDefinition.fromMap(
                              docs[index].data() as Map<String, dynamic>);
                          return ListTile(
                            title: Text(mat.name),
                            trailing: const Icon(Icons.add),
                            onTap: () => _addItem(mat),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          // --- RIGHT: JOB PREVIEW ---
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(lang.translate('job_contents'),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = _selectedItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                              "${lang.translate('requires')}: ${item.requiredPhotos.join(', ')}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () =>
                                setState(() => _selectedItems.removeAt(index)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _createJob(lang),
                      child: Text(lang.translate('confirm_create_job')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
