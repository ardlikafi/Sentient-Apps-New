import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:sentient/features/courses/course_screen.dart';
import 'package:sentient/features/courses/course_detail_screen.dart';
import 'package:sentient/features/shop/shop_screen.dart';
import 'package:sentient/core/services/firebase_service.dart';
import 'package:sentient/features/shop/product_detail_screen.dart';
import 'package:sentient/features/articles/article_detail_screen.dart';
import 'package:sentient/core/services/simulated_order_service.dart';
import 'package:sentient/core/widgets/simulated_order_widgets.dart';
import 'package:sentient/core/widgets/product_card.dart';
import 'package:sentient/features/home/home_shimmer.dart';
import 'home_header.dart';
import 'event_section.dart';
// Definisikan color palette Anda
const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

// Warna untuk gradasi
const Color kGradientStartBlue = Color(0xFF000A26);
const Color kGradientEndBlue = Color(0xFF0A3D91);

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;
  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return HomeContent(onNavigateToTab: onNavigateToTab);
  }
}

class HomeContent extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const HomeContent({super.key, this.onNavigateToTab});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with AutomaticKeepAliveClientMixin<HomeContent> {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _allArticles = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    print("HomeContent initState called");
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    print("Fetching initial data for HomeContent...");
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      await Future.wait([
        _fetchCourseData(),
        _fetchShopData(),
        _fetchArticleData(), // Fetch data artikel
      ]);
      if (mounted) {
        print("Initial data fetch complete.");
        setState(() => _isLoading = false);
      }
    } catch (e, s) {
      print('Error saat fetch data Home: $e\n$s');
      if (mounted) {
        setState(() {
          _errorMsg = 'Terjadi error saat mengambil data Home: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    print("Refreshing HomeContent data...");
    await _fetchInitialData();
  }

  Future<void> _fetchCourseData() async {
    print('Mulai fetch course...');
    try {
      final courses = await FirebaseService.getAllCourses();
      if (mounted) {
        setState(() {
          _allCourses = courses;
        });
      }
    } catch (e) {
      print('Error fetch course: $e');
    }
  }

  Future<void> _fetchShopData() async {
    print('Mulai fetch shop...');
    try {
      final products = await FirebaseService.getAllProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
        });
      }
    } catch (e) {
      print('Error fetch shop: $e');
    }
  }

  Future<void> _fetchArticleData() async {
    print('Mulai fetch article...');
    try {
      final random = Random();
      final articles = await FirebaseService.getAllArticles();
      if (mounted) {
        setState(() {
          _allArticles = List.from(articles)..shuffle(random);
          _allArticles = _allArticles.take(6).toList();
        });
      }
      print('Articles fetched successfully.');
    } catch (e) {
      print('Error fetch article: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: kVeryLightBlue,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child:
              _isLoading
                  ? const HomeShimmer()
                  : (_errorMsg != null)
                  ? SizedBox(
                    height:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        kToolbarHeight,
                    child: Center(
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HomeHeader(),
                        const EventSection(),
                        CoursesSection(
                          allCourses: _allCourses,
                          onNavigateToTab: widget.onNavigateToTab,
                        ),
                        ShopSection(
                          allProducts: _allProducts,
                          onNavigateToTab: widget.onNavigateToTab,
                        ),
                        ArticleSection(allArticles: _allArticles),
                        const SizedBox(height: kToolbarHeight + 4),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}

// CoursesSection Widget (Tombol See All tetap push CourseScreen)
class CoursesSection extends StatefulWidget {
  final List<Map<String, dynamic>> allCourses;
  final Function(int)? onNavigateToTab;
  const CoursesSection({super.key, required this.allCourses, this.onNavigateToTab});
  @override
  State<CoursesSection> createState() => _CoursesSectionState();
}

class _CoursesSectionState extends State<CoursesSection> {
  String _selectedFilter = "All Course";
  List<Map<String, dynamic>> _filteredCourses = [];

  StreamSubscription? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _applyFilter();
    _orderSubscription = SimulatedOrderService.orderStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _applyFilter() {
    setState(() {
      if (widget.allCourses.isEmpty) {
        _filteredCourses = [];
        return;
      }

      List<Map<String, dynamic>> tempCourses;

      if (_selectedFilter == "All Course") {
        tempCourses = List.from(widget.allCourses);
      } else if (_selectedFilter == "Popular" || _selectedFilter == "Populer") {
        tempCourses =
            widget.allCourses
                .where(
                  (course) =>
                      (course['rating'] != null &&
                          (course['rating'] as num) >= 4.5) ||
                      (course['category'] == 'popular'),
                )
                .toList();
      } else if (_selectedFilter == "Free") {
        tempCourses =
            widget.allCourses
                .where((course) => (course['price'] as num? ?? 0) == 0)
                .toList();
      } else if (_selectedFilter == "Premium") {
        tempCourses =
            widget.allCourses
                .where((course) => (course['price'] as num? ?? 0) > 0)
                .toList();
      } else {
        tempCourses = List.from(widget.allCourses);
      }
      _filteredCourses = tempCourses;
    });
  }

  @override
  void didUpdateWidget(covariant CoursesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allCourses != widget.allCourses) {
      _applyFilter();
    }
  }

  Widget _buildFilterButton(String title) {
    bool isActive = _selectedFilter == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedFilter = title;
            _applyFilter();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? kPrimaryBlue : kVeryLightBlue,
          foregroundColor: isActive ? kVeryLightBlue : kPrimaryBlue,
          elevation: isActive ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side:
                isActive
                    ? BorderSide.none
                    : const BorderSide(color: kPrimaryBlue, width: 1.5),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
        child: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Courses",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),
                TextButton(
                  onPressed: widget.onNavigateToTab != null 
                    ? () => widget.onNavigateToTab!(1) 
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CourseScreen(),
                          ),
                        );
                      },
                  child: Text(
                    "See all",
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton("All Course"),
                  _buildFilterButton("Popular"),
                  _buildFilterButton("Free"),
                  _buildFilterButton("Premium"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child:
                _filteredCourses.isEmpty
                    ? Center(
                      child: Text(
                        "No courses found for '$_selectedFilter'",
                        style: TextStyle(color: kDarkBlue.withOpacity(0.7)),
                      ),
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = _filteredCourses[index];
                        return CourseCard(course: course);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class CourseCard extends StatefulWidget {
  final Map<String, dynamic> course;
  const CourseCard({super.key, required this.course});

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  String? _videoId;
  StreamSubscription? _orderSubscription;

  @override
  void initState() {
    super.initState();
    final String? youtubeUrl = widget.course['youtube_url'] as String?;
    if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
      _videoId = extractYoutubeId(youtubeUrl);
    }
    _orderSubscription = SimulatedOrderService.orderStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.course['price'] as num? ?? 0;
    final String? imageUrl = widget.course['imageUrl'] as String?;
    final String? thumbnailUrl =
        _videoId != null ? 'https://img.youtube.com/vi/$_videoId/0.jpg' : null;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isPremium = userProvider.isPremium || SimulatedOrderService.isPremium;

    return GestureDetector(
      onTap: () async {
        if (price > 0 && !isPremium) {
          await PremiumPaywallDialog.show(context);
          if (mounted) setState(() {});
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              course: widget.course,
              videoId: _videoId,
              ),
          ),
        );
        if (mounted) setState(() {});
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: kLightBlue.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              ),
              child: Stack(
                children: [
                  if (thumbnailUrl != null)
                    Image.network(
                      thumbnailUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print(
                          "Error loading YouTube thumbnail, trying asset: $error",
                        );
                        return Image.asset(
                          imageUrl ?? 'assets/images/course1.png',
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print(
                              "Error loading both thumbnail and asset image: $error",
                            );
                            return Container(
                              height: 120,
                              color: kLightBlue.withOpacity(0.3),
                              child: const Center(
                                child: Icon(
                                  Icons.photo_size_select_actual_outlined,
                                  color: kDarkBlue,
                                  size: 30,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loadingBuilder: (c, child, p) {
                        if (p == null) return child;
                        return SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                kPrimaryBlue,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  else if (imageUrl != null && imageUrl.startsWith('assets/'))
                    Image.asset(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading asset image: $error");
                        return Container(
                          height: 120,
                          color: kLightBlue.withOpacity(0.3),
                          child: const Center(
                            child: Icon(
                              Icons.photo_size_select_actual_outlined,
                              color: kDarkBlue,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      height: 120,
                      color: kLightBlue.withOpacity(0.3),
                      child: const Center(
                        child: Icon(
                          Icons.photo_size_select_actual_outlined,
                          color: kDarkBlue,
                          size: 30,
                        ),
                      ),
                    ),

                  if (_videoId != null && (price == 0 || isPremium))
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),

                  // Lock Overlay
                  if (price > 0 && !isPremium)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.55),
                        child: const Center(
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.amber,
                            size: 36,
                          ),
                        ),
                      ),
                    ),

                  // Premium Banner Label
                  if (price > 0 && !isPremium)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.workspace_premium, size: 12, color: kDarkBlue),
                            SizedBox(width: 4),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: kDarkBlue,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.course['title']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kDarkBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    const Spacer(),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (widget.course['category'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.course['category'].toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlue,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: price == 0
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : (isPremium
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : Colors.amber.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            price == 0
                                ? "Free"
                                : (isPremium ? "Unlocked" : "Premium"),
                            style: TextStyle(
                              fontSize: 10,
                              color: price == 0
                                  ? const Color(0xFF059669)
                                  : (isPremium ? const Color(0xFF059669) : const Color(0xFFB45309)),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "${widget.course['rating']} (${widget.course['reviewCount']})",
                          style: TextStyle(
                            fontSize: 12,
                            color: kDarkBlue.withOpacity(0.7),
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

String? extractYoutubeId(String url) {
  if (url.isEmpty) {
    return null;
  }
  final RegExp regExp = RegExp(
    r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|\/v\/|embed\/|v=)([0-9A-Za-z_-]{11}).*',
    caseSensitive: false,
    multiLine: false,
  );
  final match = regExp.firstMatch(url);
  return match?.group(1);
}



class ShopSection extends StatefulWidget {
  final List<Map<String, dynamic>> allProducts;
  final Function(int)? onNavigateToTab;
  const ShopSection({super.key, required this.allProducts, this.onNavigateToTab});
  @override
  State<ShopSection> createState() => _ShopSectionState();
}

class _ShopSectionState extends State<ShopSection> {
  String _selectedFilter = "All Product";
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      if (widget.allProducts.isEmpty) {
        _filteredProducts = [];
        return;
      }
      List<Map<String, dynamic>> tempProducts;

      if (_selectedFilter == "All Product") {
        tempProducts = List.from(widget.allProducts);
      } else if (_selectedFilter == "Chess") {
        tempProducts =
            widget.allProducts
                .where((product) => product['category'] == 'Chess')
                .toList();
      } else if (_selectedFilter == "Items") {
        tempProducts =
            widget.allProducts
                .where((product) => product['category'] == 'Items')
                .toList();
      } else {
        tempProducts = List.from(widget.allProducts);
      }
      _filteredProducts = tempProducts;
    });
  }

  @override
  void didUpdateWidget(covariant ShopSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allProducts != widget.allProducts) {
      _applyFilter();
    }
  }

  Widget _buildFilterButton(String title) {
    bool isActive = _selectedFilter == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedFilter = title;
            _applyFilter();
          });
        },
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
    final displayedProducts = _filteredProducts.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Shop",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),
                TextButton(
                  onPressed: widget.onNavigateToTab != null 
                    ? () => widget.onNavigateToTab!(3) 
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShopScreen(),
                          ),
                        );
                      },
                  child: Text(
                    "See all",
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton("All Product"),
                  _buildFilterButton("Chess"),
                  _buildFilterButton("Items"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child:
                displayedProducts.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          _selectedFilter == "All Product"
                              ? "No products found."
                              : "No products found in category '$_selectedFilter'.",
                          style: TextStyle(color: kDarkBlue.withOpacity(0.7)),
                        ),
                      ),
                    )
                    : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: displayedProducts.length,
                      itemBuilder: (context, index) {
                        final product = displayedProducts[index];
                        return ProductCard(product: product);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}



class ArticleSection extends StatefulWidget {
  final List<Map<String, dynamic>> allArticles;
  const ArticleSection({super.key, required this.allArticles});
  @override
  State<ArticleSection> createState() => _ArticleSectionState();
}

class _ArticleSectionState extends State<ArticleSection> {
  List<Map<String, dynamic>> _displayedArticles = [];
  final Random _random = Random();
  @override
  void initState() {
    super.initState();
    _loadRandomArticles();
  }

  void _loadRandomArticles() {
    if (widget.allArticles.isNotEmpty) {
      final List<Map<String, dynamic>> shuffled = List.from(widget.allArticles)
        ..shuffle(_random);
      setState(() {
        _displayedArticles = shuffled.take(6).toList();
      });
    } else {
      setState(() {
        _displayedArticles = [];
      });
    }
  }

  @override
  void didUpdateWidget(covariant ArticleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allArticles != widget.allArticles) {
      _loadRandomArticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Article",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _displayedArticles.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    "No articles to display.",
                    style: TextStyle(color: kDarkBlue.withOpacity(0.7)),
                  ),
                ),
              )
              : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.65,
                ),
                itemCount: _displayedArticles.length,
                itemBuilder: (context, index) {
                  final article = _displayedArticles[index];
                  // Menggunakan ArticleCard yang onTap-nya diubah
                  return ArticleCard(article: article);
                },
              ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                print("See all articles pressed");
                // Navigasi ke halaman daftar artikel
                // TODO: Implement navigation to a dedicated article list/screen
              },
              child: Text(
                "See all articles",
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ArticleCard Widget (onTap diubah untuk navigasi)
class ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  const ArticleCard({super.key, required this.article});
  @override
  Widget build(BuildContext context) {
    // Ambil imageUrl dari data artikel
    final String? imageUrl = article['imageUrl'] as String?;

    return GestureDetector(
      onTap: () {
        print("Article tapped: ${article['title']}");
        // Navigasi ke ArticleDetailScreen saat card ditekan
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: kLightBlue.withOpacity(0.6),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
                child:
                    // --- Logika pemuatan gambar untuk Article Card ---
                    imageUrl != null && imageUrl.isNotEmpty
                        ? (imageUrl.startsWith(
                              'assets/',
                            ) // Cek jika itu path asset
                            ? Image.asset(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) {
                                print(
                                  "Error loading article asset image: $imageUrl - $e",
                                );
                                return _buildErrorPlaceholder(); // Placeholder jika asset gagal
                              },
                            )
                            : Image.network(
                              // Jika bukan asset, coba network
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) {
                                print(
                                  "Error loading article network image: $imageUrl - $e",
                                );
                                return _buildErrorPlaceholder(); // Placeholder jika network gagal
                              },
                              loadingBuilder: (c, child, p) {
                                if (p == null) return child;
                                return Center(
                                  // Loading indicator
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      kPrimaryBlue,
                                    ),
                                  ),
                                );
                              },
                            ))
                        : _buildErrorPlaceholder(), // Placeholder jika imageUrl null/kosong
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          article['title'] ?? 'No Title',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kDarkBlue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          article['summary'] ?? 'No summary available.',
                          style: TextStyle(
                            fontSize: 11,
                            color: kDarkBlue.withOpacity(0.7),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        article['date'] ?? 'No Date',
                        style: TextStyle(
                          fontSize: 10,
                          color: kDarkBlue.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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

  // Helper method untuk placeholder gambar jika gagal dimuat
  Widget _buildErrorPlaceholder() {
    return Container(
      color: kLightBlue.withOpacity(0.2), // Warna latar belakang placeholder
      child: Center(
        child: Icon(
          Icons.article_outlined, // Ikon placeholder
          color: kDarkBlue.withOpacity(0.4),
          size: 40,
        ),
      ),
    );
  }
}
