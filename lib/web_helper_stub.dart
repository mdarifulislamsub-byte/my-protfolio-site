// web_helper_stub.dart
library html;

import 'dart:typed_data';

class Blob {
  // কনস্ট্রাক্টর
  Blob(List<dynamic> blobs, String type);
}

class UrlClass {
  // মেথডগুলো static হতে হবে কারণ main.dart-এ html.Url.createObjectUrlFromBlob() এভাবে ডাকা হয়েছে
  String createObjectUrlFromBlob(dynamic blob) => '';
  void revokeObjectUrl(String url) {}
}

// গ্লোবাল অবজেক্ট হিসেবে এক্সপোজ করা, যাতে html.Url হিসেবে অ্যাক্সেস করা যায়
final UrlClass Url = UrlClass();

class AnchorElement {
  String? href;
  AnchorElement({this.href});
  void setAttribute(String name, String value) {}
  void click() {}
}

class Window {
  void open(String url, String target) {}
}

final Window window = Window();

class FileUploadInputElement {
  String? accept;
  void click() {}

  // onChange স্ট্রীম যেন ইভেন্ট টাইপ ম্যাচ করে
  Stream<dynamic> get onChange => const Stream.empty();
  List<dynamic>? get files => null;
}

class FileReader {
  void readAsArrayBuffer(dynamic blob) {}
  Stream<dynamic> get onLoadEnd => const Stream.empty();
  dynamic get result => null;
}