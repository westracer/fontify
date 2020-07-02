import 'package:meta/meta.dart';

import '../../utils/exception.dart';

// Top DICT operators

/// 1/unitsPerEm 0 0 1/unitsPerEm 0 0. Omitted if unitsPerEm is 1000.
final CFFOperator fontMatrix = CFFOperator(const [12, 7]);

/// CharStrings INDEX offset.
final CFFOperator charStrings = CFFOperator(const [17]);

/// Font DICT (FD) INDEX offset.
final CFFOperator fdArray = CFFOperator(const [12, 36]);

/// FDSelect structure offset. OOmitted if just one Font DICT.
final CFFOperator fdSelect = CFFOperator(const [12, 37]);

/// VariationStore structure offset. Omitted if there is no varation data.
final CFFOperator vstore = CFFOperator(const [24]);

// Font DICT operators

/// Private DICT size and offset
final CFFOperator private = CFFOperator(const [18]);

final CFFOperator blueValues = CFFOperator(const [6]);
final CFFOperator otherBlues = CFFOperator(const [7]);
final CFFOperator familyBlues = CFFOperator(const [8]);
final CFFOperator familyOtherBlues = CFFOperator(const [9]);
final CFFOperator stdHW = CFFOperator(const [10]);
final CFFOperator stdVW = CFFOperator(const [11]);
final CFFOperator escape = CFFOperator(const [12]);
final CFFOperator subrs = CFFOperator(const [19]);
final CFFOperator vsindex = CFFOperator(const [22]);
final CFFOperator blend = CFFOperator(const [23]);
final CFFOperator bcd = CFFOperator(const [30]);

final CFFOperator blueScale = CFFOperator(const [12, 9]);
final CFFOperator blueShift = CFFOperator(const [12, 10]);
final CFFOperator blueFuzz = CFFOperator(const [12, 11]);
final CFFOperator stemSnapH = CFFOperator(const [12, 12]);
final CFFOperator stemSnapV = CFFOperator(const [12, 13]);
final CFFOperator languageGroup = CFFOperator(const [12, 17]);
final CFFOperator expansionFactor = CFFOperator(const [12, 18]);

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