import 'package:flutter/material.dart';
import '../../../../core/network/app_file.dart';

class MediaViewerPage extends StatelessWidget {
  final AppFile file;

  const MediaViewerPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(file.name, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.download_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: file.id,
            child: Image.asset(
              file.url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
