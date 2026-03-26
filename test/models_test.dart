// test/models_test.dart
// Basic unit tests for TenderPro AI models

import 'package:flutter_test/flutter_test.dart';
import 'package:tenderpro_ai/models/models.dart';

void main() {
  group('BoqItem', () {
    test('total is quantity × rate', () {
      final item = BoqItem(
        itemNo: 1,
        description: 'Excavation',
        unit: 'm³',
        quantity: 10,
        rate: 1800,
      );
      expect(item.total, 18000);
    });

    test('copyWith preserves id', () {
      final item = BoqItem(
        itemNo: 1,
        description: 'Concrete',
        unit: 'm³',
        quantity: 5,
        rate: 22000,
      );
      final updated = item.copyWith(quantity: 10);
      expect(updated.id, item.id);
      expect(updated.quantity, 10);
    });

    test('JSON round-trip', () {
      final item = BoqItem(
        itemNo: 2,
        description: 'Brickwork',
        unit: 'm²',
        quantity: 50,
        rate: 3500,
      );
      final json = item.toJson();
      final restored = BoqItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.total, item.total);
    });
  });

  group('Quotation', () {
    test('grand total includes VAT and margin', () {
      final items = [
        BoqItem(itemNo: 1, description: 'Item A', unit: 'pcs', quantity: 10, rate: 1000),
      ];
      final q = Quotation(items: items, vatRate: 0.16, profitMargin: 0.10);
      // subtotal = 10000, vat = 1600, margin = 1000, grand = 12600
      expect(q.subtotal, 10000);
      expect(q.vatAmount, 1600);
      expect(q.marginAmount, 1000);
      expect(q.grandTotal, 12600);
    });
  });

  group('Project', () {
    test('itemCount and totalValue aggregate boqItems', () {
      final project = Project(
        name: 'Test Project',
        boqItems: [
          BoqItem(itemNo: 1, description: 'A', unit: 'm²', quantity: 10, rate: 500),
          BoqItem(itemNo: 2, description: 'B', unit: 'm³', quantity: 5, rate: 2000),
        ],
      );
      expect(project.itemCount, 2);
      expect(project.totalValue, 15000); // 5000 + 10000
    });

    test('JSON round-trip preserves all fields', () {
      final project = Project(
        name: 'Round Trip',
        description: 'Test',
        status: ProjectStatus.active,
      );
      final json = project.toJson();
      final restored = Project.fromJson(json);
      expect(restored.id, project.id);
      expect(restored.name, project.name);
      expect(restored.status, ProjectStatus.active);
    });
  });
}
