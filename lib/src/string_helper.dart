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
}
