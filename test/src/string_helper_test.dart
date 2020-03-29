import 'package:enough_coi/src/string_helper.dart';
import 'package:test/test.dart';

void main() {
  test('clearNonAsciiAndNonNumeric', () {
    expect(
        StringHelper.clearNonAsciiAndNonNumeric('hello world'), 'hello_world');
    expect(StringHelper.clearNonAsciiAndNonNumeric('h'), 'h');
    expect(StringHelper.clearNonAsciiAndNonNumeric('hällö wörldß'),
        'h_ll__w_rld_');
  });

  test('split', () {
    expect(StringHelper.split('hello'), ['hello']);
    expect(StringHelper.split('a b c'), ['a', 'b', 'c']);
    expect(StringHelper.split('hello world'), ['hello', 'world']);
    expect(StringHelper.split('"my name" <name@domain.com>'),
        ['"my name"', '<name@domain.com>']);
    expect(
        StringHelper.split(
            '"my name" <name@domain.com>;  someaddress@otherdomain.com; "first last"  <first.last@domain.com>'),
        [
          '"my name"',
          '<name@domain.com>',
          ';',
          'someaddress@otherdomain.com',
          ';',
          '"first last"',
          '<first.last@domain.com>'
        ]);
    expect(
        StringHelper.split(
            '"my name" <name@domain.com>;  "first last"  <first.last@domain.com>'),
        [
          '"my name"',
          '<name@domain.com>',
          ';',
          '"first last"',
          '<first.last@domain.com>'
        ]);
  });
}
