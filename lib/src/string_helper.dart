class StringHelper {
  static const int _runeSpace = 32;
  static const int _runeDoubleQuote = 34;
  static const int _runeSingleQuote = 39;
  static const int _rune0 = 48;
  static const int _rune9 = 57;
  static const int _runeComma = 44;
  static const int _runeSemicolon = 59;
  static const int _runeSmallerThan = 60;
  static const int _runeGreaterThan = 62;
  static const int _runeAt = 64;
  static const int _runeAUpperCase = 65;
  static const int _runeALowerCase = 97;
  static const int _runeZUpperCase = 90;
  static const int _runeZLowerCase = 122;
  static String clearNonAsciiAndNonNumeric(String input) {
    var runes = input.runes;
    var buffer = StringBuffer();
    for (var rune in runes) {
      if ((rune < _rune0 || rune > _runeZLowerCase) ||
          (rune > _rune9 && rune < _runeAUpperCase) ||
          (rune > _runeZUpperCase && rune < _runeALowerCase)) {
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
    var splitRune = _runeSpace; // space
    for (var i = 0; i < text.length; i++) {
      var rune = runes.elementAt(i);
      if (isInValue) {
        if (rune == splitRune || rune == _runeSemicolon) {
          if (rune == _runeSpace &&
              i == startIndex + 1 &&
              runes.elementAt(i - 1) == _runeSpace) {
            // just two spaces after each other
            startIndex++;
            isInValue = false;
          } else {
            // semicolons can also split values
            var endIndex = i;
            if (rune != _runeSpace && rune != _runeSemicolon) {
              endIndex++;
            }
            result.add(text.substring(startIndex, endIndex).trim());
            if (rune == _runeSemicolon) {
              result.add(';');
              i++;
            }
            startIndex = i + 1;
            isInValue = false;
          }
        }
      } else {
        if (rune == _runeSemicolon) {
          result.add(';');
          if (i < text.length - 1) {
            i++;
            rune = runes.elementAt(i);
          }
        }
        if (rune == _runeSpace) {
          // space
          splitRune = rune;
          // this might be "value <something>", in this case the next rune is the more relevant one:
          if (i < text.length - 1) {
            splitRune = _getSplitRune(runes.elementAt(i + 1));
            if (splitRune != _runeSpace) {
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

  static List<String> splitAddressParts(String text) {
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
    var valueEndRune = _runeSpace; // space
    for (var i = 0; i < text.length; i++) {
      var rune = runes.elementAt(i);
      if (isInValue) {
        if (rune == valueEndRune) {
          isInValue = false;
        }
      } else {
        if (rune == _runeComma || rune == _runeSemicolon) {
          // found a split position
          var textPart = text.substring(startIndex, i).trim();
          result.add(textPart);
          startIndex = i + 1;
        } else if (rune == _runeDoubleQuote) {
          valueEndRune = _runeDoubleQuote;
          isInValue = true;
        } else if (rune == _runeSmallerThan) {
          valueEndRune = _runeGreaterThan;
          isInValue = true;
        }
      }
    }
    if (startIndex < text.length - 1) {
      var textPart = text.substring(startIndex).trim();
      result.add(textPart);
    }
    return result;
  }

  static Word findEmailAddress(String text) {
    if (text == null) {
      return null;
    }

    var atIndex = text.lastIndexOf('@');
    if (atIndex == -1) {
      return null;
    }
    var isInValue = false;
    var startIndex = 0;
    var endIndex = text.length;
    var valueEndRune = _runeSpace; // space
    var runes = text.runes;
    var isFoundAtRune = false;
    for (var i = endIndex; --i >= 0;) {
      var rune = runes.elementAt(i);
      if (isInValue) {
        if (rune == valueEndRune) {
          isInValue = false;
        }
      } else {
        if (rune == _runeAt) {
          isFoundAtRune = true;
        } else if (!isFoundAtRune) {
          if (rune == _runeGreaterThan || rune == _runeSpace) {
            endIndex = i;
          }
        } else if (rune == _runeSmallerThan || rune == _runeSpace) {
          startIndex = i + 1;
          break;
        } else if (isFoundAtRune && rune == _runeDoubleQuote) {
          isInValue = true;
          valueEndRune = _runeDoubleQuote;
        }
      }
    }
    var email = text.substring(startIndex, endIndex);
    return Word(startIndex, endIndex, email);
  }

  static int _getSplitRune(int rune) {
    var splitRune = _runeSpace;
    if (rune == _runeDoubleQuote || rune == _runeSingleQuote) {
      splitRune = rune;
    } else if (rune == _runeSmallerThan) {
      splitRune = _runeGreaterThan;
    }
    return splitRune;
  }
}

class Word {
  final int startIndex;
  final int endIndex;
  final String text;
  Word(this.startIndex, this.endIndex, this.text);
}
