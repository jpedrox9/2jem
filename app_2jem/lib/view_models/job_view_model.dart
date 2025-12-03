import 'dart:convert'; // Required for JSON encoding
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart'; // Required for finding save paths
import 'package:app_2jem/models/installation_models.dart';

class JobViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  InstallationJob? _currentJob;
  String? _currentJobDocId;
  bool _isUploading = false;

  InstallationJob? get currentJob => _currentJob;
  bool get isJobActive => _currentJob != null;
  bool get isUploading => _isUploading;

  Future<void> startNewJob(String storeId, String jobDocId) async {
    _currentJobDocId = jobDocId;
    final String techEmail = _auth.currentUser?.email ?? "Unknown Tech";

    try {
      final doc = await _firestore.collection('jobs').doc(jobDocId).get();
      final data = doc.data() as Map<String, dynamic>;

      List<JobItem> loadedItems = [];
      if (data['items'] != null) {
        loadedItems =
            (data['items'] as List).map((x) => JobItem.fromMap(x)).toList();
      }

      _currentJob = InstallationJob(
        storeId: storeId,
        items: loadedItems,
        technicianEmail: techEmail,
      );

      // NEW: Try to restore local draft if one exists
      if (!kIsWeb) {
        await _restoreLocalDraft();
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error loading job: $e");
    }
  }

  Future<void> capturePhoto(String itemId, String photoLabel) async {
    if (_currentJob == null) return;

    try {
      ImageSource source = ImageSource.camera;
      if (!kIsWeb && Platform.isWindows) {
        source = ImageSource.gallery;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (image == null) return;

      String finalPath = image.path;

      // NEW: Save the image to a permanent local location so it survives app restart
      if (!kIsWeb) {
        final savedFile = await _saveImageLocally(image);
        finalPath = savedFile.path;
      }

      final itemIndex = _currentJob!.items.indexWhere((i) => i.id == itemId);
      if (itemIndex != -1) {
        _currentJob!.items[itemIndex].photos[photoLabel] = finalPath;

        // NEW: Update the draft JSON
        if (!kIsWeb) {
          await _updateDraftJson();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error capturing photo: $e");
    }
  }

  String? getPhotoPath(String itemId, String photoLabel) {
    if (_currentJob == null) return null;
    final item = _currentJob!.items
        .firstWhere((i) => i.id == itemId, orElse: () => _currentJob!.items[0]);
    return item.photos[photoLabel];
  }

  void clearPhoto(String itemId, String photoLabel) {
    if (_currentJob == null) return;
    final itemIndex = _currentJob!.items.indexWhere((i) => i.id == itemId);
    if (itemIndex != -1) {
      _currentJob!.items[itemIndex].photos.remove(photoLabel);

      // NEW: Update JSON to reflect removal
      if (!kIsWeb) _updateDraftJson();

      notifyListeners();
    }
  }

  Future<bool> submitJob() async {
    if (_currentJob == null ||
        !_currentJob!.isJobComplete ||
        _currentJobDocId == null) return false;

    _isUploading = true;
    notifyListeners();

    try {
      await _uploadAllPhotos();

      final jobData = _currentJob!.toMap();
      jobData['status'] = 'completed';

      await _firestore.collection('jobs').doc(_currentJobDocId).update(jobData);

      // NEW: Clean up local draft files after success
      if (!kIsWeb) {
        await _clearLocalDraft();
      }

      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _uploadAllPhotos() async {
    final String jobId =
        "${_currentJob!.storeId}_${DateTime.now().millisecondsSinceEpoch}";

    Future<String> uploadOne(String? localPath, String name) async {
      if (localPath == null || localPath.isEmpty) return "";
      if (localPath.startsWith('http')) return localPath;

      try {
        final ref = _storage.ref().child('job_photos/$jobId/$name.jpg');

        if (kIsWeb) {
          await ref.putData(await XFile(localPath).readAsBytes(),
              SettableMetadata(contentType: 'image/jpeg'));
        } else {
          await ref.putFile(File(localPath));
        }
        return await ref.getDownloadURL();
      } catch (e) {
        debugPrint("Failed to upload $name: $e");
        return "";
      }
    }

    for (var item in _currentJob!.items) {
      for (var label in item.requiredPhotos) {
        if (item.photos.containsKey(label)) {
          final safeName = "${item.name}_$label"
              .replaceAll(RegExp(r'[^\w\s]+'), '')
              .replaceAll(' ', '_');
          final url = await uploadOne(item.photos[label], safeName);
          item.photos[label] = url;
        }
      }
    }
  }

  // =========================================================
  // LOCAL DRAFT LOGIC (OFFLINE SAVE)
  // =========================================================

  /// Gets the directory specific to this job ID
  Future<Directory> _getJobDraftDir() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final jobDir =
        Directory('${appDocDir.path}/job_drafts/${_currentJobDocId!}');
    if (!await jobDir.exists()) {
      await jobDir.create(recursive: true);
    }
    return jobDir;
  }

  /// Copies a picked image to the permanent draft folder
  Future<File> _saveImageLocally(XFile image) async {
    final jobDir = await _getJobDraftDir();
    // Create a unique filename based on time
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(image.path).copy('${jobDir.path}/$fileName');
    return savedImage;
  }

  /// Saves the current structure (mapping of items -> photos) to JSON
  Future<void> _updateDraftJson() async {
    if (_currentJob == null || _currentJobDocId == null) return;

    try {
      final jobDir = await _getJobDraftDir();
      final jsonFile = File('${jobDir.path}/draft_data.json');

      // Create a map of ItemID -> { PhotoLabel: PhotoPath }
      final Map<String, Map<String, String>> draftData = {};

      for (var item in _currentJob!.items) {
        if (item.photos.isNotEmpty) {
          draftData[item.id] = item.photos;
        }
      }

      await jsonFile.writeAsString(json.encode(draftData));
    } catch (e) {
      debugPrint("Error saving draft JSON: $e");
    }
  }

  /// Restores photos from JSON if available
  Future<void> _restoreLocalDraft() async {
    if (_currentJobDocId == null) return;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      // Check if directory exists directly to avoid creating it unnecessarily
      final jobDir =
          Directory('${appDocDir.path}/job_drafts/$_currentJobDocId');
      final jsonFile = File('${jobDir.path}/draft_data.json');

      if (!await jsonFile.exists()) return;

      final content = await jsonFile.readAsString();
      final Map<String, dynamic> draftData = json.decode(content);

      // Iterate through our loaded items and fill in the photos
      for (var item in _currentJob!.items) {
        if (draftData.containsKey(item.id)) {
          final savedPhotos = Map<String, String>.from(draftData[item.id]);

          // Verify files still exist before adding them
          savedPhotos.forEach((label, path) {
            if (File(path).existsSync()) {
              item.photos[label] = path;
            }
          });
        }
      }
      debugPrint("Draft restored successfully.");
    } catch (e) {
      debugPrint("Error restoring draft: $e");
    }
  }

  /// Deletes the draft folder after successful upload
  Future<void> _clearLocalDraft() async {
    if (_currentJobDocId == null) return;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final jobDir =
          Directory('${appDocDir.path}/job_drafts/$_currentJobDocId');

      if (await jobDir.exists()) {
        await jobDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint("Error clearing local draft: $e");
    }
  }
}
