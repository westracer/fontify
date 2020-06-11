import 'dart:typed_data';

import 'abstract.dart';
import 'hhea.dart';
import 'table_record_entry.dart';

const _kLongHorMetricSize = 4;

class LongHorMetric {
  LongHorMetric(this.advanceWidth, this.lsb);

  factory LongHorMetric.fromByteData(ByteData byteData, int offset) {
    return LongHorMetric(
      byteData.getUint16(offset),
      byteData.getInt16(offset + 2),
    );
  }
  
  final int advanceWidth;
  final int lsb;
}

class HorizontalMetricsTable extends FontTable {
  HorizontalMetricsTable(
    TableRecordEntry entry,
    this.hMetrics,
    this.leftSideBearings,
  ) : super.fromTableRecordEntry(entry);

  factory HorizontalMetricsTable.fromByteData(
    ByteData byteData, 
    TableRecordEntry entry,
    HorizontalHeaderTable hhea,
    int numGlyphs
  ) {
    final hMetrics = List.generate(
      hhea.numberOfHMetrics,
      (i) => LongHorMetric.fromByteData(byteData, entry.offset + _kLongHorMetricSize * i)
    );
    final offset = entry.offset + _kLongHorMetricSize * hhea.numberOfHMetrics;
    final leftSideBearings = List.generate(
      numGlyphs - hhea.numberOfHMetrics,
      (i) => byteData.getInt16(offset + 2 * i)
    );

    return HorizontalMetricsTable(entry, hMetrics, leftSideBearings);
  }

  final List<LongHorMetric> hMetrics;
  final List<int> leftSideBearings;
}