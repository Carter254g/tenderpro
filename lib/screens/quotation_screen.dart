// lib/screens/quotation_screen.dart
// Quotation screen — VAT, profit margin, grand total and PDF export

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class QuotationScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const QuotationScreen({super.key, required this.onNavigate});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  double _vatRate = 16.0;    // percentage
  double _marginRate = 10.0; // percentage
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final project = provider.activeProject;

        if (project == null || project.boqItems.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quotation')),
            body: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Items to Quote',
              subtitle: 'Add BOQ items first before generating a quotation.',
              actionLabel: 'Go to BOQ',
              onAction: () => widget.onNavigate(2),
            ),
          );
        }

        // Calculations
        final subtotal = project.boqItems.fold(0.0, (s, i) => s + i.total);
        final vatAmt = subtotal * (_vatRate / 100);
        final marginAmt = subtotal * (_marginRate / 100);
        final grandTotal = subtotal + vatAmt + marginAmt;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quotation'),
                Text(
                  project.name,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _exportPdf(context, project, subtotal, vatAmt, marginAmt, grandTotal),
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Quotation Header Card ──────────────
                    _buildHeaderCard(project),
                    const SizedBox(height: 16),

                    // ── Item Summary ──────────────────────
                    _buildItemsSummary(project),
                    const SizedBox(height: 16),

                    // ── Rate Adjustments ──────────────────
                    _buildRateAdjustments(),
                    const SizedBox(height: 16),

                    // ── Financial Summary ─────────────────
                    _buildFinancialSummary(subtotal, vatAmt, marginAmt, grandTotal),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
              if (_isExporting)
                const LoadingOverlay(message: 'Generating PDF...'),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(
            context, project, subtotal, vatAmt, marginAmt, grandTotal,
          ),
        );
      },
    );
  }

  // ── Header Card ─────────────────────────────
  Widget _buildHeaderCard(Project project) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'QUOTATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Ref: Q-${DateTime.now().year}-${project.id.substring(0, 6).toUpperCase()}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (project.description != null) ...[
            const SizedBox(height: 4),
            Text(
              project.description!,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetaItem(Icons.calendar_today_outlined, 'Date', Formatters.date(DateTime.now())),
              const SizedBox(width: 24),
              _buildMetaItem(Icons.receipt_outlined, 'Items', '${project.itemCount}'),
              const SizedBox(width: 24),
              _buildMetaItem(Icons.flag_outlined, 'Currency', 'KES'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ── Items Summary ───────────────────────────
  Widget _buildItemsSummary(Project project) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('Item Breakdown', style: Theme.of(context).textTheme.headlineSmall),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: project.boqItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final item = project.boqItems[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${item.itemNo}',
                          style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${Formatters.number(item.quantity)} ${item.unit} × ${Formatters.kes(item.rate)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.kes(item.total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Rate Adjustment Sliders ─────────────────
  Widget _buildRateAdjustments() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate Adjustments', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // VAT
          Row(
            children: [
              const Icon(Icons.percent, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('VAT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_vatRate.toInt()}%',
                            style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _vatRate,
                      min: 0,
                      max: 30,
                      divisions: 30,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _vatRate = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),

          // Profit Margin
          Row(
            children: [
              const Icon(Icons.trending_up, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Profit Margin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_marginRate.toInt()}%',
                            style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _marginRate,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      activeColor: AppColors.success,
                      onChanged: (v) => setState(() => _marginRate = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Financial Summary ───────────────────────
  Widget _buildFinancialSummary(
    double subtotal,
    double vatAmt,
    double marginAmt,
    double grandTotal,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financial Summary', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          InfoRow(label: 'Subtotal (Works)', value: Formatters.kes(subtotal)),
          const SizedBox(height: 6),
          InfoRow(
            label: 'VAT (${_vatRate.toInt()}%)',
            value: Formatters.kes(vatAmt),
          ),
          const SizedBox(height: 6),
          InfoRow(
            label: 'Profit Margin (${_marginRate.toInt()}%)',
            value: Formatters.kes(marginAmt),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),

          // Grand Total highlight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GRAND TOTAL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Inclusive of VAT & Margin',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.kes(grandTotal),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ──────────────────────────────
  Widget _buildBottomBar(
    BuildContext context,
    Project project,
    double subtotal,
    double vatAmt,
    double marginAmt,
    double grandTotal,
  ) {
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
      child: AccentButton(
        label: 'Export as PDF',
        icon: Icons.picture_as_pdf_outlined,
        isLoading: _isExporting,
        onPressed: () => _exportPdf(context, project, subtotal, vatAmt, marginAmt, grandTotal),
      ),
    );
  }

  // ── PDF Export (simulated) ─────────────────
  Future<void> _exportPdf(
    BuildContext context,
    Project project,
    double subtotal,
    double vatAmt,
    double marginAmt,
    double grandTotal,
  ) async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate PDF generation
    setState(() => _isExporting = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('PDF Generated'),
            ],
          ),
          content: Text(
            'Quotation for "${project.name}" has been generated.\n\n'
            'Grand Total: ${Formatters.kes(grandTotal)}\n\n'
            'In a production app, this would save and share the PDF file.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
