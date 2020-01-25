/// Classification of COI events
///
/// Compare [CoiEvent]
enum CoiEventType { loginFailure}

/// Base class for any event that can be fired by the COI client at any time.
class CoiEvent {
  final CoiEventType eventType;
  CoiEvent(this.eventType);
}

/// Reasons for a login failure
enum LoginFailedReason {
  imapNotReachable, imapUserInvalid, smtpNotReachable, smtpUserInvalid, smtpStartTlsFailed
}

/// Notifies about the login has failed
class CoiLoginFailedEvent extends CoiEvent {
  LoginFailedReason reason;
  CoiLoginFailedEvent(this.reason) : super(CoiEventType.loginFailure);
}



