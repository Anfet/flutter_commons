const kb = 1024;
const mb = kb * 1024;
const gb = mb * 1024;

/// Units used by [FormattedFilesize].
enum FilesizeMetric {
  bytes("B"),
  kbytes("KB"),
  mbytes("MB"),
  gbytes("GB");

  /// Text abbreviation used in formatting output.
  final String abbr;

  const FilesizeMetric(this.abbr);
}

/// Stores a file size in bytes and exposes convenience conversions/formatting.
///
/// At most one constructor argument may be provided (`bytes`, `kbytes`,
/// `mbytes`, or `gbytes`); passing several fails an assertion. If all are
/// omitted, the value defaults to `0`.
class FormattedFilesize {
  /// Size value normalized to bytes.
  final int bytes;

  /// Creates a size object from one of supported units.
  FormattedFilesize({int? bytes, int? kbytes, int? mbytes, int? gbytes})
    : assert([bytes, kbytes, mbytes, gbytes].where((it) => it != null).length <= 1, 'Provide at most one size argument'),
      bytes = bytes ?? (kbytes != null ? kbytes * kb : (mbytes != null ? mbytes * mb : (gbytes ?? 0) * gb));

  /// Size in kilobytes, truncated.
  int get inKB => bytes ~/ kb;

  /// Size in megabytes, truncated.
  int get inMB => bytes ~/ mb;

  /// Size in gigabytes, truncated.
  int get inGB => bytes ~/ gb;

  /// Best-fit metric based on current [bytes] value.
  FilesizeMetric get metric =>
      bytes >= gb ? FilesizeMetric.gbytes : (bytes >= mb ? FilesizeMetric.mbytes : (bytes >= kb ? FilesizeMetric.kbytes : FilesizeMetric.bytes));

  /// Returns size converted to a specific [metric].
  int inMetric(FilesizeMetric metric) {
    switch (metric) {
      case FilesizeMetric.bytes:
        return bytes;
      case FilesizeMetric.kbytes:
        return inKB;
      case FilesizeMetric.mbytes:
        return inMB;
      case FilesizeMetric.gbytes:
        return inGB;
    }
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is FormattedFilesize && bytes == other.bytes;

  @override
  int get hashCode => bytes.hashCode;

  /// Formats the size in the best-fit [metric], truncated (1.9 MB -> `1MB`).
  @override
  String toString() {
    return "${inMetric(metric)}${metric.abbr}";
  }
}
