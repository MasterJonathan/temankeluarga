// === NEW WIDGET: FULL SCREEN IMAGE VIEWER ===
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:http/http.dart' as http;
import 'package:teman_keluarga/app/theme/app_theme.dart'; // Wajib tambah ini di pubspec.yaml


class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageViewer({required this.imageUrl});

  Future<void> _downloadImage(BuildContext context) async {
    try {
      var response = await http.get(Uri.parse(imageUrl));
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.bodyBytes),
        quality: 100,
        name: "memory_${DateTime.now().millisecondsSinceEpoch}",
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['isSuccess']
                  ? "Gambar tersimpan di Galeri"
                  : "Gagal menyimpan gambar",
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: AppColors.surface),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadImage(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          // Fitur Zoom & Pan bawaan Flutter
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imageUrl, // Tag harus sama dgn di list
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
