import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../lib/flutter_multiple_downloder.dart';

void main() {
  test('future download', () async {
    Downloader dl = new Downloader(
        "http://app01.78x56.com/Xii_2021-03-13%2010%EF%BC%9A41.ipa",
        p: 7);
    await dl.download(onPercentage: (done, total) => {print("$done/$total")});
  });
  test('streamd download', () async {
    Downloader dl = new Downloader(
        "http://app01.78x56.com/Xii_2021-03-13%2010%EF%BC%9A41.ipa",
        p: 11);
    final st = await dl.downStream();
    print("test returned");
    final StreamSubscription<ProcessState> sub = st.listen((event) {
      print("${event.successCount}/${event.chunks.length}");
    });
    await sub.asFuture();
    sub.cancel();
    final data = dl.state.asList();
    print('file download success length:${data.length}');
  });
}
