import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_2jem/models/installation_models.dart';
import 'package:app_2jem/providers/language_provider.dart'; // Import LanguageProvider
import 'package:app_2jem/views/language_selector.dart'; // Import Selector

class MaterialManagementPage extends StatefulWidget {
  const MaterialManagementPage({super.key});

  @override
  State<MaterialManagementPage> createState() => _MaterialManagementPageState();
}

class _MaterialManagementPageState extends State<MaterialManagementPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _photoLabelController = TextEditingController();
  final List<String> _currentPhotos = [];

  void _addPhotoLabel() {
    if (_photoLabelController.text.trim().isNotEmpty) {
      setState(() {
        _currentPhotos.add(_photoLabelController.text.trim());
        _photoLabelController.clear();
      });
    }
  }

  Future<void> _saveMaterial(LanguageProvider lang) async {
    if (_nameController.text.isEmpty || _currentPhotos.isEmpty) return;

    final docRef =
        FirebaseFirestore.instance.collection('material_definitions').doc();
    final material = MaterialDefinition(
      id: docRef.id,
      name: _nameController.text.trim(),
      requiredPhotos: _currentPhotos,
    );

    await docRef.set(material.toMap());

    if (mounted) {
      setState(() {
        _nameController.clear();
        _currentPhotos.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('material_saved'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('manage_materials')),
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- CREATION FORM ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.translate('create_material_template'),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                          labelText: lang.translate('material_name')),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _photoLabelController,
                            decoration: InputDecoration(
                                labelText: lang.translate('photo_label')),
                            onSubmitted: (_) => _addPhotoLabel(),
                          ),
                        ),
                        IconButton(
                            onPressed: _addPhotoLabel,
                            icon: const Icon(Icons.add_circle)),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: _currentPhotos
                          .map((p) => Chip(
                                label: Text(p),
                                onDeleted: () =>
                                    setState(() => _currentPhotos.remove(p)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: () => _saveMaterial(lang),
                        child: Text(lang.translate('save_template'))),
                  ],
                ),
              ),
            ),
          ),

          // --- LIST OF EXISTING MATERIALS ---
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
                    final data = docs[index].data() as Map<String, dynamic>;
                    final mat = MaterialDefinition.fromMap(data);
                    return ListTile(
                      title: Text(mat.name),
                      subtitle: Text(
                          "${lang.translate('photos_label')}: ${mat.requiredPhotos.join(", ")}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance
                            .collection('material_definitions')
                            .doc(mat.id)
                            .delete(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
