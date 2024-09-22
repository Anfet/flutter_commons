import 'package:flutter/material.dart';
import 'package:flutter_commons/src/utils.dart';

extension WidgetExt on Widget {
  Widget get expanded => Expanded(child: this);
}

extension StateExt<T extends StatefulWidget> on State<T> {
  void scheduleOnNextFrame(VoidCallback block) => WidgetsBinding.instance.addPostFrameCallback((timeStamp) => block());
}

extension GlobalKeyExt<T extends State<StatefulWidget>> on GlobalKey<T> {
  Widget get requireWidget => require(currentWidget);

  T get requireState => require(currentState);

  BuildContext get requireContext => require(requireContext);
}
