import 'package:flutter/material.dart';
import 'dart:math'; // Untuk Random().nextInt() pada shuffle sederhana
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:sentient/course_screen.dart';
import 'package:sentient/shop_screen.dart';
import 'package:sentient/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:io';

// Definisikan color palette Anda
const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

// Warna untuk gradasi
const Color kGradientStartBlue = Color(0xFF000A26);
const Color kGradientEndBlue = Color(0xFF0A3D91);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pageOptions = <Widget>[
    HomeContent(),
    CourseScreen(),
    ShopScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pageOptions),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: kDarkBlue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Course',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined),
                activeIcon: Icon(Icons.store),
                label: 'Shop',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: kVeryLightBlue,
            unselectedItemColor: kLightBlue.withOpacity(0.7),
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            onTap: _onItemTapped,
            elevation: 0,
            iconSize: 26,
            selectedFontSize: 13,
            unselectedFontSize: 12,
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Map<String, dynamic>? _homeHeaderData;
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _allArticles = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Jika kembali dari profile, refresh data
    _fetchHomeHeaderData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      await Future.wait([
        _fetchHomeHeaderData(),
        _fetchCourseData(),
        _fetchShopData(),
        _fetchArticleData(),
      ]);
    } catch (e, s) {
      print('Error saat fetch data Home: $e\n$s');
      if (mounted) {
        setState(
          () => _errorMsg = 'Terjadi error saat mengambil data Home: $e',
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refreshData() async {
    await _fetchInitialData();
  }

  Future<void> _fetchHomeHeaderData() async {
    print('Mulai fetch profile...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) {
          setState(
            () => _errorMsg = 'Token tidak ditemukan. Silakan login ulang.',
          );
        }
        print('Token tidak ditemukan.');
        return;
      }
      final result = await ApiService.getProfile(token);
      if (mounted) {
        if (result != null) {
          setState(() => _homeHeaderData = result);
          print('Profile berhasil diambil.');
        } else {
          setState(() => _errorMsg = 'Gagal mengambil data profile.');
          print('Gagal mengambil data profile.');
        }
      }
    } catch (e) {
      print('Error fetch profile: $e');
      if (mounted) setState(() => _errorMsg = 'Error fetch profile: $e');
    }
  }

  Future<void> _fetchCourseData() async {
    print('Mulai fetch course...');
    try {
      await Future.delayed(Duration(milliseconds: 300));
      _allCourses = [
        {
          "id": "c1",
          "imageUrl": "assets/images/course1.png",
          "title": "Mastering Chess Fundamentals",
          "price": 100000,
          "rating": 4.5,
          "reviewCount": 50,
          "category": "popular",
          "youtube_url":
              "https://www.youtube.com/watch?v=OCSbzArwB10", // Chess for Beginners
          "description":
              "Learn the complete basics of chess with this comprehensive guide. Perfect for beginners who want to start their chess journey.",
        },
        {
          "id": "c2",
          "imageUrl": "assets/images/course2.png",
          "title": "Tactical Patterns & Strategy",
          "price": 270000,
          "rating": 4.8,
          "reviewCount": 75,
          "category": "popular",
          "youtube_url":
              "https://www.youtube.com/watch?v=NAIQyoPcjNM", // Chess Tactics for Intermediate Players
          "description":
              "Master essential tactical patterns and strategic concepts to improve your game.",
        },
        {
          "id": "c3",
          "imageUrl": "assets/images/course3.png",
          "title": "Opening Repertoire for All Levels",
          "price": 400000,
          "rating": 4.2,
          "reviewCount": 30,
          "category": "all",
          "youtube_url":
              "https://www.youtube.com/watch?v=W1gWHIpQNVU", // Top 5 Chess Openings
          "description":
              "Build a strong opening repertoire with proven strategies for all levels.",
        },
        {
          "id": "c4",
          "imageUrl": "assets/images/course1.png",
          "title": "Free Basic Chess Rules",
          "price": 0,
          "rating": 4.0,
          "reviewCount": 120,
          "category": "free",
          "youtube_url":
              "https://www.youtube.com/watch?v=Reza8udb47Y", // Chess for Beginners (ulang)
          "description":
              "Start your chess journey with this free course covering all the basic rules and concepts.",
        },
        {
          "id": "c5",
          "imageUrl": "assets/images/course2.png",
          "title": "Advanced Endgame Techniques",
          "price": 350000,
          "rating": 4.9,
          "reviewCount": 90,
          "category": "popular",
          "youtube_url":
              "https://www.youtube.com/watch?v=MA8Scue28Ks", // Chess Endgame Masterclass
          "description":
              "Master the art of endgame play with advanced techniques and strategies.",
        },
      ];
      if (mounted) setState(() {});
    } catch (e) {
      print('Error fetch course: $e');
      if (mounted) setState(() => _errorMsg = 'Error fetch course: $e');
    }
  }

  Future<void> _fetchShopData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _allProducts = [
        {
          "id": "p1",
          "imageUrl":
              "https://m.media-amazon.com/images/I/71zVVEVB5tL._AC_SL1500_.jpg",
          "name": "Beautiful Metal Chess Set",
          "subtitle": "Chess Board",
          "price": 99999,
          "category": "chess",
        },
        {
          "id": "p2",
          "imageUrl":
              "https://m.media-amazon.com/images/I/81M7o+-V3CL._AC_SL1500_.jpg",
          "name": "Beautiful Handcrafted Wooden Chess Set",
          "subtitle": "Chess Board",
          "price": 149999,
          "category": "chess",
        },
        {
          "id": "p3",
          "imageUrl":
              "https://m.media-amazon.com/images/I/71v5Xyol6qL._AC_SL1500_.jpg",
          "name": "Elegant Glass Chess Set",
          "subtitle": "Chess Board",
          "price": 199999,
          "category": "chess",
        },
        {
          "id": "p4",
          "imageUrl":
              "https://m.media-amazon.com/images/I/71UohSAT3DL._AC_SL1500_.jpg",
          "name": "Luxurious Marble Chess Set",
          "subtitle": "Chess Board",
          "price": 129999,
          "category": "chess",
        },
        {
          "id": "p5",
          "imageUrl":
              "https://m.media-amazon.com/images/I/61O23yq4mDL._AC_SL1000_.jpg",
          "name": "Chess Clock Digital Timer",
          "subtitle": "Chess Items",
          "price": 250000,
          "category": "items",
        },
        {
          "id": "p6",
          "imageUrl":
              "https://m.media-amazon.com/images/I/71g7g9WnB2L._AC_SL1500_.jpg",
          "name": "Roll-Up Chess Board",
          "subtitle": "Chess Items",
          "price": 150000,
          "category": "items",
        },
      ];
      if (mounted) setState(() {});
    } catch (e) {
      print('Error fetch shop: $e');
    }
  }

  Future<void> _fetchArticleData() async {
    print('Mulai fetch article...');
    try {
      await Future.delayed(Duration(milliseconds: 300));
      final random = Random();
      _allArticles = [
        {
          "id": "a1",
          "imageUrl":
              "https://images.chesscomfiles.com/uploads/v1/images_users/tiny_mce/PedroPinhata/phpY0h0bY.jpeg",
          "title":
              "Learn Chess with a Mind of Its Own: The Sentient Chess Tutor",
          "summary":
              "Master the fundamentals of chess through interactive lessons, guided practice, and personalized AI feedback.",
          "date": "Maret 16, 2025",
          "source": "Chess.com Blog",
        },
        {
          "id": "a2",
          "imageUrl":
              "https://images.chesscomfiles.com/uploads/v1/article/26022.77233108.630x354o.4aad52961f70.jpeg",
          "title": "Top 5 Openings for Beginners",
          "summary":
              "Discover the most effective and easy-to-learn chess openings to start your games强.",
          "date": "Maret 10, 2025",
          "source": "Lichess Org",
        },
        {
          "id": "a3",
          "imageUrl":
              "https://images.chesscomfiles.com/uploads/v1/images_users/tiny_mce/SamCopeland/phpfoXLVf.png",
          "title": "Understanding Middlegame Pawn Structures",
          "summary":
              "A deep dive into how pawn structures can dictate your middlegame strategy and plans.",
          "date": "Maret 05, 2025",
          "source": "ChessBase News",
        },
        {
          "id": "a4",
          "imageUrl":
              "https://images.chesscomfiles.com/uploads/v1/images_users/tiny_mce/ColinStapczynski/phpu2Yd7y.jpeg",
          "title": "The Art of a Kingside Attack",
          "summary":
              "Learn key patterns and ideas for launching a successful attack on your opponent's king.",
          "date": "Februari 28, 2025",
          "source": "The Week in Chess",
        },
        {
          "id": "a5",
          "imageUrl":
              "https://images.chesscomfiles.com/uploads/v1/images_users/tiny_mce/PedroPinhata/phppEkvum.png",
          "title": "How to Analyze Your Chess Games",
          "summary":
              "Improve your chess by effectively analyzing your past games, identifying mistakes and good moves.",
          "date": "Februari 20, 2025",
          "source": "Chessable",
        },
        {
          "id": "a6",
          "imageUrl":
              "https://www.chess.com/chess-themes/images/banners/variant_atomic.jpg",
          "title": "Introduction to Chess Variants",
          "summary":
              "Explore fun and exciting chess variants like Crazyhouse, Bughouse, and Atomic chess.",
          "date": "Februari 15, 2025",
          "source": "Chess Variants Org",
        },
      ];
      if (mounted) {
        setState(() {
          _allArticles = List.from(_allArticles)..shuffle(random);
          _allArticles = _allArticles.take(6).toList();
        });
      }
      print('Article berhasil diambil.');
    } catch (e) {
      print('Error fetch article: $e');
      if (mounted) setState(() => _errorMsg = 'Error fetch article: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVeryLightBlue,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child:
                _isLoading
                    ? SizedBox(
                      height:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          kToolbarHeight,
                      child: const Center(child: CircularProgressIndicator()),
                    )
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
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeHeader(profileData: _homeHeaderData),
                        const EventSection(),
                        CoursesSection(allCourses: _allCourses),
                        ShopSection(allProducts: _allProducts),
                        ArticleSection(allArticles: _allArticles),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

class HomeHeader extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  const HomeHeader({super.key, required this.profileData});
  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _greeting = "";
  String _username = "User";
  String? _email;
  String? _avatarPath;
  ImageProvider? _avatarImage;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _syncUser();
    _loadLocalAvatar();
  }

  Future<void> _loadLocalAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('avatar_path');
    if (path != null && path.isNotEmpty) {
      setState(() {
        _avatarPath = path;
        _avatarImage = FileImage(File(path));
      });
    } else {
      setState(() {
        _avatarPath = null;
        _avatarImage = null;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLocalAvatar();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour >= 5 && hour < 12) {
        _greeting = "Good Morning";
      } else if (hour >= 12 && hour < 18) {
        _greeting = "Good Afternoon";
      } else {
        _greeting = "Good Evening";
      }
    });
  }

  void _syncUser() {
    final user =
        widget.profileData != null ? widget.profileData!['user'] : null;
    setState(() {
      _username = user?['username'] ?? 'User';
      _email = user?['email'];
    });
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileData != widget.profileData) {
      _syncUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    ImageProvider? avatarImage = _avatarImage;
    if (avatarImage == null) {
      final profile =
          widget.profileData != null ? widget.profileData!['profile'] : null;
      if (profile != null &&
          profile['avatar'] != null &&
          profile['avatar'].toString().isNotEmpty) {
        final avatarPath = profile['avatar'].toString();
        if (avatarPath.startsWith('http') || avatarPath.startsWith('https')) {
          avatarImage = NetworkImage(avatarPath);
        } else {
          avatarImage = FileImage(File(avatarPath));
        }
      } else {
        avatarImage = null;
      }
    }
    return Container(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: topPadding + 16.0,
        bottom: 24.0,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000A26), Color(0xFF0F52BA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: kLightBlue.withOpacity(0.5),
                backgroundImage: avatarImage != null ? avatarImage : null,
                child:
                    avatarImage == null
                        ? const Icon(Icons.person, size: 32, color: kDarkBlue)
                        : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting,
                    style: TextStyle(
                      color: kVeryLightBlue.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_username!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_email != null)
                    Text(
                      _email!,
                      style: TextStyle(
                        color: kVeryLightBlue.withOpacity(0.8),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          ),
          InkWell(
            onTap: () => print("Notification button pressed"),
            customBorder: const CircleBorder(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E5F2).withOpacity(0.40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0xFF0F52BA), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EventSection extends StatefulWidget {
  const EventSection({super.key});

  @override
  State<EventSection> createState() => _EventSectionState();
}

class _EventSectionState extends State<EventSection> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, String>> _eventItems = [
    {
      "imageUrl": "assets/images/hikaru.png",
      "title": "Studi With Hikaru",
      "subtitle": "Only \$4",
      "buttonText": "Get Now",
    },
    {
      "imageUrl": "assets/images/magnus.png",
      "title": "Masterclass with Magnus",
      "subtitle": "Limited Seats!",
      "buttonText": "Join Now",
    },
    {
      "imageUrl": "assets/images/gotham.png",
      "title": "GothamChess Bootcamp",
      "subtitle": "Become a Chess Bruh",
      "buttonText": "Buy",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    if (_eventItems.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_pageController.hasClients) return;
      int nextPage = (_currentPage + 1) % _eventItems.length;
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
    if (_eventItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _eventItems.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                final event = _eventItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildEventCard(event: event),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _eventItems.length,
              (index) => _buildDot(index: index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({required Map<String, String> event}) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: kPrimaryBlue,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(
                event['imageUrl']!,
                fit: BoxFit.cover,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: double.infinity,
                    color: kLightBlue.withOpacity(0.3),
                    child: const Center(
                      child: Icon(
                        Icons.photo_size_select_actual_outlined,
                        color: kVeryLightBlue,
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event['subtitle']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kVeryLightBlue,
                    foregroundColor: kPrimaryBlue,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  child: Text(event['buttonText']!),
                ),
              ],
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

class CoursesSection extends StatefulWidget {
  final List<Map<String, dynamic>> allCourses;
  const CoursesSection({super.key, required this.allCourses});
  @override
  State<CoursesSection> createState() => _CoursesSectionState();
}

class _CoursesSectionState extends State<CoursesSection> {
  String _selectedFilter = "All Course";
  List<Map<String, dynamic>> _filteredCourses = [];

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == "All Course") {
        _filteredCourses = List.from(widget.allCourses);
      } else if (_selectedFilter == "Populer") {
        _filteredCourses =
            widget.allCourses
                .where(
                  (course) =>
                      course['rating'] >= 4.5 ||
                      course['category'] == 'popular',
                )
                .toList();
      } else if (_selectedFilter == "Free") {
        _filteredCourses =
            widget.allCourses.where((course) => course['price'] == 0).toList();
      }
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
                  onPressed: () => print("See all courses pressed"),
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
                  _buildFilterButton("Populer"),
                  _buildFilterButton("Free"),
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
  YoutubePlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _isVideoLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    setState(() {
      _isVideoLoading = true;
    });
    final String? youtubeUrl = widget.course['youtube_url'] as String?;
    if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
      final videoId = extractYoutubeId(youtubeUrl);
      if (videoId != null) {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            mute: true,
            showVideoAnnotations: false,
          ),
        );
        _isVideoInitialized = true;
      }
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.course['price'] as num? ?? 0;
    final String? imageUrl = widget.course['imageUrl'] as String?;
    final String? youtubeUrl = widget.course['youtube_url'] as String?;
    final String? videoId =
        youtubeUrl != null ? extractYoutubeId(youtubeUrl) : null;
    final String? thumbnailUrl =
        videoId != null ? 'https://img.youtube.com/vi/$videoId/0.jpg' : null;

    return GestureDetector(
      onTap: () {
        if (youtubeUrl != null && youtubeUrl.isNotEmpty && videoId != null) {
          showDialog(
            context: context,
            builder:
                (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.1,
                    vertical: MediaQuery.of(context).size.height * 0.25,
                  ),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: YoutubePlayer(
                            controller: YoutubePlayerController.fromVideoId(
                              videoId: videoId,
                              params: const YoutubePlayerParams(
                                showControls: true,
                                showFullscreenButton: true,
                                mute: false,
                                showVideoAnnotations: false,
                              ),
                            ),
                            aspectRatio: 16 / 9,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
          );
        } else {
          print("Course tapped: " + (widget.course['title'] ?? ''));
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12.0),
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
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) {
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
                    Image.asset(
                      imageUrl ?? 'assets/images/course1.png',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading course image: $error");
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
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (youtubeUrl != null &&
                              youtubeUrl.isNotEmpty &&
                              videoId != null) {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                          0.1,
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                          0.25,
                                    ),
                                    child: Stack(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            child: YoutubePlayer(
                                              controller:
                                                  YoutubePlayerController.fromVideoId(
                                                    videoId: videoId,
                                                    params:
                                                        const YoutubePlayerParams(
                                                          showControls: true,
                                                          showFullscreenButton:
                                                              true,
                                                          mute: false,
                                                          showVideoAnnotations:
                                                              false,
                                                        ),
                                                  ),
                                              aspectRatio: 16 / 9,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            );
                          }
                        },
                        splashColor: Colors.black12,
                        highlightColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 10),
                  Text(
                    price == 0
                        ? "Free"
                        : "Rp. ${NumberFormat.decimalPattern('id_ID').format(price)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }
}

String? extractYoutubeId(String url) {
  final RegExp regExp = RegExp(
    r'(?:v=|\/)([0-9A-Za-z_-]{11}).*',
    caseSensitive: false,
    multiLine: false,
  );
  final match = regExp.firstMatch(url);
  return match != null ? match.group(1) : null;
}

class ShopSection extends StatefulWidget {
  final List<Map<String, dynamic>> allProducts;
  const ShopSection({super.key, required this.allProducts});
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
      if (_selectedFilter == "All Product") {
        _filteredProducts = List.from(widget.allProducts);
      } else if (_selectedFilter == "Chess") {
        _filteredProducts =
            widget.allProducts
                .where((product) => product['category'] == 'chess')
                .toList();
      } else if (_selectedFilter == "Items") {
        _filteredProducts =
            widget.allProducts
                .where((product) => product['category'] == 'items')
                .toList();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ShopSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allProducts != widget.allProducts) _applyFilter();
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
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShopScreen(),
                        ),
                      ),
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
                          "No products found for '$_selectedFilter'",
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
        print("Product tapped: ${widget.product['name']}");
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
                        const SizedBox.shrink(),
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
                          onTap: () {
                            // Panggil setState untuk memberitahu Flutter agar membangun ulang widget
                            setState(() {
                              // Balikkan nilai _isLiked
                              _isLiked = !_isLiked;
                            });
                            print(
                              "Like status for ${widget.product['name']} is now: $_isLiked",
                            );
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              // Warna background ikon sedikit lebih terang saat disukai
                              color: kVeryLightBlue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              // Ganti ikon berdasarkan status _isLiked
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              // Ganti warna ikon menjadi merah saat disukai
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
          const SizedBox(height: 5),
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
                  return ArticleCard(article: article);
                },
              ),
        ],
      ),
    );
  }
}

class ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  const ArticleCard({super.key, required this.article});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => print("Article tapped: ${article['title']}"),
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
                child: Image.network(
                  article['imageUrl']!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: kLightBlue.withOpacity(0.2),
                        child: Center(
                          child: Icon(
                            Icons.article_outlined,
                            color: kDarkBlue.withOpacity(0.4),
                            size: 40,
                          ),
                        ),
                      ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                        strokeWidth: 2.0,
                      ),
                    );
                  },
                ),
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
                      children: [
                        Text(
                          article['title']!,
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
                          article['summary']!,
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
                        article['date']!,
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
}
