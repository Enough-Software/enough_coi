import 'package:enough_coi/conversation.dart';
import 'package:enough_coi/message.dart';
import 'package:enough_coi/src/conversation_manager.dart';
import 'package:enough_coi/src/message_manager.dart';
import 'package:event_bus/event_bus.dart';
import 'package:enough_mail/enough_mail.dart';

import '../email_account.dart';
import '../events.dart';

class ConnectedAccount {
  EmailAccount account;
  ImapClient imapClient;
  SmtpClient smtpClient;
  ConversationManager _conversationManager;
  MessageManager _messageManager;

  final EventBus _bus;
  final String _clientDomain;
  bool _isLogEnabled;

  ConnectedAccount(this.account, this._bus, this._clientDomain, 
      {this.imapClient, this.smtpClient, bool isLogEnabled = false}) {
    _isLogEnabled = isLogEnabled;
    _conversationManager = ConversationManager(account);
    _messageManager = MessageManager(_conversationManager);
  }

  Future<bool> connectIncoming() async {
    imapClient ??= ImapClient(bus: _bus, isLogEnabled: _isLogEnabled);
    var server = account.incomingServer;
    await imapClient.connectToServer(server.hostname, server.port,
        isSecure: server.isSecureSocket);
    var response = await imapClient.login(
        account.incomingUserName, account.incomingPassword);
    return response.isOkStatus;
  }

  Future<bool> connectOutgoing() async {
    smtpClient ??=
        SmtpClient(_clientDomain, bus: _bus, isLogEnabled: _isLogEnabled);
    var server = account.outgoingServer;
    await smtpClient.connectToServer(server.hostname, server.port,
        isSecure: server.isSecureSocket);
    var ehloResponse = await smtpClient.ehlo();
    if (ehloResponse.isFailedStatus) {
      return false;
    }
    if (!server.isSecureSocket) {
      // upgrate to SSL connection first:
      var startTlsResponse = await smtpClient.startTls();
      if (startTlsResponse.isFailedStatus) {
        //print('SMTP STARTTLS failed, unable to proceed via insure connection');
        _bus.fire(CoiLoginFailedEvent(LoginFailedReason.smtpStartTlsFailed));
        return false;
      }
    }
    var response = await smtpClient.login(
        account.outgoingUserName, account.outgoingPassword);
    return response.isOkStatus;
  }

  Future<List<MimeMessage>> fetchMessageHeaders() async {
    var connected = await _connectIncomingIfRequired();
    if (!connected) {
      print('connection failed');
      return null;
    }
    var mailboxResponse = await imapClient.listMailboxes();
    if (mailboxResponse.isFailedStatus || mailboxResponse.result.isEmpty) {
      print('no mailboxes');
      return null;
    }
    var mailbox = mailboxResponse.result
        .firstWhere((box) => box.name?.toLowerCase() == 'inbox');
    var selectResponse = await imapClient.selectMailbox(mailbox);
    if (selectResponse.isFailedStatus) {
      return null;
    }
    if (mailbox.messagesExists == 0) {
      return null;
    }
    //TODO use QRESYNC value to see if a refresh is required
    var lowerSequenceNumber =
        (mailbox.messagesExists < 100) ? 1 : mailbox.messagesExists - 100;
    var fetchContents =
        'BODY[HEADER]'; // '(FLAGS ENVELOPE BODY RFC822.SIZE BODY[HEADER])';
    var fetchHeaderResponse = await imapClient.fetchMessages(
        mailbox.messagesExists, lowerSequenceNumber, fetchContents);
    return fetchHeaderResponse.result;
  }

  Future<List<MimeMessage>> fetchChatMessages() async {
    var connected = await _connectIncomingIfRequired();
    if (!connected) {
      print('connection failed');
      return null;
    }
    var mailboxResponse = await imapClient.listMailboxes();
    if (mailboxResponse.isFailedStatus || mailboxResponse.result.isEmpty) {
      print('no mailboxes');
      return null;
    }
    var mailbox = mailboxResponse.result
        .firstWhere((box) => box.name?.toLowerCase() == 'inbox');
    var selectResponse = await imapClient.selectMailbox(mailbox);
    if (selectResponse.isFailedStatus) {
      return null;
    }
    if (mailbox.messagesExists == 0) {
      return null;
    }
    //TODO use QRESYNC value to see if a refresh is required
    var lowerSequenceNumber =
        (mailbox.messagesExists < 100) ? 1 : mailbox.messagesExists - 100;
    var fetchContents =
        '(ENVELOPE BODY.PEEK[HEADER.FIELDS (References Subject From)])'; // '(FLAGS ENVELOPE BODY RFC822.SIZE BODY[HEADER])';
    var fetchHeaderResponse = await imapClient.fetchMessages(
        mailbox.messagesExists, lowerSequenceNumber, fetchContents);
    var allMessages = fetchHeaderResponse.result;
    var chatMessages = <MimeMessage>[];
    for (var message in allMessages) {
      var references = message.getHeaderValue('references');
      if (references != null) {
        if (references.startsWith(r'<chat$')) {
          chatMessages.add(message);
        }
      } else if (message.messageId != null &&
          message.messageId.startsWith(r'<chat$')) {
        chatMessages.add(message);
      }
    }
    return chatMessages;
  }

  Future<MimeMessage> fetchMessageBody(MimeMessage message) async {
    var response = await imapClient
        .fetchMessagesByCriteria('${message.sequenceId} BODY[1]');
    if (response.isOkStatus && response.result.isNotEmpty) {
      var responseMessage = response.result.first;
      var content = responseMessage.getBodyPart(1);
      message.setBodyPart(1, content);
      message.bodyRaw = content;
      return message;
    }
    return null;
  }

   Future<List<Conversation>> fetchConversations() async {

    var connected = await _connectIncomingIfRequired();
    if (!connected) {
      print('connection failed');
      return null;
    }
    var mailboxResponse = await imapClient.listMailboxes();
    if (mailboxResponse.isFailedStatus || mailboxResponse.result.isEmpty) {
      print('no mailboxes');
      return null;
    }
    var mailbox = mailboxResponse.result
        .firstWhere((box) => box.name?.toLowerCase() == 'inbox');
    var selectResponse = await imapClient.selectMailbox(mailbox);
    if (selectResponse.isFailedStatus) {
      return null;
    }
    if (mailbox.messagesExists == 0) {
      return null;
    }
    //TODO use QRESYNC value to see if a refresh is required
    var lowerSequenceNumber =
        (mailbox.messagesExists < 100) ? 1 : mailbox.messagesExists - 100;
    var fetchContents =
    '(BODY BODY.PEEK[HEADER.FIELDS (message-Id references subject from to cc date content-type content-transfer-encoding)])'; // '(FLAGS ENVELOPE BODY RFC822.SIZE BODY[HEADER])';
        //'(BODY.PEEK[TEXT] BODY.PEEK[HEADER.FIELDS (message-Id references subject from to cc date content-type content-transfer-encoding)])'; // '(FLAGS ENVELOPE BODY RFC822.SIZE BODY[HEADER])';
    var fetchHeaderResponse = await imapClient.fetchMessages(
        mailbox.messagesExists, lowerSequenceNumber, fetchContents);
    var allMessages = fetchHeaderResponse.result;
    for (var mimeMessage in allMessages) {
      await _messageManager.addMessage(mimeMessage);
    }
    return _conversationManager.getConversations();
  }

  Future<bool> sendMessage(MimeMessage message) async {
    var connected = await _connectOutgoingIfRequired();
    if (connected) {
      var response = await smtpClient.sendMessage(message);
      return response.isOkStatus;
    } else {
      return false;
    }
  }

  Future<bool> _connectIncomingIfRequired() {
    if (imapClient == null || imapClient.isNotLoggedIn) {
      return connectIncoming();
    }
    return Future.value(true);
  }

  Future<bool> _connectOutgoingIfRequired() {
    if (smtpClient == null || smtpClient.isNotLoggedIn) {
      return connectOutgoing();
    }
    return Future.value(true);
  }
}
