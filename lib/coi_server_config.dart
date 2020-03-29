enum ChatMessageFilterRule { none, active, seen }

class CoiServerConfiguration {
  bool isServerCoiCompliant;
  bool isServerWebPushCompliant;
  String hierarchySeparator;
  bool isCoiEnabledForUser;
  ChatMessageFilterRule filterRule;
  String mailboxRoot;
  String get mailboxChats =>
      (mailboxRoot ?? 'COI') + (hierarchySeparator ?? '/') + 'Chats';
  String get mailboxContacts =>
      (mailboxRoot ?? 'COI') + (hierarchySeparator ?? '/') + 'Contacts';

  CoiServerConfiguration(
      this.isServerCoiCompliant,
      this.isServerWebPushCompliant,
      this.hierarchySeparator,
      this.isCoiEnabledForUser,
      this.filterRule,
      this.mailboxRoot);
}
