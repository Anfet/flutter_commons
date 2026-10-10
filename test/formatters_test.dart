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

    test('formatted can be read repeatedly', () {
      final formatter = CustomFormatter(text: '12345', pattern: '###-##');

      expect(formatter.formatted, '123-45');
      expect(formatter.formatted, '123-45');
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

    test('formats text that replaces a longer selection', () {
      final inputFormatter = CustomInputFormatter(pattern: '###-###');

      final result = inputFormatter.formatEditUpdate(
        const TextEditingValue(text: '123-456'),
        const TextEditingValue(text: '9876'),
      );

      expect(result.text, '987-6');
    });

    test('keeps a plain deletion unformatted so separators can be erased', () {
      final inputFormatter = CustomInputFormatter(pattern: '###-###');

      final result = inputFormatter.formatEditUpdate(
        const TextEditingValue(text: '123-'),
        const TextEditingValue(text: '123'),
      );

      expect(result.text, '123');
    });

    test('formats pasted text longer than the pattern without losing digits', () {
      final inputFormatter = CustomInputFormatter(pattern: '###-###');

      final result = inputFormatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1 2 3 4 5 6'),
      );

      expect(result.text, '123-456');
    });

    test('backwards ignores input beyond the pattern', () {
      final inputFormatter = CustomInputFormatter(pattern: '### ###', backwards: true);

      final result = inputFormatter.formatEditUpdate(
        const TextEditingValue(text: '123 456'),
        const TextEditingValue(text: '123 4567'),
      );

      expect(result.text, '123 456');
    });
  });

  group('CustomFormatter modes', () {
    final cases = <({String name, String text, String pattern, bool strip, bool backwards, String expected})>[
      (name: 'backwards groups from the end', text: '12345', pattern: '### ###', strip: false, backwards: true, expected: '12 345'),
      (name: 'backwards reformats a deletion', text: '12 34', pattern: '### ###', strip: false, backwards: true, expected: '1 234'),
      (name: 'any placeholder copies characters', text: 'ab1c', pattern: '__-__', strip: false, backwards: false, expected: 'ab-1c'),
      (name: 'empty text keeps the leading literals', text: '', pattern: '+X (###)', strip: false, backwards: false, expected: '+X ('),
      (name: 'empty text strips the leading literals', text: '', pattern: '+X (###)', strip: true, backwards: false, expected: ''),
    ];

    for (final c in cases) {
      test(c.name, () {
        final formatter = CustomFormatter(text: c.text, pattern: c.pattern, stripPlaceholdersIfNoText: c.strip, backwards: c.backwards);

        expect(formatter.formatted, c.expected);
      });
    }
  });
}
