import '../utils/ttf.dart' as ttf_utils;

import 'table/abstract.dart';
import 'table/all.dart';
import 'table/glyph/simple.dart';
import 'table/offset.dart';

class TrueTypeFont {
  TrueTypeFont(this.offsetTable, this.tableMap);

  // TODO: introduce generic glyph class later
  factory TrueTypeFont.fromGlyphs(List<SimpleGlyph> glyphList, List<String> glyphNameList) {
    assert(
      glyphNameList.length == glyphList.length, 
      'Lengths of glyph list and glyph name list are different'
    );

    final glyf = GlyphDataTable.fromGlyphs(glyphList);
    final head = HeaderTable.create(glyf, revision: 1);
    final hmtx = HorizontalMetricsTable.create(glyf);
    final hhea = HorizontalHeaderTable.create(glyf, hmtx);
    final post = PostScriptTable.create(glyphNameList);

    // TODO: rest of tables
    return TrueTypeFont(null, {
      ttf_utils.kGlyfTag: glyf,
      ttf_utils.kHeadTag: head,
      ttf_utils.kHmtxTag: hmtx,
      ttf_utils.kHheaTag: hhea,
      ttf_utils.kPostTag: post,
    });
  }
  
  final OffsetTable offsetTable;
  final Map<String, FontTable> tableMap;

  HeaderTable get head => tableMap[ttf_utils.kHeadTag] as HeaderTable;
  MaximumProfileTable get maxp => tableMap[ttf_utils.kMaxpTag] as MaximumProfileTable;
  IndexToLocationTable get loca => tableMap[ttf_utils.kLocaTag] as IndexToLocationTable;
  GlyphDataTable get glyf => tableMap[ttf_utils.kGlyfTag] as GlyphDataTable;
  GlyphSubstitutionTable get gsub => tableMap[ttf_utils.kGSUBTag] as GlyphSubstitutionTable;
  OS2Table get os2 => tableMap[ttf_utils.kOS2Tag] as OS2Table;
  PostScriptTable get post => tableMap[ttf_utils.kPostTag] as PostScriptTable;
  NamingTable get name => tableMap[ttf_utils.kNameTag] as NamingTable;
  CharacterToGlyphTable get cmap => tableMap[ttf_utils.kCmapTag] as CharacterToGlyphTable;
  HorizontalHeaderTable get hhea => tableMap[ttf_utils.kHheaTag] as HorizontalHeaderTable;
  HorizontalMetricsTable get hmtx => tableMap[ttf_utils.kHmtxTag] as HorizontalMetricsTable;
}