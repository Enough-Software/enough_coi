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

  test('splitAddressParts', () {
    expect(StringHelper.splitAddressParts('hello'), ['hello']);
    expect(StringHelper.splitAddressParts('a b c'), ['a b c']);
    expect(StringHelper.splitAddressParts('hello world'), ['hello world']);
    expect(StringHelper.splitAddressParts('"my, name" <name@domain.com>'),
        ['"my, name" <name@domain.com>']);
    expect(
        StringHelper.splitAddressParts(
            '"my name" <name@domain.com>;  someaddress@otherdomain.com; "first last" <first.last@domain.com>'),
        [
          '"my name" <name@domain.com>',
          'someaddress@otherdomain.com',
          '"first last" <first.last@domain.com>'
        ]);
    expect(
        StringHelper.splitAddressParts(
            'my name <name@domain.com>, "first, last" <first.last@domain.com>'),
        ['my name <name@domain.com>', '"first, last" <first.last@domain.com>']);
    expect(
        StringHelper.splitAddressParts(
            'my name <name@domain.com>, "first, last" <first.last@domain.com>,'),
        ['my name <name@domain.com>', '"first, last" <first.last@domain.com>']);
  });

  test('findEmailAddress', () {
    var emailWord = StringHelper.findEmailAddress('hello@world.com');
    expect(emailWord, isNotNull);
    expect(emailWord.text, 'hello@world.com');
    expect(emailWord.startIndex, 0);
    expect(emailWord.endIndex, emailWord.text.length);

    emailWord = StringHelper.findEmailAddress('<hello@world.com>');
    expect(emailWord, isNotNull);
    expect(emailWord.text, 'hello@world.com');
    expect(emailWord.startIndex, 1);
    expect(emailWord.endIndex, '<hello@world.com>'.length - 1);

    emailWord = StringHelper.findEmailAddress('"world, hello" <hello@world.com>');
    expect(emailWord, isNotNull);
    expect(emailWord.text, 'hello@world.com');
    expect(emailWord.startIndex, '"world, hello" <'.length);
    expect(emailWord.endIndex, '"world, hello" <hello@world.com>'.length - 1);

    emailWord = StringHelper.findEmailAddress('hello world <hello@world.com>');
    expect(emailWord, isNotNull);
    expect(emailWord.text, 'hello@world.com');
    expect(emailWord.startIndex, 'hello world <'.length);
    expect(emailWord.endIndex, 'hello world <hello@world.com>'.length - 1);

    emailWord = StringHelper.findEmailAddress('hello world <"john..doe"@world.com>');
    expect(emailWord, isNotNull);
    expect(emailWord.text, '"john..doe"@world.com');
    expect(emailWord.startIndex, 'hello world <'.length);
    expect(emailWord.endIndex, 'hello world <"john..doe"@world.com>'.length - 1);

    emailWord = StringHelper.findEmailAddress('hello world <"john@doe"@world.com>');
    expect(emailWord, isNotNull);
    expect(emailWord.text, '"john@doe"@world.com');
    expect(emailWord.startIndex, 'hello world <'.length);
    expect(emailWord.endIndex, 'hello world <"john@doe"@world.com>'.length - 1);

    emailWord = StringHelper.findEmailAddress('hello world <"john@doe"@world.com>  ');
    expect(emailWord, isNotNull);
    expect(emailWord.text, '"john@doe"@world.com');
    expect(emailWord.startIndex, 'hello world <'.length);
    expect(emailWord.endIndex, 'hello world <"john@doe"@world.com>  '.length - 3);
  });
}
