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
        '(BODY.PEEK[HEADER.FIELDS (message-Id references subject from to cc date content-type content-transfer-encoding)])';
    var fetchHeaderResponse = await imapClient.fetchMessages(
        mailbox.messagesExists, lowerSequenceNumber, fetchContents);
    var allMessages = fetchHeaderResponse.result;
    for (var mimeMessage in allMessages) {
      await _messageManager.addMessage(mimeMessage);
    }
    return _conversationManager.getConversations();
  }

  Future<Message> fetchMessageContents(Message message) async {
    var fetchHeaderResponse = await imapClient
        .fetchMessagesByCriteria('${message.sequenceId} (BODY BODY.PEEK[1])');
    var allMessages = fetchHeaderResponse.result;
    //print('allMessages.length=${allMessages?.length}');
    if (allMessages?.length == 1) {
      var mimeMessage = allMessages.first;
      var bodyPartText = mimeMessage.getBodyPart(1);
      var structures = mimeMessage.body?.structures;
      //print('structures.length=${structures?.length}');
      String decodedText;
      if (structures != null && structures.isNotEmpty) {
        var structure = structures.first;
        //print('type=${structure.type}');
        if (structure.type == 'text') {
          var charsets = structure.attributes
              .where((a) => a.name.toUpperCase() == 'CHARSET');
          if (charsets.isNotEmpty) {
            var charset = charsets.first.value;
            var transferEncoding = structure.encoding;
            //print('charset=$charset encoder=$transferEncoding');
            decodedText = EncodingsHelper.decodeText(
                bodyPartText, transferEncoding, charset);
          }
        }
      }
      if (decodedText == null) {
        mimeMessage.text = bodyPartText;
        decodedText = mimeMessage.decodeContentText();
      }
      if (decodedText != null && decodedText.length > 50) {
        decodedText = decodedText.substring(0, 50) + '...';
      }
      message.addPart(TextMessagePart(decodedText));
    } else {
      print('unable to load ${message.sequenceId}');
    }
    return message;
  }

  Future<List<MetaDataEntry>> getMetaData(String entry,
      {String mailboxName, int maxSize, MetaDataDepth depth}) async {
    var connected = await _connectIncomingIfRequired();
    if (!connected) {
      print('connection failed');
      return null;
    }
    var response = await imapClient.getMetaData(entry,
        mailboxName: mailboxName, maxSize: maxSize, depth: depth);
    if (response.isFailedStatus) {
      return null;
    }
    return response.result;
  }

  Future<bool> setMetaData(String entry, String value,
      {String mailboxName}) async {
    var connected = await _connectIncomingIfRequired();
    if (!connected) {
      print('connection failed');
      return null;
    }
    var metaDataEntry = MetaDataEntry()
      ..entry = entry
      ..valueText = value
      ..mailboxName = mailboxName;
    var response = await imapClient.setMetaData(metaDataEntry);
    return response.isOkStatus;
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

  Future<List<Capability>> getIncomingCapabilities() async {
    await _connectIncomingIfRequired();
    return imapClient.serverInfo.capabilities;
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

  Future<String> getIncomingHierarchySeparator() async {
    await _connectIncomingIfRequired();
    if (imapClient.serverInfo.pathSeparator == null) {
      await imapClient.listMailboxes();
    }
    return imapClient.serverInfo.pathSeparator;
  }
}
