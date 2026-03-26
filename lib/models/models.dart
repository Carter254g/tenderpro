// lib/models/models.dart
// All data models for TenderPro AI

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─────────────────────────────────────────────
// BOQ Item Model
// ─────────────────────────────────────────────
class BoqItem {
  final String id;
  int itemNo;
  String description;
  String unit;
  double quantity;
  double rate;

  BoqItem({
    String? id,
    required this.itemNo,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.rate,
  }) : id = id ?? _uuid.v4();

  // Auto-calculated total
  double get total => quantity * rate;

  BoqItem copyWith({
    int? itemNo,
    String? description,
    String? unit,
    double? quantity,
    double? rate,
  }) {
    return BoqItem(
      id: id,
      itemNo: itemNo ?? this.itemNo,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemNo': itemNo,
    'description': description,
    'unit': unit,
    'quantity': quantity,
    'rate': rate,
  };

  factory BoqItem.fromJson(Map<String, dynamic> json) => BoqItem(
    id: json['id'],
    itemNo: json['itemNo'],
    description: json['description'],
    unit: json['unit'],
    quantity: (json['quantity'] as num).toDouble(),
    rate: (json['rate'] as num).toDouble(),
  );
}

// ─────────────────────────────────────────────
// Quotation Model
// ─────────────────────────────────────────────
class Quotation {
  final String id;
  final List<BoqItem> items;
  final double vatRate;        // e.g. 0.16 for 16%
  final double profitMargin;  // e.g. 0.10 for 10%
  final DateTime createdAt;

  Quotation({
    String? id,
    required this.items,
    this.vatRate = 0.16,
    this.profitMargin = 0.10,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0, (sum, i) => sum + i.total);
  double get vatAmount => subtotal * vatRate;
  double get marginAmount => subtotal * profitMargin;
  double get grandTotal => subtotal + vatAmount + marginAmount;
}

// ─────────────────────────────────────────────
// Project Model
// ─────────────────────────────────────────────
class Project {
  final String id;
  String name;
  String? description;
  final DateTime createdAt;
  DateTime updatedAt;
  List<BoqItem> boqItems;
  ProjectStatus status;

  Project({
    String? id,
    required this.name,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BoqItem>? boqItems,
    this.status = ProjectStatus.draft,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        boqItems = boqItems ?? [];

  // Quick stats
  int get itemCount => boqItems.length;
  double get totalValue => boqItems.fold(0, (s, i) => s + i.total);

  Project copyWith({
    String? name,
    String? description,
    List<BoqItem>? boqItems,
    ProjectStatus? status,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      boqItems: boqItems ?? this.boqItems,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'boqItems': boqItems.map((i) => i.toJson()).toList(),
    'status': status.name,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    boqItems: (json['boqItems'] as List).map((i) => BoqItem.fromJson(i)).toList(),
    status: ProjectStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => ProjectStatus.draft,
    ),
  );
}

enum ProjectStatus { draft, active, completed, archived }

extension ProjectStatusExtension on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.draft: return 'Draft';
      case ProjectStatus.active: return 'Active';
      case ProjectStatus.completed: return 'Completed';
      case ProjectStatus.archived: return 'Archived';
    }
  }
}
