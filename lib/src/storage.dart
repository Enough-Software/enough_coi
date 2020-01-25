import 'dart:io';
import 'package:objectdb/objectdb.dart';
import 'package:enough_coi/mail_server_config.dart';

import '../email_account.dart';

ObjectDB _accountDb;

class Storage {
  Future<void> init() async {
    final path = Directory.current.path + '/coicli_accounts.db';
    var db = ObjectDB(path);
    await db.open();
    _accountDb = db;
  }

  Future<List<EmailAccount>> loadAccounts() async {
    var accountMaps = await _accountDb.find({'type': 'account'});
    if (accountMaps.isEmpty) {
      return <EmailAccount>[];
    }
    var accounts = <EmailAccount>[];
    for (var map in accountMaps) {
      accounts.add(StorageMapper.accountFromMap(map));
    }
    return accounts;
  }

  Future<void> addAccount(EmailAccount account) async {
    await _accountDb.insert(StorageMapper.accountToMap(account));
  }

  Future<void> removeAccount(EmailAccount account) async {
    await _accountDb.remove(StorageMapper.accountToMap(account));
  }
}

class StorageMapper {
  static EmailAccount accountFromMap(Map<dynamic, dynamic> map) {
    return EmailAccount(
        map['name'],
        map['email'],
        map['providerName'],
        map['incomingUserName'],
        map['incomingPassword'],
        serverFromString(map['incomingServer']),
        map['outgoingUserName'],
        map['outgoingPassword'],
        serverFromString(map['outgoingServer']));
  }

  static Map<dynamic, dynamic> accountToMap(EmailAccount account) {
    var map = {
      'type': 'account',
      'name': account.name,
      'email': account.email,
      'providerName': account.providerName,
      'incomingUserName': account.incomingUserName,
      'incomingPassword': account.incomingPassword,
      'incomingServer': serverToString(account.incomingServer),
      'outgoingUserName': account.outgoingUserName,
      'outgoingPassword': account.outgoingPassword,
      'outgoingServer': serverToString(account.outgoingServer)
    };
    return map;
  }

  static Map<dynamic, dynamic> serverToMap(ServerConfig server) {
    return {
      'type': server.type,
      'typeName': server.typeName,
      'hostname': server.hostname,
      'port': server.port,
      'username': server.username,
      'usernameType': server.usernameType,
      'authentication': server.authentication,
      'authenticationAlternative': server.authenticationAlternative
    };
  }

  static String serverToString(ServerConfig server) {
    var buffer = StringBuffer();
    buffer.write(server.type.index);
    buffer.write(';');
    buffer.write(server.typeName);
    buffer.write(';');
    buffer.write(server.hostname);
    buffer.write(';');
    buffer.write(server.port);
    buffer.write(';');
    buffer.write(server.socketType.index);
    buffer.write(';');
    buffer.write(server.username);
    buffer.write(';');
    buffer.write(server.usernameType.index);
    buffer.write(';');
    buffer.write(server.authentication.index);
    buffer.write(';');
    buffer.write(server.authenticationAlternative?.index ?? '<null>');
    return buffer.toString();
  }

  static ServerConfig serverFromString(String text) {
    var elements = text.split(';');
    var config = ServerConfig();
    config.type = ServerType.values[int.parse(elements[0])];
    config.typeName = elements[1];
    config.hostname = elements[2];
    config.port = int.parse(elements[3]);
    config.socketType = SocketType.values[int.parse(elements[4])];
    config.username = elements[5];
    config.usernameType = UsernameType.values[int.parse(elements[6])];
    config.authentication = Authentication.values[int.parse(elements[7])];
    var alt = elements[8];
    if (alt != '<null>') {
      config.authenticationAlternative = Authentication.values[int.parse(alt)];
    }
    return config;
  }
}
