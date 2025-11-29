import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'liked_products_screen.dart';
import 'product_card.dart';
import 'mock_data.dart';

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
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredProducts = [];
  String _selectedCategory = "All Product";


  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(allMockProducts);
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    List<Map<String, dynamic>> tempProducts = List.from(allMockProducts);
    final query = _searchController.text.toLowerCase();

    if (_selectedCategory != "All Product") {
      tempProducts = tempProducts.where((p) => p['category'] == _selectedCategory).toList();
    }

    if (query.isNotEmpty) {
      tempProducts = tempProducts.where((product) {
        final productName = product['name']!.toLowerCase();
        return productName.contains(query);
      }).toList();
    }

    setState(() {
      _filteredProducts = tempProducts;
    });
  }

  void _updateCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kVeryLightBlue,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: kDarkBlue, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Search product name...",
                        hintStyle: TextStyle(color: kDarkBlue.withOpacity(0.7), fontSize: 16),
                        filled: true,
                        fillColor: kLightBlue.withOpacity(0.6),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 20.0, right: 12.0),
                          child: Icon(Icons.search, color: kDarkBlue.withOpacity(0.8), size: 24),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LikedProductsScreen()),
                      );
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kLightBlue.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite, color: kPrimaryBlue.withOpacity(0.9), size: 24),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const DiscountBannerSection(),
                    CategoryAndProductSection(
                      products: _filteredProducts,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: _updateCategory,
                    ),
                    const SizedBox(height: 20),
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
    {"title": "50% OFF", "subtitle": "Metal Chess Sets", "imageUrl": "assets/images/product1.png"},
    {"title": "NEW ARRIVAL", "subtitle": "Glass Chess Sets", "imageUrl": "assets/images/product3.png"},
  ];

  static const int _initialPage = 10000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 1.0,
      initialPage: _initialPage,
    );
    _currentPage = _initialPage;
    if (_bannerItems.length > 1) _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.animateToPage(
        _currentPage + 1,
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
    if (_bannerItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 5.0, bottom: 24.0),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) {
                final int actualIndex = index % _bannerItems.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildBannerCard(banner: _bannerItems[actualIndex]),
                );
              },
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
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(banner['title']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(banner['subtitle']!, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(banner['imageUrl']!, fit: BoxFit.cover, height: double.infinity,
                errorBuilder: (c, e, s) => Container(color: kLightBlue.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required int index}) {
    bool isActive = (_currentPage % _bannerItems.length) == index;
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


class CategoryAndProductSection extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryAndProductSection({
    super.key,
    required this.products,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  Widget _buildFilterButton(String title) {
    bool isActive = selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () => onCategorySelected(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? kPrimaryBlue : kVeryLightBlue,
          foregroundColor: isActive ? kVeryLightBlue : kPrimaryBlue,
          elevation: isActive ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isActive ? BorderSide.none : const BorderSide(color: kPrimaryBlue, width: 1.5),
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
          const Text("Category", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue)),
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.72,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          ),
        ],
      ),
    );
  }
}