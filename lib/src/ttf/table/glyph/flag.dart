import 'dart:typed_data';

import '../../../utils/ttf.dart' as ttf_utils;

const _kOnCurvePointValue = 0x01;
const _kXshortVectorValue = 0x02;
const _kYshortVectorValue = 0x04;
const _kRepeatFlagValue = 0x08;
const _kXisSameValue = 0x10;
const _kYisSameValue = 0x20;
const _kOverlapSimpleValue = 0x40;
const _kReservedValue = 0x80;

class SimpleGlyphFlag {
  SimpleGlyphFlag(
    this.onCurvePoint,
    this.xShortVector,
    this.yShortVector,
    this.repeat,
    this.xIsSameOrPositiveXshortVector,
    this.yIsSameOrPositiveYshortVector,
    this.overlapSimple,
    this.reserved
  );

  factory SimpleGlyphFlag.fromByteData(ByteData byteData, int offset) {
    final flag = byteData.getUint8(offset);
    final repeatFlag = ttf_utils.checkBitMask(flag, _kRepeatFlagValue);
    final repeatTimes = repeatFlag ? byteData.getUint8(offset + 1) : null;

    return SimpleGlyphFlag(
      ttf_utils.checkBitMask(flag, _kOnCurvePointValue),
      ttf_utils.checkBitMask(flag, _kXshortVectorValue),
      ttf_utils.checkBitMask(flag, _kYshortVectorValue),
      repeatTimes,
      ttf_utils.checkBitMask(flag, _kXisSameValue),
      ttf_utils.checkBitMask(flag, _kYisSameValue),
      ttf_utils.checkBitMask(flag, _kOverlapSimpleValue),
      ttf_utils.checkBitMask(flag, _kReservedValue)
    );
  }

  final bool onCurvePoint;
  final bool xShortVector;
  final bool yShortVector;
  final int repeat;
  final bool xIsSameOrPositiveXshortVector;
  final bool yIsSameOrPositiveYshortVector;
  final bool overlapSimple;
  final bool reserved;
  
  int get size => 1 + (repeat != null ? 1 : 0);
  int get repeatTimes => repeat ?? 0;
}