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
