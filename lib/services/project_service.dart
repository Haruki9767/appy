import '../models/project.dart';
import 'storage_service.dart';

class ProjectService {
  static const String _projectsBoxName = 'projects';

  static Future<void> createProject(Project project) async {
    await StorageService.saveProject(project);
  }

  static Future<void> updateProject(Project project) async {
    await StorageService.saveProject(project);
  }

  static Future<void> deleteProject(String id) async {
    await StorageService.deleteProject(id);
  }

  static Future<List<Project>> getAllProjects() async {
    return await StorageService.getAllProjects();
  }

  static Future<List<Project>> getProjectsByStatus(String status) async {
    final projects = await getAllProjects();
    return projects.where((p) => p.status == status).toList();
  }

  static Future<List<Project>> getProjectsByType(String type) async {
    final projects = await getAllProjects();
    return projects.where((p) => p.type == type).toList();
  }

  static Future<int> getCompletedProjects() async {
    final projects = await getAllProjects();
    return projects.where((p) => p.status == 'completed').length;
  }

  static Future<int> getTotalProjects() async {
    final projects = await getAllProjects();
    return projects.length;
  }
}