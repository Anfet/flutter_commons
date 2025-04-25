import 'package:flutter_commons/src/data/app_store/app_store.dart';
import 'package:flutter_commons/src/data/app_store/impl/store_resolver_stub.dart';

class AppStoreResolverWeb implements AppStoreResolver {
  @override
  Future<AppStore> resolve() async {
    return AppStore.web;
  }
}