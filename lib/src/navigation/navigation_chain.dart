import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:siberian_core/siberian_core.dart';

enum NavigationChainFlow {
  ///the flow must push another route. the somewhere in future a OnChainResult event will follow
  push,

  ///the flow must replace current route. no more events will be fired
  replace,

  ///the flow must ignore the chain
  ignore,
}

class NavigationChain with Logging {
  late final List<String> segments;
  late final Map<String, String> queryParameters;

  bool get hasRoute => segments.isNotEmpty;

  String get route => segments.isEmpty ? "/" : "/${segments.first}";

  bool get canAdvance => segments.length > 1;

  String get path => "/$_segmentString${queryParameters.isEmpty ? "" : "?$_queryString"}";

  String get _queryString => queryParameters.join(separator: "&");

  String get _segmentString => segments.join("/");

  NavigationChain(String path) {
    Uri? uri = Uri.tryParse(path);

    if (uri == null) {
      if (!path.startsWith("/")) {
        path = "/$path";
        uri = Uri.tryParse(path);
      }
    }

    if (uri == null) {
      throw BadPathException("cannot parse url '$path'");
    }

    segments = List.of(uri.pathSegments);
    queryParameters = Map.unmodifiable(uri.queryParameters);
  }

  NavigationChain? advance() {
    if (canAdvance) {
      final advancedSegments = segments.sublist(1);
      final advancedPath = "/${advancedSegments.join("/")}${queryParameters.isEmpty ? "" : "?$_queryString"}";
      return NavigationChain(advancedPath);
    }

    return null;
  }

  String consumeRoute() {
    if (!hasRoute) {
      throw const ReachedEndException("cannot consume route; reached chain end");
    }

    final result = segments.removeAt(0);
    log("'$path' -> consuming '/$result' as route");
    return "/$result";
  }

  ///just consumes the argument without advancing to next screen
  String takeArgument() {
    if (!hasRoute) {
      throw const ReachedEndException("cannot consume; reached chain end");
    }

    final result = segments.removeAt(0);
    log("'$path' -> consuming '$result' as argument");
    return result;
  }
}

@immutable
class NavigationChainException extends AppException {
  const NavigationChainException(super.message);
}

@immutable
class BadPathException extends NavigationChainException {
  const BadPathException(super.message);
}

@immutable
class ReachedEndException extends NavigationChainException {
  const ReachedEndException(super.message);
}
