import 'package:meta/meta.dart';

import '../utils/exception.dart';
import '../utils/ttf.dart';

import 'defaults.dart';
import 'table/abstract.dart';
import 'table/all.dart';
import 'table/glyph/simple.dart';
import 'table/offset.dart';

class TrueTypeFont {
  TrueTypeFont(this.offsetTable, this.tableMap);

  // TODO: introduce generic glyph class later
  factory TrueTypeFont.fromGlyphs({
    @required List<SimpleGlyph> glyphList, 
    @required String fontName,
    List<String> glyphNameList,
    String description,
    Revision revision = kDefaultFontRevision,
    String achVendID = kDefaultAchVendID,
  }) {
    if (glyphNameList != null && glyphNameList.length != glyphList.length) {
      throw TableDataFormatException(
        'Lengths of glyph list and glyph name list must be same'
      );
    }

    final glyf = GlyphDataTable.fromGlyphs(glyphList);
    final head = HeaderTable.create(glyf, revision);
    final hmtx = HorizontalMetricsTable.create(glyf);
    final hhea = HorizontalHeaderTable.create(glyf, hmtx, head);
    final post = PostScriptTable.create(glyphNameList);
    final name = NamingTable.create(fontName, description, revision);
    final maxp = MaximumProfileTable.create(glyf);
    // TODO: GSUB, cmap
    final os2  = OS2Table.create(hmtx, head, hhea, achVendID);

    // TODO: rest of tables
    return TrueTypeFont(null, {
      kGlyfTag: glyf,
      kMaxpTag: maxp,
      kHeadTag: head,
      kHmtxTag: hmtx,
      kHheaTag: hhea,
      kPostTag: post,
      kNameTag: name,
      kOS2Tag:  os2,
    });
  }
  
  final OffsetTable offsetTable;
  final Map<String, FontTable> tableMap;

  HeaderTable get head => tableMap[kHeadTag] as HeaderTable;
  MaximumProfileTable get maxp => tableMap[kMaxpTag] as MaximumProfileTable;
  IndexToLocationTable get loca => tableMap[kLocaTag] as IndexToLocationTable;
  GlyphDataTable get glyf => tableMap[kGlyfTag] as GlyphDataTable;
  GlyphSubstitutionTable get gsub => tableMap[kGSUBTag] as GlyphSubstitutionTable;
  OS2Table get os2 => tableMap[kOS2Tag] as OS2Table;
  PostScriptTable get post => tableMap[kPostTag] as PostScriptTable;
  NamingTable get name => tableMap[kNameTag] as NamingTable;
  CharacterToGlyphTable get cmap => tableMap[kCmapTag] as CharacterToGlyphTable;
  HorizontalHeaderTable get hhea => tableMap[kHheaTag] as HorizontalHeaderTable;
  HorizontalMetricsTable get hmtx => tableMap[kHmtxTag] as HorizontalMetricsTable;
}