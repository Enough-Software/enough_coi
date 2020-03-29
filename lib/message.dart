import 'dart:typed_data';
import 'package:enough_mail/enough_mail.dart';

class Message {
  String id;
  String conversationId;
  String threadReference;
  String groupId;
  String fromId;
  MailAddress from;
  List<MailAddress> recipients;
  DateTime date;
  String subject;
  List<MessagePart> parts;

  int sequenceId;
  bool get isChat =>
      (threadReference != null) && threadReference.startsWith(r'<chat$');

  String source;
  bool _hasText = false;
  bool get hasText => _hasText;
  String _text;
  String get text => _text;

  Message();
  Message.withId(this.id);

  bool get isOneToOneChat =>
      isChat &&
      !threadReference.startsWith(r'<chat$group') &&
      (recipients != null) &&
      (recipients.length == 1);

  void addRecipients(List<MailAddress> addresses) {
    recipients ??= <MailAddress>[];
    recipients.addAll(addresses);
  }

  void addPart(MessagePart part) {
    parts ??= <MessagePart>[];
    parts.add(part);
    if (!_hasText && part is TextMessagePart) {
      _text = part.text;
      _hasText = part.text?.isNotEmpty ?? false;
    }
  }
}

enum MessagePartType { text, image, audio, video, unknown }

class MessagePart {
  MediaType type;
  MessagePart(this.type);
}

class TextMessagePart extends MessagePart {
  String text;
  TextMessagePart(this.text, MediaType mediaType) : super(mediaType);
}

class ImageMessagePart extends MessagePart {
  Uint8List data;
  ImageMessagePart(this.data, MediaType mediaType) : super(mediaType);
}
