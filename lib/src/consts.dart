//ignore_for_file: prefer_function_declarations_over_variables
import 'randomizer.dart';

final nothing = () {};
final noop = () {};
final noopP1 = (_) {};
final noopP2 = (_, __) {};

class Strings {
  Strings._();

  static const String empty = "";
  static const String space = " ";
  static const nbsp = ' ';
}

class Ints {
  Ints._();

  static const int zero = 0;

  static const int maxInt = 0x7fffffff;

  static int randomInt() => random.nextInt(0xffffffff);
}
