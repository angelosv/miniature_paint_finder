import 'package:miniature_paint_finder/repositories/base_repository.dart';
import 'package:miniature_paint_finder/services/api_service.dart';
import 'package:miniature_paint_finder/data/api_constants.dart';
import 'package:miniature_paint_finder/models/project.dart';
import 'dart:convert';
/// Repositorio para operaciones con proyectos de pintura
abstract class ProjectRepository extends BaseRepository<Project> {
  /// Obtiene los proyectos del usuario autenticado con paginación
  Future<Map<String, dynamic>> getUserProjects({int page = 1, int limit = 10});

  /// Crea un item ligado al proyecto (e.g., user_color_images)
  Future<bool> addProjectItem({
    required String projectId,
    required String table,
    required String tableId,
  });

  /// Elimina un item ligado al proyecto
  Future<bool> deleteProjectItem({
    required String itemId,
  });
}

/// Implementación del repositorio de proyectos usando API
class ApiProjectRepository implements ProjectRepository {
  final ApiService _apiService;

  ApiProjectRepository(this._apiService);

  @override
  Future<List<Project>> getAll() async {
    try {
      final response = await _apiService.get(ApiEndpoints.projects);
      final data = response is Map<String, dynamic> ? response['data'] : response;
      final items = (data is Map<String, dynamic> && data['projects'] is List)
          ? data['projects'] as List
          : (response is List ? response : <dynamic>[]);
      return items.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getUserProjects({int page = 1, int limit = 10}) async {
    try {   
      final response = await _apiService.get(
        '${ApiEndpoints.projects}?page=$page&limit=$limit',
      );

      final data = response;  
      // New backend response uses snake_case keys; normalize to camelCase
      final currentPage = data['current_page'] ?? data['current_page'] ?? page;
      final totalPages = data['total_pages'] ?? data['total_pages'] ?? 1;
      final totalProjects = data['total_projects'] ?? data['total_projects'] ?? 0;
      final totalDone = data['total_done'] ?? 0;
      final totalActive = data['total_active'] ?? 0;
      final totalShown = data['total_shown'] ?? 0;
      final pageLimit = data['limit'] ?? limit;

      final projects = (data['projects'] is List)
          ? List<Map<String, dynamic>>.from(data['projects'] as List)
          : <Map<String, dynamic>>[];

      return {
        'currentPage': int.parse(currentPage.toString()),
        'totalPages': int.parse(totalPages.toString()),
        'totalProjects': int.parse(totalProjects.toString()),
        'totalDone': int.parse(totalDone.toString()),
        'totalActive': int.parse(totalActive.toString()),
        'totalShown': int.parse(totalShown.toString()),
        'limit': int.parse(pageLimit.toString()),
        'projects': projects,
      };
    } catch (e) {
      print('**** getUserProjects ERROR data: $e');    

      return {
        'currentPage': page,
        'totalPages': 1,
        'totalProjects': 0,
        'totalDone': 0,
        'totalActive': 0,
        'totalShown': 0,
        'limit': limit,
        'projects': <Map<String, dynamic>>[],
      };
    }
  }

  @override
  Future<Project?> getById(String id) async {
    try {
      final response = await _apiService.get(ApiEndpoints.projectById(id));
      // Map API project (with items.data) to UI Project model
      if (response is Map<String, dynamic>) {
        final map = response;
        final List<dynamic> items = (map['items'] as List?) ?? [];

        final paletteIds = items
            .where((item) => item['table'] == 'palettes')
            .map((item) => item['table_id'] as String)
            .toList();

        final images = items
            .where((item) => item['table'] == 'user_color_images')
            .map((item) {
              final data = item['data'] as Map<String, dynamic>? ?? {};
              return ProjectImage(
                itemId: (item['id'] ?? '') as String,
                id: (item['table_id'] ?? item['id'] ?? '') as String,
                imagePath: (data['image_path'] ?? '') as String,
                caption: null,
                type: ProjectImageType.reference,
                isMain: false,
                createdAt:
                    DateTime.tryParse((data['created_at'] ?? '') as String) ??
                    DateTime.tryParse((item['created_at'] ?? '') as String) ??
                    DateTime.now(),
              );
            })
            .toList();

        final paints = items
            .where((item) => item['table'] == 'paints')
            .map((item) {
              final data = item['data'] as Map<String, dynamic>? ?? {};
              final brandId = (data['brand_id'] ?? item['brand_id'] ?? 'Unknown') as String;
              return ProjectPaint(
                paintId: (data['id'] ?? item['table_id'] ?? '') as String,
                paintName: (data['name'] ?? 'Paint') as String,
                paintBrand: (data['set'] ?? brandId) as String,
                brandAvatar: brandId.isNotEmpty ? brandId[0] : 'U',
                colorHex: (data['hex'] ?? '#000000') as String,
                notes: null,
                addedAt:
                    DateTime.tryParse((item['created_at'] ?? '') as String) ??
                    DateTime.now(),
              );
            })
            .toList();

        String statusStr = (map['status'] ?? 'planning').toString().toLowerCase();
        final status = statusStr == 'in_progress'
            ? ProjectStatus.inProgress
            : statusStr == 'completed'
                ? ProjectStatus.completed
                : statusStr == 'on_hold'
                    ? ProjectStatus.onHold
                    : ProjectStatus.planning;

        return Project(
          id: map['id'] ?? id,
          name: map['name'] ?? 'Untitled',
          description: map['description'],
          images: images,
          paletteIds: paletteIds,
          paints: paints,
          createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
          status: status,
          userId: map['user_id'] ?? '',
          tags: (map['tags'] is List) ? List<String>.from(map['tags'] as List) : const [],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Project> create(Project item) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.projects,
        item.toJson(),
      );
      print('**** create project response: $response');
      return Project.fromJson(response as Map<String, dynamic>);
      print('**** create project response: $response');
    } catch (e) {
      print('**** error creating project: $e');
      return item;
    }
  }

  @override
  Future<Project> update(Project item) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.projectById(item.id),
        item.toJson(),
      );
      return Project.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return item;
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final response = await _apiService.delete(ApiEndpoints.projectById(id));
      if (response is Map<String, dynamic>) {
        return response['executed'] == true || response['success'] == true;
      }
      return true; // No content
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> addProjectItem({
    required String projectId,
    required String table,
    required String tableId,
  }) async {
    try {
      final payload = {
        'project_id': projectId,
        'table': table,
        'table_id': tableId,
      };
      final response = await _apiService.post(
        '${ApiEndpoints.createProjectItem}',
        payload,
      );
      if (response is Map<String, dynamic>) {
        return response['executed'] == true || response['success'] == true;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteProjectItem({
    required String itemId,
  }) async {
    try {
      final endpoint =
          '${ApiEndpoints.deleteProjectItem(itemId)}';
      final response = await _apiService.delete(endpoint);
      if (response is Map<String, dynamic>) {
        return response['executed'] == true || response['success'] == true;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}


