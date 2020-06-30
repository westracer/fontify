import 'package:meta/meta.dart';

import '../../utils/exception.dart';

// Top DICT operators

/// 1/unitsPerEm 0 0 1/unitsPerEm 0 0. Omitted if unitsPerEm is 1000.
final CFFOperator fontMatrixOperator = CFFOperator(const [12, 7]);

/// CharStrings INDEX offset.
final CFFOperator charStringsOperator = CFFOperator(const [17]);

/// Font DICT (FD) INDEX offset.
final CFFOperator fdArrayOperator = CFFOperator(const [12, 36]);

/// FDSelect structure offset. OOmitted if just one Font DICT.
final CFFOperator fdSelectOperator = CFFOperator(const [12, 37]);

/// VariationStore structure offset. Omitted if there is no varation data.
final CFFOperator vstoreOperator = CFFOperator(const [24]);

@immutable
class CFFOperator {
  CFFOperator(this.byteList) 
  : intValue = byteList?.fold<int>(0, (p, e) => (p << 8) + e) 
    {
      if (byteList?.length != 1 && byteList?.length != 2) {
        throw TableDataFormatException('Wrong CFF operator value');
      }
    }

  final List<int> byteList;
  final int intValue;

  int get size => byteList.length;

  @override
  int get hashCode => intValue.hashCode;

  @override
  bool operator==(Object other) {
    if (other is CFFOperator) {
      return other.intValue == intValue;
    }

    return false;
  }
}