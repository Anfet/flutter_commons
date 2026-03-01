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
/// Exactly one constructor argument is typically provided (`bytes`, `kbytes`,
/// `mbytes`, or `gbytes`). If all are omitted, the value defaults to `0`.
class FormattedFilesize {
  /// Size value normalized to bytes.
  late final int bytes;

  /// Creates a size object from one of supported units.
  FormattedFilesize({int? bytes, int? kbytes, int? mbytes, int? gbytes}) {
    if (bytes != null) {
      this.bytes = bytes;
    } else if (kbytes != null) {
      this.bytes = kbytes * kb;
    } else if (mbytes != null) {
      this.bytes = mbytes * mb;
    } else if (gbytes != null) {
      this.bytes = gbytes * gb;
    } else {
      this.bytes = 0;
    }
  }

  /// Size in kilobytes, truncated.
  int get inKB => (bytes / kb).truncate();

  /// Size in megabytes, truncated.
  int get inMB => (bytes / mb).truncate();

  /// Size in gigabytes, truncated.
  int get inGB => (bytes / gb).truncate();

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
  String toString() {
    return "${inMetric(metric)}${metric.abbr}";
  }
}
