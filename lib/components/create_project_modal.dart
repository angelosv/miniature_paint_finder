import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/models/project.dart';
import 'package:miniature_paint_finder/repositories/project_repository.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:provider/provider.dart';

class CreateProjectModal extends StatefulWidget {
  const CreateProjectModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateProjectModal(),
    );
  }

  @override
  State<CreateProjectModal> createState() => _CreateProjectModalState();
}

class _CreateProjectModalState extends State<CreateProjectModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  ProjectStatus _selectedStatus = ProjectStatus.planning;
  final List<String> _selectedTags = [];

  final List<String> _availableTags = [
    'warhammer-40k',
    'space-marines',
    'fantasy',
    'orks',
    'elves',
    'chaos',
    'necrons',
    'custodes',
    'weathering',
    'osl',
    'tmm',
    'nmm',
    'dragon',
    'knight',
    'large-miniature',
    'army',
    'character',
    'vehicle',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveGuidelines.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Create New Project',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveGuidelines.spacingL,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Project Name *',
                        hintText: 'e.g., Space Marine Captain',
                        prefixIcon: Icon(Icons.edit),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a project name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: ResponsiveGuidelines.spacingL),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Tell us about your project...',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),

                    SizedBox(height: ResponsiveGuidelines.spacingL),

                    // Status Selection
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveGuidelines.spacingS),
                    Wrap(
                      spacing: 8.w,
                      children:
                          ProjectStatus.values.map((status) {
                            final isSelected = _selectedStatus == status;
                            return FilterChip(
                              label: Text(
                                '${status.emoji} ${status.displayName}',
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStatus = status;
                                });
                              },
                              selectedColor: AppTheme.marineBlue.withOpacity(
                                0.2,
                              ),
                              checkmarkColor: AppTheme.marineBlue,
                            );
                          }).toList(),
                    ),

                    SizedBox(height: ResponsiveGuidelines.spacingL),

                    // Tags Selection
                    Text(
                      'Tags (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveGuidelines.spacingS),
                    Text(
                      'Select relevant tags to help categorize your project',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                    ),
                    SizedBox(height: ResponsiveGuidelines.spacingM),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children:
                          _availableTags.map((tag) {
                            final isSelected = _selectedTags.contains(tag);
                            return FilterChip(
                              label: Text(tag),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTags.add(tag);
                                  } else {
                                    _selectedTags.remove(tag);
                                  }
                                });
                              },
                              selectedColor: AppTheme.marineOrange.withOpacity(
                                0.2,
                              ),
                              checkmarkColor: AppTheme.marineOrange,
                            );
                          }).toList(),
                    ),

                    SizedBox(height: ResponsiveGuidelines.spacingXL),

                    // Info Box
                    Container(
                      padding: EdgeInsets.all(ResponsiveGuidelines.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.marineBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveGuidelines.radiusM,
                        ),
                        border: Border.all(
                          color: AppTheme.marineBlue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.marineBlue,
                            size: ResponsiveGuidelines.iconS,
                          ),
                          SizedBox(width: ResponsiveGuidelines.spacingS),
                          Expanded(
                            child: Text(
                              'After creating your project, you\'ll be able to add images, palettes, and paints to track your progress.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.marineBlue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: ResponsiveGuidelines.spacingXL),
                  ],
                ),
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: ResponsiveGuidelines.spacingM),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _createProject,
                    child: Text('Create Project'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<IAuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a project'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final project = Project(
      id: 'project_${now.millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      images: [],
      paletteIds: [],
      paints: [],
      createdAt: now,
      updatedAt: now,
      status: _selectedStatus,
      userId: currentUser.id,
      tags: List.from(_selectedTags),
    );
    
    try {
      final repo = Provider.of<ProjectRepository>(context, listen: false);
      await repo.create(project);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${project.name}" created successfully!'),
            backgroundColor: AppTheme.greenColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error creating project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
