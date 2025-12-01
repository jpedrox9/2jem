import 'dart:io';
import 'package:flutter/foundation.dart'; // Import this for kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_2jem/providers/language_provider.dart';

class PhotoCaptureTile extends StatelessWidget {
  final String title;
  final String? photoPath;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const PhotoCaptureTile({
    super.key,
    required this.title,
    required this.photoPath,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final bool hasPhoto = photoPath != null && photoPath!.isNotEmpty;

    Widget thumbnail;
    if (hasPhoto) {
      thumbnail = Stack(
        alignment: Alignment.center,
        children: [
          // Check if running on Web OR if the path is already a network URL
          (kIsWeb ||
                  photoPath!.startsWith('http') ||
                  photoPath!.startsWith('blob:'))
              ? Image.network(
                  photoPath!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.red),
                    );
                  },
                )
              : Image.file(
                  File(photoPath!),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.red),
                    );
                  },
                ),
          Positioned(
            top: -10,
            right: -10,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
              ),
              onPressed: onClear,
            ),
          )
        ],
      );
    } else {
      thumbnail = Container(
        width: 60,
        height: 60,
        color: Colors.grey[200],
        child: const Icon(Icons.photo_camera_outlined, color: Colors.grey),
      );
    }

    return ListTile(
      leading: thumbnail,
      title: Text(title),
      subtitle: Text(
        hasPhoto ? lang.translate('photo_taken') : lang.translate('pending'),
        style: TextStyle(
          color: hasPhoto ? Colors.green : Colors.orange,
          fontStyle: FontStyle.italic,
        ),
      ),
      trailing: IconButton(
        icon: Icon(hasPhoto ? Icons.camera_alt : Icons.camera_alt),
        color: Theme.of(context).primaryColor,
        iconSize: 30,
        onPressed: onTap,
      ),
      onTap: onTap,
    );
  }
}
