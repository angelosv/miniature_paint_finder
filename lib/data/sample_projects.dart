import 'package:miniature_paint_finder/models/project.dart';

/// Sample project data for testing and demonstration
class SampleProjects {
  static final List<Project> _sampleProjects = [
    Project(
      id: '1',
      name: 'Space Marine Captain',
      description: 'Ultramarines Captain with power sword and storm bolter',
      images: [
        ProjectImage(
          id: 'img1',
          imagePath: 'assets/images/space_marine.png',
          caption: 'Base coated miniature',
          type: ProjectImageType.process,
          isMain: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ProjectImage(
          id: 'img2',
          imagePath: 'assets/images/placeholder1.jpg',
          caption: 'Armor details completed',
          type: ProjectImageType.process,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        ProjectImage(
          id: 'img3',
          imagePath: 'assets/images/placeholder2.jpg',
          caption: 'Final result',
          type: ProjectImageType.result,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
      paletteIds: ['palette1', 'palette2'],
      paints: [
        ProjectPaint(
          paintId: 'paint1',
          paintName: 'Macragge Blue',
          paintBrand: 'Citadel',
          brandAvatar: 'C',
          colorHex: '#0F3B82',
          notes: 'Base color for armor',
          addedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ProjectPaint(
          paintId: 'paint2',
          paintName: 'Leadbelcher',
          paintBrand: 'Citadel',
          brandAvatar: 'C',
          colorHex: '#888D8F',
          notes: 'Metallic parts',
          addedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        ProjectPaint(
          paintId: 'paint3',
          paintName: 'Retributor Armour',
          paintBrand: 'Citadel',
          brandAvatar: 'C',
          colorHex: '#C39E81',
          notes: 'Golden details',
          addedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      status: ProjectStatus.completed,
      userId: 'user1',
      tags: ['space-marines', 'ultramarines', 'warhammer-40k'],
    ),
    Project(
      id: '2',
      name: 'Ork Warboss',
      description: 'Big bad Ork with power klaw and custom armor',
      images: [
        ProjectImage(
          id: 'img4',
          imagePath: 'assets/images/placeholder3.jpg',
          caption: 'Primed and ready',
          type: ProjectImageType.process,
          isMain: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        ProjectImage(
          id: 'img5',
          imagePath: 'assets/images/placeholder4.jpg',
          caption: 'Green skin base',
          type: ProjectImageType.process,
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ],
      paletteIds: ['palette3'],
      paints: [
        ProjectPaint(
          paintId: 'paint4',
          paintName: 'Waaagh! Flesh',
          paintBrand: 'Citadel',
          brandAvatar: 'C',
          colorHex: '#6A7C3D',
          notes: 'Ork skin base',
          addedAt: DateTime.now().subtract(const Duration(days: 9)),
        ),
        ProjectPaint(
          paintId: 'paint5',
          paintName: 'Khorne Red',
          paintBrand: 'Citadel',
          brandAvatar: 'C',
          colorHex: '#650001',
          notes: 'Armor plates',
          addedAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      status: ProjectStatus.inProgress,
      userId: 'user1',
      tags: ['orks', 'warboss', 'warhammer-40k'],
    ),
    Project(
      id: '3',
      name: 'Elven Archer',
      description: 'Wood elf ranger with bow and forest camouflage',
      images: [
        ProjectImage(
          id: 'img6',
          imagePath: 'assets/images/placeholder5.jpg',
          caption: 'Reference image',
          type: ProjectImageType.reference,
          isMain: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      paletteIds: [],
      paints: [
        ProjectPaint(
          paintId: 'paint6',
          paintName: 'Castellan Green',
          paintBrand: 'Citadel',
          brandAvatar: 'C',
          colorHex: '#264715',
          notes: 'Cloak color',
          addedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      status: ProjectStatus.planning,
      userId: 'user1',
      tags: ['elves', 'fantasy', 'archer'],
    ),
    Project(
      id: '4',
      name: 'Dragon Miniature',
      description: 'Ancient red dragon with fire effects',
      images: [
        ProjectImage(
          id: 'img7',
          imagePath: 'assets/images/placeholder6.jpg',
          caption: 'Assembled and primed',
          type: ProjectImageType.process,
          isMain: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ],
      paletteIds: ['palette4'],
      paints: [
        ProjectPaint(
          paintId: 'paint7',
          paintName: 'Mephiston Red',
          paintBrand: 'Citadel',
          brandAvatar: 'C',
          colorHex: '#960C09',
          notes: 'Dragon scales',
          addedAt: DateTime.now().subtract(const Duration(days: 28)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now().subtract(const Duration(days: 25)),
      status: ProjectStatus.onHold,
      userId: 'user1',
      tags: ['dragon', 'fantasy', 'large-miniature'],
    ),
  ];

  /// Get user's projects
  static List<Project> getUserProjects() {
    return List.from(_sampleProjects);
  }

  /// Get all projects (only user projects for now)
  static List<Project> getAllProjects() {
    return getUserProjects();
  }

  /// Get projects by status
  static List<Project> getProjectsByStatus(ProjectStatus status) {
    return getAllProjects().where((p) => p.status == status).toList();
  }

  /// Get recent projects (last 30 days)
  static List<Project> getRecentProjects() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return getAllProjects()
        .where((p) => p.updatedAt.isAfter(thirtyDaysAgo))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Get project by ID
  static Project? getProjectById(String id) {
    try {
      return getAllProjects().firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search projects by name or tags
  static List<Project> searchProjects(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllProjects().where((project) {
      return project.name.toLowerCase().contains(lowercaseQuery) ||
          project.description?.toLowerCase().contains(lowercaseQuery) == true ||
          project.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Get projects by completion status
  static List<Project> getCompletedProjects() {
    return getProjectsByStatus(ProjectStatus.completed);
  }

  static List<Project> getInProgressProjects() {
    return getProjectsByStatus(ProjectStatus.inProgress);
  }

  static List<Project> getPlanningProjects() {
    return getProjectsByStatus(ProjectStatus.planning);
  }

  static List<Project> getOnHoldProjects() {
    return getProjectsByStatus(ProjectStatus.onHold);
  }
}
