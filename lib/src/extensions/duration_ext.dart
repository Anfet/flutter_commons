import 'package:sprintf/sprintf.dart';

extension DurationExt on Duration {
  String get hhmmss {
    Duration copy = Duration(seconds: inSeconds);

    final hours = copy.inHours;
    if (hours > 0) {
      copy -= Duration(hours: hours);
    }

    final minutes = copy.inMinutes;
    if (minutes > 0) {
      copy -= Duration(minutes: minutes);
    }

    if (hours > 0) {
      return sprintf('%02d:%02d:%02d', [hours, minutes, copy.inSeconds]);
    } else {
      return sprintf('%02d:%02d', [minutes, copy.inSeconds]);
    }
  }

  Future get future => Future.delayed(this);

  Future get wait => future;

  /// Divides to millisecond precision. [divider] must be finite and non-zero.
  Duration operator /(double divider) {
    if (divider == 0 || !divider.isFinite) {
      throw ArgumentError.value(divider, 'divider', 'Must be finite and non-zero');
    }
    return Duration(milliseconds: inMilliseconds ~/ divider);
  }
}

extension IntForDuration on int {
  Duration get milliseconds => Duration(milliseconds: this);

  Duration get seconds => Duration(seconds: this);

  Duration get minutes => Duration(minutes: this);

  Duration get hours => Duration(hours: this);

  Duration get days => Duration(days: this);

  Duration get weeks => Duration(days: this * 7);
}
