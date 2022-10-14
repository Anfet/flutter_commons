import 'package:flutter/foundation.dart';

import 'bloc_reaction.dart';

@immutable
abstract class BlocState {
  Iterable<BlocReaction?> get reactions => [];
}
