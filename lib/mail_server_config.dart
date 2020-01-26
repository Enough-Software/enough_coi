import 'package:json_annotation/json_annotation.dart';

part 'mail_server_config.g.dart';

@JsonSerializable(explicitToJson: true)
class ClientConfig {
  String version;
  List<ConfigEmailProvider> emailProviders;

  bool get isNotValid =>
      emailProviders == null ||
      emailProviders.isEmpty ||
      emailProviders.first.preferredIncomingServer == null ||
      emailProviders.first.preferredOutgoingServer == null;
  bool get isValid => !isNotValid;

  ClientConfig({this.version});

  /// JSON generation code
  factory ClientConfig.fromJson(Map<String, dynamic> json) =>
      _$ClientConfigFromJson(json);

  /// JSON generation code
  Map<String, dynamic> toJson() => _$ClientConfigToJson(this);

  void addEmailProvider(ConfigEmailProvider provider) {
    emailProviders ??= <ConfigEmailProvider>[];
    emailProviders.add(provider);
  }

  ServerConfig get preferredIncomingServer => emailProviders?.isEmpty ?? true
      ? null
      : emailProviders.first.preferredIncomingServer;
  ServerConfig get preferredIncomingImapServer =>
      emailProviders?.isEmpty ?? true
          ? null
          : emailProviders.first.preferredIncomingImapServer;
  ServerConfig get preferredIncomingPopServer => emailProviders?.isEmpty ?? true
      ? null
      : emailProviders.first.preferredIncomingPopServer;
  ServerConfig get preferredOutgoingServer => emailProviders?.isEmpty ?? true
      ? null
      : emailProviders.first.preferredOutgoingServer;
  ServerConfig get preferredOutgoingSmtpServer =>
      emailProviders?.isEmpty ?? true
          ? null
          : emailProviders.first.preferredOutgoingSmtpServer;
  String get displayName =>
      emailProviders?.isEmpty ?? true ? null : emailProviders.first.displayName;
}

@JsonSerializable(explicitToJson: true)
class ConfigEmailProvider {
  String id;
  List<String> domains;
  String displayName;
  String displayShortName;
  List<ServerConfig> incomingServers;
  List<ServerConfig> outgoingServers;
  String documentationUrl;
  ServerConfig preferredIncomingServer;
  ServerConfig preferredIncomingImapServer;
  ServerConfig preferredIncomingPopServer;
  ServerConfig preferredOutgoingServer;
  ServerConfig preferredOutgoingSmtpServer;

  ConfigEmailProvider(
      {this.id,
      this.domains,
      this.displayName,
      this.displayShortName,
      this.incomingServers,
      this.outgoingServers});

  /// JSON generation code
  factory ConfigEmailProvider.fromJson(Map<String, dynamic> json) =>
      _$ConfigEmailProviderFromJson(json);

  /// JSON generation code
  Map<String, dynamic> toJson() => _$ConfigEmailProviderToJson(this);

  void addDomain(String name) {
    domains ??= <String>[];
    domains.add(name);
  }

  void addIncomingServer(ServerConfig server) {
    incomingServers ??= <ServerConfig>[];
    incomingServers.add(server);
    preferredIncomingServer ??= server;
    if (server.type == ServerType.imap && preferredIncomingImapServer == null) {
      preferredIncomingImapServer = server;
    }
    if (server.type == ServerType.pop && preferredIncomingPopServer == null) {
      preferredIncomingPopServer = server;
    }
  }

  void addOutgoingServer(ServerConfig server) {
    outgoingServers ??= <ServerConfig>[];
    outgoingServers.add(server);
    preferredOutgoingServer ??= server;
    if (server.type == ServerType.smtp && preferredOutgoingSmtpServer == null) {
      preferredOutgoingSmtpServer = server;
    }
  }
}

enum ServerType { imap, pop, smtp, unknown }

enum SocketType { plain, ssl, starttls, unknown }

enum Authentication {
  oauth2,
  passwordCleartext,
  plain,
  passwordEncrypted,
  secure,
  ntlm,
  gsapi,
  clientIpAddress,
  tlsClientCert,
  smtpAfterPop,
  none,
  unknown
}

enum UsernameType { emailAddress, emailLocalPart, realname, unknown }

@JsonSerializable(explicitToJson: true)
class ServerConfig {
  String typeName;
  ServerType type;
  String hostname;
  int port;
  SocketType socketType;
  String get socketTypeName =>
      socketType.toString().substring('sockeType.'.length);
  Authentication authentication;
  Authentication authenticationAlternative;
  String username;
  UsernameType usernameType;

  bool get isSecureSocket => (socketType == SocketType.ssl);

  ServerConfig(
      {this.type,
      this.hostname,
      this.port,
      this.socketType,
      this.authentication,
      this.username});

  /// JSON generation code
  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);

  /// JSON generation code
  Map<String, dynamic> toJson() => _$ServerConfigToJson(this);

  @override
  String toString() {
    return '$typeName $hostname:$port ($socketType) ($authentication) with username $username';
  }
}
