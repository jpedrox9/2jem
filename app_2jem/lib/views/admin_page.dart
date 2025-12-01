import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/views/job_details_page.dart';
import 'package:app_2jem/views/language_selector.dart';
import 'package:app_2jem/views/user_management_page.dart';

class PhotoEntry {
  final String label;
  final String url;
  const PhotoEntry({required this.label, required this.url});
}

class StoreReport {
  final String storeId;
  final String date;
  final String technician;
  final String status; // Added status
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

    if (data['registers'] != null) {
      final List<dynamic> regs = data['registers'];
      for (var r in regs) {
        final regName = 'Register ${r['registerNumber']}';
        final List<PhotoEntry> entries = [];

        void addIfPresent(String? url, String label) {
          if (url != null && url.isNotEmpty) {
            entries.add(PhotoEntry(label: label, url: url));
          }
        }

        addIfPresent(r['oldPinpadFront'], 'old_front');
        addIfPresent(r['oldPinpadBack'], 'old_back');
        addIfPresent(r['newPinpadFront'], 'new_front');
        addIfPresent(r['newPinpadBack'], 'new_back');
        addIfPresent(r['wholeSetNew'], 'whole_set');
        addIfPresent(r['saleTestInvoice'], 'sale_invoice');
        addIfPresent(r['refundTestInvoice'], 'refund_invoice');

        if (entries.isNotEmpty) {
          photos[regName] = entries;
        }
      }
    }

    if (data['backupPinpad'] != null) {
      final b = data['backupPinpad'];
      final List<PhotoEntry> backupEntries = [];

      void addB(String? url, String label) {
        if (url != null && url.isNotEmpty) {
          backupEntries.add(PhotoEntry(label: label, url: url));
        }
      }

      addB(b['backupPinpadFront'], 'backup_front');
      addB(b['backupPinpadBack'], 'backup_back');
      addB(b['backupPinpadSim'], 'backup_sim');
      addB(b['manualButtonRegister'], 'backup_manual');
      addB(b['transactionConfirmation'], 'backup_trans');
      addB(b['saleInvoice'], 'backup_sale');
      addB(b['refundInvoice'], 'backup_refund');

      if (backupEntries.isNotEmpty) {
        photos['Backup Pinpad'] = backupEntries;
      }
    }

    String dateStr = 'Unknown';
    if (data['completionTime'] != null) {
      dateStr = data['completionTime'].toString().split('T')[0];
    } else if (data['startTime'] != null) {
      dateStr = "Created: " + data['startTime'].toString().split('T')[0];
    }

    return StoreReport(
      storeId: data['storeId'] ?? 'Unknown Store',
      date: dateStr,
      technician: data['technicianEmail'] ?? 'Pending',
      status: data['status'] ?? 'unknown',
      categorizedPhotos: photos,
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  // Function to open the dialog to create a new job
  void _showCreateJobDialog(BuildContext context) {
    final TextEditingController storeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Job'),
          content: TextField(
            controller: storeController,
            decoration: const InputDecoration(
              labelText: 'Store ID',
              hintText: 'e.g., 12345-US',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final storeId = storeController.text.trim();
                if (storeId.isNotEmpty) {
                  // Create the job in Firestore
                  await FirebaseFirestore.instance.collection('jobs').add({
                    'storeId': storeId,
                    'status': 'open', // Mark as open
                    'startTime': DateTime.now().toIso8601String(),
                    'technicianEmail': null, // No tech yet
                  });
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Job created for store $storeId')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('admin_dashboard')),
        actions: [
          // NEW: Button to create a job
          IconButton(
            icon: const Icon(Icons.add_business),
            tooltip: 'Create Job',
            onPressed: () => _showCreateJobDialog(context),
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
        // Order by start time so newest created jobs show up top
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

              // Visual cue for status
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
                    ? 'Status: OPEN (Waiting for Tech)'
                    : '${lang.translate('technician')}: ${report.technician}\n${lang.translate('date')}: ${report.date}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: isOpen
                    ? null
                    : () {
                        // Can only view details if not open (or enable it to see empty state)
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
