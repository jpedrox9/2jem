// Using 'XFile' from image_picker, but 'File' is also common.
// For this model, we'll store the path as a String, which is safer
// for serialization and state.
typedef PhotoFile = String;

/// Represents the data for a single register's pinpad swap.
class RegisterChecklist {
  final int registerNumber;
  PhotoFile? oldPinpadFront;
  PhotoFile? oldPinpadBack;
  PhotoFile? newPinpadFront;
  PhotoFile? newPinpadBack;
  PhotoFile? wholeSetNew;
  PhotoFile? saleTestInvoice;
  PhotoFile? refundTestInvoice;

  RegisterChecklist({required this.registerNumber});

  // A helper to check if all photos for this register are complete
  // Added trim() and isEmpty checks to prevent empty strings from counting as "done"
  bool get isComplete {
    bool valid(String? s) => s != null && s.trim().isNotEmpty;
    return valid(oldPinpadFront) &&
        valid(oldPinpadBack) &&
        valid(newPinpadFront) &&
        valid(newPinpadBack) &&
        valid(wholeSetNew) &&
        valid(saleTestInvoice) &&
        valid(refundTestInvoice);
  }

  // Helper to get a list of all required photo titles
  List<String> get photoRequirements => [
        'Old Pinpad: Front',
        'Old Pinpad: Back',
        'New Pinpad: Front',
        'New Pinpad: Back',
        'Whole Set (New)',
        'Sale Test Invoice',
        'Refund Test Invoice',
      ];

  Map<String, dynamic> toMap() {
    return {
      'registerNumber': registerNumber,
      'oldPinpadFront': oldPinpadFront,
      'oldPinpadBack': oldPinpadBack,
      'newPinpadFront': newPinpadFront,
      'newPinpadBack': newPinpadBack,
      'wholeSetNew': wholeSetNew,
      'saleTestInvoice': saleTestInvoice,
      'refundTestInvoice': refundTestInvoice,
    };
  }
}

/// Represents the data for the single backup pinpad.
class BackupChecklist {
  PhotoFile? backupPinpadFront;
  PhotoFile? backupPinpadBack;
  PhotoFile? backupPinpadSim;
  PhotoFile? manualButtonRegister;
  PhotoFile? transactionConfirmation;
  PhotoFile? saleInvoice;
  PhotoFile? refundInvoice;

  BackupChecklist();

  bool get isComplete {
    bool valid(String? s) => s != null && s.trim().isNotEmpty;
    return valid(backupPinpadFront) &&
        valid(backupPinpadBack) &&
        valid(backupPinpadSim) &&
        valid(manualButtonRegister) &&
        valid(transactionConfirmation) &&
        valid(saleInvoice) &&
        valid(refundInvoice);
  }

  List<String> get photoRequirements => [
        'Backup Pinpad: Front',
        'Backup Pinpad: Back',
        'Backup Pinpad: SIM Card',
      ];

  Map<String, dynamic> toMap() {
    return {
      'backupPinpadFront': backupPinpadFront,
      'backupPinpadBack': backupPinpadBack,
      'backupPinpadSim': backupPinpadSim,
      'manualButtonRegister': manualButtonRegister,
      'transactionConfirmation': transactionConfirmation,
      'saleInvoice': saleInvoice,
      'refundInvoice': refundInvoice,
    };
  }
}

/// The main data object for the entire installation job.
class InstallationJob {
  final String storeId;
  final String? technicianEmail;
  final DateTime startTime;
  final List<RegisterChecklist> registers;
  final BackupChecklist backupPinpad;

  InstallationJob(
      {required this.storeId, required int registerCount, this.technicianEmail})
      : registers = List.generate(registerCount,
            (index) => RegisterChecklist(registerNumber: index + 1)),
        backupPinpad = BackupChecklist(),
        startTime = DateTime.now();

  bool get isJobComplete {
    // Check if all registers are complete AND the backup is complete.
    if (!backupPinpad.isComplete) return false;
    for (final register in registers) {
      if (!register.isComplete) return false;
    }
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'technicianEmail': technicianEmail,
      'startTime': startTime.toIso8601String(),
      'completionTime': DateTime.now().toIso8601String(),
      'registers': registers.map((r) => r.toMap()).toList(),
      'backupPinpad': backupPinpad.toMap(),
    };
  }
}
