// lib/providers/app_provider.dart
// Central state management using Provider pattern

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../config/env.dart';

// API key is loaded securely from Env (--dart-define or lib/config/env.dart)
// See lib/config/env.dart for setup instructions.
String get _anthropicApiKey => Env.anthropicApiKey;
const String _claudeModel   = Env.claudeModel;
const String _apiUrl        = Env.apiUrl;

// ─── System prompt ────────────────────────────────────────────────────────────
// Sent once per call. Instructs Claude to act as a Kenyan construction
// estimator and return ONLY valid JSON — no markdown fences, no explanations.
const String _systemPrompt = '''
You are an expert construction estimator and procurement officer with deep knowledge 
of the Kenyan construction market (Nairobi and major towns).

Your task:
1. Parse the provided tender document text.
2. Extract every measurable and supply line item.
3. Suggest realistic Kenyan market unit prices (KES) for each item based on 
   current local rates for labour, materials, and equipment.
4. Combine duplicate items and normalise units to: m3, m2, m, kg, pcs, lm, set, lot.
5. If a quantity cannot be determined set it to null.

Return ONLY a single valid JSON object — no markdown fences, no explanation text:

{
  "boq": [
    {
      "item_no": "1",
      "description": "string",
      "unit": "string",
      "quantity": number or null,
      "unit_price": number,
      "amount": number or null
    }
  ],
  "subtotal": number,
  "vat": number,
  "profit": number,
  "grand_total": number
}

Rules:
- amount = quantity * unit_price  (null if quantity is null)
- subtotal = sum of all amounts
- vat = subtotal * 0.16
- profit = 0  (caller applies margin separately)
- grand_total = subtotal + vat + profit
- Use KES market rates current to 2025 for Nairobi, Kenya.
- Never output anything other than the JSON object above.
''';

class AppProvider extends ChangeNotifier {
  // ─── State ───────────────────────────────
  List<Project> _projects = [];
  Project?      _activeProject;
  bool          _isLoading    = false;
  String?       _errorMessage;

  // ─── Getters ─────────────────────────────
  List<Project> get projects      => List.unmodifiable(_projects);
  Project?      get activeProject => _activeProject;
  bool          get isLoading     => _isLoading;
  String?       get errorMessage  => _errorMessage;

  // Dashboard stats
  int get totalProjects  => _projects.length;
  int get activeTenders  =>
      _projects.where((p) => p.status == ProjectStatus.active).length;

  // ─── Init ────────────────────────────────
  AppProvider() {
    _loadProjects();
  }

  // ─── Projects CRUD ───────────────────────

  void addProject(Project project) {
    _projects.insert(0, project);
    _activeProject = project;
    _saveProjects();
    notifyListeners();
  }

  void setActiveProject(Project project) {
    _activeProject = project;
    notifyListeners();
  }

  void updateProject(Project updated) {
    final idx = _projects.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _projects[idx] = updated;
      if (_activeProject?.id == updated.id) _activeProject = updated;
      _saveProjects();
      notifyListeners();
    }
  }

  void deleteProject(String projectId) {
    _projects.removeWhere((p) => p.id == projectId);
    if (_activeProject?.id == projectId) {
      _activeProject = _projects.isNotEmpty ? _projects.first : null;
    }
    _saveProjects();
    notifyListeners();
  }

  // ─── BOQ Management ──────────────────────

  void updateBoqItems(List<BoqItem> items) {
    if (_activeProject == null) return;
    _activeProject = _activeProject!.copyWith(boqItems: items);
    updateProject(_activeProject!);
  }

  void addBoqItem(BoqItem item) {
    if (_activeProject == null) return;
    updateBoqItems([..._activeProject!.boqItems, item]);
  }

  void removeBoqItem(String itemId) {
    if (_activeProject == null) return;
    final items = _activeProject!.boqItems
        .where((i) => i.id != itemId)
        .toList();
    for (int i = 0; i < items.length; i++) items[i].itemNo = i + 1;
    updateBoqItems(items);
  }

  void updateBoqItem(BoqItem updated) {
    if (_activeProject == null) return;
    final items = _activeProject!.boqItems
        .map((i) => i.id == updated.id ? updated : i)
        .toList();
    updateBoqItems(items);
  }

  // ─── AI Extraction — TEXT ─────────────────────────────────────────────────
  //
  // Called from UploadTenderScreen when the user pastes text or when
  // extractBoqFromFile() has already extracted text from a file.
  //
  // Returns an empty list and sets errorMessage on failure.

  Future<List<BoqItem>> extractBoqFromText(String text) async {
    _setLoading(true);
    _clearError();

    try {
      if (text.trim().isEmpty) {
        throw Exception('No content provided for extraction.');
      }

      final items = await _callClaudeApi(userText: text);
      return items;
    } catch (e) {
      _setError('Extraction failed: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // ─── AI Extraction — FILE BYTES ───────────────────────────────────────────
  //
  // For PDF / DOCX / TXT files.  Pass the raw bytes and the file name.
  // The method encodes supported types as base64 (PDF) or decodes plain text,
  // then forwards to the API.
  //
  // Usage from UploadTenderScreen:
  //   final bytes = await _pickedFile!.readAsBytes();  // file_picker gives Uint8List
  //   final items = await provider.extractBoqFromFile(bytes, _pickedFile!.name);

  Future<List<BoqItem>> extractBoqFromFile(
    Uint8List bytes,
    String fileName,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final ext = fileName.split('.').last.toLowerCase();
      List<BoqItem> items;

      if (ext == 'pdf') {
        // Send PDF as a base64 document block — Claude can read PDFs natively.
        items = await _callClaudeApi(pdfBytes: bytes);
      } else {
        // TXT / DOCX: decode bytes as UTF-8 and treat as plain text.
        // For real DOCX you would first extract text server-side or use
        // a Dart DOCX parsing library before calling this method.
        final text = utf8.decode(bytes, allowMalformed: true);
        items = await _callClaudeApi(userText: text);
      }

      return items;
    } catch (e) {
      _setError('File extraction failed: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // ─── Claude API call ──────────────────────────────────────────────────────
  //
  // Builds the request body, calls the API, strips any accidental markdown
  // fences, parses the JSON, and maps it to List<BoqItem>.
  //
  // Exactly ONE of [userText] or [pdfBytes] must be non-null.

  Future<List<BoqItem>> _callClaudeApi({
    String?    userText,
    Uint8List? pdfBytes,
  }) async {
    // Build the content array for the user turn
    final List<Map<String, dynamic>> contentBlocks = [];

    if (pdfBytes != null) {
      // PDF document block — Claude reads it natively
      contentBlocks.add({
        'type': 'document',
        'source': {
          'type'       : 'base64',
          'media_type' : 'application/pdf',
          'data'       : base64Encode(pdfBytes),
        },
      });
      contentBlocks.add({
        'type': 'text',
        'text': 'Extract the Bill of Quantities from this tender document.',
      });
    } else {
      contentBlocks.add({
        'type': 'text',
        'text': userText!,
      });
    }

    final requestBody = jsonEncode({
      'model'      : _claudeModel,
      'max_tokens' : 4096,
      'system'     : _systemPrompt,
      'messages'   : [
        {
          'role'   : 'user',
          'content': contentBlocks,
        },
      ],
    });

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type'      : 'application/json',
        'x-api-key'         : _anthropicApiKey,
        'anthropic-version' : '2023-06-01',
      },
      body: requestBody,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Claude API error ${response.statusCode}: ${response.body}',
      );
    }

    // Parse the API envelope
    final envelope = jsonDecode(response.body) as Map<String, dynamic>;
    final contentList = envelope['content'] as List<dynamic>;

    // Concatenate all text blocks (Claude may split into several)
    final rawText = contentList
        .where((b) => b['type'] == 'text')
        .map<String>((b) => b['text'] as String)
        .join('');

    // Strip accidental markdown fences (safety net)
    final cleaned = rawText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Parse the BOQ JSON
    final Map<String, dynamic> parsed = jsonDecode(cleaned);
    final List<dynamic> boqList = parsed['boq'] as List<dynamic>;

    // Map to BoqItem — note: AI returns unit_price, model uses `rate`
    final items = boqList.asMap().entries.map((entry) {
      final idx  = entry.key;
      final json = entry.value as Map<String, dynamic>;

      return BoqItem(
        itemNo     : idx + 1,
        description: json['description'] as String? ?? '',
        unit       : json['unit']        as String? ?? 'pcs',
        quantity   : _toDouble(json['quantity'])   ?? 0.0,
        rate       : _toDouble(json['unit_price']) ?? 0.0, // ← unit_price → rate
      );
    }).toList();

    return items;
  }

  // ─── Type-safe number coercion ────────────────────────────────────────────
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int)    return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ─── Helpers ─────────────────────────────
  void _setLoading(bool val) { _isLoading = val; notifyListeners(); }
  void _setError(String msg) { _errorMessage = msg; notifyListeners(); }
  void _clearError()         { _errorMessage = null; notifyListeners(); }
  void clearError()          => _clearError();

  // ─── Persistence ─────────────────────────

  Future<void> _loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data  = prefs.getString('projects');
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _projects = decoded.map((j) => Project.fromJson(j)).toList();
        if (_projects.isNotEmpty) _activeProject = _projects.first;
        notifyListeners();
      }
    } catch (_) { /* start fresh on error */ }
  }

  Future<void> _saveProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'projects',
        jsonEncode(_projects.map((p) => p.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ─── Demo seed data ───────────────────────────────────────────────────────
  // Kept so the dashboard has something to show on first launch.

  void seedDemoData() {
    if (_projects.isNotEmpty) return;

    addProject(Project(
      name       : 'Mombasa Road Office Block',
      description: 'G+3 commercial office development along Mombasa Road',
      status     : ProjectStatus.active,
      boqItems   : _demoItems(),
    ));

    addProject(Project(
      name       : 'KPLC Substation Supply',
      description: 'Supply and installation of electrical equipment',
      status     : ProjectStatus.draft,
    ));
  }

  List<BoqItem> _demoItems() => [
    BoqItem(itemNo: 1, description: 'Excavation and earthworks - foundation trenches',  unit: 'm³', quantity: 45.0,  rate: 1800),
    BoqItem(itemNo: 2, description: 'Reinforced concrete grade 25 - foundation slab',   unit: 'm³', quantity: 12.5,  rate: 22000),
    BoqItem(itemNo: 3, description: 'Burnt clay bricks - 230mm wall',                   unit: 'm²', quantity: 180.0, rate: 3500),
    BoqItem(itemNo: 4, description: 'Structural steel columns (100x100 UC)',             unit: 'kg',  quantity: 850.0, rate: 280),
    BoqItem(itemNo: 5, description: 'Corrugated iron roofing sheets - 0.5mm gauge',     unit: 'm²', quantity: 220.0, rate: 1200),
    BoqItem(itemNo: 6, description: 'Electrical wiring 2.5mm twin & earth cable',       unit: 'm',   quantity: 600.0, rate: 85),
    BoqItem(itemNo: 7, description: 'CPVC plumbing pipes 25mm diameter',                unit: 'm',   quantity: 120.0, rate: 450),
    BoqItem(itemNo: 8, description: 'Internal plaster - cement/sand ratio 1:4',         unit: 'm²', quantity: 350.0, rate: 650),
  ];
}
