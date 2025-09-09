import 'package:miniature_paint_finder/repositories/base_repository.dart';
import 'package:miniature_paint_finder/services/api_service.dart';
import 'package:miniature_paint_finder/data/api_constants.dart';
import 'package:miniature_paint_finder/models/project.dart';
import 'dart:convert';
/// Repositorio para operaciones con proyectos de pintura
abstract class ProjectRepository extends BaseRepository<Project> {
  /// Obtiene los proyectos del usuario autenticado con paginación
  Future<Map<String, dynamic>> getUserProjects({int page = 1, int limit = 10});
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
      return Project.fromJson(response as Map<String, dynamic>);
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
}


