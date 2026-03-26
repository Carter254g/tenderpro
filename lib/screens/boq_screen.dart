// lib/screens/boq_screen.dart
// Bill of Quantities screen — editable table with full CRUD

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class BoqScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const BoqScreen({super.key, required this.onNavigate});

  @override
  State<BoqScreen> createState() => _BoqScreenState();
}

class _BoqScreenState extends State<BoqScreen> {
  bool _showTotalsBar = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final project = provider.activeProject;

        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('BOQ / Items')),
            body: EmptyState(
              icon: Icons.table_chart_outlined,
              title: 'No Active Project',
              subtitle: 'Upload a tender or create a project first.',
              actionLabel: 'Upload Tender',
              onAction: () => widget.onNavigate(1),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bill of Quantities'),
                Text(
                  project.name,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            actions: [
              // Project selector
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: AppColors.white),
                tooltip: 'Switch project',
                onPressed: () => _showProjectSwitcher(context, provider),
              ),
              // Add item
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.white),
                tooltip: 'Add item',
                onPressed: () => _showItemDialog(context, provider),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Totals Summary Bar ───────────────
              if (_showTotalsBar) _buildTotalsBar(project),

              // ── Table ────────────────────────────
              Expanded(
                child: project.boqItems.isEmpty
                    ? _buildEmptyBoq(context)
                    : _buildTable(context, provider, project),
              ),

              // ── Bottom Action ─────────────────────
              _buildBottomBar(context, project),
            ],
          ),
        );
      },
    );
  }

  // ── Totals Summary Bar ─────────────────────
  Widget _buildTotalsBar(Project project) {
    final total = project.totalValue;
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${project.itemCount} Items',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  Formatters.kes(total),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Subtotal',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ─────────────────────────────
  Widget _buildEmptyBoq(BuildContext context) {
    return EmptyState(
      icon: Icons.table_rows_outlined,
      title: 'No BOQ Items',
      subtitle: 'Upload a tender to extract items, or add them manually.',
      actionLabel: 'Add Item',
      onAction: () => _showItemDialog(context, context.read<AppProvider>()),
    );
  }

  // ── Scrollable Table ────────────────────────
  Widget _buildTable(BuildContext context, AppProvider provider, Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Table header
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const _TableHeaderRow(),
          ),

          // Table rows
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: project.boqItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = project.boqItems[index];
                return _BoqTableRow(
                  item: item,
                  isEven: index.isEven,
                  onEdit: () => _showItemDialog(context, provider, item: item),
                  onDelete: () => _confirmDelete(context, provider, item),
                );
              },
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ── Bottom Action Bar ───────────────────────
  Widget _buildBottomBar(BuildContext context, Project project) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showItemDialog(context, context.read<AppProvider>()),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: project.boqItems.isEmpty
                  ? null
                  : () => widget.onNavigate(3),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Generate Quotation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add/Edit Item Dialog ────────────────────
  void _showItemDialog(BuildContext context, AppProvider provider, {BoqItem? item}) {
    final isEdit = item != null;
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final unitCtrl = TextEditingController(text: item?.unit ?? '');
    final qtyCtrl = TextEditingController(
      text: item != null ? Formatters.number(item.quantity) : '',
    );
    final rateCtrl = TextEditingController(
      text: item != null ? Formatters.number(item.rate) : '',
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEdit ? 'Edit Item' : 'Add BOQ Item',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description *'),
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: 'Unit *', hintText: 'm², kg, m...'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(labelText: 'Quantity *'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rate (KES) *',
                  prefixText: 'KES ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (isEdit) {
                        provider.updateBoqItem(item!.copyWith(
                          description: descCtrl.text.trim(),
                          unit: unitCtrl.text.trim(),
                          quantity: double.parse(qtyCtrl.text),
                          rate: double.parse(rateCtrl.text),
                        ));
                      } else {
                        final nextNo = (provider.activeProject?.itemCount ?? 0) + 1;
                        provider.addBoqItem(BoqItem(
                          itemNo: nextNo,
                          description: descCtrl.text.trim(),
                          unit: unitCtrl.text.trim(),
                          quantity: double.parse(qtyCtrl.text),
                          rate: double.parse(rateCtrl.text),
                        ));
                      }
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(isEdit ? 'Update Item' : 'Add Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Confirm Delete ──────────────────────────
  void _confirmDelete(BuildContext context, AppProvider provider, BoqItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Remove "${item.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeBoqItem(item.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Project Switcher ────────────────────────
  void _showProjectSwitcher(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Select Project', style: Theme.of(context).textTheme.headlineMedium),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: provider.projects.map((p) => ListTile(
                leading: Icon(
                  Icons.folder_outlined,
                  color: p.id == provider.activeProject?.id
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(p.name, style: const TextStyle(fontSize: 14)),
                subtitle: Text('${p.itemCount} items', style: const TextStyle(fontSize: 12)),
                selected: p.id == provider.activeProject?.id,
                selectedTileColor: AppColors.primarySurface,
                onTap: () {
                  provider.setActiveProject(p);
                  Navigator.pop(ctx);
                },
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Table Header Row
// ─────────────────────────────────────────────
class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: const [
          SizedBox(width: 30, child: _HeaderCell('#')),
          SizedBox(width: 8),
          Expanded(flex: 3, child: _HeaderCell('Description')),
          SizedBox(width: 8),
          SizedBox(width: 48, child: _HeaderCell('Unit')),
          SizedBox(width: 8),
          SizedBox(width: 52, child: _HeaderCell('Qty')),
          SizedBox(width: 8),
          SizedBox(width: 80, child: _HeaderCell('Rate')),
          SizedBox(width: 8),
          SizedBox(width: 88, child: _HeaderCell('Total')),
          SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Table Data Row
// ─────────────────────────────────────────────
class _BoqTableRow extends StatelessWidget {
  final BoqItem item;
  final bool isEven;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BoqTableRow({
    required this.item,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? AppColors.surface : AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item No
          SizedBox(
            width: 30,
            child: Text(
              '${item.itemNo}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Description
          Expanded(
            flex: 3,
            child: Text(
              item.description,
              style: const TextStyle(fontSize: 12, color: AppColors.text),
            ),
          ),
          const SizedBox(width: 8),
          // Unit
          SizedBox(
            width: 48,
            child: Text(
              item.unit,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          // Quantity
          SizedBox(
            width: 52,
            child: Text(
              Formatters.number(item.quantity),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          // Rate
          SizedBox(
            width: 80,
            child: Text(
              Formatters.number(item.rate),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          // Total
          SizedBox(
            width: 88,
            child: Text(
              Formatters.number(item.total),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 36,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textMuted),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppColors.error)),
                ),
              ],
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
            ),
          ),
        ],
      ),
    );
  }
}
