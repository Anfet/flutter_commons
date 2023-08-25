import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:sprintf/sprintf.dart';

const _maxCharactersInLine = 800;
final _pattern = RegExp('.{50,$_maxCharactersInLine}');
final _dateFormatter = DateFormat("Hms");
const _tagAction = ":";
const _encoder = JsonEncoder.withIndent(null);

Logger logger = Logger(
  printer: CustomLogger(
    truncateMessages: true,
  ),
);

void installLogger(Logger value) {
  logger = value;
}

class CustomLogger extends LogPrinter {
  final bool truncateMessages;

  CustomLogger({this.truncateMessages = true}) : super();

  @override
  List<String> log(LogEvent event) {
    var messageStr = _stringifyMessage(event.message);
    var errorStr = event.error != null ? '\n${event.error}' : '';
    final now = DateTime.now();
    final msec = sprintf("%03i", [now.millisecond]);
    var timeStr = "${_dateFormatter.format(now)}.$msec";
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
      return _encoder.convert(finalMessage);
    } else {
      return finalMessage.toString();
    }
  }
}

void logCustom(message, {String tag = "", Level level = Level.trace, dynamic error, StackTrace? stackTrace}) {
  logger.log(level, (tag.isEmpty ? message : "$tag$_tagAction $message"), error: error, stackTrace: stackTrace);
}

mixin Logging {
  void logMessage(message, {String? tag, Level level = Level.trace, dynamic error, StackTrace? stackTrace}) =>
      logCustom(message, level: level, tag: tag ?? "$runtimeType", error: error, stackTrace: stackTrace);

  void warn(message, {String? tag, dynamic error, StackTrace? stackTrace}) =>
      logCustom(message, level: Level.warning, tag: tag ?? "$runtimeType", error: error, stackTrace: stackTrace);

  @deprecated
  void verbose(message, {String? tag, dynamic error, StackTrace? stackTrace}) =>
      logCustom(message, level: Level.trace, tag: tag ?? "$runtimeType", error: error, stackTrace: stackTrace);

  void trace(message, {String? tag, dynamic error, StackTrace? stackTrace}) =>
      logCustom(message, level: Level.trace, tag: tag ?? "$runtimeType", error: error, stackTrace: stackTrace);

  void error(message, [dynamic error, StackTrace? stackTrace, String? tag]) =>
      logCustom(message, level: Level.error, tag: tag ?? "$runtimeType", error: error, stackTrace: stackTrace);
}
