//import 'package:enough_coi/mail_server_config.dart';
import 'package:event_bus/event_bus.dart';
import 'package:enough_coi/enough_coi.dart';
import 'package:enough_coi/src/connected_account.dart';
import 'package:enough_coi/src/storage.dart';
import 'package:enough_mail/enough_mail.dart';

import 'email_account.dart';

class CoiClient {
  /// Allows to listens for events
  ///
  /// If no event bus is specified in the constructor, an aysnchronous bus is used.
  /// Usage:
  /// ```
  /// eventBus.on<CoiLoginFailedEvent>().listen((event) {
  ///   // All events are of type CoiLoginFailedEvent (or subtypes of it).
  ///   _log(event.eventType);
  /// });
  ///
  /// eventBus.on<CoiEvent>().listen((event) {
  ///   // All events are of type CoiEvent (or subtypes of it).
  ///   _log(event.eventType);
  /// });
  /// ```
  EventBus eventBus;
  bool _isLogEnabled;
  String _clientDomain = 'COI-dev.org';
  Storage _storage;
  List<EmailAccount> _accounts = <EmailAccount>[];
  final Map<EmailAccount, ConnectedAccount> _connectedAccounts =
      <EmailAccount, ConnectedAccount>{};

  CoiClient._internal(String clientDomain,
      {EventBus bus, bool isLogEnabled = false}) {
    eventBus = bus ?? EventBus();
    _isLogEnabled = isLogEnabled;
    if (clientDomain != null) {
      _clientDomain = clientDomain;
    }
    _storage = Storage();
  }

  static Future<CoiClient> init(String clientDomain,
      {EventBus bus,
      bool isLogEnabled = false,
      bool initStorage = true}) async {
    var client =
        CoiClient._internal(clientDomain, bus: bus, isLogEnabled: isLogEnabled);
    if (initStorage) {
      await client._storage.init();
    }
    return client;
  }

  Future<List<EmailAccount>> loadAccounts() async {
    _accounts = await _storage.loadAccounts();
    return _accounts;
  }

  Future<ClientConfig> discover(String emailAddress,
      {bool isEmailValidated = false}) async {
    if (!isEmailValidated && MailHelper.isNotEmailAddress(emailAddress)) {
      return null;
    }
    isEmailValidated = true;
    // [1] autodiscover from sub-domain, compare: https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration
    var emailDomain = MailHelper.getDomainFromEmail(emailAddress);
    var config = await MailHelper.autodiscoverFromAutoConfigSubdomain(
        emailAddress, emailDomain, _isLogEnabled);
    if (config != null) {
      return _updateDisplayNames(config, emailDomain);
    }
    var mxDomain = await MailHelper.autodiscoverMxDomain(emailDomain);
    _log('mxDomain for [$emailDomain] is [$mxDomain]');
    if (mxDomain != null && mxDomain != emailDomain) {
      config = await MailHelper.autodiscoverFromAutoConfigSubdomain(
          emailAddress, mxDomain, _isLogEnabled);
      if (config != null) {
        return _updateDisplayNames(config, emailDomain);
      }
    }
    // TODO allow more autodiscover options:
    // [2] https://docs.microsoft.com/en-us/previous-versions/office/office-2010/cc511507(v=office.14)
    // [3] https://docs.microsoft.com/en-us/exchange/client-developer/exchange-web-services/autodiscover-for-exchange
    // [4] https://docs.microsoft.com/en-us/exchange/architecture/client-access/autodiscover
    // [6] by trying typical options like imap.$domain, mail.$domain, etc

    //print('querying ISP DB for $mxDomain');

    // [5] autodiscover from Mozilla ISP DB: https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration
    config = await MailHelper.autodiscoverFromIspDb(mxDomain, _isLogEnabled);
    //print('got config $config for $mxDomain.');
    return _updateDisplayNames(config, emailDomain);
  }

  Future<List<EmailAccount>> addAccount(EmailAccount account) async {
    _accounts.add(account);
    await _storage.addAccount(account);
    return _accounts;
  }

  Future<List<EmailAccount>> removeAccount(EmailAccount account) async {
    var removed = _accounts.remove(account);
    if (removed) {
      await _storage.removeAccount(account);
    }
    return _accounts;
  }

  Future<EmailAccount> tryLogin(String email, ClientConfig config,
      {String password,
      String incomingUserName,
      String incomingPassword,
      ServerConfig incomingServer,
      String outgoingUserName,
      String outgoingPassword,
      ServerConfig outgoingServer}) async {
    if (config.preferredIncomingImapServer == null ||
        config.preferredOutgoingSmtpServer == null) {
      return null;
    }
    incomingServer ??= config.preferredIncomingImapServer;
    incomingUserName ??= MailHelper.getUserName(incomingServer, email);
    incomingPassword ??= password;
    _log('IMAP login into $incomingServer for user $incomingUserName...');
    var imapClient = ImapClient(isLogEnabled: _isLogEnabled);
    var connectedSocket = await imapClient.connectToServer(
        incomingServer.hostname, incomingServer.port,
        isSecure: incomingServer.socketType == SocketType.ssl);
    if (connectedSocket == null) {
      eventBus.fire(CoiLoginFailedEvent(LoginFailedReason.imapNotReachable));
      return null;
    }
    var loginImapResponse =
        await imapClient.login(incomingUserName, incomingPassword);
    if (loginImapResponse.isFailedStatus) {
      //print('IMAP login failed for host $imapConfig for user $userName');
      eventBus.fire(CoiLoginFailedEvent(LoginFailedReason.imapUserInvalid));
      return null;
    }
    outgoingServer ??= config.preferredOutgoingSmtpServer;
    outgoingUserName ??= MailHelper.getUserName(outgoingServer, email);
    outgoingPassword ??= password;
    _log('SMTP login into $outgoingServer for user $outgoingUserName');
    var smtpClient = SmtpClient(_clientDomain, isLogEnabled: _isLogEnabled);
    var isSecure = outgoingServer.socketType == SocketType.ssl;
    await smtpClient.connectToServer(
        outgoingServer.hostname, outgoingServer.port,
        isSecure: isSecure);
    await smtpClient.ehlo();
    if (!isSecure) {
      // upgrate to SSL connection first:
      var startTlsResponse = await smtpClient.startTls();
      if (startTlsResponse.isFailedStatus) {
        //print('SMTP STARTTLS failed, unable to proceed via insure connection');
        eventBus
            .fire(CoiLoginFailedEvent(LoginFailedReason.smtpStartTlsFailed));
        return null;
      }
    }
    var loginSmtpResponse =
        await smtpClient.login(outgoingUserName, outgoingPassword);
    if (loginSmtpResponse.isFailedStatus) {
      //print('SMTP login failed for host $smtpConfig for user $userName');
      eventBus.fire(CoiLoginFailedEvent(LoginFailedReason.smtpUserInvalid));
      return null;
    }
    return EmailAccount(
        null,
        email,
        config.displayName,
        incomingUserName,
        incomingPassword,
        incomingServer,
        outgoingUserName,
        outgoingPassword,
        outgoingServer);
  }

  ConnectedAccount _getConnectedAccount(EmailAccount account) {
    //TODO use factory constructor
    ConnectedAccount connectedAccount;
    if (!_connectedAccounts.containsKey(account)) {
      connectedAccount = ConnectedAccount(account, eventBus, _clientDomain,
          isLogEnabled: _isLogEnabled);
      _connectedAccounts[account] = connectedAccount;
    } else {
      connectedAccount = _connectedAccounts[account];
    }
    return connectedAccount;
  }

  Future<List<Message>> fetchMessageHeaders(EmailAccount account) {
    var connectedAccount = _getConnectedAccount(account);
    return connectedAccount.fetchMessageHeaders();
  }

  Future<Message> fetchMessageBody(Message message, account) {
    var connectedAccount = _getConnectedAccount(account);
    return connectedAccount.fetchMessageBody(message);
  }

  Future<bool> sendMessage(bool isChatMessage, String text,
      List<String> recipients, EmailAccount account,
      [String subject = null]) {
    //TODO allow to reply to message
    //TODO allow to send other message types than text
    var connectedAccount = _getConnectedAccount(account);
    var message = Message();
    message.addHeader('From', account.email);
    message.addHeader('To', recipients.join(';'));
    message.addHeader(
        'Content-Type', 'text/plain; charset=utf-8; format=flowed');
    message.addHeader('MIME-Version', '1.0');
    //message.addHeader('Content-Transfer-Encoding', ''); TODO define Content-Transfer-Encoding
    var dateHeaderValue = EncodingsHelper.encodeDate(DateTime.now());
    message.addHeader('Date', dateHeaderValue);
    if (isChatMessage) {
      subject ??=
          'Chat message from ${MailHelper.getLocalPartFromEmail(account.email)}';
      message.addHeader('Chat-Version', '1.0');
      message.addHeader('Message-Id',
          '<chat\$${DateTime.now().microsecondsSinceEpoch}@${MailHelper.getDomainFromEmail(account.email)}>');
    }
    message.addHeader('Subject', subject);
    message.recipients = recipients;
    message.bodyRaw = text;

    print(
        'Sending ${isChatMessage ? 'chat' : ''} message [$text] to $recipients from [${account.name}] at $dateHeaderValue');
    return connectedAccount.sendMessage(message);
  }

  // Future<bool> connectAndLoginFaster(
  //     String email, String password, ClientConfig config) async {
  //   var futures = <Future>[];
  //   var imapConfig = config.preferredIncomingImapServer;
  //   if (imapConfig != null) {
  //     var imapClient = ImapClient();
  //     futures.add(imapClient
  //         .connectToServer(imapConfig.hostname, imapConfig.port,
  //             isSecure: imapConfig.socketType == SocketType.ssl)
  //         .then((s) {
  //       var userName = MailHelper.getUserName(imapConfig, email);
  //       imapClient.login(userName, password).then((loginImapResponse) {
  //         if (loginImapResponse.isFailedStatus) {
  //           eventBus.fire(CoiLoginFailedEvent());
  //         }
  //       }, onError: () {
  //         eventBus.fire(CoiLoginFailedEvent());
  //         return false;
  //       });
  //     }));
  //   }
  //   var smtpConfig = config.preferredOutgoingSmtpServer;
  //   if (smtpConfig != null) {
  //     var smtpClient = SmtpClient('COI SDK');
  //     var userName = MailHelper.getUserName(smtpConfig, email);
  //     futures
  //         .add(smtpClient.login(userName, password).then((loginSmtpResponse) {
  //       if (loginSmtpResponse.isFailedStatus) {
  //         eventBus.fire(CoiLoginFailedEvent());
  //         return false;
  //       }
  //     }));
  //   }
  //   await Future.wait(futures);
  //   return true;
  // }

  ClientConfig _updateDisplayNames(ClientConfig config, String mailDomain) {
    if (config?.emailProviders?.isNotEmpty ?? false) {
      for (var provider in config.emailProviders) {
        if (provider.displayName != null) {
          provider.displayName =
              provider.displayName.replaceFirst('%EMAILDOMAIN%', mailDomain);
        }
        if (provider.displayShortName != null) {
          provider.displayShortName = provider.displayShortName
              .replaceFirst('%EMAILDOMAIN%', mailDomain);
        }
      }
    }
    return config;
  }

  void _log(String text) {
    if (_isLogEnabled) {
      print(text);
    }
  }
}
