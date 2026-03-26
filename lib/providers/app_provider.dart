import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../config/env.dart';

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
- profit = 0
- grand_total = subtotal + vat + profit
- Use KES market rates current to 2025 for Nairobi, Kenya.
- Never output anything other than the JSON object above.
''';

class AppProvider extends ChangeNotifier {
  List<Project> _projects = [];
  Project? _activeProject;
  bool _isLoading = false;
  String? _errorMessage;

  List<Project> get projects => List.unmodifiable(_projects);
  Project? get activeProject => _activeProject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalProjects => _projects.length;
  int get activeTenders =>
      _projects.where((p) => p.status == ProjectStatus.active).length;

  AppProvider() {
    _loadProjects();
  }

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

  Future<List<BoqItem>> extractBoqFromText(String text) async {
    _setLoading(true);
    _clearError();
    try {
      if (text.trim().isEmpty) throw Exception('No content provided.');
      return await _callGeminiApi(userText: text);
    } catch (e) {
      _setError('Extraction failed: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<List<BoqItem>> extractBoqFromFile(
    Uint8List bytes,
    String fileName,
  ) async {
    _setLoading(true);
    _clearError();
    try {
      final text = utf8.decode(bytes, allowMalformed: true);
      return await _callGeminiApi(userText: text);
    } catch (e) {
      _setError('File extraction failed: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<List<BoqItem>> _callGeminiApi({required String userText}) async {
    final url =
        '${Env.apiUrl}?key=${Env.geminiApiKey}';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _systemPrompt},
            {'text': userText},
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 4096,
      },
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
    }

    final envelope = jsonDecode(response.body) as Map<String, dynamic>;
    final rawText = envelope['candidates'][0]['content']['parts'][0]['text'] as String;

    final cleaned = rawText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final Map<String, dynamic> parsed = jsonDecode(cleaned);
    final List<dynamic> boqList = parsed['boq'] as List<dynamic>;

    return boqList.asMap().entries.map((entry) {
      final idx = entry.key;
      final json = entry.value as Map<String, dynamic>;
      return BoqItem(
        itemNo: idx + 1,
        description: json['description'] as String? ?? '',
        unit: json['unit'] as String? ?? 'pcs',
        quantity: _toDouble(json['quantity']) ?? 0.0,
        rate: _toDouble(json['unit_price']) ?? 0.0,
      );
    }).toList();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _setLoading(bool val) { _isLoading = val; notifyListeners(); }
  void _setError(String msg) { _errorMessage = msg; notifyListeners(); }
  void _clearError() { _errorMessage = null; notifyListeners(); }
  void clearError() => _clearError();

  Future<void> _loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('projects');
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _projects = decoded.map((j) => Project.fromJson(j)).toList();
        if (_projects.isNotEmpty) _activeProject = _projects.first;
        notifyListeners();
      }
    } catch (_) {}
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

  void seedDemoData() {
    if (_projects.isNotEmpty) return;
    addProject(Project(
      name: 'Mombasa Road Office Block',
      description: 'G+3 commercial office development along Mombasa Road',
      status: ProjectStatus.active,
      boqItems: _demoItems(),
    ));
    addProject(Project(
      name: 'KPLC Substation Supply',
      description: 'Supply and installation of electrical equipment',
      status: ProjectStatus.draft,
    ));
  }

  List<BoqItem> _demoItems() => [
    BoqItem(itemNo: 1, description: 'Excavation and earthworks - foundation trenches', unit: 'm³', quantity: 45.0, rate: 1800),
    BoqItem(itemNo: 2, description: 'Reinforced concrete grade 25 - foundation slab', unit: 'm³', quantity: 12.5, rate: 22000),
    BoqItem(itemNo: 3, description: 'Burnt clay bricks - 230mm wall', unit: 'm²', quantity: 180.0, rate: 3500),
    BoqItem(itemNo: 4, description: 'Structural steel columns (100x100 UC)', unit: 'kg', quantity: 850.0, rate: 280),
    BoqItem(itemNo: 5, description: 'Corrugated iron roofing sheets - 0.5mm gauge', unit: 'm²', quantity: 220.0, rate: 1200),
    BoqItem(itemNo: 6, description: 'Electrical wiring 2.5mm twin & earth cable', unit: 'm', quantity: 600.0, rate: 85),
    BoqItem(itemNo: 7, description: 'CPVC plumbing pipes 25mm diameter', unit: 'm', quantity: 120.0, rate: 450),
    BoqItem(itemNo: 8, description: 'Internal plaster - cement/sand ratio 1:4', unit: 'm²', quantity: 350.0, rate: 650),
  ];
}