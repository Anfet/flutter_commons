import 'package:flutter/painting.dart';

extension TextStyleExt on TextStyle {
  TextStyle bold() => copyWith(fontWeight: FontWeight.bold);

  TextStyle medium() => copyWith(fontWeight: FontWeight.w500);

  TextStyle normal() => copyWith(fontWeight: FontWeight.w400);

  TextStyle thin() => copyWith(fontWeight: FontWeight.w300);

  TextStyle extraBold() => copyWith(fontWeight: FontWeight.w800);

  TextStyle w100() => copyWith(fontWeight: FontWeight.w100);

  TextStyle w200() => copyWith(fontWeight: FontWeight.w200);

  TextStyle w300() => copyWith(fontWeight: FontWeight.w300);

  TextStyle w400() => copyWith(fontWeight: FontWeight.w400);

  TextStyle w500() => copyWith(fontWeight: FontWeight.w500);

  TextStyle w600() => copyWith(fontWeight: FontWeight.w600);

  TextStyle w700() => copyWith(fontWeight: FontWeight.w700);

  TextStyle w800() => copyWith(fontWeight: FontWeight.w800);

  TextStyle w900() => copyWith(fontWeight: FontWeight.w900);
}
