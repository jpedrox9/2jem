/// Defines a "Type" of work (e.g., "Register Installation", "Router Swap")
/// This is the template the Admin creates.
class MaterialDefinition {
  final String id;
  final String name;
  final List<String> requiredPhotos;

  MaterialDefinition({
    required this.id,
    required this.name,
    required this.requiredPhotos,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'requiredPhotos': requiredPhotos,
    };
  }

  factory MaterialDefinition.fromMap(Map<String, dynamic> map) {
    return MaterialDefinition(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      requiredPhotos: List<String>.from(map['requiredPhotos'] ?? []),
    );
  }
}

/// Represents a specific item in a job (e.g., "Register #1" based on "Register Installation" template)
class JobItem {
  final String id; // Unique ID for this specific item instance
  final String name; // Display name (e.g., "Register 1")
  final List<String> requiredPhotos; // Copied from template
  final Map<String, String> photos; // Map: PhotoLabel -> Url/Path

  JobItem({
    required this.id,
    required this.name,
    required this.requiredPhotos,
    Map<String, String>? photos,
  }) : photos = photos ?? {};

  bool get isComplete {
    // Check if every required label exists in the photos map and is not empty
    for (var label in requiredPhotos) {
      if (!photos.containsKey(label) || photos[label]!.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'requiredPhotos': requiredPhotos,
      'photos': photos,
    };
  }

  factory JobItem.fromMap(Map<String, dynamic> map) {
    return JobItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      requiredPhotos: List<String>.from(map['requiredPhotos'] ?? []),
      photos: Map<String, String>.from(map['photos'] ?? {}),
    );
  }
}

/// The main Job object
class InstallationJob {
  final String storeId;
  final String? technicianEmail;
  final DateTime startTime;
  final List<JobItem> items; // Dynamic list of work items

  InstallationJob({
    required this.storeId,
    required this.items,
    this.technicianEmail,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  bool get isJobComplete {
    if (items.isEmpty) return false;
    for (final item in items) {
      if (!item.isComplete) return false;
    }
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'technicianEmail': technicianEmail,
      'startTime': startTime.toIso8601String(),
      'completionTime': DateTime.now().toIso8601String(),
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}
