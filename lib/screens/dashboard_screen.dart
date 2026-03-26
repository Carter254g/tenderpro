// lib/screens/dashboard_screen.dart
// Main dashboard — overview of projects and quick actions

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── Hero App Bar ──────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildAppBarBg(context, provider),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Stats Row ─────────────────────────
                    _buildStatsRow(context, provider),
                    const SizedBox(height: 24),

                    // ── Quick Actions ─────────────────────
                    const SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),

                    // ── Recent Projects ───────────────────
                    SectionHeader(
                      title: 'Recent Projects',
                      action: 'View All',
                      onAction: () => onNavigate(3),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentProjects(context, provider),

                    const SizedBox(height: 100), // bottom nav clearance
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── App Bar Background ────────────────────────
  Widget _buildAppBarBg(BuildContext context, AppProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TP',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TenderPro AI',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Welcome back! Ready to win tenders.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────
  Widget _buildStatsRow(BuildContext context, AppProvider provider) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Total Projects',
            value: provider.totalProjects.toString(),
            icon: Icons.folder_outlined,
            color: AppColors.primary,
            bgColor: AppColors.primarySurface,
            onTap: () => onNavigate(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Active Tenders',
            value: provider.activeTenders.toString(),
            icon: Icons.assignment_outlined,
            color: AppColors.success,
            bgColor: AppColors.successLight,
            onTap: () => onNavigate(3),
          ),
        ),
      ],
    );
  }

  // ── Quick Actions ─────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.upload_file_outlined,
            label: 'Upload Tender',
            subtitle: 'Extract BOQ with AI',
            color: AppColors.primary,
            bgColor: AppColors.primarySurface,
            onTap: () => onNavigate(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.add_circle_outline,
            label: 'New Project',
            subtitle: 'Start from scratch',
            color: AppColors.accent,
            bgColor: AppColors.accentLight,
            onTap: () => _showNewProjectDialog(context),
          ),
        ),
      ],
    );
  }

  void _showNewProjectDialog(BuildContext context) {
    final controller = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'New Project',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'e.g. Mombasa Road Office Block',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief project description',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final project = Project(
                  name: controller.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                );
                context.read<AppProvider>().addProject(project);
                Navigator.pop(ctx);
                onNavigate(3);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ── Recent Projects ───────────────────────────
  Widget _buildRecentProjects(BuildContext context, AppProvider provider) {
    final recent = provider.projects.take(3).toList();

    if (recent.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'No Projects Yet',
        subtitle: 'Upload a tender or create a project to get started.',
        actionLabel: 'Upload Tender',
        onAction: () => onNavigate(1),
      );
    }

    return Column(
      children: recent
          .map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProjectTile(
                  project: p,
                  onTap: () {
                    context.read<AppProvider>().setActiveProject(p);
                    onNavigate(2);
                  },
                ),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Action Card Widget
// ─────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Project Tile Widget
// ─────────────────────────────────────────────
class _ProjectTile extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectTile({required this.project, required this.onTap});

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_outlined, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${project.itemCount} items • ${Formatters.relativeTime(project.updatedAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(
              label: project.status.label,
              color: _statusColor,
              bgColor: _statusBg,
            ),
          ],
        ),
      ),
    );
  }
}
