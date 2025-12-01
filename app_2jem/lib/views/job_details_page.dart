import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // Add this package
import 'package:archive/archive.dart'; // Add this package
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/views/admin_page.dart';
import 'package:app_2jem/views/language_selector.dart';
// Add universal_html to pubspec.yaml for this to work cross-platform
import 'package:universal_html/html.dart' as html;

class JobDetailsPage extends StatelessWidget {
  final StoreReport report;

  const JobDetailsPage({super.key, required this.report});

  // Function to download all photos as a single ZIP file
  Future<void> _downloadAllPhotos(BuildContext context) async {
    if (kIsWeb) {
      // Notify user process has started
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating ZIP file... This may take a few seconds.'),
          duration: Duration(seconds: 4),
        ),
      );

      try {
        final archive = Archive();
        int count = 0;

        // Loop through all categories and photos
        for (var entry in report.categorizedPhotos.entries) {
          // Clean category name for filename (remove spaces/symbols)
          final categoryName = entry.key
              .replaceAll(RegExp(r'[^\w\s]+'), '')
              .replaceAll(' ', '_');

          for (var photo in entry.value) {
            try {
              // 1. Fetch image data from Firebase URL
              // This works because we configured CORS earlier!
              final response = await http.get(Uri.parse(photo.url));

              if (response.statusCode == 200) {
                // 2. Create a filename: Category_Label.jpg
                final safeLabel =
                    photo.label.replaceAll(RegExp(r'[^\w\s]+'), '_');
                final filename = '${categoryName}_$safeLabel.jpg';

                // 3. Add file to the archive
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
              const SnackBar(content: Text('No photos found to zip.')),
            );
          }
          return;
        }

        // 4. Encode the archive to ZIP format
        final encoder = ZipEncoder();
        final zipBytes = encoder.encode(archive);

        if (zipBytes != null) {
          // 5. Create a Blob from the zip bytes
          final blob = html.Blob([zipBytes], 'application/zip');

          // 6. Create a download link and click it programmatically
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', '${report.storeId}_photos.zip')
            ..click();

          // Cleanup
          html.Url.revokeObjectUrl(url);

          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ZIP file downloaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Zip error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error creating ZIP: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    } else {
      // Mobile Placeholder
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ZIP download is currently supported on Web only.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(report.storeId),
        actions: [
          // DOWNLOAD BUTTON
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download All Photos (ZIP)',
            onPressed: () => _downloadAllPhotos(context),
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
