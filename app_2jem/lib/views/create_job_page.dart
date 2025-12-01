import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_2jem/models/installation_models.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final TextEditingController _storeController = TextEditingController();

  // This list holds what we will put into the job
  final List<JobItem> _selectedItems = [];

  void _addItem(MaterialDefinition template) {
    setState(() {
      // Generate a unique name (e.g., Register 1, Register 2)
      int count =
          _selectedItems.where((i) => i.name.startsWith(template.name)).length;

      _selectedItems.add(JobItem(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(), // Simple unique ID
        name: "${template.name} ${count + 1}",
        requiredPhotos: template.requiredPhotos,
      ));
    });
  }

  Future<void> _createJob() async {
    if (_storeController.text.isEmpty || _selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter Store ID and add items.')));
      return;
    }

    final jobData = {
      'storeId': _storeController.text.trim(),
      'status': 'open',
      'startTime': DateTime.now().toIso8601String(),
      'technicianEmail': null,
      // Save the list of items as Maps
      'items': _selectedItems.map((i) => i.toMap()).toList(),
    };

    await FirebaseFirestore.instance.collection('jobs').add(jobData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job Created Successfully')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Job')),
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
                    decoration: const InputDecoration(
                        labelText: 'Store ID', border: OutlineInputBorder()),
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Available Materials (Tap to Add)",
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Job Contents",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                              "Requires: ${item.requiredPhotos.join(', ')}"),
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
                      onPressed: _createJob,
                      child: const Text("CONFIRM & CREATE JOB"),
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
