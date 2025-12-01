import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:app_2jem/models/installation_models.dart';

enum PhotoType {
  old_front,
  old_back,
  new_front,
  new_back,
  whole_set,
  sale_invoice,
  refund_invoice,
  backup_front,
  backup_back,
  backup_sim,
  backup_manual,
  backup_trans,
  backup_sale,
  backup_refund
}

class JobViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add Auth instance

  InstallationJob? _currentJob;
  String? _currentJobDocId;
  bool _isUploading = false;

  InstallationJob? get currentJob => _currentJob;
  bool get isJobActive => _currentJob != null;
  bool get isUploading => _isUploading;

  void startNewJob(String storeId, int registerCount, String jobDocId) {
    _currentJobDocId = jobDocId;

    // Get current user email, fallback to 'Unknown Tech' if null
    final String techEmail = _auth.currentUser?.email ?? "Unknown Tech";

    _currentJob = InstallationJob(
      storeId: storeId,
      registerCount: registerCount,
      technicianEmail: techEmail, // Use the real email
    );
    notifyListeners();
  }

  // ... rest of the file remains exactly the same ...
  Future<void> capturePhoto(PhotoType type, {int? registerIndex}) async {
    if (_currentJob == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (image == null) return;

      final String photoPath = image.path;

      if (registerIndex != null) {
        _updateRegisterPhoto(registerIndex, type, photoPath);
      } else {
        _updateBackupPhoto(type, photoPath);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error capturing photo: $e");
    }
  }

  void _updateRegisterPhoto(int index, PhotoType type, String? path) {
    final register = _currentJob!.registers[index];
    switch (type) {
      case PhotoType.old_front:
        register.oldPinpadFront = path;
        break;
      case PhotoType.old_back:
        register.oldPinpadBack = path;
        break;
      case PhotoType.new_front:
        register.newPinpadFront = path;
        break;
      case PhotoType.new_back:
        register.newPinpadBack = path;
        break;
      case PhotoType.whole_set:
        register.wholeSetNew = path;
        break;
      case PhotoType.sale_invoice:
        register.saleTestInvoice = path;
        break;
      case PhotoType.refund_invoice:
        register.refundTestInvoice = path;
        break;
      default:
        break;
    }
  }

  void _updateBackupPhoto(PhotoType type, String? path) {
    final backup = _currentJob!.backupPinpad;
    switch (type) {
      case PhotoType.backup_front:
        backup.backupPinpadFront = path;
        break;
      case PhotoType.backup_back:
        backup.backupPinpadBack = path;
        break;
      case PhotoType.backup_sim:
        backup.backupPinpadSim = path;
        break;
      case PhotoType.backup_manual:
        backup.manualButtonRegister = path;
        break;
      case PhotoType.backup_trans:
        backup.transactionConfirmation = path;
        break;
      case PhotoType.backup_sale:
        backup.saleInvoice = path;
        break;
      case PhotoType.backup_refund:
        backup.refundInvoice = path;
        break;
      default:
        break;
    }
  }

  String? getPhotoPath(PhotoType type, {int? registerIndex}) {
    if (_currentJob == null) return null;

    if (registerIndex != null) {
      final register = _currentJob!.registers[registerIndex];
      switch (type) {
        case PhotoType.old_front:
          return register.oldPinpadFront;
        case PhotoType.old_back:
          return register.oldPinpadBack;
        case PhotoType.new_front:
          return register.newPinpadFront;
        case PhotoType.new_back:
          return register.newPinpadBack;
        case PhotoType.whole_set:
          return register.wholeSetNew;
        case PhotoType.sale_invoice:
          return register.saleTestInvoice;
        case PhotoType.refund_invoice:
          return register.refundTestInvoice;
        default:
          return null;
      }
    } else {
      final backup = _currentJob!.backupPinpad;
      switch (type) {
        case PhotoType.backup_front:
          return backup.backupPinpadFront;
        case PhotoType.backup_back:
          return backup.backupPinpadBack;
        case PhotoType.backup_sim:
          return backup.backupPinpadSim;
        case PhotoType.backup_manual:
          return backup.manualButtonRegister;
        case PhotoType.backup_trans:
          return backup.transactionConfirmation;
        case PhotoType.backup_sale:
          return backup.saleInvoice;
        case PhotoType.backup_refund:
          return backup.refundInvoice;
        default:
          return null;
      }
    }
  }

  void clearPhoto(PhotoType type, {int? registerIndex}) {
    if (registerIndex != null) {
      _updateRegisterPhoto(registerIndex, type, null);
    } else {
      _updateBackupPhoto(type, null);
    }
    notifyListeners();
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
        throw Exception("Photo upload failed");
      }
    }

    for (var reg in _currentJob!.registers) {
      reg.oldPinpadFront = await uploadOne(
          reg.oldPinpadFront, 'reg${reg.registerNumber}_old_front');
      reg.oldPinpadBack = await uploadOne(
          reg.oldPinpadBack, 'reg${reg.registerNumber}_old_back');
      reg.newPinpadFront = await uploadOne(
          reg.newPinpadFront, 'reg${reg.registerNumber}_new_front');
      reg.newPinpadBack = await uploadOne(
          reg.newPinpadBack, 'reg${reg.registerNumber}_new_back');
      reg.wholeSetNew = await uploadOne(
          reg.wholeSetNew, 'reg${reg.registerNumber}_whole_set');
      reg.saleTestInvoice =
          await uploadOne(reg.saleTestInvoice, 'reg${reg.registerNumber}_sale');
      reg.refundTestInvoice = await uploadOne(
          reg.refundTestInvoice, 'reg${reg.registerNumber}_refund');
    }

    final bk = _currentJob!.backupPinpad;
    bk.backupPinpadFront =
        await uploadOne(bk.backupPinpadFront, 'backup_front');
    bk.backupPinpadBack = await uploadOne(bk.backupPinpadBack, 'backup_back');
    bk.backupPinpadSim = await uploadOne(bk.backupPinpadSim, 'backup_sim');
    bk.manualButtonRegister =
        await uploadOne(bk.manualButtonRegister, 'backup_manual');
    bk.transactionConfirmation =
        await uploadOne(bk.transactionConfirmation, 'backup_trans');
    bk.saleInvoice = await uploadOne(bk.saleInvoice, 'backup_sale');
    bk.refundInvoice = await uploadOne(bk.refundInvoice, 'backup_refund');
  }
}
