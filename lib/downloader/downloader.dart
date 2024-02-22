import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:cronet_test/downloader/chunked_downloader.dart';
import 'package:cronet_test/downloader/download_progress.dart';
import 'package:cronet_test/downloader/downloader_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class Downloader {
  Downloader._();
  static Downloader? _instance;
  static Downloader get instance => _instance ??= Downloader._();

  int downloadingCount = 0;
  int concurrency = 3;
  final downloads = Queue<DownloaderItem>();
  SendPort? _port;
  void registerPort({
    required String portName,
  }) =>
      _port ??= IsolateNameServer.lookupPortByName(portName);

  void setConcurrency(int downloads) => concurrency = downloads;

  void enqueue({
    required DownloaderItem item,
    bool ignoreConcurrency = false,
  }) {
    if (ignoreConcurrency) {
      _download(
        item: item,
        ignoreConcurrency: ignoreConcurrency,
      );
      return;
    }
    if (downloadingCount >= concurrency) {
      downloads.add(item);
    } else {
      downloadingCount++;
      _download(item: item);
    }
  }

  void _takeNext() {
    if (downloads.isNotEmpty) {
      _download(item: downloads.removeFirst());
    } else {
      if (downloadingCount > 0) {
        downloadingCount--;
      }
    }
  }

  void cancelAll() {
    downloads.clear();
    downloadingCount = 0;
  }

  Future<void> _download({
    required DownloaderItem item,
    bool ignoreConcurrency = false,
  }) async {
    try {
      final rootIsolateToken = RootIsolateToken.instance!;
      await Isolate.run(
        () async {
          BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
          await _downloadCore(
            item: item,
            ignoreConcurrency: ignoreConcurrency,
          );
        },
        debugName: item.id.toString(),
      );
    } on Exception catch (e) {
      _port?.send(
        MediaDownloadProgress(
          taskId: item.id,
          status: -1,
        ).toMap(),
      );
      debugPrint('[Downloader] Exception $e');
    } finally {
      if (!ignoreConcurrency) {
        _takeNext();
      }
    }
  }

  Future<void> _downloadCore({
    required DownloaderItem item,
    required bool ignoreConcurrency,
  }) async {
    final saveTo = item.pathToSave != null && (Platform.isIOS)
        ? '${item.pathToSave}/${item.fileName}'
        : '${(await getTemporaryDirectory()).path}/${item.fileName}';
    debugPrint(
      '[Downloader] saveTo: $saveTo, pathToSave: ${item.pathToSave} filename: ${item.fileName}',
    );
    const userAgent =
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36';
    await ChunkedDownloader(
      url: item.url,
      ua: userAgent,
      headers: {
        HttpHeaders.userAgentHeader: userAgent,
      },
      onError: (error) {
        debugPrint('[Downloader] onError: $error');
      },
      onDone: (file) {
        debugPrint('[Downloader] onDone: ${item.fileName} ${item.id}');
        _port?.send(
          MediaDownloadProgress(
            taskId: item.id,
            progress: 100,
            status: 3,
          ).toMap(),
        );
      },
      saveFilePath: saveTo,
    ).start();
  }
}
