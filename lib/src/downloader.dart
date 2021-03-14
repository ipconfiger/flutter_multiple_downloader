import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class UnsupportedException extends Error {
  @override
  String errMsg() => "Not support range request";
}

class Chunk {
  int partNumber;
  int startOffset;
  int endOffset;
  bool finished;
  List<int> data;
  Chunk(this.partNumber, this.startOffset, this.endOffset) {
    finished = false;
    data = <int>[];
  }
  @override
  String toString() {
    return "n:$partNumber, data:${data.length}";
  }
}

class ProcessState {
  String url;
  int fileSize;
  List<Chunk> chunks;
  int successCount;
  int _chunkSize;
  ProcessState(this.url, {int chunkSize: 0}) {
    _chunkSize = chunkSize;
    fileSize = 0;
    successCount = 0;
  }
  init(int size) {
    fileSize = size;
    chunks = <Chunk>[];
    for (var i = 0; i < 600; i++) {
      final startIdx = i * _chunkSize;
      var endIdx = (i + 1) * _chunkSize;
      if (endIdx > fileSize) {
        endIdx = fileSize;
      }
      this.chunks.add(new Chunk(i + 1, startIdx, endIdx));
      if (endIdx == fileSize) {
        // be sure reach the end of file, quit loop
        break;
      }
    }
  }

  Uint8List asList() {
    final result = <int>[];
    for (var ck in this.chunks) {
      result.addAll(ck.data);
    }
    return Uint8List.fromList(result);
  }

  @override
  String toString() {
    return "url:${this.url}, size:${this.fileSize}, chunks:${this.chunks}";
  }
}

typedef void OnPercentage(int done, int total);

class Downloader {
  ProcessState state;
  HttpClient client;
  int processors;
  StreamController<ProcessState> controller;
  OnPercentage _onPercentage;

  Downloader(String url, {int chunkSize: 501001, int p: 2}) {
    state = ProcessState(url, chunkSize: chunkSize);
    client = new HttpClient();
    processors = p;
  }

  Future<ProcessState> download({OnPercentage onPercentage}) async {
    _onPercentage = onPercentage;
    final req = await client.headUrl(Uri.parse(state.url));
    final resp = await req.close();
    if (resp.headers['accept-ranges'].first != 'bytes') {
      throw UnsupportedException();
    }
    final fileSize = int.parse(resp.headers['content-length'].first);
    this.state.init(fileSize);
    final indexies = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
    final futrues = indexies
        .sublist(0, processors)
        .map((pid) => processor(state, pid, processors));
    await Future.wait(futrues);
    return state;
  }

  Future<Stream<ProcessState>> downStream() async {
    final req = await client.headUrl(Uri.parse(state.url));
    final resp = await req.close();
    if (resp.headers['accept-ranges'].first != 'bytes') {
      throw UnsupportedException();
    }
    final fileSize = int.parse(resp.headers['content-length'].first);
    this.state.init(fileSize);
    controller = new StreamController<ProcessState>();
    final indexies = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
    for (var pid in indexies.sublist(0, processors)) {
      processor(state, pid, processors);
    }
    return controller.stream;
  }

  Future processor(ProcessState state, int pid, int pcount) async {
    for (var chunk in state.chunks) {
      if (chunk.partNumber % pcount == pid) {
        final st = await downChunk(state, chunk.partNumber - 1);
        if (controller != null) {
          controller.add(st);
        }
        if (_onPercentage != null) {
          _onPercentage(st.successCount, st.chunks.length);
        }
      }
    }
    if (state.successCount == state.chunks.length) {
      if (controller != null) {
        //print('close stream');
        await controller.close();
      }
    }
  }

  Future<ProcessState> downChunk(ProcessState state, int idx) async {
    Chunk ck = state.chunks[idx];
    HttpClient c = new HttpClient();
    final req = await c.getUrl(Uri.parse(state.url));
    req.headers.add('Range', "bytes=${ck.startOffset}-${ck.endOffset - 1}");
    //print("bytes=${ck.startOffset}-${ck.endOffset - 1}");
    final resp = await req.close();
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      for (var ls in await resp.toList()) {
        ck.data.addAll(ls);
      }
    }
    //print('chunk data: ${ck.data.length}');
    state.successCount++;
    return state;
  }
}
