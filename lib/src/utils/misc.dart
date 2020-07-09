import 'dart:math' as math;

const int kInt32Max = 2147483647;
const int kInt32Min = -2147483648;

const int kUnicodeSpaceCharCode = 0x20;

const int kUnicodePrivateUseAreaStart = 0xE000;
const int kUnicodePrivateUseAreaEnd   = 0xF8FF;

int combineHashCode(int hashFirst, int hashOther) {
  int hash = 17;
  hash = hash * 31 + hashFirst;
  hash = hash * 31 + hashOther;
  return hash;
}

extension MockableDateTime on DateTime {
  static DateTime mockedDate;

  static DateTime now() => mockedDate ?? DateTime.now();
}

extension PointExt<T extends num> on math.Point<T> {
  math.Point<int> toIntPoint() => math.Point<int>(x.toInt(), y.toInt());
}