import 'package:equatable/equatable.dart';

class MediaDownloadProgress extends Equatable {
  const MediaDownloadProgress({
    this.taskId = -1,
    this.progress = 0,
    this.status = -1,
    this.localPath,
  });

  factory MediaDownloadProgress.fromMap(Map<String, dynamic> map) =>
      MediaDownloadProgress(
        taskId: map['taskId'] as int,
        progress: map['progress'] as int,
        status: map['status'] as int,
        localPath: map['localPath'] as String?,
      );

  final int taskId;
  final String? localPath;
  final int progress, status;

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'localPath': localPath,
      'progress': progress,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        taskId,
        progress,
        status,
      ];

  @override
  String toString() =>
      'MediaDownloadProgress(taskId: $taskId, status: $status progress:$progress, localPath: $localPath)';
}
