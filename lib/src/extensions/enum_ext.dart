extension EnumByName<T extends Enum> on Iterable<T> {
  T byNameOr(String name, T defaultValue) {
    try {
      return byName(name);
    } catch (_) {
      return defaultValue;
    }
  }
}
