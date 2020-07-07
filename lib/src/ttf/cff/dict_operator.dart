import 'dart:collection';

import 'operator.dart';

// Top DICT operators

/// 1/unitsPerEm 0 0 1/unitsPerEm 0 0. Omitted if unitsPerEm is 1000.
const fontMatrix = CFFOperator(CFFOperatorContext.dict, 12, 7);

/// CharStrings INDEX offset.
const charStrings = CFFOperator(CFFOperatorContext.dict, 17);

/// Font DICT (FD) INDEX offset.
const fdArray = CFFOperator(CFFOperatorContext.dict, 12, 36);

/// FDSelect structure offset. OOmitted if just one Font DICT.
const fdSelect = CFFOperator(CFFOperatorContext.dict, 12, 37);

/// VariationStore structure offset. Omitted if there is no varation data.
const vstore = CFFOperator(CFFOperatorContext.dict, 24);

// Font DICT operators

/// Private DICT size and offset
const private = CFFOperator(CFFOperatorContext.dict, 18);

const blueValues = CFFOperator(CFFOperatorContext.dict, 6);
const otherBlues = CFFOperator(CFFOperatorContext.dict, 7);
const familyBlues = CFFOperator(CFFOperatorContext.dict, 8);
const familyOtherBlues = CFFOperator(CFFOperatorContext.dict, 9);
const stdHW = CFFOperator(CFFOperatorContext.dict, 10);
const stdVW = CFFOperator(CFFOperatorContext.dict, 11);
const escape = CFFOperator(CFFOperatorContext.dict, 12);
const subrs = CFFOperator(CFFOperatorContext.dict, 19);
const vsindex = CFFOperator(CFFOperatorContext.dict, 22);
const blend = CFFOperator(CFFOperatorContext.dict, 23);
const bcd = CFFOperator(CFFOperatorContext.dict, 30);

const blueScale = CFFOperator(CFFOperatorContext.dict, 12, 9);
const blueShift = CFFOperator(CFFOperatorContext.dict, 12, 10);
const blueFuzz = CFFOperator(CFFOperatorContext.dict, 12, 11);
const stemSnapH = CFFOperator(CFFOperatorContext.dict, 12, 12);
const stemSnapV = CFFOperator(CFFOperatorContext.dict, 12, 13);
const languageGroup = CFFOperator(CFFOperatorContext.dict, 12, 17);
const expansionFactor = CFFOperator(CFFOperatorContext.dict, 12, 18);

final Map<CFFOperator, String> dictOperatorNames = UnmodifiableMapView({
  fontMatrix: 'FontMatrix',
  charStrings: 'CharStrings',
  fdArray: 'FDArray',
  fdSelect: 'FDSelect',
  vstore: 'vstore',
  
  private: 'Private',

  blueValues: 'BlueValues',
  otherBlues: 'OtherBlues',
  familyBlues: 'FamilyBlues',
  familyOtherBlues: 'FamilyOtherBlues',
  stdHW: 'StdHW',
  stdVW: 'StdVW',
  escape: 'escape',
  subrs: 'Subrs',
  vsindex: 'vsindex',
  blend: 'blend',
  bcd: 'BCD',

  blueScale: 'BlueScale',
  blueShift: 'BlueShift',
  blueFuzz: 'BlueFuzz',
  stemSnapH: 'StemSnapH',
  stemSnapV: 'StemSnapV',
  languageGroup: 'LanguageGroup',
  expansionFactor: 'ExpansionFactor',
});