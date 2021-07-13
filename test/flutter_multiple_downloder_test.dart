import 'package:flutter_multiple_downloader/flutter_multiple_downloder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('future download', () async {
    Downloader dl = new Downloader(
        "http://app01.78x56.com/Xii_2021-03-13%2010%EF%BC%9A41.ipa",
        p: 3);
    await dl.download(onPercentage: (done, total) => {print("$done/$total")});
    if (dl.noError) {
      final data = dl.state.asList();
      expect(data.length, dl.state.fileSize);
    }
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
    if (dl.noError) {
      final data = dl.state.asList();
      print('file download success length:${data.length}');
    }
  });
}
