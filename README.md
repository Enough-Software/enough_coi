Experimental [COI](https://coi-dev.org) client for Dart developers.


Available under the commercial friendly 
[MPL Mozilla Public License 2.0](https://www.mozilla.org/en-US/MPL/).

## Usage

A simple usage example:

```dart
import 'package:enough_coi/enough_coi.dart';

void main() async {
  var client = await CoiClient.init('enough.de');
  var email = 'user@domain.com';
  var config = await client.discover(email);
  if (config != null) {
    var account = await client.tryLogin(email, config, password: 'secret');
    if (account != null) {
      var isChatMessage = true;
      var recipients = ['Lise.Meitner@domain.com'];
      var messageSent = await client.sendMessage(
          isChatMessage, 'Hello COI world!', recipients, account);
      print('message has been sent: $messageSent');
    }
  }
}

```


## Installation
Add this dependency your pubspec.yaml file:

```
dependencies:
  enough_coi: ^0.0.4
```

For more info visit [pub.dev](https://pub.dev/packages/enough_coi).

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Enough-Software/enough_coi/issues
