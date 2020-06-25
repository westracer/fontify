import 'dart:math' as math;
import 'dart:typed_data';

import '../../utils/misc.dart';

import 'abstract.dart';
import 'glyf.dart';
import 'glyph/simple.dart';
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

  factory LongHorMetric.createForGlyph(SimpleGlyph glyph) {
    return LongHorMetric(glyph.header.xMax - glyph.header.xMin, 0);
  }
  
  final int advanceWidth;
  final int lsb;

  int getRsb(int xMax, int xMin) => advanceWidth - (lsb + xMax - xMin);

  int get size => _kLongHorMetricSize;
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

  factory HorizontalMetricsTable.create(GlyphDataTable glyf) {
    final hMetrics = List.generate(
      glyf.glyphList.length,
      (i) => LongHorMetric.createForGlyph(glyf.glyphList[i])
    );

    return HorizontalMetricsTable(null, hMetrics, []);
  }

  final List<LongHorMetric> hMetrics;
  final List<int> leftSideBearings;

  // TODO: subtract _kLongHorMetricSize?
  @override
  int get size => hMetrics.length * _kLongHorMetricSize + leftSideBearings.length * 2;  

  int get advanceWidthMax => hMetrics.fold<int>(0, (p, v) => math.max(p, v.advanceWidth));

  int get minLeftSideBearing => hMetrics.fold<int>(kInt64Max, (p, v) => math.min(p, v.lsb));

  int getMinRightSideBearing(GlyphDataTable glyf) {
    int minRsb = kInt64Max;

    for (int i = 0; i < glyf.glyphList.length; i++) {
      final g = glyf.glyphList[i];
      final rsb = hMetrics[i].getRsb(g.header.xMax, g.header.xMin);

      minRsb = math.min(minRsb, rsb);
    }

    return minRsb;
  }

  int getMaxExtent(GlyphDataTable glyf) {
    int maxExtent = kInt64Min;

    for (int i = 0; i < glyf.glyphList.length; i++) {
      final g = glyf.glyphList[i];
      final extent = hMetrics[i].lsb + (g.header.xMax - g.header.xMin);

      maxExtent = math.max(maxExtent, extent);
    }

    return maxExtent;
  }

  @override
  void encodeToBinary(ByteData byteData, int offset) {
    // TODO: implement encode
    throw UnimplementedError();
  }
}