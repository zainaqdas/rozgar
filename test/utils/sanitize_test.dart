import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/utils/sanitize.dart';

void main() {
  group('sanitizeInput', () {
    test('strips raw HTML tags', () {
      expect(sanitizeInput('<script>alert(1)</script>'), 'alert(1)');
    });

    test('decodes entities BEFORE stripping so encoded payloads are removed',
        () {
      final out = sanitizeInput('&lt;script&gt;alert(1)&lt;/script&gt;');
      expect(out.contains('<script>'), isFalse);
      expect(out.contains('&lt;'), isFalse);
      expect(out, 'alert(1)');
    });

    test('preserves plain text', () {
      expect(sanitizeInput('Hello World'), 'Hello World');
    });

    test('decodes ampersand entities', () {
      expect(sanitizeInput('Tom &amp; Jerry'), 'Tom & Jerry');
    });

    test('decodes quote entities', () {
      expect(sanitizeInput('&quot;hi&quot; &#39;there&#39;'), '"hi" \'there\'');
    });

    test('handles empty string', () {
      expect(sanitizeInput(''), '');
    });
  });
}
