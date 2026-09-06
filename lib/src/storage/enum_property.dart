import 'storable_property.dart';

/// Public class EnumProperty.
class EnumProperty<T extends Enum> extends StorablePropertyImpl<T> {
  final T defaultValue;
  final Iterable<T> values;

  EnumProperty(super.storage, super.name, {required this.values, super.onSave, required this.defaultValue}) : super(defaultValue: () => defaultValue);

  @override
  T decode(String value) {
    for (final candidate in values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
    throw FormatException('Invalid enum value for "$name"');
  }

  @override
  String encode(T value) => value.name;
}
