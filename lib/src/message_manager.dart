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

  Future<Conversation> addMessage(MimeMessage mimeMessage) async {
    var message = _messageParser.parse(mimeMessage);
    var conversation =
        await _conversationManager.getConversationForMessage(message);
    message.conversationId = conversation.id;
    conversation.lastMessage = message;
    //TODO save message
    return conversation;
  }
}

class MessageParser {
  Message parse(MimeMessage mimeMessage) {
    var parsedMessage = Message.withId(GuidHelper.createGuid());
    parsedMessage.subject = mimeMessage.decodeHeaderValue('subject');
    //print('parsing ${parsedMessage.subject}...');
    var fromRaw = mimeMessage.decodeHeaderValue('from');
    if (fromRaw != null) {
      var addresses = MailHelper.parseEmailAddreses(fromRaw);
      if (addresses != null && addresses.isNotEmpty) {
        parsedMessage.from = addresses.first;
      }
    }
    var referenceRaw = mimeMessage.getHeaderValue('references');
    referenceRaw ??= mimeMessage.getHeaderValue('message-id');
    if (referenceRaw != null) {
      var endIndex = referenceRaw.indexOf('>');
      if (endIndex != -1) {
        parsedMessage.threadReference = referenceRaw.substring(0, endIndex + 1);
      }
    }
    var recipientsRaw = mimeMessage.decodeHeaderValue('to');
    if (recipientsRaw != null) {
      var addresses = MailHelper.parseEmailAddreses(recipientsRaw);
      parsedMessage.addRecipients(addresses);
    }
    recipientsRaw = mimeMessage.decodeHeaderValue('cc');
    if (recipientsRaw != null) {
      var addresses = MailHelper.parseEmailAddreses(recipientsRaw);
      parsedMessage.addRecipients(addresses);
    }
    var dateRaw = mimeMessage.getHeaderValue('date');
    if (dateRaw == null) {
      parsedMessage.date = DateTime.now();
    } else {
      // TODO parse date
      parsedMessage.date = DateTime.now();
    }
    if (mimeMessage.text != null) {
      var decodedText = mimeMessage.decodeContentText();
      parsedMessage.addPart(TextMessagePart(decodedText));
    }
    parsedMessage.sequenceId = mimeMessage.sequenceId;
    // TODO add other message parts than text
    return parsedMessage;
  }
}
