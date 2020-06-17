import 'table/abstract.dart';
import 'table/all.dart';
import 'table/glyph/simple.dart';
import 'table/offset.dart';

class TrueTypeFont {
  TrueTypeFont(this.offsetTable, this.tableMap);

  factory TrueTypeFont.fromGlyphs(List<SimpleGlyph> glyphList) {
    final glyf = GlyphDataTable.fromGlyphs(glyphList);
    final head = HeaderTable.create(glyf, revision: 1);
    final hmtx = HorizontalMetricsTable.create(glyf);
    final hhea = HorizontalHeaderTable.create(glyf, hmtx);

    // TODO: rest of tables
    return TrueTypeFont(null, {});
  }
  
  final OffsetTable offsetTable;
  final Map<String, FontTable> tableMap;
}