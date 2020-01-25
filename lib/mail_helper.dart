import 'dart:async';
import 'package:enough_coi/src/http_client_helper.dart';
import 'package:xml/xml.dart' as xml;
import 'package:basic_utils/basic_utils.dart';

import 'mail_server_config.dart';

/// Lowlevel helper methods for mail scenarios
class MailHelper {
  static bool isEmailAddress(String emailInput) {
    return EmailUtils.isEmail(emailInput);
  }

  static bool isNotEmailAddress(String emailInput) =>
      !isEmailAddress(emailInput);

  /// Extracts the domain from the email address (the part after the @)
  static String getDomainFromEmail(String emailAddress) =>
      emailAddress.substring(emailAddress.indexOf('@') + 1);

  /// Extracts the local part from the email address (the part before the @)
  static String getLocalPartFromEmail(String emailAddress) =>
      emailAddress.substring(0, emailAddress.indexOf('@'));

  static String getUserName(ServerConfig config, String email) {
    return (config.usernameType == UsernameType.emailAddress)
        ? email
        : (config.usernameType == UsernameType.unknown)
            ? config.username
            : getLocalPartFromEmail(email);
  }

  /// Autodiscovers mail configuration from sub-domain
  ///
  /// compare: https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration
  static Future<ClientConfig> autodiscoverFromAutoConfigSubdomain(
      String emailAddress,
      [String domain,
      bool isLogEnabled = false]) async {
    domain ??= getDomainFromEmail(emailAddress);
    var url =
        'https://autoconfig.$domain/mail/config-v1.1.xml?emailaddress=$emailAddress';
    if (isLogEnabled) {
      print('Discover: trying $url');
    }
    var response = await HttpClientHelper.httpGet(url, validStatusCode: 200);
    if (response?.statusCode != 200) {
      url = // try insecure lookup:
          'http://autoconfig.$domain/mail/config-v1.1.xml?emailaddress=$emailAddress';
      if (isLogEnabled) {
        print('Discover: trying $url');
      }
      response = await HttpClientHelper.httpGet(url, validStatusCode: 200);
      if (response?.statusCode != 200) {
        return null;
      }
    }
    return parseClientConfig(response.content);
  }

  /// Looks up domain referenced by the email's domain DNS MX record
  static Future<String> autodiscoverMxDomainFromEmail(
      String emailAddress) async {
    var domain = getDomainFromEmail(emailAddress);
    return autodiscoverMxDomain(domain);
  }

  /// Looks up domain referenced by the domain's DNS MX record
  static Future<String> autodiscoverMxDomain(String domain) async {
    var mxRecords = await DnsUtils.lookupRecord(domain, RRecordType.MX);
    if (mxRecords == null || mxRecords.isEmpty) {
      //print('unable to read MX records for [$domain].');
      return null;
    }
    // for (var mxRecord in mxRecords) {
    //   print(
    //       'mx for [$domain]: ${mxRecord.name}=${mxRecord.data}  - rType=${mxRecord.rType}');
    // }
    var mxDomain = mxRecords.first.data;
    var dotIndex = mxDomain.indexOf('.');
    if (dotIndex == -1) {
      return null;
    }
    var lastDotIndex = mxDomain.lastIndexOf('.');
    if (lastDotIndex <= dotIndex - 1) {
      return null;
    }
    mxDomain = mxDomain.substring(dotIndex + 1, lastDotIndex);
    return mxDomain;
  }

  /// Autodiscovers mail configuration from Mozilla ISP DB
  ///
  /// Compare: https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration
  static Future<ClientConfig> autodiscoverFromIspDb(String domain,
      [bool isLogEnabled = false]) async {
    //print('Querying ISP DB for $domain');
    var url = 'https://autoconfig.thunderbird.net/v1.1/$domain';
    if (isLogEnabled) {
      print('Disover: trying $url');
    }
    var response = await HttpClientHelper.httpGet(url, validStatusCode: 200);
    //print('got response ${response.statusCode}');
    if (response.statusCode != 200) {
      return null;
    }
    return parseClientConfig(response.content);
  }

  /// Parses a Mozilla-compatible autoconfig file
  ///
  /// Compare: https://wiki.mozilla.org/Thunderbird:Autoconfiguration:ConfigFileFormat
  static ClientConfig parseClientConfig(String definition) {
    var config = ClientConfig();
    var document = xml.parse(definition);
    for (var node in document.children) {
      if (node is xml.XmlElement && node.name.local == 'clientConfig') {
        var versionAttributes =
            node.attributes.where((a) => a.name?.local == 'version');
        if (versionAttributes.isNotEmpty) {
          config.version = versionAttributes.first.value;
        } else {
          config.version = '1.1';
        }
        var providerNodes = node.children.where(
            (c) => c is xml.XmlElement && c.name.local == 'emailProvider');
        for (var providerNode in providerNodes) {
          if (providerNode is xml.XmlElement) {
            var provider = ConfigEmailProvider();
            provider.id = providerNode.getAttribute('id');
            for (var providerChild in providerNode.children) {
              if (providerChild is xml.XmlElement) {
                switch (providerChild.name.local) {
                  case 'domain':
                    provider.addDomain(providerChild.text);
                    break;
                  case 'displayName':
                    provider.displayName = providerChild.text;
                    break;
                  case 'displayShortName':
                    provider.displayShortName = providerChild.text;
                    break;
                  case 'incomingServer':
                    provider
                        .addIncomingServer(_parseServerConfig(providerChild));
                    break;
                  case 'outgoingServer':
                    provider
                        .addOutgoingServer(_parseServerConfig(providerChild));
                    break;
                  case 'documentation':
                    provider.documentationUrl ??=
                        providerChild.getAttribute('url');
                    break;
                }
              }
            }
            config.addEmailProvider(provider);
          }
        }
        break;
      }
    }
    if (config.isNotValid) {
      return null;
    }
    return config;
  }

  static ServerConfig _parseServerConfig(xml.XmlElement serverElement) {
    var server = ServerConfig();
    server.typeName = serverElement.getAttribute('type');
    server.type = _serverTypeFromText(server.typeName);
    for (var childNode in serverElement.children) {
      if (childNode is xml.XmlElement) {
        var text = childNode.text;
        switch (childNode.name.local) {
          case 'hostname':
            server.hostname = text;
            break;
          case 'port':
            server.port = int.tryParse(text);
            break;
          case 'socketType':
            server.socketType = _socketTypeFromText(text);
            break;
          case 'authentication':
            var auth = _authenticationFromText(text);
            if (server.authentication != null) {
              server.authenticationAlternative = auth;
            } else {
              server.authentication = auth;
            }
            break;
          case 'username':
            server.username = text;
            server.usernameType = _usernameTypeFromText(text);
            break;
        }
      }
    }
    return server;
  }

  static SocketType _socketTypeFromText(String text) {
    SocketType type;
    switch (text.toUpperCase()) {
      case 'SSL':
        type = SocketType.ssl;
        break;
      case 'STARTTLS':
        type = SocketType.starttls;
        break;
      case 'PLAIN':
        type = SocketType.plain;
        break;
      default:
        type = SocketType.unknown;
    }
    return type;
  }

  static Authentication _authenticationFromText(String text) {
    Authentication authentication;
    switch (text.toLowerCase()) {
      case 'oauth2':
        authentication = Authentication.oauth2;
        break;
      case 'password-cleartext':
        authentication = Authentication.passwordCleartext;
        break;
      case 'plain':
        authentication = Authentication.plain;
        break;
      case 'password-encrypted':
        authentication = Authentication.passwordEncrypted;
        break;
      case 'secure':
        authentication = Authentication.secure;
        break;
      case 'ntlm':
        authentication = Authentication.ntlm;
        break;
      case 'gsapi':
        authentication = Authentication.gsapi;
        break;
      case 'client-ip-address':
        authentication = Authentication.clientIpAddress;
        break;
      case 'tls-client-cert':
        authentication = Authentication.tlsClientCert;
        break;
      case 'smtp-after-pop':
        authentication = Authentication.smtpAfterPop;
        break;
      case 'none':
        authentication = Authentication.none;
        break;
      default:
        authentication = Authentication.unknown;
    }
    return authentication;
  }

  static UsernameType _usernameTypeFromText(String text) {
    UsernameType type;
    switch (text.toUpperCase()) {
      case '%EMAILADDRESS%':
        type = UsernameType.emailAddress;
        break;
      case '%EMAILLOCALPART%':
        type = UsernameType.emailLocalPart;
        break;
      case '%REALNAME%':
        type = UsernameType.realname;
        break;
      default:
        type = UsernameType.unknown;
    }
    return type;
  }

  static ServerType _serverTypeFromText(String text) {
    ServerType type;
    switch (text.toLowerCase()) {
      case 'imap':
        type = ServerType.imap;
        break;
      case 'pop3':
        type = ServerType.pop;
        break;
      case 'smtp':
        type = ServerType.smtp;
        break;
      default:
        type = ServerType.unknown;
    }
    return type;
  }
}
