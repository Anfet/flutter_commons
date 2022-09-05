import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

extension OrientationExt on Orientation {
  DeviceOrientation get asDeviceOrientation =>
      this == Orientation.portrait ? DeviceOrientation.portraitUp : DeviceOrientation.landscapeLeft;
}
