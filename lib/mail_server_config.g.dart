// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_server_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientConfig _$ClientConfigFromJson(Map<String, dynamic> json) {
  return ClientConfig(
    version: json['version'] as String,
  )..emailProviders = (json['emailProviders'] as List)
      ?.map((e) => e == null
          ? null
          : ConfigEmailProvider.fromJson(e as Map<String, dynamic>))
      ?.toList();
}

Map<String, dynamic> _$ClientConfigToJson(ClientConfig instance) =>
    <String, dynamic>{
      'version': instance.version,
      'emailProviders':
          instance.emailProviders?.map((e) => e?.toJson())?.toList(),
    };

ConfigEmailProvider _$ConfigEmailProviderFromJson(Map<String, dynamic> json) {
  return ConfigEmailProvider(
    id: json['id'] as String,
    domains: (json['domains'] as List)?.map((e) => e as String)?.toList(),
    displayName: json['displayName'] as String,
    displayShortName: json['displayShortName'] as String,
    incomingServers: (json['incomingServers'] as List)
        ?.map((e) =>
            e == null ? null : ServerConfig.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    outgoingServers: (json['outgoingServers'] as List)
        ?.map((e) =>
            e == null ? null : ServerConfig.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  )
    ..documentationUrl = json['documentationUrl'] as String
    ..preferredIncomingServer = json['preferredIncomingServer'] == null
        ? null
        : ServerConfig.fromJson(
            json['preferredIncomingServer'] as Map<String, dynamic>)
    ..preferredIncomingImapServer = json['preferredIncomingImapServer'] == null
        ? null
        : ServerConfig.fromJson(
            json['preferredIncomingImapServer'] as Map<String, dynamic>)
    ..preferredIncomingPopServer = json['preferredIncomingPopServer'] == null
        ? null
        : ServerConfig.fromJson(
            json['preferredIncomingPopServer'] as Map<String, dynamic>)
    ..preferredOutgoingServer = json['preferredOutgoingServer'] == null
        ? null
        : ServerConfig.fromJson(
            json['preferredOutgoingServer'] as Map<String, dynamic>)
    ..preferredOutgoingSmtpServer = json['preferredOutgoingSmtpServer'] == null
        ? null
        : ServerConfig.fromJson(
            json['preferredOutgoingSmtpServer'] as Map<String, dynamic>);
}

Map<String, dynamic> _$ConfigEmailProviderToJson(
        ConfigEmailProvider instance) =>
    <String, dynamic>{
      'id': instance.id,
      'domains': instance.domains,
      'displayName': instance.displayName,
      'displayShortName': instance.displayShortName,
      'incomingServers':
          instance.incomingServers?.map((e) => e?.toJson())?.toList(),
      'outgoingServers':
          instance.outgoingServers?.map((e) => e?.toJson())?.toList(),
      'documentationUrl': instance.documentationUrl,
      'preferredIncomingServer': instance.preferredIncomingServer?.toJson(),
      'preferredIncomingImapServer':
          instance.preferredIncomingImapServer?.toJson(),
      'preferredIncomingPopServer':
          instance.preferredIncomingPopServer?.toJson(),
      'preferredOutgoingServer': instance.preferredOutgoingServer?.toJson(),
      'preferredOutgoingSmtpServer':
          instance.preferredOutgoingSmtpServer?.toJson(),
    };

ServerConfig _$ServerConfigFromJson(Map<String, dynamic> json) {
  return ServerConfig(
    type: _$enumDecodeNullable(_$ServerTypeEnumMap, json['type']),
    hostname: json['hostname'] as String,
    port: json['port'] as int,
    socketType: _$enumDecodeNullable(_$SocketTypeEnumMap, json['socketType']),
    authentication:
        _$enumDecodeNullable(_$AuthenticationEnumMap, json['authentication']),
    username: json['username'] as String,
  )
    ..typeName = json['typeName'] as String
    ..authenticationAlternative = _$enumDecodeNullable(
        _$AuthenticationEnumMap, json['authenticationAlternative'])
    ..usernameType =
        _$enumDecodeNullable(_$UsernameTypeEnumMap, json['usernameType']);
}

Map<String, dynamic> _$ServerConfigToJson(ServerConfig instance) =>
    <String, dynamic>{
      'typeName': instance.typeName,
      'type': _$ServerTypeEnumMap[instance.type],
      'hostname': instance.hostname,
      'port': instance.port,
      'socketType': _$SocketTypeEnumMap[instance.socketType],
      'authentication': _$AuthenticationEnumMap[instance.authentication],
      'authenticationAlternative':
          _$AuthenticationEnumMap[instance.authenticationAlternative],
      'username': instance.username,
      'usernameType': _$UsernameTypeEnumMap[instance.usernameType],
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$ServerTypeEnumMap = {
  ServerType.imap: 'imap',
  ServerType.pop: 'pop',
  ServerType.smtp: 'smtp',
  ServerType.unknown: 'unknown',
};

const _$SocketTypeEnumMap = {
  SocketType.plain: 'plain',
  SocketType.ssl: 'ssl',
  SocketType.starttls: 'starttls',
  SocketType.unknown: 'unknown',
};

const _$AuthenticationEnumMap = {
  Authentication.oauth2: 'oauth2',
  Authentication.passwordCleartext: 'passwordCleartext',
  Authentication.plain: 'plain',
  Authentication.passwordEncrypted: 'passwordEncrypted',
  Authentication.secure: 'secure',
  Authentication.ntlm: 'ntlm',
  Authentication.gsapi: 'gsapi',
  Authentication.clientIpAddress: 'clientIpAddress',
  Authentication.tlsClientCert: 'tlsClientCert',
  Authentication.smtpAfterPop: 'smtpAfterPop',
  Authentication.none: 'none',
  Authentication.unknown: 'unknown',
};

const _$UsernameTypeEnumMap = {
  UsernameType.emailAddress: 'emailAddress',
  UsernameType.emailLocalPart: 'emailLocalPart',
  UsernameType.realname: 'realname',
  UsernameType.unknown: 'unknown',
};
