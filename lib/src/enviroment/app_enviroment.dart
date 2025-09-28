import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_commons/src/storage/storable_property.dart';

enum Enviroment { dev, stage, prod, custom }

class Enviroments {
  Enviroments._();

  static Map<Enviroment, String> enviroments = {};
}

@immutable
class AppEnviroment {
  final String enviroment;
  final String host;

  bool get isProd => enviroment == "prod";

  const AppEnviroment({
    required this.enviroment,
    required this.host,
  });

  Future<void> save(StorableProperty<String> property) async {
    var value = jsonEncode({'host': host, 'enviroment': enviroment});
    await property.setValue(value);
  }

  factory AppEnviroment.from(String text) {
    try {
      var json = jsonDecode(text);
      var build = AppEnviroment(enviroment: json['enviroment'], host: json['host']);
      return build;
    } catch (ex) {
      return AppEnviroment(enviroment: Enviroment.prod.name, host: Enviroments.enviroments[Enviroment.prod]!);
    }
  }

  static Future<AppEnviroment> load(StorableProperty<String> property) async {
    var text = await property.getValue();
    return AppEnviroment.from(text);
  }

  @override
  String toString() {
    return 'AppEnviroment{enviroment: $enviroment, host: $host}';
  }
}
