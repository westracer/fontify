import 'dart:math' as math;

import '../common/outline.dart';
import '../utils/misc.dart';
import 'path.dart';
import 'svg.dart';

/// A helper for converting SVG path to generic outline format.
class PathToOutlineConverter {
  PathToOutlineConverter(this.svg, this.path);
  
  final Svg svg;
  final PathElement path;

  final _outlines = <Outline>[];
  final _points = <math.Point<num>>[];
  final _isOnCurve = <bool>[];

  math.Point<num> _point = const math.Point(0, 0);
  PathSegment _s, _prevS;

  void _closePath() {
    final isEvenOdd = path.fillRule == 'evenodd';
    final fillRule = isEvenOdd ? FillRule.evenodd : FillRule.nonzero;

    // Y coordinates have to be flipped
    final bottom = svg.viewBox.top + svg.viewBox.height;
    final reflectedPoints = _points.map(
      (p) => math.Point<num>(p.x, bottom - p.y)
    ).toList();

    final outline = Outline(
      reflectedPoints, [..._isOnCurve], false, false, fillRule
    );
    _outlines.add(outline);

    _points.clear();
    _isOnCurve.clear();
  }

  void _moveTo() {
    final isRelative = _s.isRelative;

    for (int i = 0; i < _s.parameterList.length; i += 2) {
      final currPoint = math.Point<num>(
        _s.parameterList[i],
        _s.parameterList[i + 1]
      );

      if (isRelative) {
        _point += currPoint;
      } else {
        _point = currPoint;
      }

      _points.add(_point);
      _isOnCurve.add(true);
    }
  }

  void _lineTo() {
    final isRelative = _s.isRelative;
    final parameterLength = _s.type == PathSegmentType.lineTo ? 2 : 1;

    for (int i = 0; i < _s.parameterList.length; i += parameterLength) {
      num p1 = _s.parameterList[i];
      num p2 = parameterLength == 2 ? _s.parameterList[i + 1] : null;

      // Swapping the order for vertical line
      if (_s.type == PathSegmentType.vLineto) {
        final tmp = p1;
        p1 = p2;
        p2 = tmp;
      }

      if (isRelative) {
        _point += math.Point<num>(p1 ?? 0, p2 ?? 0);
      } else {
        _point = math.Point<num>(p1 ?? _point.x, p2 ?? _point.y);
      }

      _points.add(_point);
      _isOnCurve.add(true);
    }
  }

  void _quadTo() {
    final isRelative = _s.isRelative;
    final isSmooth = _s.type == PathSegmentType.smoothQuad;
    final parameterLength = isSmooth ? 2 : 4;

    for (int i = 0; i < _s.parameterList.length; i += parameterLength) {
      final startPoint = _point;

      var currPoints = [
        for (var j = 0; j < parameterLength; j += 2)
          math.Point<num>(
            _s.parameterList[i + j],
            _s.parameterList[i + j + 1]
          )
      ];

      // Converting to absolute points and moving current point
      if (isRelative) {
        currPoints = currPoints.map((p) => _point += p).toList();
      } else {
        _point = currPoints.last;
      }

      math.Point<num> cp = isSmooth ? startPoint : currPoints[0];
      final endPoint = currPoints.last;

      /// Calculating smooth Control Point.
      /// 
      /// If previous command was a quadratic curve,
      /// calculating a reflection of the CP on the previous command.
      /// Otherwise, CP is coincident with the current point.
      if (isSmooth && _prevS != null && isQuadSegment(_prevS)) {
        cp = startPoint.getReflectionOf(_points[_points.length - 2]);
      }

      // Converting quadratic to cubic
      final cubicCPlist = quadCurveToCubic(startPoint, cp, endPoint);

      _points.addAll([...cubicCPlist, endPoint]);
      _isOnCurve.addAll([false, false, true]);
      assert(_points.length == _isOnCurve.length, 'Lists length must be same');
    }
  }

  void _cubicTo() {
    final isRelative = _s.isRelative;
    final isSmooth = _s.type == PathSegmentType.smoothCubic;
    final parameterLength = isSmooth ? 4 : 6;

    for (int i = 0; i < _s.parameterList.length; i += parameterLength) {
      final startPoint = _point;

      var currPoints = [
        for (var j = 0; j < parameterLength; j += 2)
          math.Point<num>(
            _s.parameterList[i + j],
            _s.parameterList[i + j + 1]
          )
      ];

      // Converting to absolute points and moving current point
      if (isRelative) {
        currPoints = currPoints.map((p) => _point += p).toList();
      } else {
        _point = currPoints.last;
      }

      /// Calculating smooth Control Point.
      /// 
      /// If previous command was a cubic curve,
      /// calculating a reflection of the CP2 on the previous command.
      /// Otherwise, CP is coincident with the current point.
      if (isSmooth && _prevS != null && isCubicSegment(_prevS)) {
        assert(!_isOnCurve[_points.length - 2], 'Must be a CP');
        final cp1 = startPoint.getReflectionOf(_points[_points.length - 2]);
        currPoints.insert(0, cp1);
      }

      _points.addAll(currPoints);
      _isOnCurve.addAll([false, false, true]);
      assert(_points.length == _isOnCurve.length, 'Lists length must be same');
    }
  }

  // TODO: apply transform
  /// Converts SVG <path> to a list of outlines.
  List<Outline> convert() {
    for (int i = 0; i < path.commandList.length; i++) {
      _prevS = _s;
      _s = path.commandList[i];

      switch (_s.type) {
        case PathSegmentType.moveTo:
          _moveTo();
          break;
        case PathSegmentType.lineTo:
        case PathSegmentType.hLineTo:
        case PathSegmentType.vLineto:
          _lineTo();
          break;
        case PathSegmentType.cubic:
        case PathSegmentType.smoothCubic:
          _cubicTo();
          break;
        case PathSegmentType.quad:
        case PathSegmentType.smoothQuad:
          _quadTo();
          break;
        case PathSegmentType.arc:
          // TODO: Handle this case.
          break;
        case PathSegmentType.close:
          _closePath();
          break;
        default:
          print('Unknown SVG path command: ${_s.command} (${svg.name})'); // TODO: logging
      }
    }

    if (_points.isNotEmpty) {
      _closePath();
    }

    return _outlines;
  }
}