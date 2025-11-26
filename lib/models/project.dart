/// A model representing a miniature painting project
class Project {
  /// Unique identifier for the project
  final String id;

  /// User-given name for the project
  final String name;

  /// Optional description of the project
  final String? description;

  /// List of images in the project (process photos, final results, etc.)
  final List<ProjectImage> images;

  /// List of palettes associated with this project
  final List<ProjectPalette> palettes;

  /// List of specific paints used in this project
  final List<ProjectPaint> paints;

  /// When the project was created
  final DateTime createdAt;

  /// When the project was last updated
  final DateTime updatedAt;

  /// Current status of the project
  final ProjectStatus status;

  /// User ID who created the project
  final String userId;

  /// Tags for categorization
  final List<String> tags;

  /// Main thumbnail image path
  String? get thumbnailImage {
    if (images.isEmpty) return null;
    final mainImage = images.firstWhere(
      (img) => img.isMain,
      orElse: () => images.first,
    );
    return mainImage.imagePath;
  }

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.images,
    required this.palettes,
    required this.paints,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.userId,
    this.tags = const [],
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'images': images.map((img) => img.toJson()).toList(),
      'palettes': palettes.map((palette) => palette.toJson()).toList(),
      'paints': paints.map((paint) => paint.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': _statusToSnakeCase(status),
      'userId': userId,
      'tags': List<String>.from(tags),
    };
  }

  /// Create from JSON
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      images:
          (json['images'] as List?)
              ?.map((item) => ProjectImage.fromJson(item))
              .toList() ??
          [],
      palettes:
          (json['palettes'] as List?)
              ?.map((item) => ProjectPalette.fromJson(item))
              .toList() ??
          [],
      paints:
          (json['paints'] as List?)
              ?.map((item) => ProjectPaint.fromJson(item))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
      status: _statusFromJson(json['status']),
      userId: json['user_id'] ?? json['userId'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    );
  }

  /// Create a copy with updated fields
  Project copyWith({
    String? id,
    String? name,
    String? description,
    List<ProjectImage>? images,
    List<ProjectPalette>? palettes,
    List<ProjectPaint>? paints,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProjectStatus? status,
    String? userId,
    List<String>? tags,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      images: images ?? this.images,
      palettes: palettes ?? this.palettes,
      paints: paints ?? this.paints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
    );
  }
}

/// Status of a project
enum ProjectStatus { planning, inProgress, completed, onHold }

extension ProjectStatusExtension on ProjectStatus {
  String get displayName {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.onHold:
        return 'On Hold';
    }
  }

  String get emoji {
    switch (this) {
      case ProjectStatus.planning:
        return '📋';
      case ProjectStatus.inProgress:
        return '🎨';
      case ProjectStatus.completed:
        return '✅';
      case ProjectStatus.onHold:
        return '⏸️';
    }
  }
}

/// A model representing an image in a project
class ProjectImage {
  /// Unique identifier for the item
  final String? itemId;

  /// Unique identifier for the image
  final String id;

  /// Path to the image file
  final String imagePath;

  /// Caption or description for the image
  final String? caption;

  /// Type of image (process, result, reference, etc.)
  final ProjectImageType type;

  /// Whether this is the main/thumbnail image
  final bool isMain;

  /// When the image was added
  final DateTime createdAt;

  ProjectImage({
    this.itemId,
    required this.id,
    required this.imagePath,
    this.caption,
    required this.type,
    this.isMain = false,
    required this.createdAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'id': id,
      'imagePath': imagePath,
      'caption': caption,
      'type': type.toString(),
      'isMain': isMain,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ProjectImage.fromJson(Map<String, dynamic> json) {
    return ProjectImage(
      itemId: json['itemId'] ?? '',
      id: json['id'],
      imagePath: json['imagePath'],
      caption: json['caption'],
      type: ProjectImageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ProjectImageType.process,
      ),
      isMain: json['isMain'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// A model representing a palette linked to a project
class ProjectPalette {
  /// ID of the project item (for deletion)
  final String itemId;

  /// ID of the palette
  final String paletteId;

  /// Name of the palette
  final String name;

  /// When the palette was linked to the project
  final DateTime linkedAt;

  final int? total_paints;

  ProjectPalette({
    required this.itemId,
    required this.paletteId,
    required this.name,
    required this.linkedAt,
    this.total_paints,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'paletteId': paletteId,
      'name': name,
      'linkedAt': linkedAt.toIso8601String(),
      'total_paints': total_paints,
    };
  }

  /// Create from JSON
  factory ProjectPalette.fromJson(Map<String, dynamic> json) {
    return ProjectPalette(
      itemId: json['itemId'] ?? '',
      paletteId: json['paletteId'],
      name: json['name'],
      linkedAt: DateTime.parse(json['linkedAt']),
      total_paints: json['total_paints'] ?? 0,
    );
  }
}

/// Type of project image
enum ProjectImageType {
  process, // Work in progress photos
  result, // Final result photos
  reference, // Reference images
  palette, // Color palette references
}

extension ProjectImageTypeExtension on ProjectImageType {
  String get displayName {
    switch (this) {
      case ProjectImageType.process:
        return 'Process';
      case ProjectImageType.result:
        return 'Result';
      case ProjectImageType.reference:
        return 'Reference';
      case ProjectImageType.palette:
        return 'Palette';
    }
  }

  String get icon {
    switch (this) {
      case ProjectImageType.process:
        return '🎨';
      case ProjectImageType.result:
        return '🏆';
      case ProjectImageType.reference:
        return '📸';
      case ProjectImageType.palette:
        return '🎭';
    }
  }
}

/// A model representing a paint used in a project
class ProjectPaint {
  String? itemId;

  /// ID of the paint
  final String paintId;

  /// Name of the paint
  final String paintName;

  /// Brand of the paint
  final String paintBrand;

  /// Brand avatar/letter
  final String brandAvatar;

  /// Hex color of the paint
  final String colorHex;

  /// Optional notes about how this paint was used
  final String? notes;

  /// When this paint was added to the project
  final DateTime addedAt;

  ProjectPaint({
    this.itemId,
    required this.paintId,
    required this.paintName,
    required this.paintBrand,
    required this.brandAvatar,
    required this.colorHex,
    this.notes,
    required this.addedAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'paintId': paintId,
      'paintName': paintName,
      'paintBrand': paintBrand,
      'brandAvatar': brandAvatar,
      'colorHex': colorHex,
      'notes': notes,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ProjectPaint.fromJson(Map<String, dynamic> json) {
    return ProjectPaint(
      itemId: json['itemId'],
      paintId: json['paintId'],
      paintName: json['paintName'],
      paintBrand: json['paintBrand'],
      brandAvatar: json['brandAvatar'],
      colorHex: json['colorHex'],
      notes: json['notes'],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }
}

/// Helper functions for status conversion
String _statusToSnakeCase(ProjectStatus status) {
  switch (status) {
    case ProjectStatus.planning:
      return 'planning';
    case ProjectStatus.inProgress:
      return 'in_progress';
    case ProjectStatus.completed:
      return 'completed';
    case ProjectStatus.onHold:
      return 'on_hold';
  }
}

ProjectStatus _statusFromJson(dynamic statusValue) {
  if (statusValue == null) return ProjectStatus.planning;

  final statusString = statusValue.toString().toLowerCase().trim();

  switch (statusString) {
    case 'planning':
      return ProjectStatus.planning;
    case 'in_progress':
      return ProjectStatus.inProgress;
    case 'completed':
      return ProjectStatus.completed;
    case 'on_hold':
      return ProjectStatus.onHold;
    default:
      // Fallback for old format or unknown values
      return ProjectStatus.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == statusString,
        orElse: () => ProjectStatus.planning,
      );
  }
}
