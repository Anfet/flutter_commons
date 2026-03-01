extension BoolExt on bool {
  int compareTo(bool other) => this == other ? 0 : (this ? 1 : -1);

  int toInt() => this ? 1 : 0;

  int? compareOrNull(bool b) => this == b ? null : compareTo(b);
}
