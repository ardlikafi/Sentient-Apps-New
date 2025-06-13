// File: lib/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLiked = false;
  String? _selectedSize;
  final List<String> _sizes = ['25 cm', '50 cm', '75 cm'];

  Future<void> _launchTokopediaUrl() async {
    final Uri url = Uri.parse(
      'https://www.tokopedia.com/uncletoys88/product?utm_source=salinlink&utm_medium=share&utm_campaign=Shop-141030092-265491-Semua',
    );
    try {
      await launchUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Could not launch URL'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF000A26),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Product Detail',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // =======================================================================
              // PERUBAHAN DI SINI: Mengganti Image.network dengan Image.asset
              // =======================================================================
              child: Image.asset(
                widget.product['imageUrl']!,
                height: screenHeight * 0.45,
                fit: BoxFit.cover,
                errorBuilder:
                    (c, e, s) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50),
                      ),
                    ),
              ),
            ),
            Positioned.fill(
              top: screenHeight * 0.35,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0F9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product['subtitle']!,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.product['name']!,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                    color: Color(0xFF0A1128),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLiked = !_isLiked;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 16),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    _isLiked ? Colors.redAccent : Colors.grey,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.product['description']!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Size",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1128),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children:
                            _sizes.map((size) => _buildSizeChip(size)).toList(),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003CC5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          onPressed: () {
                            if (_selectedSize == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Silakan pilih ukuran terlebih dahulu.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            _launchTokopediaUrl();
                          },
                          child: const Text(
                            'Buy Now',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeChip(String size) {
    bool isSelected = _selectedSize == size;
    const Color kSelectedColor = Color(0xFF0F52BA);
    const Color kDefaultColor = Color(0xFFD6E5F2);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSize = size;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kSelectedColor : kDefaultColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          size,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isSelected ? kDefaultColor : kSelectedColor,
          ),
        ),
      ),
    );
  }
}
