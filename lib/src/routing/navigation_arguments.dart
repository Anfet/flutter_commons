typedef NavigationArguments = Map<String, String>;

extension NavitationArgumentsExt on NavigationArguments {
  String toQuery() {
    if (isEmpty) return "";
    var query = "?";
    var list = <String>[];
    for (var key in keys) {
      var value = Uri.encodeQueryComponent(this[key] ?? "");
      list.add("$key=$value");
    }
    return query + list.join("&");
  }
}
