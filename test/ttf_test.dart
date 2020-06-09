import 'dart:io';

import 'package:fontify/src/ttf/parser.dart';
import 'package:fontify/src/ttf/table/glyf.dart';
import 'package:fontify/src/ttf/table/head.dart';
import 'package:fontify/src/ttf/table/maxp.dart';
import 'package:fontify/src/ttf/ttf.dart';
import 'package:fontify/src/utils/ttf.dart' as ttf_utils;
import 'package:test/test.dart';

const _kTestFontAssetPath = './test_assets/test_font.ttf';

void main() {
  group('Parser', () {
    TrueTypeFont font;

    setUpAll(() {
      font = TTFParser(File(_kTestFontAssetPath)).parse();
    });

    test('Offset table', () {
      final table = font.offsetTable;

      expect(table.offset, 0);
      expect(table.length, 12);

      expect(table.entrySelector, 3);
      expect(table.numTables, 11);
      expect(table.rangeShift, 48);
      expect(table.searchRange, 128);
      expect(table.sfntVersion, 0x10000);
      expect(table.isOTTO, false);
    });

    test('Maximum Profile table', () {
      final table = font.tableMap[ttf_utils.kMaxpTag] as MaximumProfileTable;
      expect(table, isNotNull);

      expect(table.version, 0x00010000);
      expect(table.numGlyphs, 166);
      expect(table.maxPoints, 333);
      expect(table.maxContours, 22);
      expect(table.maxCompositePoints, 0);
      expect(table.maxCompositeContours, 0);
      expect(table.maxZones, 2);
      expect(table.maxTwilightPoints, 0);
      expect(table.maxStorage, 10);
      expect(table.maxFunctionDefs, 10);
      expect(table.maxInstructionDefs, 0);
      expect(table.maxStackElements, 255);
      expect(table.maxSizeOfInstructions, 0);
      expect(table.maxComponentElements, 0);
      expect(table.maxComponentDepth, 0);
    });

    test('Header table', () {
      final table = font.tableMap[ttf_utils.kHeadTag] as HeaderTable;
      expect(table, isNotNull);

      expect(table.majorVersion, 1);
      expect(table.minorVersion, 0);
      expect(table.checkSumAdjustment, 3043242535);
      expect(table.magicNumber, 1594834165);
      expect(table.flags, 11);
      expect(table.unitsPerEm, 1000);
      expect(table.created, DateTime.parse('2020-06-09T08:21:53.000Z'));
      expect(table.modified, DateTime.parse('2020-06-09T08:21:53.000Z'));
      expect(table.xMin, -11);
      expect(table.yMin, -153);
      expect(table.xMax, 1636);
      expect(table.yMax, 853);
      expect(table.macStyle, 0);
      expect(table.lowestRecPPEM, 8);
      expect(table.fontDirectionHint, 2);
      expect(table.indexToLocFormat, 0);
      expect(table.glyphDataFormat, 0);
    });

    test('Glyph Data table', () {
      final table = font.tableMap[ttf_utils.kGlyfTag] as GlyphDataTable;
      expect(table, isNotNull);
      expect(table.glyphList.length, 166 + 1);

      final glyphCalendRainbow = table.glyphList[0];
      expect(glyphCalendRainbow.header.numberOfContours, 3);
      expect(glyphCalendRainbow.header.xMin, 0);
      expect(glyphCalendRainbow.header.yMin, 0);
      expect(glyphCalendRainbow.header.xMax, 1000);
      expect(glyphCalendRainbow.header.yMax, 623);
      expect(
        glyphCalendRainbow.flags.sublist(0, 7).map((f) => f.onCurvePoint).toList(), 
        [true, false, true, false, true, false, false]
      );
      expect(glyphCalendRainbow.xCoordinates.first, 936);
      expect(glyphCalendRainbow.xCoordinates.last, 681);
      expect(glyphCalendRainbow.yCoordinates.first, 110);
      expect(glyphCalendRainbow.yCoordinates.last, 94);

      final glyphReport = table.glyphList[73];
      expect(glyphReport.header.numberOfContours, 4);
      expect(glyphReport.header.xMin, 0);
      expect(glyphReport.header.yMin, -150);
      expect(glyphReport.header.xMax, 1001);
      expect(glyphReport.header.yMax, 788);
      expect(
        glyphReport.flags.sublist(0, 7).map((f) => f.onCurvePoint).toList(), 
        [true, false, false, true, true, false, false]
      );
      expect(glyphReport.xCoordinates.first, 63);
      expect(glyphReport.xCoordinates.last, 563);
      expect(glyphReport.yCoordinates.first, 788);
      expect(glyphReport.yCoordinates.last, 350);

      final glyphPdf = table.glyphList[165];
      expect(glyphPdf.header.numberOfContours, 5);
      expect(glyphPdf.header.xMin, 0);
      expect(glyphPdf.header.yMin, -88);
      expect(glyphPdf.header.xMax, 751);
      expect(glyphPdf.header.yMax, 788);
      expect(
        glyphPdf.flags.sublist(0, 7).map((f) => f.onCurvePoint).toList(), 
        [true, false, false, true, true, false, false]
      );
      expect(glyphPdf.xCoordinates.first, 63);
      expect(glyphPdf.xCoordinates.last, 448);
      expect(glyphPdf.yCoordinates.first, 788);
      expect(glyphPdf.yCoordinates.last, 208);
    });
  });
}