import 'package:sprintf/sprintf.dart';

extension DurationExt on Duration {
  String get hhmmss {
    Duration copy = Duration(seconds: this.inSeconds);

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
}
