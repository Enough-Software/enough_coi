import 'package:enough_coi/src/string_helper.dart';
import 'package:enough_mail/enough_mail.dart';

class MailStorage {
  final String _password;
  final String _accountGuid;

  MailStorage(this._password, this._accountGuid) {
    //TODO open directory for account
  }

  String getThreadReference(MimeMessage message) {
    var rawConversationId = message.getHeaderValue('references');
    rawConversationId ??= message.getHeaderValue('message-id');
    if (rawConversationId == null) {
      print('unable to extract references or message-id from\n$message');
      return null;
    }
    var endIndex = rawConversationId.indexOf('>');
    var startIndex = rawConversationId.indexOf('<');
    if (startIndex != -1 && endIndex > startIndex + 1) {
      rawConversationId = rawConversationId.substring(startIndex + 1, endIndex);
    }
    return StringHelper.clearNonAsciiAndNonNumeric(rawConversationId);
  }

  void onNewMessage(MimeMessage message) {
    var threadId = getThreadReference(message);
    // open folder for thread
    // add message file
    // idea: immediate report message and don't wait for storage, but define completer or something in returned object, 
    // so that the interface can still for example delete the message, flag it, etc
  }
}
