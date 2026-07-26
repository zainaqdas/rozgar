import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/models/category.dart';

void main() {
  group('Category', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'home-electrical',
        'nameEn': 'Electrical Work',
        'nameUr': 'بجلی کا کام',
        'iconName': 'Zap',
        'parentCategory': 'Home Services',
        'subcategories': [
          {'id': 'wiring', 'nameEn': 'Wiring', 'nameUr': 'وائرنگ'},
          {'id': 'fan-light', 'nameEn': 'Fan & Light', 'nameUr': 'پنکھا اور لائٹ'},
        ],
      };

      final cat = Category.fromJson(json);
      expect(cat.id, 'home-electrical');
      expect(cat.nameEn, 'Electrical Work');
      expect(cat.subcategories.length, 2);
      expect(cat.subcategories[0].nameEn, 'Wiring');
    });

    test('handles empty subcategories', () {
      final json = {
        'id': 'test-cat',
        'nameEn': 'Test',
        'nameUr': 'ٹیسٹ',
      };

      final cat = Category.fromJson(json);
      expect(cat.subcategories, isEmpty);
      expect(cat.iconName, '');
    });
  });

  group('Subcategory', () {
    test('fromJson parses correctly', () {
      final json = {'id': 'pipe-leak', 'nameEn': 'Pipe Leakage', 'nameUr': 'پائپ لیکج'};
      final sub = Subcategory.fromJson(json);

      expect(sub.id, 'pipe-leak');
      expect(sub.nameEn, 'Pipe Leakage');
    });
  });
}
