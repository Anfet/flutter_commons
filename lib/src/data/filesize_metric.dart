const kb = 1024;
const mb = kb * 1024;
const gb = mb * 1024;

enum FilesizeMetric {
  bytes("B"),
  kbytes("KB"),
  mbytes("MB"),
  gbytes("GB");

  final String abbr;

  const FilesizeMetric(this.abbr);
}

class FormattedFilesize {
  late final int bytes;

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

  int get inKB => (bytes / kb).truncate();

  int get inMB => (bytes / mb).truncate();

  int get inGB => (bytes / gb).truncate();

  FilesizeMetric get metric =>
      bytes >= gb ? FilesizeMetric.gbytes : (bytes >= mb ? FilesizeMetric.mbytes : (bytes >= kb ? FilesizeMetric.kbytes : FilesizeMetric.bytes));

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
