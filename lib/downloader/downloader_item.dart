import 'package:equatable/equatable.dart';

class DownloaderItem extends Equatable {
  const DownloaderItem({
    required this.url,
    required this.fileName,
    this.pathToSave,
    required this.id,
  });

  factory DownloaderItem.fromMap(Map<String, dynamic> map) => DownloaderItem(
        url: map['url'] as String,
        fileName: map['fileName'] as String,
        pathToSave: map['pathToSave'] as String?,
        id: map['id'] as int,
      );

  final String url, fileName;
  final String? pathToSave;
  final int id;
  @override
  String toString() =>
      'DownloaderItem(url: $url, fileName: $fileName, pathToSave: $pathToSave, id: $id)';

  Map<String, dynamic> toMap() => {
        'url': url,
        'fileName': fileName,
        'pathToSave': pathToSave,
        'id': id,
      };

  @override
  List<Object?> get props => [url, fileName, pathToSave, id];
}
