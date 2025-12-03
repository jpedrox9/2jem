import 'dart:io'; // Required for File writing on native
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart'; // Required for finding save paths
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/views/admin_page.dart';
import 'package:app_2jem/views/language_selector.dart';
import 'package:universal_html/html.dart' as html;

class JobDetailsPage extends StatelessWidget {
  final StoreReport report;

  const JobDetailsPage({super.key, required this.report});

  Future<void> _downloadAllPhotos(
      BuildContext context, LanguageProvider lang) async {
    // Notify user process has started
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang.translate('zip_generating')),
        duration: const Duration(seconds: 4),
      ),
    );

    try {
      // 1. GENERATE ZIP (Common for ALL platforms)
      final archive = Archive();
      int count = 0;

      for (var entry in report.categorizedPhotos.entries) {
        final categoryName =
            entry.key.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');

        for (var photo in entry.value) {
          try {
            final response = await http.get(Uri.parse(photo.url));
            if (response.statusCode == 200) {
              final safeLabel =
                  photo.label.replaceAll(RegExp(r'[^\w\s]+'), '_');
              final filename = '${categoryName}_$safeLabel.jpg';
              final file = ArchiveFile(
                  filename, response.bodyBytes.length, response.bodyBytes);
              archive.addFile(file);
              count++;
            }
          } catch (e) {
            debugPrint("Failed to download ${photo.url}: $e");
          }
        }
      }

      if (count == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lang.translate('zip_no_photos'))),
          );
        }
        return;
      }

      final encoder = ZipEncoder();
      final zipBytes = encoder.encode(archive);

      if (zipBytes == null) {
        throw Exception("Failed to encode ZIP");
      }

      // 2. SAVE FILE (Platform Specific)
      if (kIsWeb) {
        // WEB: Trigger browser download
        final blob = html.Blob([zipBytes], 'application/zip');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', '${report.storeId}_photos.zip')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // NATIVE: Determine correct Downloads folder
        Directory? directory;

        if (Platform.isAndroid) {
          // Android specific: Go to the public Download folder
          directory = Directory('/storage/emulated/0/Download');
        } else {
          // Windows/Linux/Mac: Use the OS standard Downloads folder
          directory = await getDownloadsDirectory();
        }

        // Fallback: If downloads folder is null or doesn't exist (rare), use Documents
        if (directory == null || !await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
        }

        final String filePath =
            '${directory.path}/${report.storeId}_photos.zip';
        final File file = File(filePath);
        await file.writeAsBytes(zipBytes);

        if (context.mounted) {
          // Show the path to the user
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                    title: const Text("Download Complete"),
                    content: Text("File saved to:\n$filePath"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"))
                    ],
                  ));
        }
      }

      // Success SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.translate('zip_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Zip error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${lang.translate('zip_error')} $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(report.storeId),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download All Photos (ZIP)',
            onPressed: () => _downloadAllPhotos(context, lang),
          ),
          const LanguageSelector(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${lang.translate('technician')}: ${report.technician}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${lang.translate('date')}: ${report.date}',
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...report.categorizedPhotos.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    entry.key.startsWith('Register')
                        ? entry.key
                        : lang.translate(entry.key),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: const Icon(Icons.folder_open, color: Colors.green),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _buildPhotoGrid(context, entry.value, lang),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(
      BuildContext context, List<PhotoEntry> photos, LanguageProvider lang) {
    if (photos.isEmpty)
      return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(lang.translate('no_photos')));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return InkWell(
          onTap: () => _showFullScreenImage(context, photo.url),
          child: GridTile(
            footer: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(lang.translate(photo.label),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  maxLines: 1),
            ),
            child: Image.network(photo.url, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
        context: context,
        builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: InteractiveViewer(child: Image.network(url))));
  }
}
