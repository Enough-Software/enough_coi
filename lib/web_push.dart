import 'dart:convert';

enum WebPushMessageType { chat, mail, all }

class WebPushSubscription {
  String id;
  String client;
  String device;
  WebPushMessageType messageType;
  WebPushResource resource;

  static WebPushSubscription fromValues(
      String client,
      String device,
      WebPushMessageType messageType,
      String endpoint,
      String p256dhKey,
      String authKey) {
    var resource = WebPushResource()
      ..endpoint = endpoint
      ..keys = WebPushKey.withValues(p256dhKey, authKey);
    return WebPushSubscription()
      ..client = client
      ..device = device
      ..messageType = messageType
      ..resource = resource;
  }

  static WebPushSubscription fromJson(String jsonSource) {
    var json = jsonDecode(jsonSource) as Map;
    String msgtype = json['msgtype'];
    WebPushMessageType type;
    switch (msgtype) {
      case 'chat':
        type = WebPushMessageType.chat;
        break;
      case 'mail':
        type = WebPushMessageType.mail;
        break;
      default:
        type = WebPushMessageType.all;
    }
    var subscription = WebPushSubscription()
      ..client = json['client']
      ..device = json['device']
      ..messageType = type
      ..resource = WebPushResource();
    var resourceJson = json['resource'];
    subscription.resource.endpoint = resourceJson['endpoint'];
    subscription.resource.keys = WebPushKey();
    var keyJson = resourceJson['keys'];
    subscription.resource.keys.p256dh = keyJson['p256dh'];
    subscription.resource.keys.auth = keyJson['keys'];
    return subscription;
  }

  String toJson() {
    var msgtype = messageType == WebPushMessageType.chat
        ? 'chat'
        : messageType == WebPushMessageType.mail ? 'mail' : 'all';
    var endpoint = resource?.endpoint;
    var p256dh = resource?.keys?.p256dh;
    var auth = resource?.keys?.auth;
    return '{"client": "$client", "device": "$device", "msgtype": "$msgtype", '
        '"resource": { "endpoint": "$endpoint", '
        '"keys": { "p256dh": "$p256dh", "auth": "$auth"}'
        '}}';
  }
}

class WebPushResource {
  String endpoint;
  WebPushKey keys;
}

class WebPushKey {
  String p256dh;
  String auth;

  WebPushKey();
  WebPushKey.withValues(this.p256dh, this.auth);
}
