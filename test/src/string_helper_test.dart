import 'package:enough_coi/src/string_helper.dart';
import 'package:test/test.dart';

void main() {
    test('clearNonAsciiAndNonNumeric', ()  {
      expect(StringHelper.clearNonAsciiAndNonNumeric('hello world'), 'hello_world');
      expect(StringHelper.clearNonAsciiAndNonNumeric('h'), 'h');
      expect(StringHelper.clearNonAsciiAndNonNumeric('hällö wörldß'), 'h_ll__w_rld_');
    });
}
