import 'dart:io';

import 'package:flutter/material.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
  }) : assert(imagePaths.length > 0, 'imagePaths bo\'sh bo\'lmasligi kerak');

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.imagePaths.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemCount: widget.imagePaths.length,
        itemBuilder: (context, index) {
          final path = widget.imagePaths[index];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: (() {
                final isNetwork = path.startsWith('http') || path.startsWith('https');
                if (isNetwork) {
                  return Image.network(
                    path,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'Rasmni yuklashda xatolik',
                        style: TextStyle(color: Colors.white),
                      );
                    },
                  );
                } else {
                  final file = path.startsWith('file://') 
                      ? File.fromUri(Uri.parse(path))
                      : File(path);
                  return Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'Rasmni yuklashda xatolik',
                        style: TextStyle(color: Colors.white),
                      );
                    },
                  );
                }
              })(),
            ),
          );
        },
      ),
    );
  }
}
