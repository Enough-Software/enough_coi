import 'dart:async';
import 'dart:convert';
import 'dart:io';

class HttpClientHelper {
  static Future<SimpleHttpResponse> httpGet(String url,
      {int validStatusCode = -1}) async {
    var client = HttpClient();
    try {
      var request = await client.getUrl(Uri.parse(url));
      var response = await request.close();
      if (validStatusCode != -1 && response.statusCode != validStatusCode) {
        return SimpleHttpResponse(response.statusCode, null);
      }
      var responseBody = await httpReadResponse(response);
      return SimpleHttpResponse(response.statusCode, responseBody);
    } catch (e) {
      stderr.writeln('Unabkle to GET $url: $e');
    }
    return null;
  }

  static Future<String> httpReadResponse(HttpClientResponse response) {
    var completer = Completer<String>();
    String contents;
    response.transform(utf8.decoder).listen((data) {
      contents = data;
    }, onDone: () => completer.complete(contents));
    return completer.future;
  }
}

class SimpleHttpResponse {
  int statusCode;
  String content;
  SimpleHttpResponse(this.statusCode, this.content);
}
