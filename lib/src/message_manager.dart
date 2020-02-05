import 'package:enough_coi/conversation.dart';
import 'package:enough_coi/mail_helper.dart';
import 'package:enough_coi/src/conversation_manager.dart';
import 'package:enough_coi/src/guid_helper.dart';
import 'package:enough_mail/enough_mail.dart';

import '../message.dart';

class MessageManager {
  final ConversationManager _conversationManager;
  final MessageParser _messageParser = MessageParser();

  MessageManager(this._conversationManager);

  Future<Conversation> addMessage(MimeMessage rawMessage) async {
    var message = _messageParser.parse(rawMessage);
    var conversation =
        await _conversationManager.getConversationForMessage(message);
    message.conversationId = conversation.id;
    conversation.lastMessage = message;
    //TODO save message
    return conversation;
  }
}

class MessageParser {
  Message parse(MimeMessage rawMessage) {
    var parsedMessage = Message.withId(GuidHelper.createGuid());
    parsedMessage.subject = rawMessage.decodeHeaderValue('subject');
    //print('parsing ${parsedMessage.subject}...');
    var fromRaw = rawMessage.decodeHeaderValue('from');
    if (fromRaw != null) {
      var addresses = MailHelper.parseEmailAddreses(fromRaw);
      if (addresses != null && addresses.isNotEmpty) {
        parsedMessage.from = addresses.first;
      }
    }
    var referenceRaw = rawMessage.getHeaderValue('references');
    referenceRaw ??= rawMessage.getHeaderValue('message-id');
    if (referenceRaw != null) {
      var endIndex = referenceRaw.indexOf('>');
      if (endIndex != -1) {
        parsedMessage.threadReference = referenceRaw.substring(0, endIndex + 1);
      }
    }
    var recipientsRaw = rawMessage.decodeHeaderValue('to');
    if (recipientsRaw != null) {
      var addresses = MailHelper.parseEmailAddreses(recipientsRaw);
      parsedMessage.addRecipients(addresses);
    }
    recipientsRaw = rawMessage.decodeHeaderValue('cc');
    if (recipientsRaw != null) {
      var addresses = MailHelper.parseEmailAddreses(recipientsRaw);
      parsedMessage.addRecipients(addresses);
    }
    var dateRaw = rawMessage.getHeaderValue('date');
    if (dateRaw == null) {
      parsedMessage.date = DateTime.now();
    } else {
      // TODO parse date
      parsedMessage.date = DateTime.now();
    }
    if (rawMessage.text != null) {
      var decodedText = rawMessage.decodeContentText();
      parsedMessage.addPart(TextMessagePart(decodedText));
    }
    // TODO add other message parts than text
    return parsedMessage;
  }
}
