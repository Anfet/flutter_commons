class NavigationRoute {
  static const noPathIndex = -1;
  final String path;
  late final List<String> parts;
  late final Map<String, String> arguments;
  int _pathIndex = noPathIndex;

  NavigationRoute(this.path) {
    final uri = Uri.tryParse(path) ?? Uri();
    parts = List.unmodifiable(uri.pathSegments.toList());
    arguments = Map.unmodifiable(uri.queryParameters);
  }

  bool get hasCurrentPath => _pathIndex > noPathIndex;

  String get currentPath => parts[_pathIndex];

  bool get hasNextPath => _pathIndex < parts.length - 1;

  String advance() {
    assert(hasNextPath, "navigation path has no more parts");
    _pathIndex++;
    return parts[_pathIndex];
  }

  Map<String, dynamic> toMap() {
    return {
      'path': this.path,
      'parts': this.parts,
      'arguments': this.arguments,
      'pathIndex': this._pathIndex,
    };
  }

  factory NavigationRoute.fromMap(Map<String, dynamic> map) {
    return NavigationRoute.init(
      path: map['path'] as String,
      parts: map['parts'] as List<String>,
      arguments: map['arguments'] as Map<String, String>,
      pathIndex: map['pathIndex'] as int,
    );
  }

  NavigationRoute.init({
    required this.path,
    required this.parts,
    required this.arguments,
    required int pathIndex,
  }) : _pathIndex = pathIndex;
}
