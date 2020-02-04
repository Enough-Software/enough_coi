import 'package:enough_coi/email_account.dart';
import 'package:enough_coi/src/guid_helper.dart';

import 'message.dart';

class Conversation {
  final bool _isReadOnly;
  bool get isReadOnly => _isReadOnly;

  final String id;
  String threadReference;
  String name;
  List<String> contactIds;
  bool isChat;

  Message lastMessage;
  List<Message> messages = <Message>[];
  // Account account; // String accountId?
  
  //List<Participant> participants;
  
  //Conversation(this.name, this.id, this.contactIds, [this._isReadOnly = false]);
  Conversation(this.id, [this._isReadOnly = false]);

  static Conversation fromMessage(Message message, EmailAccount account) {
    var conversation = Conversation(GuidHelper.createGuid());
    conversation.threadReference = message.threadReference;
    if (message.recipients == null && message.recipients.length > 1) {
      // this is a group conversation:
      conversation.name = message.subject;
    } else {
      if (message.from?.email == account.email) {
        if (message.recipients.isNotEmpty) {
          var recipient = message.recipients.first;
          conversation.name = recipient.name ?? recipient.email;
        }
      } else {
        conversation.name = message.from?.name ?? message.from?.email;
      }
    }
    conversation.isChat = message.isChat;
    return conversation;
  }

  void addMessage(Message message) {
    messages.add(message);
  }

}

class GroupConversation extends Conversation {
  final String groupId;
  GroupConversation(String id, this.groupId, [bool isReadOnly = false]) : super(id, isReadOnly);
}
