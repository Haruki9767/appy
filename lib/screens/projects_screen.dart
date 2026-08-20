import 'package:flutter/material.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';
import '../models/project.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  String _filter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    _projects = await ProjectService.getAllProjects();
    if (mounted) setState(() => _isLoading = false);
  }

  List<Project> get _filteredProjects {
    if (_filter == 'all') return _projects;
    return _projects.where((p) => p.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects & Exams'),
        backgroundColor: AppTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProjectDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Not Started', 'notstarted'),
                  _buildFilterChip('In Progress', 'inprogress'),
                  _buildFilterChip('Completed', 'completed'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProjects.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 64, color: AppTheme.textSecondary),
                            SizedBox(height: 16),
                            Text('No projects yet',
                                style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                            SizedBox(height: 8),
                            Text('Tap the + button to create one',
                                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProjects.length,
                        itemBuilder: (_, i) => _buildProjectCard(_filteredProjects[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filter = value),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.focusRed.withOpacity(0.1),
        checkmarkColor: AppTheme.focusRed,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.focusRed : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final statusColor = _getStatusColor(project.status);
    final statusText = _getStatusText(project.status);
    final priorityColor = _getPriorityColor(project.priority);

    return Dismissible(
      key: Key(project.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.errorRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // FIX: was onDismissed — item was removed from view before the dialog
      // resolved, so cancelling the dialog left it visually gone but not deleted.
      // confirmDismiss keeps the item visible until the user confirms.
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) async {
        await ProjectService.deleteProject(project.id);
        _loadProjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project deleted'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project.priority,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: priorityColor),
                  ),
                ),
              ],
            ),
            if (project.description != null && project.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(project.description!,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(_getTypeIcon(project.type), size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(project.type,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(width: 16),
                const Icon(Icons.subject, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    project.subject ?? 'No subject',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Progress',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const Spacer(),
                Text('${project.progress}%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: project.progress / 100,
                backgroundColor: Colors.grey.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  project.progress >= 100 ? AppTheme.successGreen : AppTheme.focusRed,
                ),
                minHeight: 6,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showProjectDialog(project),
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showProjectDialog([Project? project]) async {
    final formKey = GlobalKey<FormState>();
    final isEditing = project != null;

    // FIX: all controllers created once here and disposed after dialog closes.
    // Previously the deadline controller was created INSIDE StatefulBuilder,
    // meaning it was recreated on every setModalState() call and never disposed.
    final titleController = TextEditingController(text: project?.title ?? '');
    final descriptionController = TextEditingController(text: project?.description ?? '');
    final notesController = TextEditingController(text: project?.notes ?? '');
    final deadlineController = TextEditingController(text: project?.deadline ?? '');

    // FIX: dropdown state variables declared OUTSIDE StatefulBuilder so they
    // survive rebuilds. Previously they were declared inside the builder, which
    // meant every setModalState() call reset them to their initial values,
    // making it impossible to change dropdowns — the Create button would always
    // submit the default values regardless of what the user selected.
    String selectedType     = project?.type     ?? 'project';
    String selectedStatus   = project?.status   ?? 'notstarted';
    String selectedPriority = project?.priority ?? 'medium';
    String selectedSubject  = project?.subject  ?? '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => StatefulBuilder(
          builder: (ctx, setModalState) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              // Keep form above keyboard
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Project' : 'New Project',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Type
                  _buildDropdown(
                    label: 'Type',
                    value: selectedType,
                    items: const ['project', 'exam', 'test'],
                    onChanged: (v) => setModalState(() => selectedType = v!),
                  ),
                  // FIX: missing SizedBox after Type dropdown — fields were
                  // crammed together with no spacing.
                  const SizedBox(height: 12),

                  // Title
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  // Subject
                  _buildDropdown(
                    label: 'Subject',
                    value: selectedSubject.isEmpty ? null : selectedSubject,
                    items: const [
                      'Mathematics', 'Physics', 'Chemistry',
                      'English', 'History', 'Computer Science',
                    ],
                    onChanged: (v) => setModalState(() => selectedSubject = v ?? ''),
                  ),
                  const SizedBox(height: 12),

                  // Priority
                  _buildDropdown(
                    label: 'Priority',
                    value: selectedPriority,
                    items: const ['low', 'medium', 'high'],
                    onChanged: (v) => setModalState(() => selectedPriority = v!),
                  ),
                  const SizedBox(height: 12),

                  // Status
                  _buildDropdown(
                    label: 'Status',
                    value: selectedStatus,
                    items: const ['notstarted', 'inprogress', 'completed'],
                    onChanged: (v) => setModalState(() => selectedStatus = v!),
                  ),
                  const SizedBox(height: 12),

                  // Deadline
                  // FIX: controller is now the stable deadlineController defined
                  // above, not TextEditingController(text: selectedDeadline)
                  // which was recreated on every rebuild and never disposed.
                  TextFormField(
                    controller: deadlineController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Deadline',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        final formatted = date.toIso8601String().split('T').first;
                        setModalState(() => deadlineController.text = formatted);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          // FIX: was missing backgroundColor — button rendered
                          // with default grey Material style instead of focusRed.
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.focusRed,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;

                            final newProject = Project(
                              id:          project?.id,
                              title:       titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              subject:     selectedSubject,
                              priority:    selectedPriority,
                              status:      selectedStatus,
                              deadline:    deadlineController.text,
                              progress:    project?.progress ?? 0,
                              notes:       notesController.text.trim(),
                              type:        selectedType,
                            );

                            if (isEditing) {
                              await ProjectService.updateProject(newProject);
                            } else {
                              await ProjectService.createProject(newProject);
                            }

                            if (mounted) {
                              Navigator.pop(ctx);
                              _loadProjects();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      isEditing ? 'Project updated!' : 'Project created!'),
                                  backgroundColor: AppTheme.successGreen,
                                ),
                              );
                            }
                          },
                          child: Text(isEditing ? 'Update' : 'Create'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // FIX: dispose all controllers after modal closes — previously only
    // title/description/notes were disposed; deadline leaked on every open.
    titleController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    deadlineController.dispose();
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _deleteProject(String id) async {
    await ProjectService.deleteProject(id);
    _loadProjects();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return AppTheme.successGreen;
      case 'inprogress': return AppTheme.focusRed;
      default: return AppTheme.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed': return 'Completed';
      case 'inprogress': return 'In Progress';
      default: return 'Not Started';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return AppTheme.warningYellow;
      default: return AppTheme.successGreen;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'exam': return Icons.assignment;
      case 'test': return Icons.quiz;
      default: return Icons.folder;
    }
  }
}
