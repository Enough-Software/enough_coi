class StringHelper {
  static String clearNonAsciiAndNonNumeric(String input) {
    var runes = input.runes;
    var buffer = StringBuffer();
    for (var rune in runes) {
      if ((rune < 48 || rune > 123) ||
          (rune > 57 && rune < 65) ||
          (rune > 90 && rune < 97)) {
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
    var splitRune = 32; // space
    for (var i = 0; i < text.length; i++) {
      var rune = runes.elementAt(i);
      if (isInValue) {
        if (rune == splitRune || rune == 59) {
          if (rune == 32 && i == startIndex + 1 && runes.elementAt(i-1) == 32) {
            // just two spaces after each other
            startIndex++;
            isInValue = false;
          } else {
            // semicolons can also split values
            var endIndex = i;
            if (rune != 32 && rune != 59) {
              endIndex++;
            }
            result.add(text.substring(startIndex, endIndex).trim());
            if (rune == 59) {
              result.add(';');
              i++;
            }
            startIndex = i + 1;
            isInValue = false;
          }
        }
      } else {
        if (rune == 59) {
          result.add(';');
          if (i < text.length - 1) {
            i++;
            rune = runes.elementAt(i);
          }
        }
        if (rune == 32) {
          // space
          splitRune = rune;
          // this might be "value <something>", in this case the next rune is the more relevant one:
          if (i < text.length - 1) {
            splitRune = _getSplitRune(runes.elementAt(i + 1));
            if (splitRune != 32) {
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
    var splitRune = 32; // space
    if (rune == 34 || rune == 39) {
      // double-quote || single-quote
      splitRune = rune;
    } else if (rune == 60) {
      // >
      splitRune = 62; // >
    }
    return splitRune;
  }
}
