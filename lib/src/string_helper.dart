import 'package:enough_mail/src/util/ascii_runes.dart';

class StringHelper {

  static String clearNonAsciiAndNonNumeric(String input) {
    var runes = input.runes;
    var buffer = StringBuffer();
    for (var rune in runes) {
      if ((rune < AsciiRunes.rune0 || rune > AsciiRunes.runeZLowerCase) ||
          (rune > AsciiRunes.rune9 && rune < AsciiRunes.runeAUpperCase) ||
          (rune > AsciiRunes.runeZUpperCase && rune < AsciiRunes.runeALowerCase)) {
        buffer.write('_');
      } else {
        buffer.write(String.fromCharCode(rune));
      }
    }
    return buffer.toString();
  }

  static List<String> split(String text) {
    if (text == null) {
      return null;
    }
    if (text.isEmpty) {
      return [];
    }
    var result = <String>[];
    var runes = text.runes;
    var isInValue = false;
    var startIndex = 0;
    var splitRune = AsciiRunes.runeSpace; // space
    for (var i = 0; i < text.length; i++) {
      var rune = runes.elementAt(i);
      if (isInValue) {
        if (rune == splitRune || rune == AsciiRunes.runeSemicolon) {
          if (rune == AsciiRunes.runeSpace &&
              i == startIndex + 1 &&
              runes.elementAt(i - 1) == AsciiRunes.runeSpace) {
            // just two spaces after each other
            startIndex++;
            isInValue = false;
          } else {
            // semicolons can also split values
            var endIndex = i;
            if (rune != AsciiRunes.runeSpace && rune != AsciiRunes.runeSemicolon) {
              endIndex++;
            }
            result.add(text.substring(startIndex, endIndex).trim());
            if (rune == AsciiRunes.runeSemicolon) {
              result.add(';');
              i++;
            }
            startIndex = i + 1;
            isInValue = false;
          }
        }
      } else {
        if (rune == AsciiRunes.runeSemicolon) {
          result.add(';');
          if (i < text.length - 1) {
            i++;
            rune = runes.elementAt(i);
          }
        }
        if (rune == AsciiRunes.runeSpace) {
          // space
          splitRune = rune;
          // this might be "value <something>", in this case the next rune is the more relevant one:
          if (i < text.length - 1) {
            splitRune = _getSplitRune(runes.elementAt(i + 1));
            if (splitRune != AsciiRunes.runeSpace) {
              i++;
            }
          }
        } else {
          splitRune = _getSplitRune(rune);
        }
        startIndex = i;
        isInValue = true;
      }
    }
    if (startIndex < text.length) {
      result.add(text.substring(startIndex).trim());
    }
    return result;
  }

  static int _getSplitRune(int rune) {
    var splitRune = AsciiRunes.runeSpace;
    if (rune == AsciiRunes.runeDoubleQuote || rune == AsciiRunes.runeSingleQuote) {
      splitRune = rune;
    } else if (rune == AsciiRunes.runeSmallerThan) {
      splitRune = AsciiRunes.runeGreaterThan;
    }
    return splitRune;
  }
}