import 'package:flutter_commons/src/data/app_store/app_store.dart';

Future<AppStore> resolveStore() async {
  return AppStore.web;
}
