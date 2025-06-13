import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'product_detail_screen.dart';

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
  // =======================================================================
  // PERUBAHAN 1: State "diangkat" dari CategoryAndProductSection ke sini
  // =======================================================================
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredProducts = [];
  String _selectedCategory = "All Product";

  // Data master produk sekarang ada di sini
  final List<Map<String, dynamic>> _allProducts = [
    {
      "id": "p1",
      "imageUrl": "assets/images/product1.png",
      "name": "Beautiful Metal Chess Set",
      "subtitle": "Chess Board",
      "price": 99999,
      "category": "Chess",
      "description":
          "Rasakan nuansa modern dan premium dengan set catur logam ini. Dibuat dengan presisi tinggi, setiap bidak memiliki bobot yang mantap dan detail yang tajam. Sempurna untuk permainan kompetitif maupun sebagai pajangan yang elegan di ruang kerja Anda.",
    },
    {
      "id": "p2",
      "imageUrl": "assets/images/product2.png",
      "name": "Beautiful Handcrafted Wooden Chess Set",
      "subtitle": "Chess Board",
      "price": 149999,
      "category": "Chess",
      "description":
          "Kembali ke akar klasik dengan set catur kayu buatan tangan ini. Setiap bidak diukir dengan teliti dari kayu Sheesham dan Boxwood, memberikan sentuhan hangat dan otentik. Papan catur yang kokoh melengkapi set yang abadi ini.",
    },
    {
      "id": "p3",
      "imageUrl": "assets/images/product3.png",
      "name": "Elegant Glass Chess Set",
      "subtitle": "Chess Board",
      "price": 199999,
      "category": "Chess",
      "description":
          "Lebih dari sekadar permainan, set catur kaca ini adalah sebuah karya seni. Desainnya yang transparan dan minimalis menciptakan tampilan yang menakjubkan di atas meja apa pun. Bidak yang bening dan buram memberikan kontras visual yang indah.",
    },
    {
      "id": "p4",
      "imageUrl": "assets/images/product4.png",
      "name": "Luxurious Marble Chess Set",
      "subtitle": "Chess Board",
      "price": 129999,
      "category": "Chess",
      "description":
          "Tingkatkan pengalaman bermain Anda dengan kemewahan set catur marmer. Setiap bidak dipoles dari batu marmer asli, memberikan bobot dan nuansa yang tak tertandingi. Pola alami batu membuat setiap set menjadi unik.",
    },
    {
      "id": "p5",
      "imageUrl": "assets/images/product5.png",
      "name": "Chess Clock Digital Timer",
      "subtitle": "Chess Items",
      "price": 250000,
      "category": "Items",
      "description":
          "Jam catur digital yang andal untuk pemain serius. Dilengkapi dengan mode bonus dan delay, jam ini memenuhi standar turnamen FIDE. Mudah dioperasikan, dengan layar besar yang jelas dan tombol yang responsif untuk permainan cepat.",
    },
    {
      "id": "p6",
      "imageUrl": "assets/images/product6.png",
      "name": "Roll-Up Chess Board",
      "subtitle": "Chess Items",
      "price": 150000,
      "category": "Items",
      "description":
          "Bawa permainan catur ke mana saja dengan papan catur gulung ini. Terbuat dari vinyl atau silikon berkualitas tinggi yang tahan lama dan mudah dibersihkan. Ringan dan portabel, ideal untuk klub catur, turnamen, atau bermain di taman.",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Awalnya, tampilkan semua produk
    _filteredProducts = List.from(_allProducts);
    // Tambahkan listener ke search controller untuk memanggil fungsi filter setiap kali teks berubah
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  // =======================================================================
  // PERUBAHAN 2: Fungsi filter utama yang menggabungkan pencarian dan kategori
  // =======================================================================
  void _filterProducts() {
    List<Map<String, dynamic>> tempProducts = List.from(_allProducts);
    final query = _searchController.text.toLowerCase();

    // 1. Filter berdasarkan kategori yang dipilih
    if (_selectedCategory != "All Product") {
      tempProducts =
          tempProducts
              .where((p) => p['category'] == _selectedCategory)
              .toList();
    }

    // 2. Filter berdasarkan query pencarian dari hasil filter kategori
    if (query.isNotEmpty) {
      tempProducts =
          tempProducts.where((product) {
            final productName = product['name']!.toLowerCase();
            return productName.contains(query);
          }).toList();
    }

    // Update UI dengan produk yang sudah difilter
    setState(() {
      _filteredProducts = tempProducts;
    });
  }

  // Fungsi untuk mengubah kategori dan memanggil filter ulang
  void _updateCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            // =======================================================================
            // PERUBAHAN 3: Menghapus Stack dan tombol filter
            // =======================================================================
            child: TextField(
              controller:
                  _searchController, // Hubungkan controller ke TextField
              style: const TextStyle(color: kDarkBlue, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Search product name...",
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
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const DiscountBannerSection(),
                  // =======================================================================
                  // PERUBAHAN 4: Mengirim data dan fungsi ke widget anak
                  // =======================================================================
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
    );
  }
}

// =======================================================================
// WIDGET BANNER DISKON (Tidak ada perubahan)
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
      "subtitle": "Metal Chess Sets",
      "imageUrl": "assets/images/product1.png",
    },
    {
      "title": "NEW ARRIVAL",
      "subtitle": "Glass Chess Sets",
      "imageUrl": "assets/images/product3.png",
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
              child: Image.asset(
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
// PERUBAHAN 5: Widget ini sekarang menerima data dari parent-nya
// =======================================================================
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
        // Panggil callback function yang diberikan oleh parent
        onPressed: () => onCategorySelected(title),
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
          // Gunakan data 'products' yang diterima dari parent
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
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

// =======================================================================
// WIDGET KARTU PRODUK (Tidak ada perubahan)
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: widget.product),
          ),
        );
      },
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
                child: Image.asset(
                  widget.product['imageUrl']!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (c, e, s) => Container(
                        color: kLightBlue.withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: kVeryLightBlue.withOpacity(0.7),
                            size: 40,
                          ),
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
