import 'package:flutter/services.dart';
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

    const phone = '+7 (###) ###-##-##';
    final edits = <({String name, String pattern, bool backwards, String old, int oldCaret, String next, int nextCaret, String text, int caret})>[
      (
        name: 'a typed digit equal to a literal fills the first placeholder',
        pattern: phone,
        backwards: false,
        old: '',
        oldCaret: 0,
        next: '7',
        nextCaret: 1,
        text: '+7 (7',
        caret: 5,
      ),
      (
        name: 'a raw paste with the country code skips the literal',
        pattern: phone,
        backwards: false,
        old: '',
        oldCaret: 0,
        next: '79123456789',
        nextCaret: 11,
        text: '+7 (912) 345-67-89',
        caret: 18,
      ),
      (
        name: 'a formatted paste keeps its digits',
        pattern: phone,
        backwards: false,
        old: '',
        oldCaret: 0,
        next: '+7 (912) 345-67-89',
        nextCaret: 18,
        text: '+7 (912) 345-67-89',
        caret: 18,
      ),
      (
        name: 'a paste with separators keeps every digit',
        pattern: '###-###',
        backwards: false,
        old: '',
        oldCaret: 0,
        next: '1 2 3 4 5 6',
        nextCaret: 11,
        text: '123-456',
        caret: 7,
      ),
      (
        name: 'typing after a group adds the separator',
        pattern: phone,
        backwards: false,
        old: '+7 (912',
        oldCaret: 7,
        next: '+7 (9123',
        nextCaret: 8,
        text: '+7 (912) 3',
        caret: 10,
      ),
      (
        name: 'typing in the middle keeps the caret at the edit',
        pattern: phone,
        backwards: false,
        old: '+7 (912) 3',
        oldCaret: 5,
        next: '+7 (9512) 3',
        nextCaret: 6,
        text: '+7 (951) 23',
        caret: 6,
      ),
      (
        name: 'backspace over a separator erases the previous digit',
        pattern: phone,
        backwards: false,
        old: '+7 (912) 3',
        oldCaret: 8,
        next: '+7 (912 3',
        nextCaret: 7,
        text: '+7 (913',
        caret: 6,
      ),
      (
        name: 'delete over a separator erases the next digit',
        pattern: phone,
        backwards: false,
        old: '+7 (912) 3',
        oldCaret: 7,
        next: '+7 (912 3',
        nextCaret: 7,
        text: '+7 (912',
        caret: 7,
      ),
      (
        name: 'a full value ignores more input',
        pattern: phone,
        backwards: false,
        old: '+7 (912) 345-67-89',
        oldCaret: 18,
        next: '+7 (912) 345-67-890',
        nextCaret: 19,
        text: '+7 (912) 345-67-89',
        caret: 18,
      ),
      (
        name: 'a shorter text replacing the selection is formatted',
        pattern: '###-###',
        backwards: false,
        old: '123-456',
        oldCaret: 7,
        next: '9876',
        nextCaret: 4,
        text: '987-6',
        caret: 5,
      ),
      (
        name: 'any placeholders add no trailing separator',
        pattern: '__-__',
        backwards: false,
        old: 'a',
        oldCaret: 1,
        next: 'ab',
        nextCaret: 2,
        text: 'ab',
        caret: 2,
      ),
      (
        name: 'any placeholders keep emoji whole',
        pattern: '__-__',
        backwards: false,
        old: '',
        oldCaret: 0,
        next: '😀ab',
        nextCaret: 4,
        text: '😀a-b',
        caret: 5,
      ),
      (
        name: 'backwards typing regroups from the end',
        pattern: '### ###',
        backwards: true,
        old: '12 345',
        oldCaret: 6,
        next: '12 3456',
        nextCaret: 7,
        text: '123 456',
        caret: 7,
      ),
      (
        name: 'backwards backspace over a separator erases the previous digit',
        pattern: '### ###',
        backwards: true,
        old: '12 345',
        oldCaret: 3,
        next: '12345',
        nextCaret: 2,
        text: '1 345',
        caret: 1,
      ),
      (
        name: 'backwards full value ignores more input',
        pattern: '### ###',
        backwards: true,
        old: '123 456',
        oldCaret: 7,
        next: '123 4567',
        nextCaret: 8,
        text: '123 456',
        caret: 7,
      ),
      (
        name: 'text set by the app is formatted from scratch',
        pattern: '###-###',
        backwards: false,
        old: '1234',
        oldCaret: 4,
        next: '12345',
        nextCaret: 5,
        text: '123-45',
        caret: 6,
      ),
    ];

    for (final e in edits) {
      test(e.name, () {
        final formatter = CustomInputFormatter(pattern: e.pattern, backwards: e.backwards);

        final result = formatter.formatEditUpdate(
          TextEditingValue(
            text: e.old,
            selection: TextSelection.collapsed(offset: e.oldCaret),
          ),
          TextEditingValue(
            text: e.next,
            selection: TextSelection.collapsed(offset: e.nextCaret),
          ),
        );

        expect((result.text, result.selection.baseOffset), (e.text, e.caret));
      });
    }
  });

  group('CustomFormatter modes', () {
    final cases = <({String name, String text, String pattern, bool strip, bool backwards, String expected})>[
      (name: 'backwards groups from the end', text: '12345', pattern: '### ###', strip: false, backwards: true, expected: '12 345'),
      (name: 'backwards reformats a deletion', text: '12 34', pattern: '### ###', strip: false, backwards: true, expected: '1 234'),
      (name: 'any placeholder copies characters', text: 'ab1c', pattern: '__-__', strip: false, backwards: false, expected: 'ab-1c'),
      (name: 'any placeholder adds no trailing literal', text: 'ab', pattern: '__-__', strip: false, backwards: false, expected: 'ab'),
      (name: 'trailing non-digits add no trailing literal', text: '123a', pattern: '###-#', strip: false, backwards: false, expected: '123'),
      (name: 'a literal does not swallow a raw digit', text: '7', pattern: '+7 (###)', strip: false, backwards: false, expected: '+7 (7'),
      (
        name: 'extra raw digits skip a matching literal',
        text: '79123456789',
        pattern: '+7 (###) ###-##-##',
        strip: false,
        backwards: false,
        expected: '+7 (912) 345-67-89',
      ),
      (name: 'emoji fills one placeholder', text: '😀😀x', pattern: '__', strip: false, backwards: true, expected: '😀x'),
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
