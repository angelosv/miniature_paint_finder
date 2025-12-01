import 'package:miniature_paint_finder/models/project.dart';
import 'package:miniature_paint_finder/models/paint.dart';

/// Mock data for testing
class MockData {
  
  /// Test user credentials
  static const String testEmail = 'test@miniaturepaintfinder.com';
  static const String testPassword = 'TestPassword123!';
  static const String testUserName = 'Test User';

  /// Sample project data
  static List<Project> get sampleProjects => [
    Project(
      id: 'test-project-1',
      name: 'Space Marine Captain',
      description: 'Ultramarines captain with power sword',
      images: [],
      palettes: [],
      paints: [],
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
      status: ProjectStatus.inProgress,
      userId: 'test-user',
      tags: ['warhammer', 'space-marines', 'ultramarines'],
    ),
    Project(
      id: 'test-project-2',
      name: 'Ork Warboss',
      description: 'Big green mean fighting machine',
      images: [],
      palettes: [],
      paints: [],
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      updatedAt: DateTime.now().subtract(Duration(days: 3)),
      status: ProjectStatus.planning,
      userId: 'test-user',
      tags: ['warhammer', 'orks'],
    ),
    Project(
      id: 'test-project-3',
      name: 'Elven Archer',
      description: 'High elf archer with longbow',
      images: [],
      palettes: [],
      paints: [],
      createdAt: DateTime.now().subtract(Duration(days: 15)),
      updatedAt: DateTime.now().subtract(Duration(days: 15)),
      status: ProjectStatus.completed,
      userId: 'test-user',
      tags: ['fantasy', 'elves'],
    ),
  ];

  /// Sample paint data
  static List<Paint> get samplePaints => [
    Paint(
      id: 'test-paint-1',
      name: 'Macragge Blue',
      hex: '#0F3D7C',
      set: 'Base',
      code: 'M001',
      r: 15,
      g: 61,
      b: 124,
      brand: 'Citadel',
      category: 'Base',
      isMetallic: false,
      isTransparent: false,
    ),
    Paint(
      id: 'test-paint-2',
      name: 'Leadbelcher',
      hex: '#888D8F',
      set: 'Base',
      code: 'M002',
      r: 136,
      g: 141,
      b: 143,
      brand: 'Citadel',
      category: 'Base',
      isMetallic: true,
      isTransparent: false,
    ),
    Paint(
      id: 'test-paint-3',
      name: 'Agrax Earthshade',
      hex: '#A0845C',
      set: 'Shade',
      code: 'S001',
      r: 160,
      g: 132,
      b: 92,
      brand: 'Citadel',
      category: 'Shade',
      isMetallic: false,
      isTransparent: true,
    ),
    Paint(
      id: 'test-paint-4',
      name: 'Waagh! Flesh',
      hex: '#61A02A',
      set: 'Base',
      code: 'M003',
      r: 97,
      g: 160,
      b: 42,
      brand: 'Citadel',
      category: 'Base',
      isMetallic: false,
      isTransparent: false,
    ),
    Paint(
      id: 'test-paint-5',
      name: 'Retributor Armour',
      hex: '#C39E81',
      set: 'Base',
      code: 'M004',
      r: 195,
      g: 158,
      b: 129,
      brand: 'Citadel',
      category: 'Base',
      isMetallic: true,
      isTransparent: false,
    ),
  ];

  /// Test project names for creation/deletion tests
  static List<String> get testProjectNames => [
    'E2E Test Project 1',
    'E2E Test Project 2',
    'E2E Test Project 3',
    'Performance Test Project',
    'Offline Test Project',
    'Sync Test Project',
  ];

  /// Test palette names
  static List<String> get testPaletteNames => [
    'E2E Test Palette 1',
    'E2E Test Palette 2',
    'Space Marine Colors',
    'Ork Skin Tones',
    'Metallic Collection',
  ];

  /// Sample search terms for testing
  static List<String> get searchTerms => [
    'blue',
    'metallic',
    'citadel',
    'base',
    'shade',
    'green',
    'space marine',
    'ork',
  ];

  /// Test tags
  static List<String> get testTags => [
    'warhammer',
    'fantasy',
    'space-marines',
    'orks',
    'elves',
    'dwarfs',
    'chaos',
    'imperial',
  ];

  /// Performance test data
  static List<String> generateBulkProjectNames(int count) {
    return List.generate(
      count, 
      (index) => 'Bulk Test Project ${index + 1}',
    );
  }

  static List<String> generateBulkPaletteNames(int count) {
    return List.generate(
      count, 
      (index) => 'Bulk Test Palette ${index + 1}',
    );
  }

  /// Error scenarios
  static Map<String, dynamic> get errorScenarios => {
    'invalid_email': 'invalid-email',
    'weak_password': '123',
    'empty_project_name': '',
    'long_project_name': 'A' * 200,
    'special_characters': '!@#\$%^&*()',
    'sql_injection': "'; DROP TABLE projects; --",
  };

  /// Network simulation data
  static Map<String, Duration> get networkDelays => {
    'fast': Duration(milliseconds: 100),
    'normal': Duration(milliseconds: 500),
    'slow': Duration(seconds: 2),
    'timeout': Duration(seconds: 30),
  };

  /// Expected UI text for verification
  static Map<String, List<String>> get expectedTexts => {
    'home_screen': [
      'My Projects',
      'Recent Palettes',
      'Paints',
      'See all',
    ],
    'projects_screen': [
      'New Project',
      'Projects',
      'Grid',
      'List',
    ],
    'auth_screen': [
      'Sign In',
      'Sign Up',
      'Email',
      'Password',
    ],
    'empty_states': [
      'No projects yet',
      'No palettes yet',
      'No items in inventory',
      'No items in wishlist',
    ],
  };

  /// Test configuration
  static Map<String, dynamic> get testConfig => {
    'timeout_duration': 30, // seconds
    'retry_attempts': 3,
    'screenshot_on_failure': true,
    'cleanup_after_test': true,
    'parallel_execution': false,
    'performance_threshold_ms': 5000,
  };
}
