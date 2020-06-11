import 'dart:typed_data';

import '../../utils/ttf.dart' as ttf_utils;
import 'language_system.dart';

const kScriptRecordSize = 6;

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
      (i) => LanguageSystemRecord.fromByteData(byteData, offset + 4 + kLangSysRecordSize * i)
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
      (i) => ScriptRecord.fromByteData(byteData, offset + 2 + kScriptRecordSize * i)
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