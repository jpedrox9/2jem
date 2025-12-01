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
        final bool isUploading = viewModel.isUploading;

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
                  itemCount: job.items.length,
                  itemBuilder: (context, index) {
                    return _buildDynamicItemCard(
                        context, viewModel, job.items[index], lang);
                  },
                ),
          floatingActionButton: !isUploading
              ? FloatingActionButton.extended(
                  onPressed: isJobComplete
                      ? () => _showCompletionDialog(context, viewModel, lang)
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

  Widget _buildDynamicItemCard(BuildContext context, JobViewModel viewModel,
      JobItem item, LanguageProvider lang) {
    return Card(
      child: ExpansionTile(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: Icon(
          item.isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: item.isComplete ? Colors.green : Colors.grey,
        ),
        initiallyExpanded: true,
        children: item.requiredPhotos.map((label) {
          return PhotoCaptureTile(
            title: lang.translate(label) == label
                ? label
                : lang.translate(
                    label), // Use translation if available, else raw label
            photoPath: viewModel.getPhotoPath(item.id, label),
            onTap: () => viewModel.capturePhoto(item.id, label),
            onClear: () => viewModel.clearPhoto(item.id, label),
          );
        }).toList(),
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
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(lang.translate('submit')),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                bool success = await viewModel.submitJob();
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(lang.translate('upload_success')),
                        backgroundColor: Colors.green));
                    Navigator.of(context).pop(); // Back to setup
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
