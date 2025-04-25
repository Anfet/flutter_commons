import 'randomizer.dart';

const nbsp = ' ';
final void Function() nothing = () {};

class Strings {
  Strings._();

  static const String empty = "";
  static const String space = " ";
}

class Ints {
  Ints._();

  static const int zero = 0;

  static const int maxInt = 0x7fffffff;

  static int randomInt() => random.nextInt(0xffffffff);
}
