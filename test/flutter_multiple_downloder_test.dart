import 'package:flutter_test/flutter_test.dart';

import '../lib/flutter_multiple_downloder.dart';

void main() {
  test('future download', () async {
    Downloader dl = new Downloader(
        "https://cologfilestorage.s3.amazonaws.com/log_file/03be2d5d01ae0e126dfe05207b83526e44c90adedddcb032869fd25db2f396c981_16723610-8c53-11eb-a98f-fd758ba359c3.mp4",
        p: 7);
    await dl.download(onPercentage: (done, total) => {print("$done/$total")});
    final data = dl.state.asList();
    expect(data.length, dl.state.fileSize);
  });
  test('streamd download', () async {
    Downloader dl = new Downloader(
        "http://app01.78x56.com/Xii_2021-03-13%2010%EF%BC%9A41.ipa",
        p: 11);
    final st = await dl.downStream();
    print("test returned");
    await st.forEach((state) {
      print("${state.successCount}/${state.chunks.length}");
    });
    final data = dl.state.asList();
    print('file download success length:${data.length}');
  });
}
