import 'package:enough_coi/email_account.dart';

import '../conversation.dart';
import '../message.dart';

class ConversationManager {
  
  final Map<String, Conversation> _conversationsMap = <String, Conversation>{};
  final List<Conversation> _allConversations = <Conversation>[];
  final EmailAccount _account;

  ConversationManager(this._account);

  List<Conversation> getConversations() {
    _allConversations.sort((a,b) => b.lastMessage.date.compareTo(a.lastMessage.date));
    return _allConversations;
  }

  Future<Conversation> getConversationForMessage(Message message) async {
    Conversation conversation;
    String email;
    //print('${message.subject} == chat: ${message.isChat},  == 1:1: ${message.isOneToOneChat}');
    if (message.isOneToOneChat) {
      email = message.recipients.first.email;
      if (email == _account.email) {
        email = message.from?.email;
      }
      //print('1:1 message with $email');
      if (email != null) {
        conversation = getConversation(email: email);
      }
    }
    if (conversation == null && message.threadReference != null) {
      conversation = getConversation(threadReference: message.threadReference);
    }
    if (conversation == null) {
      // create new conversation based on message
      conversation = Conversation.fromMessage(message, _account);
      await addConversation(conversation, email);
    }
    conversation.lastMessage = message;
    conversation.addMessage(message);
    // TODO save conversation
    return conversation;
  }

  Conversation getConversation(
      {String id, String groupId, String threadReference, String email}) {
    if (id != null) {
      return _conversationsMap[id];
    }
    if (groupId != null) {
      return _conversationsMap['group.$groupId'];
    }
    if (threadReference != null) {
      return _conversationsMap['thread.$threadReference'];
    }
    if (email != null) {
      return _conversationsMap['email.$email'];
    }
    return null;
  }

  Future<bool> addConversation(Conversation conversation, String email) async{
    _conversationsMap[conversation.id] = conversation;
    if (conversation.threadReference != null) {
      _conversationsMap['thread.${conversation.threadReference}'] =
          conversation;
    }
    if (email != null) {
      _conversationsMap['email.${email}'] =
          conversation;
    }
    if (conversation is GroupConversation) {
      _conversationsMap['group.${conversation.groupId}'] = conversation;
    }
    _allConversations.add(conversation);
    // TODO store conversation
    return true;
  }
}
