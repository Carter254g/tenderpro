PopupMenuEntry<ProjectStatus>// lib/screens/projects_screen.dart
// Projects list — manage and navigate all projects

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class ProjectsScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const ProjectsScreen({super.key, required this.onNavigate});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  ProjectStatus? _filterStatus;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Project> _filtered(List<Project> all) {
    return all.where((p) {
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchStatus = _filterStatus == null || p.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final filtered = _filtered(provider.projects);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My Projects'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Search Bar ────────────────────────
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white12,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              // ── Filter chips ──────────────────────
              if (_filterStatus != null)
                Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Chip(
                        label: Text('Status: ${_filterStatus!.label}'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setState(() => _filterStatus = null),
                      ),
                    ],
                  ),
                ),

              // ── Project List ──────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(provider)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProjectCard(
                            project: filtered[i],
                            isActive: filtered[i].id == provider.activeProject?.id,
                            onOpen: () {
                              provider.setActiveProject(filtered[i]);
                              widget.onNavigate(2);
                            },
                            onEdit: () => _showEditDialog(context, provider, filtered[i]),
                            onDelete: () => _confirmDelete(context, provider, filtered[i]),
                            onStatusChange: (status) {
                              final updated = filtered[i].copyWith(status: status);
                              provider.updateProject(updated);
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateDialog(context, provider),
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.text,
            icon: const Icon(Icons.add),
            label: const Text(
              'New Project',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppProvider provider) {
    return EmptyState(
      icon: Icons.folder_open_outlined,
      title: _searchQuery.isNotEmpty ? 'No Results Found' : 'No Projects Yet',
      subtitle: _searchQuery.isNotEmpty
          ? 'Try a different search term.'
          : 'Create your first project or upload a tender.',
      actionLabel: _searchQuery.isEmpty ? 'Create Project' : null,
      onAction: _searchQuery.isEmpty
          ? () => _showCreateDialog(context, provider)
          : null,
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Status', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterStatus == null,
                  onSelected: (_) {
                    setState(() => _filterStatus = null);
                    Navigator.pop(ctx);
                  },
                ),
                ...ProjectStatus.values.map((s) => FilterChip(
                  label: Text(s.label),
                  selected: _filterStatus == s,
                  onSelected: (_) {
                    setState(() => _filterStatus = s);
                    Navigator.pop(ctx);
                  },
                )),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Project', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Project Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final project = Project(
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      );
                      provider.addProject(project);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Create Project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, AppProvider provider, Project project) {
    final nameCtrl = TextEditingController(text: project.name);
    final descCtrl = TextEditingController(text: project.description ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Project', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Project Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final updated = project.copyWith(
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      );
                      provider.updateProject(updated);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, Project project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'Are you sure you want to delete "${project.name}"? '
          'This will remove all ${project.itemCount} BOQ items. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteProject(project.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Project Card
// ─────────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final Project project;
  final bool isActive;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(ProjectStatus) onStatusChange;

  const _ProjectCard({
    required this.project,
    required this.isActive,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  Color get _statusColor {
    switch (project.status) {
      case ProjectStatus.active: return AppColors.success;
      case ProjectStatus.completed: return AppColors.info;
      case ProjectStatus.archived: return AppColors.textMuted;
      default: return AppColors.warning;
    }
  }

  Color get _statusBg {
    switch (project.status) {
      case ProjectStatus.active: return AppColors.successLight;
      case ProjectStatus.completed: return AppColors.infoLight;
      case ProjectStatus.archived: return AppColors.border;
      default: return AppColors.warningLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Top row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primarySurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.border,
                    ),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    color: isActive ? AppColors.primary : AppColors.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      if (project.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          project.description!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          StatusBadge(
                            label: project.status.label,
                            color: _statusColor,
                            bgColor: _statusBg,
                          ),
                          const SizedBox(width: 8),
                          if (isActive)
                            const StatusBadge(
                              label: 'Active View',
                              color: AppColors.primary,
                              bgColor: AppColors.primarySurface,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'open', child: Text('Open BOQ')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuButton<ProjectStatus>(
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        child: Text('Change Status'),
                      ),
                      itemBuilder: (_) => ProjectStatus.values
                          .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                          .toList(),
                      onSelected: onStatusChange,
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'open') onOpen();
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                ),
              ],
            ),
          ),

          // Bottom stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                _StatItem(icon: Icons.list_alt_outlined, value: '${project.itemCount}', label: 'Items'),
                const SizedBox(width: 16),
                _StatItem(
                  icon: Icons.payments_outlined,
                  value: Formatters.kesCompact(project.totalValue),
                  label: 'Value',
                ),
                const Spacer(),
                Text(
                  Formatters.relativeTime(project.updatedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onOpen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Open',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
