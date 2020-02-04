import 'dart:typed_data';

class Message {
  String id;
  String conversationId;
  String threadReference;
  String groupId;
  String fromId;
  EmailAddress from;
  List<EmailAddress> recipients;
  DateTime date;
  String subject;
  List<MessagePart> parts;
  bool get isChat =>
      (threadReference != null) && threadReference.startsWith(r'<chat$');

  String source;

  Message();
  Message.withId(this.id);

  bool get isOneToOneChat =>
      isChat &&
      !threadReference.startsWith(r'<chat$group') &&
      (recipients != null) &&
      (recipients.length == 1);

  void addRecipients(List<EmailAddress> addresses) {
    if (recipients == null) {
      recipients = addresses;
    } else {
      recipients.addAll(addresses);
    }
  }
}

class EmailAddress {
  String name;
  String email;
  String get domain =>
      email.contains('@') ? email.substring(email.indexOf('@') + 1) : null;

  EmailAddress(this.name, this.email);
  EmailAddress.empty();
}

enum MessagePartType { text, image, audio, video, unknown }

class MessagePart {
  MessagePartType type;
  MessagePart(this.type);
}

class TextMessagePart extends MessagePart {
  String text;
  TextMessagePart(this.text) : super(MessagePartType.text);
}

enum ImageType { png, jpeg, gif, other }

class ImageMessagePart extends MessagePart {
  ImageType imageType;
  Uint8List data;
  ImageMessagePart(this.imageType, this.data) : super(MessagePartType.image);
}
