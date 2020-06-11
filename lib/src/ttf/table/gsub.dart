import 'dart:typed_data';

import '../../utils/ttf.dart' as ttf_utils;

import 'abstract.dart';
import 'table_record_entry.dart';

const _kLangSysRecordSize = 6;
const _kScriptRecordSize = 6;

class GlyphSubstitutionTableHeader {
  GlyphSubstitutionTableHeader(
    this.majorVersion,
    this.minorVersion,
    this.scriptListOffset,
    this.featureListOffset,
    this.lookupListOffset,
    this.featureVariationsOffset
  );

  factory GlyphSubstitutionTableHeader.fromByteData(
    ByteData byteData, 
    TableRecordEntry entry,
  ) {
    final minorVersion = byteData.getUint16(entry.offset + 2);
    final isV10 = byteData.getUint16(entry.offset + 2) == 0;

    return GlyphSubstitutionTableHeader(
      byteData.getUint16(entry.offset),
      minorVersion,
      byteData.getUint16(entry.offset + 4),
      byteData.getUint16(entry.offset + 6),
      byteData.getUint16(entry.offset + 8),
      isV10 ? null : byteData.getUint32(entry.offset + 10),
    );
  }

  final int majorVersion;
  final int minorVersion;
  final int scriptListOffset;
  final int featureListOffset;
  final int lookupListOffset;
  final int featureVariationsOffset;

  bool get isV10 => minorVersion == 0;
  
  int get size => isV10 ? 10 : 12;
}

class LanguageSystemRecord {
  LanguageSystemRecord(
    this.langSysTag,
    this.langSysOffset
  );

  factory LanguageSystemRecord.fromByteData(ByteData byteData, int offset) {
    return LanguageSystemRecord(
      ttf_utils.convertTagToString(Uint8List.view(byteData.buffer, offset, 4)),
      byteData.getUint16(offset + 4),
    );
  }

  final String langSysTag;
  final int langSysOffset;
}

class LanguageSystemTable {
  LanguageSystemTable(
    this.lookupOrder, 
    this.requiredFeatureIndex, 
    this.featureIndexCount, 
    this.featureIndices,
  );

  factory LanguageSystemTable.fromByteData(
    ByteData byteData,
    int offset
  ) {
    final featureIndexCount = byteData.getUint16(offset + 4);
    final featureIndices = List.generate(
      featureIndexCount, 
      (i) => byteData.getUint16(offset + 6 + 2 * i)
    );

    return LanguageSystemTable(
      byteData.getUint16(offset),
      byteData.getUint16(offset + 2),
      featureIndexCount,
      featureIndices
    );
  }

  final int lookupOrder;
  final int requiredFeatureIndex;
  final int featureIndexCount;
  final List<int> featureIndices;
}

class ScriptTable {
  ScriptTable(
    this.defaultLangSysOffset,
    this.langSysCount,
    this.langSysRecords,
    this.langSysTables,
    this.defaultLangSys,
  );

  factory ScriptTable.fromByteData(
    ByteData byteData, 
    int offset,
    ScriptRecord record
  ) {
    offset += record.scriptOffset;

    final defaultLangSysOffset = byteData.getUint16(offset);
    LanguageSystemTable defaultLangSys;
    if (defaultLangSysOffset != 0) {
      defaultLangSys = LanguageSystemTable.fromByteData(byteData, offset + defaultLangSysOffset);
    }

    final langSysCount = byteData.getUint16(offset + 2);
    final langSysRecords = List.generate(
      langSysCount,
      (i) => LanguageSystemRecord.fromByteData(byteData, offset + 4 + _kLangSysRecordSize * i)
    );
    final langSysTables = langSysRecords
      .map((r) => LanguageSystemTable.fromByteData(byteData, offset + r.langSysOffset))
      .toList();
    
    return ScriptTable(
      defaultLangSysOffset,
      langSysCount,
      langSysRecords,
      langSysTables,
      defaultLangSys,
    );
  }

  final int defaultLangSysOffset;
  final int langSysCount;
  final List<LanguageSystemRecord> langSysRecords;

  final List<LanguageSystemTable> langSysTables;
  final LanguageSystemTable defaultLangSys;
}

class ScriptRecord {
  ScriptRecord(
    this.scriptTag,
    this.scriptOffset
  );

  factory ScriptRecord.fromByteData(ByteData byteData, int offset) {    
    return ScriptRecord(
      ttf_utils.convertTagToString(Uint8List.view(byteData.buffer, offset, 4)),
      byteData.getUint16(offset + 4),
    );
  }

  final String scriptTag;
  final int scriptOffset;
}

class ScriptListTable {
  ScriptListTable(
    this.scriptCount,
    this.scriptRecords,
    this.scriptTables
  );

  factory ScriptListTable.fromByteData(ByteData byteData, int offset) {
    final scriptCount = byteData.getUint16(offset);
    final scriptRecords = List.generate(
      scriptCount, 
      (i) => ScriptRecord.fromByteData(byteData, offset + 2 + _kScriptRecordSize * i)
    );
    final scriptTables = List.generate(
      scriptCount,
      (i) => ScriptTable.fromByteData(byteData, offset, scriptRecords[i])
    );
    
    return ScriptListTable(scriptCount, scriptRecords, scriptTables);
  }

  final int scriptCount;
  final List<ScriptRecord> scriptRecords;

  final List<ScriptTable> scriptTables;
}

class GlyphSubstitutionTable extends FontTable {
  GlyphSubstitutionTable(
    TableRecordEntry entry,
    this.header,
    this.scriptListTable,
  ) : super.fromTableRecordEntry(entry);

  factory GlyphSubstitutionTable.fromByteData(
    ByteData byteData, 
    TableRecordEntry entry,
  ) {
    final header = GlyphSubstitutionTableHeader.fromByteData(byteData, entry);

    final scriptListTable = ScriptListTable.fromByteData(byteData, entry.offset + header.scriptListOffset);

    return GlyphSubstitutionTable(
      entry,
      header,
      scriptListTable,
    );
  }

  final GlyphSubstitutionTableHeader header;
  final ScriptListTable scriptListTable;
}