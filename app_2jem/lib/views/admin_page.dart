import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/views/job_details_page.dart';
import 'package:app_2jem/views/language_selector.dart';
import 'package:app_2jem/views/user_management_page.dart';
import 'package:app_2jem/views/material_management_page.dart';
import 'package:app_2jem/views/create_job_page.dart';

class PhotoEntry {
  final String label;
  final String url;
  const PhotoEntry({required this.label, required this.url});
}

class StoreReport {
  final String storeId;
  final String date;
  final String technician;
  final String status;
  final Map<String, List<PhotoEntry>> categorizedPhotos;

  const StoreReport({
    required this.storeId,
    required this.date,
    required this.technician,
    required this.status,
    required this.categorizedPhotos,
  });

  factory StoreReport.fromMap(Map<String, dynamic> data) {
    final Map<String, List<PhotoEntry>> photos = {};

    if (data['items'] != null) {
      for (var item in data['items']) {
        final itemName = item['name'] ?? 'Unknown Item';
        final List<PhotoEntry> entries = [];
        final Map<String, dynamic> itemPhotos = item['photos'] ?? {};

        itemPhotos.forEach((label, url) {
          if (url != null && url.toString().isNotEmpty) {
            entries.add(PhotoEntry(label: label, url: url));
          }
        });

        if (entries.isNotEmpty) {
          photos[itemName] = entries;
        }
      }
    }

    String dateStr = 'Unknown';
    if (data['completionTime'] != null) {
      dateStr = data['completionTime'].toString().split('T')[0];
    } else if (data['startTime'] != null) {
      dateStr = "Open: " + data['startTime'].toString().split('T')[0];
    }

    return StoreReport(
      storeId: data['storeId'] ?? 'Unknown',
      date: dateStr,
      technician: data['technicianEmail'] ?? 'Pending',
      status: data['status'] ?? 'unknown',
      categorizedPhotos: photos,
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('admin_dashboard')),
        actions: [
          // NEW: Manage Materials Button
          IconButton(
            icon: const Icon(Icons.build_circle),
            tooltip: 'Manage Materials',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const MaterialManagementPage())),
          ),
          // NEW: Create Job Button (Page)
          IconButton(
            icon: const Icon(Icons.add_business),
            tooltip: 'Create Job',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CreateJobPage())),
          ),
          const LanguageSelector(),
          const SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No jobs found.'));

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final report = StoreReport.fromMap(data);
              final isOpen = report.status == 'open';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isOpen ? Colors.orange : Colors.green,
                  child: Icon(isOpen ? Icons.pending : Icons.check,
                      color: Colors.white),
                ),
                title: Text(report.storeId,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(isOpen
                    ? lang.translate('status_open')
                    : '${lang.translate('technician')}: ${report.technician}\n${lang.translate('date')}: ${report.date}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: isOpen
                    ? null
                    : () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                JobDetailsPage(report: report)));
                      },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const UserManagementPage()));
        },
        label: Text(lang.translate('manage_users')),
        icon: const Icon(Icons.manage_accounts),
      ),
    );
  }
}
