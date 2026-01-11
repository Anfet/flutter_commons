import 'package:flutter_commons/src/data/lazy.dart';
import 'package:flutter_commons/src/extensions/list_ext.dart';
import 'package:flutter_commons/src/utils/mutex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
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
    'mutex',
    () async {
      final mutex = Mutex();

      // The first lock should keep the mutex locked for 5 seconds.
      mutex.lock(() async {
        print('Locked 1');
        await Future.delayed(const Duration(seconds: 2));
        print('Unlocked 1');
      });

      await mutex.whileBusy();

      // The second lock shouldn't invoke the methods inside until the first mutex
      // completes the execution (which should happen after the 5 seconds have
      // passed).
      mutex.lock(() async {
        print('Locked 2');
        await Future.delayed(const Duration(seconds: 2));
        print('Unlocked 2');
      });

      await mutex.whileBusy();

      // The third lock should acquire the lock after the first two awaits are done.
      mutex.lock(() async {
        print('Locked 3');
        await Future.delayed(const Duration(seconds: 2));
        print('Unlocked 3');
      });

      await mutex.whileBusy();
    },
  );

  test(
    'take test',
    () {
      var abc = ['a', 'b', 'c', 'd'];
      var r = abc.takeCount(2, remove: true);
      assert(abc.join('') == 'cd');
      assert(r.join() == 'ab');

      abc = ['a', 'b', 'c', 'd'];
      r = abc.takeCount(10, remove: true);
      assert(abc.isEmpty);
      assert(r.length == 4);

      abc = ['a', 'b', 'c', 'd'];
      r = abc.takeLastCount(2, remove: true);
      assert(abc.join('') == 'ab');
      assert(r.join() == 'cd');
    },
  );
}
