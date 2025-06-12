// File: lib/shop_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

// --- Konstanta Warna ---
const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVeryLightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Find Your\nDream Chess",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  style: const TextStyle(color: kDarkBlue, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Search",
                    hintStyle: TextStyle(
                      color: kDarkBlue.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: kLightBlue.withOpacity(0.6),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 12.0),
                      child: Icon(
                        Icons.search,
                        color: kDarkBlue.withOpacity(0.8),
                        size: 24,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: InkWell(
                    onTap: () => print("Filter button tapped!"),
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: const BoxDecoration(
                        color: kLightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tune,
                        color: kDarkBlue.withOpacity(0.9),
                        size: 22.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Konten yang bisa di-scroll
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: const [
                  DiscountBannerSection(),
                  CategoryAndProductSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// WIDGET BANNER DISKON
// =======================================================================
class DiscountBannerSection extends StatefulWidget {
  const DiscountBannerSection({super.key});
  @override
  State<DiscountBannerSection> createState() => _DiscountBannerSectionState();
}

class _DiscountBannerSectionState extends State<DiscountBannerSection> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  final List<Map<String, String>> _bannerItems = [
    {
      "title": "50% OFF",
      "subtitle": "05 - 10 July",
      "imageUrl":
          "https://m.media-amazon.com/images/I/81M7o+-V3CL._AC_SL1500_.jpg",
    },
    {
      "title": "NEW ARRIVAL",
      "subtitle": "Glass Chess Sets",
      "imageUrl":
          "https://m.media-amazon.com/images/I/71v5Xyol6qL._AC_SL1500_.jpg",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    if (_bannerItems.length > 1) _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_pageController.hasClients) return;
      int nextPage = (_currentPage + 1) % _bannerItems.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _bannerItems.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder:
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildBannerCard(banner: _bannerItems[index]),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bannerItems.length,
              (index) => _buildDot(index: index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard({required Map<String, String> banner}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kPrimaryBlue,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner['title']!,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  banner['subtitle']!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                banner['imageUrl']!,
                fit: BoxFit.cover,
                height: double.infinity,
                errorBuilder:
                    (c, e, s) => Container(color: kLightBlue.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required int index}) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? kPrimaryBlue : kLightBlue,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// =======================================================================
// WIDGET KATEGORI DAN PRODUK
// =======================================================================
class CategoryAndProductSection extends StatefulWidget {
  const CategoryAndProductSection({super.key});
  @override
  State<CategoryAndProductSection> createState() =>
      _CategoryAndProductSectionState();
}

class _CategoryAndProductSectionState extends State<CategoryAndProductSection> {
  String _selectedFilter = "All Product";
  List<Map<String, dynamic>> _filteredProducts = [];
  final List<Map<String, dynamic>> _allProducts = [
    {
      "id": "p1",
      "imageUrl":
          "https://m.media-amazon.com/images/I/71zVVEVB5tL._AC_SL1500_.jpg",
      "name": "Beautiful Metal Chess Set",
      "subtitle": "Chess Board",
      "price": 99999,
      "category": "Chess",
    },
    {
      "id": "p2",
      "imageUrl":
          "https://m.media-amazon.com/images/I/81M7o+-V3CL._AC_SL1500_.jpg",
      "name": "Beautiful Handcrafted Wooden Chess Set",
      "subtitle": "Chess Board",
      "price": 149999,
      "category": "Chess",
    },
    {
      "id": "p3",
      "imageUrl":
          "https://m.media-amazon.com/images/I/71v5Xyol6qL._AC_SL1500_.jpg",
      "name": "Elegant Glass Chess Set",
      "subtitle": "Chess Board",
      "price": 199999,
      "category": "Chess",
    },
    {
      "id": "p4",
      "imageUrl":
          "https://m.media-amazon.com/images/I/71UohSAT3DL._AC_SL1500_.jpg",
      "name": "Luxurious Marble Chess Set",
      "subtitle": "Chess Board",
      "price": 129999,
      "category": "Chess",
    },
    {
      "id": "p5",
      "imageUrl":
          "https://m.media-amazon.com/images/I/61O23yq4mDL._AC_SL1000_.jpg",
      "name": "Chess Clock Digital Timer",
      "subtitle": "Chess Items",
      "price": 250000,
      "category": "Items",
    },
    {
      "id": "p6",
      "imageUrl":
          "https://m.media-amazon.com/images/I/71g7g9WnB2L._AC_SL1500_.jpg",
      "name": "Roll-Up Chess Board",
      "subtitle": "Chess Items",
      "price": 150000,
      "category": "Items",
    },
  ];

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == "All Product") {
        _filteredProducts = List.from(_allProducts);
      } else {
        _filteredProducts =
            _allProducts
                .where((p) => p['category'] == _selectedFilter)
                .toList();
      }
    });
  }

  Widget _buildFilterButton(String title) {
    bool isActive = _selectedFilter == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed:
            () => setState(() {
              _selectedFilter = title;
              _applyFilter();
            }),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? kPrimaryBlue : kVeryLightBlue,
          foregroundColor: isActive ? kVeryLightBlue : kPrimaryBlue,
          elevation: isActive ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side:
                isActive
                    ? BorderSide.none
                    : const BorderSide(color: kPrimaryBlue, width: 1.5),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        child: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Category",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kDarkBlue,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton("All Product"),
                _buildFilterButton("Chess"),
                _buildFilterButton("Items"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              return ProductCard(product: _filteredProducts[index]);
            },
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// WIDGET KARTU PRODUK (digabung di sini)
// =======================================================================
class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.decimalPattern('id_ID');

    return GestureDetector(
      onTap: () => print("Product tapped: ${widget.product['name']}"),
      child: Container(
        decoration: BoxDecoration(
          color: kPrimaryBlue,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: kDarkBlue.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
                child: Image.network(
                  widget.product['imageUrl']!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (c, e, s) => Container(
                        color: kLightBlue.withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: kVeryLightBlue.withOpacity(0.7),
                            size: 40,
                          ),
                        ),
                      ),
                  loadingBuilder:
                      (c, child, p) =>
                          p == null
                              ? child
                              : const Center(
                                child: CircularProgressIndicator(
                                  color: kVeryLightBlue,
                                ),
                              ),
                ),
              ),
            ),
            Flexible(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.product['name']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kVeryLightBlue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.product['subtitle'] ?? 'Item',
                          style: TextStyle(
                            fontSize: 11,
                            color: kVeryLightBlue.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Rp. ${formatCurrency.format(widget.product['price'])}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _isLiked = !_isLiked),
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: kVeryLightBlue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color:
                                  _isLiked ? Colors.redAccent : kVeryLightBlue,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
