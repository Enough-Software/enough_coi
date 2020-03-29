import 'package:enough_coi/conversation.dart';
import 'package:enough_coi/src/conversation_manager.dart';
import 'package:enough_coi/src/guid_helper.dart';
import 'package:enough_mail/enough_mail.dart';

import '../message.dart';

class MessageManager {
  final ConversationManager _conversationManager;

  MessageManager(this._conversationManager);

  Future<Conversation> addMessage(MimeMessage mimeMessage) async {
    var message = MessageParser.parse(mimeMessage);
    var conversation =
        await _conversationManager.getConversationForMessage(message);
    message.conversationId = conversation.id;
    conversation.lastMessage = message;
    //TODO save message
    return conversation;
  }
}

class MessageParser {
  static Message parse(MimeMessage mimeMessage, [Message parsedMessage]) {
    parsedMessage ??= Message.withId(GuidHelper.createGuid());
    parsedMessage.subject ??= mimeMessage.decodeSubject();
    //print('parsing ${parsedMessage.subject}...');
    if (parsedMessage.from == null) {
      var fromAddresses = mimeMessage.decodeHeaderMailAddressValue('from');
      if (fromAddresses != null && fromAddresses.isNotEmpty) {
        parsedMessage.from = fromAddresses.first;
      }
    }
    if (parsedMessage.threadReference == null) {
      var referenceRaw = mimeMessage.getHeaderValue('references');
      referenceRaw ??= mimeMessage.getHeaderValue('message-id');
      if (referenceRaw != null) {
        var endIndex = referenceRaw.indexOf('>');
        if (endIndex != -1) {
          parsedMessage.threadReference =
              referenceRaw.substring(0, endIndex + 1);
        }
      }
    }
    if (parsedMessage.recipients == null) {
      var recipientsAddresses = mimeMessage.decodeHeaderMailAddressValue('to');
      if (recipientsAddresses != null) {
        parsedMessage.addRecipients(recipientsAddresses);
      }
      recipientsAddresses = mimeMessage.decodeHeaderMailAddressValue('cc');
      if (recipientsAddresses != null) {
        parsedMessage.addRecipients(recipientsAddresses);
      }
    }
    parsedMessage.date ??= mimeMessage.decodeHeaderDateValue('date');
    mimeMessage.parse();
    if (mimeMessage.parts?.isNotEmpty ?? false) {
      _parseParts(mimeMessage.parts, parsedMessage);
    } else {
      _parsePart(mimeMessage, parsedMessage);
    }
    parsedMessage.sequenceId = mimeMessage.sequenceId;
    return parsedMessage;
  }

  static void _parseParts(List<MimePart> parts, Message parsedMessage) {
    if (parts == null) {
      return;
    }
    for (var part in parts) {
      _parsePart(part, parsedMessage);
    }
  }

  static void _parsePart(MimePart part, Message parsedMessage) {
    switch (part.mediaType.top) {
      case MediaToptype.text:
        var decodedText = part.decodeContentText();
        parsedMessage.addPart(TextMessagePart(decodedText, part.mediaType));
        break;
      case MediaToptype.multipart:
        // handle each part:
        _parseParts(part.parts, parsedMessage);
        break;
      // TODO add other message parts than text
      default:
        print('Unsupported media type [${part.mediaType.text}].');
    }
  }
}
