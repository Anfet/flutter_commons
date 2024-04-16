extension MapImploder<K, V> on Map<K, V> {
  String join({String separator = ",", String keyValueSeparator = "=", bool addEmptyValues = false}) {
    List keyList = keys.where((element) => addEmptyValues || ("$element".isNotEmpty && "${this[element]}".isNotEmpty)).toList(growable: false);

    String result = List.generate(keyList.length, (index) {
      var key = keyList[index];
      var value = this[key];
      return "$key$keyValueSeparator$value";
    }).join(separator);

    return result;
  }
}