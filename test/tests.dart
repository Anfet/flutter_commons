import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // test(
  //   'custom formatter forward',
  //   () {
  //     var text = ' 2 3456';
  //     var result = CustomFormatter(text: text, pattern: '### ###').formatted;
  //     print(result);
  //     assert(result == '234 56');
  //   },
  // );

  test(
    'custom formatter backwards',
    () {
      var text = '1234567';
      var result = CustomFormatter(text: text, pattern: '# ### ### ###', backwards: true).formatted;
      print(result);
      assert(result == '1 234 567');
    },
  );

  test('as', () async {
    var m = {'a': 'b'};
    var f = Future.value(m);
    var x11 = await f.map((key, value) => const MapEntry(1, 2));

  },);
}
