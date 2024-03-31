import 'randomizer.dart';

class Strings {
  Strings._();

  static const String empty = "";
  static const String space = " ";
}

class Ints {
  Ints._();

  static const int zero = 0;

  static const int maxInt = 0x7fffffff;

  static int randomInt() => randomizer.nextInt(0xffffffff);
}
