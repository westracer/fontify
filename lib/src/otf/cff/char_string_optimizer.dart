import 'char_string.dart';
import 'char_string_operator.dart';

abstract class CharStringOptimizer {
  static CharStringCommand _compactSameOperator(
      CharStringCommand prev, CharStringCommand next) {
    final prevOpnds = prev.operandList;
    final currOpnds = next.operandList;

    if (prev.operator != next.operator) {
      return next;
    }

    final op = next.operator;

    if (op == rlineto) {
      prevOpnds.addAll(currOpnds);
      return null;
    } else if (op == hlineto || op == vlineto) {
      final prevIsOdd = prevOpnds.length.isOdd;
      final currIsOdd = currOpnds.length.isOdd;

      if (prevIsOdd &&
          currIsOdd &&
          prevOpnds.first.value == currOpnds.first.value) {
        currOpnds.removeAt(0);
        prevOpnds.addAll(currOpnds);
        return null;
      }
    } else if (op == rrcurveto) {
      prevOpnds.addAll(currOpnds);
      return null;
    } else if (op == hhcurveto || op == vvcurveto) {
      final prevHasDelta = prevOpnds.length % 4 != 0;
      final currHasDelta = currOpnds.length % 4 != 0;

      final p0prev = prevHasDelta ? prevOpnds.first : null;
      final p0 = currHasDelta ? currOpnds.first : null;

      // Is axis delta same for two curves
      if (p0?.value == p0prev?.value) {
        // Removing delta - it's already present in a previous command
        if (currHasDelta) {
          currOpnds.removeAt(0);
        }

        prevOpnds.addAll(currOpnds);
        return null;
      }
    }

    return next;
  }

  static List<CharStringCommand> _optimizeEmpty(
      List<CharStringCommand> commandList) {
    return commandList
        .where((e) => !e.operandList.every((o) => o.value == 0))
        .toList();
  }

  static List<CharStringCommand> _optimizeCommandsWithSameOperators(
      List<CharStringCommand> commandList) {
    if (commandList.isEmpty) {
      return [];
    }

    final newCommandList = <CharStringCommand>[commandList.first.copy()];

    for (var i = 1; i < commandList.length; i++) {
      final prev = newCommandList.last;
      final next = commandList[i].copy();

      final optimized = _compactSameOperator(prev, next) == null;
      if (!optimized) {
        newCommandList.add(next);
      }
    }

    return newCommandList;
  }

  static List<CharStringCommand> optimize(List<CharStringCommand> commandList) {
    return _optimizeCommandsWithSameOperators(_optimizeEmpty(commandList));
  }
}
