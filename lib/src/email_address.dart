class EmailAddress {
  String name;
  String email;
  String get domain =>
      email.contains('@') ? email.substring(email.indexOf('@') + 1) : null;

  EmailAddress(this.name, this.email);
  EmailAddress.empty();
}
