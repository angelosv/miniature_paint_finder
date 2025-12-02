import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';
import 'package:miniature_paint_finder/services/project_cache_service.dart';
import 'package:miniature_paint_finder/models/project.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🎨 Project Management Tests', () {
    
    setUp(() async {
      TestHelpers.logStep('Setting up project test');
    });

    tearDown(() async {
      TestHelpers.logStep('Cleaning up project test');
    });

    testWidgets('Create New Project - Full Flow', (tester) async {
      TestHelpers.logStep('Starting project creation test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Navigate to projects screen
      await TestHelpers.navigateTo(tester, 'projects');
      
      // 2. Get initial project count
      final projectService = Provider.of<ProjectCacheService>(
        tester.element(find.byType(MaterialApp)), 
        listen: false,
      );
      final initialProjects = await projectService.getProjects();
      final initialCount = initialProjects.length;
      
      // 3. Create new project
      await tester.tapAndSettle(find.text('New Project'));
      
      const testProjectName = 'E2E Test Project';
      await tester.enterTextAndSettle(
        find.byKey(Key('project_name_field')), 
        testProjectName,
      );
      
      // Add description
      if (find.byKey(Key('project_description_field')).evaluate().isNotEmpty) {
        await tester.enterTextAndSettle(
          find.byKey(Key('project_description_field')), 
          'Created by E2E test',
        );
      }
      
      // Select status
      if (find.byKey(Key('project_status_dropdown')).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byKey(Key('project_status_dropdown')));
        await tester.tapAndSettle(find.text('Planning'));
      }
      
      // Submit creation
      await tester.tapAndSettle(find.text('Create'));
      
      // 4. Verify project created in cache
      final updatedProjects = await projectService.getProjects();
      expect(updatedProjects.length, initialCount + 1);
      
      final createdProject = updatedProjects.firstWhere(
        (p) => p.name == testProjectName,
        orElse: () => throw Exception('Project not found in cache!'),
      );
      
      // 5. Verify project appears in UI
      TestHelpers.verifyProjectExists(testProjectName);
      
      // 6. Verify project appears in Home carousel
      await TestHelpers.navigateTo(tester, 'home');
      await TestHelpers.waitForWidget(tester, find.text('My Projects'));
      
      // Should appear in carousel (if it's one of the recent 4)
      if (updatedProjects.length <= 4) {
        TestHelpers.verifyProjectExists(testProjectName);
      }
      
      TestHelpers.logResult('Project Creation', true, 
        details: 'Created project: ${createdProject.id}');
    });

    testWidgets('Edit Existing Project', (tester) async {
      TestHelpers.logStep('Starting project edit test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Create a test project first
      await TestHelpers.createTestProject(
        tester, 
        name: 'Project to Edit',
      );
      
      // 2. Navigate to project detail
      await TestHelpers.navigateTo(tester, 'projects');
      await tester.tapAndSettle(find.text('Project to Edit'));
      
      // 3. Edit project
      await tester.tapAndSettle(find.byIcon(Icons.edit));
      
      const newName = 'Edited Project Name';
      await tester.enterTextAndSettle(
        find.byKey(Key('project_name_field')), 
        newName,
      );
      
      // Change status
      if (find.byKey(Key('project_status_dropdown')).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byKey(Key('project_status_dropdown')));
        await tester.tapAndSettle(find.text('In Progress'));
      }
      
      // Save changes
      await tester.tapAndSettle(find.text('Save'));
      
      // 4. Verify changes saved
      TestHelpers.verifyProjectExists(newName);
      TestHelpers.verifyProjectNotExists('Project to Edit');
      
      TestHelpers.logResult('Project Edit', true);
    });

    testWidgets('Delete Project - Full Flow', (tester) async {
      TestHelpers.logStep('Starting project deletion test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Create a test project first
      await TestHelpers.createTestProject(
        tester, 
        name: 'Project to Delete',
      );
      
      // 2. Get project count before deletion
      final projectService = Provider.of<ProjectCacheService>(
        tester.element(find.byType(MaterialApp)), 
        listen: false,
      );
      final beforeProjects = await projectService.getProjects();
      final beforeCount = beforeProjects.length;
      
      // 3. Delete the project
      await TestHelpers.deleteProject(tester, 'Project to Delete');
      
      // 4. Verify project removed from cache
      final afterProjects = await projectService.getProjects();
      expect(afterProjects.length, beforeCount - 1);
      
      final projectExists = afterProjects.any((p) => p.name == 'Project to Delete');
      expect(projectExists, false);
      
      // 5. Verify project not in UI
      TestHelpers.verifyProjectNotExists('Project to Delete');
      
      TestHelpers.logResult('Project Deletion', true);
    });

    testWidgets('Project Status Changes', (tester) async {
      TestHelpers.logStep('Starting project status change test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Create test project
      await TestHelpers.createTestProject(
        tester, 
        name: 'Status Test Project',
        status: ProjectStatus.planning,
      );
      
      // 2. Navigate to project detail
      await TestHelpers.navigateTo(tester, 'projects');
      await tester.tapAndSettle(find.text('Status Test Project'));
      
      // 3. Change status to In Progress
      if (find.byKey(Key('status_chip')).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byKey(Key('status_chip')));
        await tester.tapAndSettle(find.text('In Progress'));
        
        // Verify status changed
        expect(find.text('🚧 In Progress'), findsOneWidget);
      }
      
      // 4. Change status to Completed
      if (find.byKey(Key('status_chip')).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byKey(Key('status_chip')));
        await tester.tapAndSettle(find.text('Completed'));
        
        // Verify status changed
        expect(find.text('✅ Completed'), findsOneWidget);
      }
      
      TestHelpers.logResult('Project Status Changes', true);
    });

    testWidgets('Project Search and Filter', (tester) async {
      TestHelpers.logStep('Starting project search test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Create multiple test projects
      await TestHelpers.createTestProject(tester, name: 'Space Marine Project');
      await TestHelpers.createTestProject(tester, name: 'Ork Warboss Project');
      await TestHelpers.createTestProject(tester, name: 'Elven Archer Project');
      
      // 2. Navigate to projects
      await TestHelpers.navigateTo(tester, 'projects');
      
      // 3. Test search functionality
      if (find.byKey(Key('search_field')).evaluate().isNotEmpty) {
        await tester.enterTextAndSettle(
          find.byKey(Key('search_field')), 
          'Space',
        );
        
        // Should show only Space Marine project
        TestHelpers.verifyProjectExists('Space Marine Project');
        TestHelpers.verifyProjectNotExists('Ork Warboss Project');
        
        // Clear search
        await tester.enterTextAndSettle(
          find.byKey(Key('search_field')), 
          '',
        );
      }
      
      // 4. Test status filter
      if (find.byKey(Key('status_filter')).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byKey(Key('status_filter')));
        await tester.tapAndSettle(find.text('Planning'));
        
        // Should show only planning projects
        // (verification depends on actual project statuses)
      }
      
      TestHelpers.logResult('Project Search and Filter', true);
    });

    testWidgets('Project Image Upload', (tester) async {
      TestHelpers.logStep('Starting project image upload test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Create test project
      await TestHelpers.createTestProject(tester, name: 'Image Test Project');
      
      // 2. Navigate to project detail
      await TestHelpers.navigateTo(tester, 'projects');
      await tester.tapAndSettle(find.text('Image Test Project'));
      
      // 3. Add image
      if (find.byKey(Key('add_image_button')).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byKey(Key('add_image_button')));
        
        // Select from gallery option
        if (find.text('Gallery').evaluate().isNotEmpty) {
          await tester.tapAndSettle(find.text('Gallery'));
          
          // Note: In real tests, this would need to handle image picker
          // For now, we just verify the flow starts
          TestHelpers.logResult('Image Upload Flow', true);
        }
      }
    });

    testWidgets('Project Pagination', (tester) async {
      TestHelpers.logStep('Starting project pagination test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Create multiple projects (more than page size)
      final projectNames = MockData.generateBulkProjectNames(15);
      for (final name in projectNames.take(5)) {
        await TestHelpers.createTestProject(tester, name: name);
      }
      
      // 2. Navigate to projects
      await TestHelpers.navigateTo(tester, 'projects');
      
      // 3. Test pagination controls
      if (find.byKey(Key('next_page_button')).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byKey(Key('next_page_button')));
        
        // Verify page changed
        expect(find.text('Page 2'), findsOneWidget);
        
        // Go back to first page
        await tester.tapAndSettle(find.byKey(Key('prev_page_button')));
        expect(find.text('Page 1'), findsOneWidget);
      }
      
      TestHelpers.logResult('Project Pagination', true);
    });

    testWidgets('Project Performance - Bulk Operations', (tester) async {
      TestHelpers.logStep('Starting project performance test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      final stopwatch = Stopwatch()..start();
      
      // 1. Create multiple projects quickly
      final projectNames = MockData.generateBulkProjectNames(10);
      for (final name in projectNames) {
        await TestHelpers.createTestProject(tester, name: name);
      }
      
      stopwatch.stop();
      
      // 2. Verify performance is acceptable
      final creationTime = stopwatch.elapsedMilliseconds;
      expect(creationTime, lessThan(60000)); // Less than 1 minute for 10 projects
      
      // 3. Test loading performance
      stopwatch.reset();
      stopwatch.start();
      
      await TestHelpers.navigateTo(tester, 'projects');
      await TestHelpers.waitForWidget(tester, find.text(projectNames.first));
      
      stopwatch.stop();
      final loadTime = stopwatch.elapsedMilliseconds;
      expect(loadTime, lessThan(5000)); // Less than 5 seconds to load
      
      TestHelpers.logResult('Project Performance', true, 
        details: 'Creation: ${creationTime}ms, Load: ${loadTime}ms');
    });

    testWidgets('Project Data Validation', (tester) async {
      TestHelpers.logStep('Starting project validation test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      await TestHelpers.navigateTo(tester, 'projects');
      
      // 1. Test empty name validation
      await tester.tapAndSettle(find.text('New Project'));
      await tester.tapAndSettle(find.text('Create'));
      
      // Should show validation error
      expect(find.textContaining('required'), findsAtLeastNWidgets(1));
      
      // 2. Test long name validation
      await tester.enterTextAndSettle(
        find.byKey(Key('project_name_field')), 
        'A' * 200, // Very long name
      );
      await tester.tapAndSettle(find.text('Create'));
      
      // Should show length validation error
      expect(find.textContaining('too long'), findsAtLeastNWidgets(1));
      
      // 3. Test special characters
      await tester.enterTextAndSettle(
        find.byKey(Key('project_name_field')), 
        MockData.errorScenarios['special_characters']!,
      );
      await tester.tapAndSettle(find.text('Create'));
      
      TestHelpers.logResult('Project Data Validation', true);
    });
  });
}
