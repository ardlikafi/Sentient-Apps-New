import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class ImageHelper {
  static const String defaultAvatar = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';

  static ImageProvider getImageProvider(String? url, {String? fallbackUrl}) {
    final fallback = fallbackUrl ?? defaultAvatar;
    if (url == null || url.trim().isEmpty) {
      return NetworkImage(fallback);
    }
    
    final trimmed = url.trim();
    if (trimmed.startsWith('data:image')) {
      try {
        final base64String = trimmed.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        print('Error decoding Base64 image: $e');
        return NetworkImage(fallback);
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    } else {
      // Local File
      try {
        final file = File(trimmed);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
      return NetworkImage(fallback);
    }
  }
}
