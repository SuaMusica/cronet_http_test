import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:cronet_test/downloader/download_progress.dart';
import 'package:cronet_test/downloader/downloader.dart';
import 'package:cronet_test/downloader/downloader_item.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

const String _downloaderPortName = 'downloader_send_port';

final _port = ReceivePort();
final progressDispatcher = StreamController<MediaDownloadProgress>.broadcast();

bool isRegistered = false;

Future<void> setupDownloadManager() async {
  if (isRegistered) {
    debugPrint('Download Manager already registered');
    return;
  }
  IsolateNameServer.removePortNameMapping(_downloaderPortName);
  isRegistered = IsolateNameServer.registerPortWithName(
    _port.sendPort,
    _downloaderPortName,
  );
  _port.listen(
    (dynamic data) {
      try {
        final p = MediaDownloadProgress.fromMap(data as Map<String, dynamic>);
        progressDispatcher.add(p);
      } catch (e) {
        debugPrint('No Progress for you $data exception: $e');
      }
    },
  );
  Downloader.instance.registerPort(portName: _downloaderPortName);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final items = <DownloaderItem>[];
  final progress = <int>[];
  late StreamSubscription<MediaDownloadProgress> _subscription;
  @override
  void initState() {
    super.initState();
    setupDownloadManager();
    setState(() {
      for (var i = 0; i < 1000; i++) {
        final randomInt = Random.secure().nextInt(9999999);
        items.add(
          DownloaderItem(
            url: 'https://picsum.photos/200/300?$randomInt',
            fileName: 'test${i}_$randomInt.jpg',
            id: i,
          ),
        );
        progress.add(0);
      }
    });
    _subscription = progressDispatcher.stream.listen((e) {
      setState(() {
        progress[e.taskId] = e.progress;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return items.isEmpty
        ? const SizedBox()
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.title),
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.download),
              label: const Text('Download All'),
              onPressed: () {
                for (final item in items) {
                  Downloader.instance.enqueue(item: item);
                }
              },
            ),
            body: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final completed = progress[index] >= 100;
                return ListTile(
                  tileColor: switch (completed) {
                    true => Colors.green,
                    _ => Colors.white,
                  },
                  title: Text('#${item.id} - ${item.fileName}'),
                  onTap: completed
                      ? null
                      : () {
                          Downloader.instance.enqueue(item: item);
                        },
                );
              },
            ),
          );
  }
}
