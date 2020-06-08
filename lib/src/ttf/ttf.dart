import 'table/abstract.dart';
import 'table/offset.dart';

class TrueTypeFont {
  TrueTypeFont(this.offsetTable, this.tableMap);
  
  final OffsetTable offsetTable;
  final Map<String, FontTable> tableMap;
}