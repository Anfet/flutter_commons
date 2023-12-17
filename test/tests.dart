import 'package:flutter_test/flutter_test.dart';
import 'package:siberian_core/src/utils/separated_list.dart';

void main() {
  test('separator test', () {
    var list = ['a', 'b', 'c'];
    var separated = SeparatedList.builder(
      list,
      builder: (index, item, list) => item,
      separatorBuilder: (index, item, list) => '-',
    );
    assert(separated.length == 5);
    var joined = separated.join();
    assert(joined == 'a-b-c');
  });
}
