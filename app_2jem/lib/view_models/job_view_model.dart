import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // CHANGED: Now loads the job items directly from Firestore
  Future<void> startNewJob(String storeId, String jobDocId) async {
    _currentJobDocId = jobDocId;
    final String techEmail = _auth.currentUser?.email ?? "Unknown Tech";

    try {
      // Fetch the existing job structure defined by Admin
      final doc = await _firestore.collection('jobs').doc(jobDocId).get();
      final data = doc.data() as Map<String, dynamic>;

      // Parse the dynamic items list
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
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading job: $e");
    }
  }

  // CHANGED: Now identifies photo by Item ID and Label (Strings), not Enum
  Future<void> capturePhoto(String itemId, String photoLabel) async {
    if (_currentJob == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (image == null) return;

      // Find the item and update the specific photo
      final itemIndex = _currentJob!.items.indexWhere((i) => i.id == itemId);
      if (itemIndex != -1) {
        _currentJob!.items[itemIndex].photos[photoLabel] = image.path;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error capturing photo: $e");
    }
  }

  String? getPhotoPath(String itemId, String photoLabel) {
    if (_currentJob == null) return null;
    final item = _currentJob!.items.firstWhere((i) => i.id == itemId,
        orElse: () => _currentJob!.items[0]); // fallback unsafe but ok for now
    return item.photos[photoLabel];
  }

  void clearPhoto(String itemId, String photoLabel) {
    if (_currentJob == null) return;
    final itemIndex = _currentJob!.items.indexWhere((i) => i.id == itemId);
    if (itemIndex != -1) {
      _currentJob!.items[itemIndex].photos.remove(photoLabel);
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

    // Loop through dynamic items and photos
    for (var item in _currentJob!.items) {
      for (var label in item.requiredPhotos) {
        if (item.photos.containsKey(label)) {
          // Generate a safe filename from item name and label
          final safeName = "${item.name}_$label"
              .replaceAll(RegExp(r'[^\w\s]+'), '')
              .replaceAll(' ', '_');
          final url = await uploadOne(item.photos[label], safeName);
          item.photos[label] = url; // Update local map with URL
        }
      }
    }
  }
}
