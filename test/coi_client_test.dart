import 'package:enough_coi/coi_client.dart';
import 'package:test/test.dart';

void main() {
  group('Onboarding tests', () {
    CoiClient client;

    setUp(() async {
      client = await CoiClient.init('coi.me', initStorage: false);
    });

    test('Autodiscover enough.de', () async {
      //print('starting autodiscover');
      var config = await client.discover('nouser@enough.de');
      expect(config != null, true);
      expect(config.preferredIncomingServer != null, true);
      expect(config.preferredIncomingImapServer != null, true);
      expect(config.preferredIncomingPopServer!= null, true);
      expect(config.preferredOutgoingServer != null, true);
      expect(config.preferredOutgoingSmtpServer != null, true);
    });



    test('Autodiscover systemschmiede.com', () async {
      //print('starting autodiscover');
      var config = await client.discover('noauser@systemschmiede.com');
      expect(config != null, true);
      expect(config.preferredIncomingImapServer != null, true);
      expect(config.preferredIncomingServer != null, true);
      expect(config.preferredIncomingImapServer != null, true);
      expect(config.preferredIncomingPopServer!= null, true);
      expect(config.preferredOutgoingServer != null, true);
      expect(config.preferredOutgoingSmtpServer != null, true);
      //print('imap: ${config.preferredIncomingImapServer.hostname}');
    });
  });
}
