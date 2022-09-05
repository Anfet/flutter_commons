const KB = 1024;
const MB = KB * 1024;
const GB = MB * 1024;

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
      this.bytes = kbytes * KB;
    } else if (mbytes != null) {
      this.bytes = mbytes * MB;
    } else if (gbytes != null) {
      this.bytes = gbytes * GB;
    } else {
      this.bytes = 0;
    }
  }

  int get inKB => (bytes / KB).truncate();

  int get inMB => (bytes / MB).truncate();

  int get inGB => (bytes / GB).truncate();

  FilesizeMetric get metric => bytes >= GB
      ? FilesizeMetric.gbytes
      : (bytes >= MB ? FilesizeMetric.mbytes : (bytes >= KB ? FilesizeMetric.kbytes : FilesizeMetric.bytes));

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
