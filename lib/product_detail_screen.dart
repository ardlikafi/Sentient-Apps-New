import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'liked_products_provider.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

const Color kAppBarGradientStart = Color(0xFF000A26);
const Color kAppBarGradientMid = Color(0xFF001759);
const Color kAppBarGradientEnd = Color(0xFF00207B);

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final double imageHeight = 300.0;
  final double contentOverlap = 30.0;

  String? _selectedSize;
  final List<String> _sizes = ['25 cm', '50 cm', '75 cm'];

  Future<void> _launchTokopediaUrl() async {
    final Uri url = Uri.parse(
      'https://www.tokopedia.com/uncletoys88/product?utm_source=salinlink&utm_medium=share&utm_campaign=Shop-141030092-265491-Semua',
    );
    try {
      await launchUrl(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not launch URL'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final likedProvider = Provider.of<LikedProductsProvider>(context);
    final bool isLiked = likedProvider.isLiked(widget.product['id']!);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: kPrimaryBlue.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          "Product Detail",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: kPrimaryBlue.withOpacity(0.5),
              child: IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.redAccent : Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  likedProvider.toggleLike(widget.product['id']!);
                },
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kAppBarGradientStart,
                kAppBarGradientMid,
                kAppBarGradientEnd,
              ],
              stops: [0.0, 0.66, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      backgroundColor: kDarkBlue,
      body: Stack(
        children: [
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: Image.asset(
              widget.product['imageUrl']!,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: kDarkBlue.withOpacity(0.5)),
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        SizedBox(height: imageHeight - contentOverlap),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: kVeryLightBlue,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30.0),
                                topRight: Radius.circular(30.0),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: _buildProductContent(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product['subtitle']!,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: kDarkBlue.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product['name']!,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: kDarkBlue,
          ),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kDarkBlue,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _sizes.map((size) => _buildSizeChip(size)).toList(),
          ),
        ),
        const SizedBox(height: 32),
        _buildBuyNowButton(),
      ],
    );
  }

  Widget _buildBuyNowButton() {
    final formatCurrency = NumberFormat.decimalPattern('id_ID');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Price",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Rp. ${formatCurrency.format(widget.product['price'])}",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
              ),
            ),
          ],
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
          ),
          onPressed: () {
            if (_selectedSize == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Silakan pilih ukuran terlebih dahulu.'),
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
      ],
    );
  }

  Widget _buildSizeChip(String size) {
    bool isSelected = _selectedSize == size;
    const Color kSelectedColor = kPrimaryBlue;
    const Color kDefaultColor = Colors.white;

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
            border: Border.all(
              color: isSelected ? kSelectedColor : kLightBlue,
              width: 1.5,
            )),
        child: Text(
          size,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isSelected ? Colors.white : kPrimaryBlue,
          ),
        ),
      ),
    );
  }
}