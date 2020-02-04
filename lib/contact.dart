import 'dart:typed_data';

class Contact {
  String id;
  String email; //TODO several emails should be possible
  String name;
  String key;
  Uint8List avatar;
  bool markedAsDeleted;
  //TODO add all vcard entries
}