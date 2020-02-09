enum ChatMessageFilterRule {
  none, active, seen
}


class CoiServerConfiguration {
  bool isServerCoiCompliant;
  bool isServerWebPushCompliant;
  String hierarchySeparator;
  bool isCoiEnabledForUser;
  ChatMessageFilterRule filterRule;
  String mailboxRoot;
  String get mailboxChats => mailboxRoot + hierarchySeparator + 'Chats';
  String get mailboxContacts => mailboxRoot + hierarchySeparator + 'Contacts';

  CoiServerConfiguration(this.isServerCoiCompliant, this.isServerWebPushCompliant, this.hierarchySeparator, this.isCoiEnabledForUser, this.filterRule, this.mailboxRoot);
}