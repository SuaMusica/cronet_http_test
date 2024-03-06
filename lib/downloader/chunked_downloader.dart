import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;

/// Progress Callback
/// [progress] is the current progress in bytes
/// [total] is the total size of the file in bytes
typedef ProgressCallback = void Function(int progress, int? total);

/// On Done Callback
/// [file] is the downloaded file
typedef OnDoneCallback = void Function(File file);

/// On Error Callback
/// [error] is the error that occured
typedef OnErrorCallback = void Function(dynamic error);

/// Custom Downloader with ChunkSize
///
/// [chunkSize] is the size of each chunk in bytes
///
/// [onProgress] is the callback function that will be called when the download is in progress
///
/// [onDone] is the callback function that will be called when the download is done
///
/// [onError] is the callback function that will be called when the download is failed
///
/// [onCancel] is the callback function that will be called when the download is canceled
///
class ChunkedDownloader {
  const ChunkedDownloader({
    required this.url,
    required this.saveFilePath,
    required this.ua,
    this.headers,
    this.onProgress,
    this.onDone,
    this.onError,
    this.onCancel,
    this.reader,
    this.speed = 0,
  });
  final String url, ua;
  final String saveFilePath;
  final ProgressCallback? onProgress;
  final OnDoneCallback? onDone;
  final OnErrorCallback? onError;
  final Function()? onCancel;
  final ChunkedStreamReader<int>? reader;
  final Map<String, String>? headers;
  final double speed;
  http.Client httpClient() {
    if (Platform.isAndroid) {
      final engine = CronetEngine.build(
        cacheMode: CacheMode.memory,
        userAgent: ua,
      );
      return CronetClient.fromCronetEngine(engine, closeEngine: true);
    }
    if (Platform.isIOS || Platform.isMacOS) {
      final config = URLSessionConfiguration.ephemeralSessionConfiguration();
      return CupertinoClient.fromSessionConfiguration(config);
    }
    return http.Client();
  }

  /// Start the download
  /// @result {Future<ChunkedDownloader>} the current instance of the downloader
  Future<void> start() async {
    final request = http.Request('GET', Uri.parse(url))
      ..headers.addAll(headers ?? {});
    final client = httpClient();
    final response = await client.send(request);
    final file = File('$saveFilePath.tmp');
    await download(file, response);
    client.close();
  }

  Future<void> download(
    File file,
    http.StreamedResponse response,
  ) async {
    IOSink? sink;
    try {
      sink = file.openWrite();
      if (onProgress == null) {
        await sink.addStream(response.stream);
      } else {
        var bytes = 0;
        await sink.addStream(
          response.stream.map((e) {
            bytes += e.length;
            onProgress?.call(bytes, response.contentLength);
            return e;
          }),
        );
      }

      await file.rename(saveFilePath);
      onDone?.call(file);
    } catch (e) {
      onError?.call(e);
    } finally {
      await sink?.flush();
      await sink?.close();
    }
  }
}
