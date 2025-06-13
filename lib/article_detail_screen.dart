// lib/article_detail_screen.dart

import 'package:flutter/material.dart';

// Definisikan atau impor warna yang dibutuhkan
const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  // HAPUS kata kunci const di sini
  ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final String title = article['title'] ?? 'No Title';
    final String category = article['category'] ?? 'Education';
    final String date = article['date'] ?? 'No Date';
    final String author =
        article['author'] ?? article['source'] ?? 'Unknown Author';
    final String imageUrl =
        article['imageUrl'] ?? ''; // Gunakan string kosong jika null
    final String summary = article['summary'] ?? 'No summary available.';

    return Scaffold(
      backgroundColor: kVeryLightBlue,
      appBar: AppBar(
        backgroundColor: kVeryLightBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDarkBlue),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          // HAPUS const di sini
          "Article",
          style: TextStyle(
            // HAPUS const di sini
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kDarkBlue.withOpacity(0.8),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.toUpperCase(),
              style: TextStyle(
                // HAPUS const di sini
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kPrimaryBlue.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                // Boleh const jika isinya const
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$date by $author',
              style: TextStyle(
                // HAPUS const di sini
                fontSize: 14,
                color: kDarkBlue.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            // Gambar Artikel: Logika untuk asset atau network
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child:
                    imageUrl.startsWith('assets/') // Cek jika path asset
                        ? Image.asset(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print(
                              "Error loading article asset image in detail: $imageUrl - $error",
                            );
                            return _buildErrorPlaceholder(); // Placeholder jika asset gagal
                          },
                        )
                        : Image.network(
                          // Jika bukan asset, coba network
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print(
                              "Error loading article network image in detail: $imageUrl - $error",
                            );
                            return _buildErrorPlaceholder(); // Placeholder jika network gagal
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              // Loading indicator
                              height: 200, // Samakan tinggi dengan placeholder
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    kPrimaryBlue,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              )
            else // Tampilkan placeholder jika imageUrl kosong
              _buildErrorPlaceholder(),

            const SizedBox(height: 16),
            Text(
              summary,
              style: TextStyle(
                // HAPUS const di sini
                fontSize: 16,
                color: kDarkBlue.withOpacity(0.9),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper method untuk placeholder gambar di detail
  Widget _buildErrorPlaceholder() {
    return Container(
      // HAPUS const di sini
      height: 200, // Ukuran placeholder
      color: kLightBlue.withOpacity(0.3), // Warna placeholder
      child: Center(
        // HAPUS const di sini
        child: Icon(
          Icons.photo_size_select_actual_outlined,
          color: kDarkBlue,
          size: 50,
        ), // Ikon placeholder
      ),
    );
  }
}
