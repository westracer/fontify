import 'dart:io';

import 'package:fontify/src/ttf/parser.dart';
import 'package:fontify/src/ttf/table/all.dart';
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

    test('OS/2 V1 table', () {
      final table = font.tableMap[ttf_utils.kOS2Tag] as OS2TableV1;
      expect(table, isNotNull);

      expect(table.version, 1);
      expect(table.xAvgCharWidth, 862);
      expect(table.usWeightClass, 400);
      expect(table.usWidthClass, 5);
      expect(table.fsType, 0);
      expect(table.ySubscriptXSize, 634);
      expect(table.ySubscriptYSize, 700);
      expect(table.ySubscriptXOffset, 0);
      expect(table.ySubscriptYOffset, 140);
      expect(table.ySuperscriptXSize, 634);
      expect(table.ySuperscriptYSize, 700);
      expect(table.ySuperscriptXOffset, 0);
      expect(table.ySuperscriptYOffset, 480);
      expect(table.yStrikeoutSize, 49);
      expect(table.yStrikeoutPosition, 258);
      expect(table.sFamilyClass, 0);
      expect(table.panose, [2,0,5,3,0,0,0,0,0,0]);
      expect(table.ulUnicodeRange1, 0);
      expect(table.ulUnicodeRange2, 0);
      expect(table.ulUnicodeRange3, 0);
      expect(table.ulUnicodeRange4, 0);
      expect(table.achVendID, 'PfEd');
      expect(table.fsSelection, 64);
      expect(table.usFirstCharIndex, 59414);
      expect(table.usLastCharIndex, 62368);
      expect(table.sTypoAscender, 850);
      expect(table.sTypoDescender, -150);
      expect(table.sTypoLineGap, 90);
      expect(table.usWinAscent, 853);
      expect(table.usWinDescent, 153);
      expect(table.ulCodePageRange1, 1);
      expect(table.ulCodePageRange2, 0);
    });

    test('PostScript table', () {
      final table = font.tableMap[ttf_utils.kPostTag] as PostScriptTable;
      expect(table, isNotNull);

      expect(table.header.version, 2);
      expect(table.header.italicAngle, 0);
      expect(table.header.underlinePosition, 10);
      expect(table.header.underlineThickness, 0);
      expect(table.header.isFixedPitch, 0);
      expect(table.header.minMemType42, 0);
      expect(table.header.maxMemType42, 0);
      expect(table.header.minMemType1, 0);
      expect(table.header.maxMemType1, 0);

      final format20 = table.data as PostScriptFormat20;
      expect(format20.numberOfGlyphs, 166);
      expect(format20.glyphNameIndex, _kPOSTformat20indicies);
      expect(format20.glyphNames.map((ps) => ps.string).toList(), _kPOSTformat20names);
    });

    test('Naming table', () {
      final table = font.tableMap[ttf_utils.kNameTag] as NamingTable;
      expect(table, isNotNull);

      expect(table.header.format, 0);
      expect(table.header.count, 18);
      expect(table.stringList.contains('Regular'), isTrue);
      expect(table.stringList.contains('TestFont'), isTrue);
      expect(table.stringList.contains('Version 1.0'), isTrue);
    });
  });
}

const _kPOSTformat20indicies = [258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,362,363,364,365,366,367,368,369,370,371,372,373,374,375,376,377,378,379,380,381,382,383,384,385,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,419,420,421,422,423];
const _kPOSTformat20names = ['','calend_rainbow','fav_group','hamburger','menu_notif','note-1','arrow-small-left','checklist','diff-modified','plus','pin','database','markdown','unverified','mark-github','globe','light-bulb','watch','primitive-dot','bookmark','gift','file-directory','versions','triangle-up','issue-closed','tag','book','git-commit','mail-read','repo-push','ellipsis','lock','terminal','key','tasklist','repo','shield-lock','pulse','triangle-down','credit-card','diff-ignored','file-submodule','primitive-square','mute','unmute','heart-outline','sync','beaker','reply','italic','diff-renamed','plus-small','dash','list-unordered','pencil','question','primitive-dot-stroke','saved','unfold','rss','arrow-small-down','line-arrow-down','fold','sign-out','issue-opened','file-code','trashcan','star','shield-check','repo-template','thumbsup','shield-x','logo-gist','report','mention','cloud-download','git-branch','squirrel','desktop-download','kebab-vertical','line-arrow-left','clippy','megaphone','repo-clone','workflow','arrow-up','chevron-up','plug','comment','location','kebab-horizontal','link-external','link','code','history','stop','graph','file-media','text-size','no-newline','gear','home','device-camera-video','diff-added','arrow-both','circuit-board','repo-pull','sign-in','eye-closed','north-star','internal-repo','check','law','cloud-upload','settings','three-bars','flame','horizontal-rule','chevron-right','chevron-left','repo-template-private','github-action','broadcast','archive','note','milestone','project','device-mobile','line-arrow-right','arrow-small-right','arrow-right','inbox','repo-forked','line-arrow-up','tools','jersey','device-desktop','package','thumbsdown','dashboard','play','dependent','rocket','calendar','smiley','issue-reopened','clock','mirror','shield','file-symlink-directory','browser','server','triangle-right','radio-tower','mail','arrow-down','diff-removed','hubot','file','gist-secret','x','screen-normal','infinity','mortar-board','alert','file-pdf'];