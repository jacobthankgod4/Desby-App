import 'package:equatable/equatable.dart';

enum FileType {
  image,
  video,
  pdf,
  other
}

class AppFile extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? localPath;
  final FileType type;
  final int size; // in bytes
  final DateTime uploadedAt;

  const AppFile({
    required this.id,
    required this.name,
    required this.url,
    this.localPath,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [id, name, url, localPath, type, size, uploadedAt];

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
