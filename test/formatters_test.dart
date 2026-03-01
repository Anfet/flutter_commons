import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomFormatter', () {
    test('formats phone-like pattern +X (###) ##-##-##', () {
      final formatter = CustomFormatter(
        text: '380991112233',
        pattern: '+X (###) ##-##-##',
      );

      expect(formatter.formatted, '+X (380) 99-11-12');
    });

    test('formats mixed direct pattern X-###-AV-SS-##', () {
      final formatter = CustomFormatter(
        text: '12345',
        pattern: 'X-###-AV-SS-##',
      );

      expect(formatter.formatted, 'X-123-AV-SS-45');
    });

    test('digit placeholders skip non-digit symbols', () {
      final formatter = CustomFormatter(
        text: 'a1b2c3d4',
        pattern: '###-#',
      );

      expect(formatter.formatted, '123-4');
    });
  });

  group('CustomInputFormatter', () {
    test('applies +X (###) ##-##-## pattern on input', () {
      final inputFormatter = CustomInputFormatter(pattern: '+X (###) ##-##-##');

      final result = inputFormatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '380991112233'),
      );

      expect(result.text, '+X (380) 99-11-12');
      expect(result.selection.baseOffset, result.text.length);
      expect(result.selection.extentOffset, result.text.length);
    });

    test('applies X-###-AV-SS-## pattern on input', () {
      final inputFormatter = CustomInputFormatter(pattern: 'X-###-AV-SS-##');

      final result = inputFormatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '98765'),
      );

      expect(result.text, 'X-987-AV-SS-65');
    });

    test('preserves meaningful spaces in source text', () {
      final inputFormatter = CustomInputFormatter(pattern: '___');

      final result = inputFormatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: ' A'),
      );

      expect(result.text, ' A');
    });
  });
}
