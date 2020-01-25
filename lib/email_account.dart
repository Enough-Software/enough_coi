import 'package:enough_coi/mail_server_config.dart';

class EmailAccount {
  String name;
  String email;
  String providerName;
  String incomingUserName;
  String incomingPassword;
  ServerConfig incomingServer;
  String outgoingUserName;
  String outgoingPassword;
  ServerConfig outgoingServer;

  EmailAccount(
      [this.name,
      this.email,
      this.providerName,
      this.incomingUserName,
      this.incomingPassword,
      this.incomingServer,
      this.outgoingUserName,
      this.outgoingPassword,
      this.outgoingServer]);
}
