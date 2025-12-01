import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/models/installation_models.dart';
import 'package:app_2jem/view_models/job_view_model.dart';
import 'package:app_2jem/views/photo_capture_tile.dart';
import 'package:app_2jem/views/language_selector.dart';

class ChecklistPage extends StatelessWidget {
  const ChecklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Consumer<JobViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.isJobActive) {
          return Scaffold(
            appBar:
                AppBar(actions: const [LanguageSelector(), SizedBox(width: 8)]),
            body: Center(child: Text(lang.translate('error_no_job'))),
          );
        }

        final job = viewModel.currentJob!;
        final bool isJobComplete = job.isJobComplete;
        final bool isUploading = viewModel.isUploading; // Check upload status

        return Scaffold(
          appBar: AppBar(
            title: Text('${lang.translate('store')}: ${job.storeId}'),
            actions: [
              const LanguageSelector(),
              const SizedBox(width: 8),
              if (isJobComplete)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child:
                      Icon(Icons.check_circle, color: Colors.lightGreenAccent),
                )
            ],
          ),
          body: isUploading
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(lang.translate('uploading')),
                  ],
                ))
              : ListView.builder(
                  itemCount: job.registers.length + 1,
                  itemBuilder: (context, index) {
                    if (index < job.registers.length) {
                      return _buildRegisterCard(
                          context, viewModel, job.registers[index], lang);
                    } else {
                      return _buildBackupCard(
                          context, viewModel, job.backupPinpad, lang);
                    }
                  },
                ),
          floatingActionButton: !isUploading
              ? FloatingActionButton.extended(
                  onPressed: isJobComplete
                      ? () {
                          _showCompletionDialog(context, viewModel, lang);
                        }
                      : null,
                  label: Text(isJobComplete
                      ? lang.translate('submit_job')
                      : lang.translate('incomplete')),
                  icon: Icon(
                      isJobComplete ? Icons.upload : Icons.hourglass_empty),
                  backgroundColor: isJobComplete ? Colors.green : Colors.grey,
                )
              : null,
        );
      },
    );
  }

  Widget _buildRegisterCard(BuildContext context, JobViewModel viewModel,
      RegisterChecklist register, LanguageProvider lang) {
    final int registerIndex = register.registerNumber - 1;
    return Card(
      child: ExpansionTile(
        title: Text(
          '${lang.translate('register_title')} ${register.registerNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: Icon(
          register.isComplete
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: register.isComplete ? Colors.green : Colors.grey,
        ),
        children: [
          PhotoCaptureTile(
            title: lang.translate('old_front'),
            photoPath: viewModel.getPhotoPath(PhotoType.old_front,
                registerIndex: registerIndex),
            onTap: () => viewModel.capturePhoto(PhotoType.old_front,
                registerIndex: registerIndex),
            onClear: () => viewModel.clearPhoto(PhotoType.old_front,
                registerIndex: registerIndex),
          ),
          PhotoCaptureTile(
            title: lang.translate('old_back'),
            photoPath: viewModel.getPhotoPath(PhotoType.old_back,
                registerIndex: registerIndex),
            onTap: () => viewModel.capturePhoto(PhotoType.old_back,
                registerIndex: registerIndex),
            onClear: () => viewModel.clearPhoto(PhotoType.old_back,
                registerIndex: registerIndex),
          ),
          const Divider(),
          PhotoCaptureTile(
            title: lang.translate('new_front'),
            photoPath: viewModel.getPhotoPath(PhotoType.new_front,
                registerIndex: registerIndex),
            onTap: () => viewModel.capturePhoto(PhotoType.new_front,
                registerIndex: registerIndex),
            onClear: () => viewModel.clearPhoto(PhotoType.new_front,
                registerIndex: registerIndex),
          ),
          PhotoCaptureTile(
            title: lang.translate('new_back'),
            photoPath: viewModel.getPhotoPath(PhotoType.new_back,
                registerIndex: registerIndex),
            onTap: () => viewModel.capturePhoto(PhotoType.new_back,
                registerIndex: registerIndex),
            onClear: () => viewModel.clearPhoto(PhotoType.new_back,
                registerIndex: registerIndex),
          ),
          const Divider(),
          PhotoCaptureTile(
            title: lang.translate('whole_set'),
            photoPath: viewModel.getPhotoPath(PhotoType.whole_set,
                registerIndex: registerIndex),
            onTap: () => viewModel.capturePhoto(PhotoType.whole_set,
                registerIndex: registerIndex),
            onClear: () => viewModel.clearPhoto(PhotoType.whole_set,
                registerIndex: registerIndex),
          ),
          PhotoCaptureTile(
            title: lang.translate('sale_invoice'),
            photoPath: viewModel.getPhotoPath(PhotoType.sale_invoice,
                registerIndex: registerIndex),
            onTap: () => viewModel.capturePhoto(PhotoType.sale_invoice,
                registerIndex: registerIndex),
            onClear: () => viewModel.clearPhoto(PhotoType.sale_invoice,
                registerIndex: registerIndex),
          ),
          PhotoCaptureTile(
            title: lang.translate('refund_invoice'),
            photoPath: viewModel.getPhotoPath(PhotoType.refund_invoice,
                registerIndex: registerIndex),
            onTap: () => viewModel.capturePhoto(PhotoType.refund_invoice,
                registerIndex: registerIndex),
            onClear: () => viewModel.clearPhoto(PhotoType.refund_invoice,
                registerIndex: registerIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(BuildContext context, JobViewModel viewModel,
      BackupChecklist backup, LanguageProvider lang) {
    return Card(
      child: ExpansionTile(
        title: Text(
          lang.translate('backup_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: Icon(
          backup.isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: backup.isComplete ? Colors.green : Colors.grey,
        ),
        initiallyExpanded: true,
        children: [
          PhotoCaptureTile(
            title: lang.translate('backup_front'),
            photoPath: viewModel.getPhotoPath(PhotoType.backup_front),
            onTap: () => viewModel.capturePhoto(PhotoType.backup_front),
            onClear: () => viewModel.clearPhoto(PhotoType.backup_front),
          ),
          PhotoCaptureTile(
            title: lang.translate('backup_back'),
            photoPath: viewModel.getPhotoPath(PhotoType.backup_back),
            onTap: () => viewModel.capturePhoto(PhotoType.backup_back),
            onClear: () => viewModel.clearPhoto(PhotoType.backup_back),
          ),
          PhotoCaptureTile(
            title: lang.translate('backup_sim'),
            photoPath: viewModel.getPhotoPath(PhotoType.backup_sim),
            onTap: () => viewModel.capturePhoto(PhotoType.backup_sim),
            onClear: () => viewModel.clearPhoto(PhotoType.backup_sim),
          ),
          PhotoCaptureTile(
            title: lang.translate('backup_manual'),
            photoPath: viewModel.getPhotoPath(PhotoType.backup_manual),
            onTap: () => viewModel.capturePhoto(PhotoType.backup_manual),
            onClear: () => viewModel.clearPhoto(PhotoType.backup_manual),
          ),
          PhotoCaptureTile(
            title: lang.translate('backup_trans'),
            photoPath: viewModel.getPhotoPath(PhotoType.backup_trans),
            onTap: () => viewModel.capturePhoto(PhotoType.backup_trans),
            onClear: () => viewModel.clearPhoto(PhotoType.backup_trans),
          ),
          PhotoCaptureTile(
            title: lang.translate('backup_sale'),
            photoPath: viewModel.getPhotoPath(PhotoType.backup_sale),
            onTap: () => viewModel.capturePhoto(PhotoType.backup_sale),
            onClear: () => viewModel.clearPhoto(PhotoType.backup_sale),
          ),
          PhotoCaptureTile(
            title: lang.translate('backup_refund'),
            photoPath: viewModel.getPhotoPath(PhotoType.backup_refund),
            onTap: () => viewModel.capturePhoto(PhotoType.backup_refund),
            onClear: () => viewModel.clearPhoto(PhotoType.backup_refund),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(
      BuildContext context, JobViewModel viewModel, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(lang.translate('job_complete')),
          content: Text(lang.translate('job_complete_msg')),
          actions: <Widget>[
            TextButton(
              child: Text(lang.translate('cancel')),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text(lang.translate('submit')),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Trigger upload
                bool success = await viewModel.submitJob();
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(lang.translate('upload_success')),
                        backgroundColor: Colors.green));
                    Navigator.of(context).pop(); // Go back to Setup
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(lang.translate('upload_fail')),
                        backgroundColor: Colors.red));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
