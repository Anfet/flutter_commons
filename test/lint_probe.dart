import 'package:flutter_commons/flutter_commons.dart';

class NonWaitable implements BlocEvent {}

void check(Bloc<BlocEvent, int> bloc) {
  bloc.addAndWait(NonWaitable());
}
