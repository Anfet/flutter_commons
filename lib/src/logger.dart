import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:sprintf/sprintf.dart';

const _maxCharactersInLine = 800;
final _pattern = RegExp('.{50,$_maxCharactersInLine}');
final _dateFormatter = DateFormat("Hms");
const _tagAction = ":";

class GlobalLogger with Logging {
  GlobalLogger._();

  static final GlobalLogger instance = GlobalLogger._();
}

class CustomLogger extends LogPrinter {
  final bool truncateMessages;

  CustomLogger({
    this.truncateMessages = true,
  }) : super();

  @override
  List<String> log(LogEvent event) {
    var messageStr = _stringifyMessage(event.message);
    var errorStr = event.error != null ? '\n${event.error}' : '';
    final now = DateTime.now();
    final msec = sprintf("%03i", [now.millisecond]);
    var timeStr = _dateFormatter.format(now) + ".$msec";
    var traceStr = event.stackTrace == null ? "" : "\n${event.stackTrace}";
    final text = '${_labelFor(event.level)} $timeStr $messageStr$errorStr$traceStr';

    final result = _pattern.allMatches(text).map((match) => match[0] ?? "").toList();

    if (!truncateMessages) {
      return result;
    }

    while (result.join("").length > _maxCharactersInLine) {
      result.removeLast();
    }

    return result;
  }

  String _labelFor(Level level) {
    var prefix = SimplePrinter.levelPrefixes[level]!;
    final color = SimplePrinter.levelColors[level]!;

    return color(prefix);
  }

  String _stringifyMessage(dynamic message) {
    final finalMessage = message is Function ? message() : message;
    if (finalMessage is Map || finalMessage is Iterable) {
      var encoder = JsonEncoder.withIndent(null);
      return encoder.convert(finalMessage);
    } else {
      return finalMessage.toString();
    }
  }
}

final _logger = Logger(
  printer: CustomLogger(
    truncateMessages: true,
  ),
);

void _logCustom(String message,
        {String tag = "", Level level = Level.verbose, dynamic error, StackTrace? stackTrace}) =>
    _logger.log(level, (tag.isEmpty ? message : "$tag$_tagAction $message"), error, stackTrace);

mixin Logging {
  void logMessage(String message, {String? tag, Level level = Level.verbose, dynamic error, StackTrace? stackTrace}) =>
      _logCustom(message, level: level, tag: tag ?? "$runtimeType", error: error, stackTrace: stackTrace);
}
