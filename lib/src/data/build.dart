import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:siberian_core/siberian_core.dart';

enum Enviroment { dev, stage, prod, custom }

class Enviroments {
  Enviroments._();

  static Map<Enviroment, String> enviroments = {};
}

@immutable
class Build {
  final String enviroment;
  final String host;

  bool get isProd => enviroment == "prod";

  const Build({
    required this.enviroment,
    required this.host,
  });

  Future<void> save(Property<String> property) async {
    var value = jsonEncode({'host': host, 'enviroment': enviroment});
    await property.setValue(value);
  }

  factory Build.from(String text) {
    try {
      var json = jsonDecode(text);
      var build = Build(enviroment: json['enviroment'], host: json['host']);
      return build;
    } catch (ex) {
      return Build(enviroment: Enviroment.prod.name, host: Enviroments.enviroments[Enviroment.prod]!);
    }
  }

  static Future<Build> load(Property<String> property) async {
    var text = await property.getValue();
    return Build.from(text);
  }

  @override
  String toString() {
    return 'Build{enviroment: $enviroment, host: $host}';
  }
}
