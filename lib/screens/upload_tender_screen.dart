// lib/screens/upload_tender_screen.dart
// Upload tender documents or paste text for AI BOQ extraction

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class UploadTenderScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const UploadTenderScreen({super.key, required this.onNavigate});

  @override
  State<UploadTenderScreen> createState() => _UploadTenderScreenState();
}

class _UploadTenderScreenState extends State<UploadTenderScreen>
    with SingleTickerProviderStateMixin {
  final _textController    = TextEditingController();
  final _projectNameCtrl   = TextEditingController();
  final _formKey           = GlobalKey<FormState>();

  PlatformFile? _pickedFile;
  bool          _isExtracting = false;
  String?       _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _textController.dispose();
    _projectNameCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Pick file from device ───────────────────────────────────────────────
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type              : FileType.custom,
        allowedExtensions : ['pdf', 'doc', 'docx', 'txt'],
        // Read bytes into memory so we can send them to the AI
        withData          : true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _error      = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick file: ${e.toString()}');
    }
  }

  // ── Trigger AI extraction ───────────────────────────────────────────────
  Future<void> _extract() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();
    final text     = _textController.text.trim();
    final hasFile  = _pickedFile != null;

    if (text.isEmpty && !hasFile) {
      setState(() => _error = 'Please upload a file or paste tender text.');
      return;
    }

    setState(() { _isExtracting = true; _error = null; });

    final projectName = _projectNameCtrl.text.trim().isEmpty
        ? (_pickedFile?.name ?? 'New Tender Project')
        : _projectNameCtrl.text.trim();

    List<BoqItem> items;

    // ── Route: file bytes vs pasted text ──────────────────────────────────
    if (hasFile && _pickedFile!.bytes != null && text.isEmpty) {
      // Real file — send bytes directly to AI (PDF natively, others as text)
      items = await provider.extractBoqFromFile(
        _pickedFile!.bytes!,
        _pickedFile!.name,
      );
    } else {
      // Pasted text (or text tab active)
      items = await provider.extractBoqFromText(text);
    }

    setState(() { _isExtracting = false; });

    if (items.isNotEmpty) {
      final project = Project(
        name     : projectName,
        status   : ProjectStatus.active,
        boqItems : items,
      );
      provider.addProject(project);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content         : Text('Extracted ${items.length} items successfully!'),
            backgroundColor : AppColors.success,
            behavior        : SnackBarBehavior.floating,
            shape           : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        widget.onNavigate(2); // Go to BOQ screen
      }
    } else {
      setState(() =>
        _error = provider.errorMessage ?? 'Extraction failed. Try again.',
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Tender'),
        bottom: TabBar(
          controller          : _tabController,
          labelColor          : AppColors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor      : AppColors.accent,
          indicatorWeight     : 3,
          tabs: const [
            Tab(text: 'Upload File', icon: Icon(Icons.upload_file, size: 18)),
            Tab(text: 'Paste Text',  icon: Icon(Icons.text_snippet, size: 18)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFileTab(),
                      _buildTextTab(),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
          if (_isExtracting)
            const LoadingOverlay(
              message: 'AI is extracting BOQ items...',
            ),
        ],
      ),
    );
  }

  // ── File Upload Tab ─────────────────────────────────────────────────────
  Widget _buildFileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildProjectNameField(),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width  : double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color        : _pickedFile != null ? AppColors.primarySurface : AppColors.white,
                borderRadius : BorderRadius.circular(14),
                border       : Border.all(
                  color: _pickedFile != null ? AppColors.primary : AppColors.border,
                  width: _pickedFile != null ? 2 : 1,
                ),
              ),
              child: _pickedFile == null
                  ? _buildDropZoneEmpty()
                  : _buildDropZoneFilled(),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color       : AppColors.infoLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Supported: PDF, DOC, DOCX, TXT. '
                    'AI will extract all BOQ items automatically.',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(
              message  : _error!,
              onDismiss: () => setState(() => _error = null),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropZoneEmpty() {
    return Column(
      children: [
        Container(
          padding   : const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            size : 36,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap to browse files',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize  : 16,
            color     : AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'PDF, DOC, DOCX, TXT up to 20MB',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDropZoneFilled() {
    return Row(
      children: [
        Container(
          padding   : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color       : AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.description_outlined,
            color: AppColors.white,
            size : 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _pickedFile!.name,
                style   : const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize  : 14,
                ),
                maxLines : 2,
                overflow : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${(_pickedFile!.size / 1024).toStringAsFixed(0)} KB',
                style: const TextStyle(
                  fontSize: 12,
                  color   : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon     : const Icon(Icons.close, color: AppColors.textMuted),
          onPressed: () => setState(() => _pickedFile = null),
        ),
      ],
    );
  }

  // ── Paste Text Tab ──────────────────────────────────────────────────────
  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildProjectNameField(),
          const SizedBox(height: 20),

          TextFormField(
            controller: _textController,
            maxLines  : 14,
            decoration: const InputDecoration(
              hintText: 'Paste your tender document text here...\n\n'
                  'The AI will analyse and extract all BOQ items, '
                  'quantities, units, and descriptions automatically.',
              alignLabelWithHint: true,
            ),
            validator: (v) {
              if (_tabController.index == 1 &&
                  (v == null || v.trim().isEmpty)) {
                return 'Please paste tender text';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          Container(
            padding   : const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color       : AppColors.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tip: Include item descriptions, units of measurement, '
                    'and quantities for best extraction accuracy.',
                    style: TextStyle(
                      fontSize: 12,
                      color   : Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(
              message  : _error!,
              onDismiss: () => setState(() => _error = null),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectNameField() {
    return TextFormField(
      controller: _projectNameCtrl,
      decoration: const InputDecoration(
        labelText  : 'Project Name',
        hintText   : 'e.g. Mombasa Bypass Road Works',
        prefixIcon : Icon(Icons.folder_outlined, size: 20),
      ),
    );
  }

  // ── Bottom Action Bar ───────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding  : const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color     : AppColors.white,
        boxShadow : [
          BoxShadow(
            color     : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset    : const Offset(0, -4),
          ),
        ],
      ),
      child: AccentButton(
        label    : 'Generate BOQ / Items',
        icon     : Icons.auto_awesome,
        onPressed: _extract,
        isLoading: _isExtracting,
      ),
    );
  }
}
