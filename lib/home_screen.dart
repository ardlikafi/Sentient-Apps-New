import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:sentient/course_screen.dart';
import 'package:sentient/shop_screen.dart';
import 'package:sentient/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import 'dart:io';
import 'package:sentient/article_detail_screen.dart';
import 'package:sentient/course_detail_screen.dart';
import 'product_card.dart';
import 'mock_data.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

const Color kHeaderGradientStart = Color(0xFF000A26);
const Color kHeaderGradientMid = Color(0xFF001759);
const Color kHeaderGradientEnd = Color(0xFF00207B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pageOptions;

  @override
  void initState() {
    super.initState();
    _pageOptions = <Widget>[
      HomeContent(onNavigateToTab: _onItemTapped),
      const CourseScreen(),
      const ShopScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVeryLightBlue,
      body: IndexedStack(index: _selectedIndex, children: _pageOptions),
      bottomNavigationBar: Container(
        clipBehavior: Clip.antiAlias,
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
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Course'),
            BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'Shop'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
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
    );
  }
}

class HomeContent extends StatefulWidget {
  final Function(int) onNavigateToTab;
  const HomeContent({super.key, required this.onNavigateToTab});
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with AutomaticKeepAliveClientMixin<HomeContent> {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic>? _homeHeaderData;
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _allArticles = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await Future.wait([
        _fetchHomeHeaderData(),
        _fetchCourseData(),
        _fetchArticleData(),
      ]);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _errorMsg = 'Terjadi error: ${e.toString()}'; _isLoading = false; });
    }
  }

  Future<void> _refreshData() async => await _fetchInitialData();

  Future<void> _fetchHomeHeaderData() async {
    try {
      if (!FirebaseService.isAuthenticated()) {
        if (mounted) setState(() => _homeHeaderData = null);
        return;
      }
      final result = await FirebaseService.getCurrentUser();
      if (mounted) setState(() => _homeHeaderData = result);
    } catch (e) { rethrow; }
  }

  Future<void> _fetchCourseData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _allCourses = [
        {
          "id": "c1",
          "imageUrl": "assets/images/course1.png",
          "headerImageUrl": "assets/images/gotham.png",
          "chessBoardUrl": "assets/images/chessboard.png",
          "title": "Mastering Chess Fundamentals",
          "headerTitle": "Mastering Chess\nFundamentals",
          "price": 100000, "rating": 4.5, "reviewCount": 50, "category": "popular",
          "youtube_url": "https://www.youtube.com/watch?v=OCSbzArwB10",
          "description": "Learn the complete basics of chess with this comprehensive guide. Perfect for beginners who want to start their chess journey. This course covers piece movement, basic tactics, and fundamental checkmating patterns.",
          "instructorName": "GothamChess",
          "instructorAvatar": "assets/images/sven.png",
          "instructorSubtitle": "International Master",
          "lessonCount": 25, "totalDuration": "8h 30m",
          "lessons": [
            {"title": "The Board and Pieces", "duration": "25m", "thumbnail": "assets/images/lesson1.png", "isLocked": false},
            {"title": "Basic Checkmates", "duration": "45m", "thumbnail": "assets/images/lesson2.png", "isLocked": false},
            {"title": "Opening Principles", "duration": "35m", "thumbnail": "assets/images/lesson1.png", "isLocked": true},
          ]
        },
        {
          "id": "c2",
          "imageUrl": "assets/images/course2.png",
          "headerImageUrl": "assets/images/kostya.png",
          "chessBoardUrl": "assets/images/chessboard.png",
          "title": "Tactical Patterns & Strategy",
          "headerTitle": "Advanced Tactical\nPatterns",
          "price": 0, "rating": 4.0, "reviewCount": 50, "category": "popular",
          "youtube_url": "https://www.youtube.com/watch?v=NAIQyoPcjNM",
          "description": "Master essential tactical patterns and strategic concepts to improve your game. This course dives deep into forks, pins, skewers, and discovered attacks.",
          "instructorName": "IM Kostya Kavutskiy",
          "instructorAvatar": "assets/images/kostya.png",
          "instructorSubtitle": "International Master",
          "lessonCount": 35, "totalDuration": "12h 15m",
          "lessons": [
            {"title": "The Anatomy of a Fork", "duration": "55m", "thumbnail": "assets/images/lesson1.png", "isLocked": false},
            {"title": "Mastering Pins & Skewers", "duration": "1h 10m", "thumbnail": "assets/images/lesson2.png", "isLocked": false},
            {"title": "Discovered & Double Attacks", "duration": "1h 30m", "thumbnail": "assets/images/lesson1.png", "isLocked": true},
            {"title": "Forcing Moves & Sacrifices", "duration": "1h 25m", "thumbnail": "assets/images/lesson2.png", "isLocked": true},
          ]
        },
        {
          "id": "c3",
          "imageUrl": "assets/images/course3.png",
          "headerImageUrl": "assets/images/magnus.png",
          "chessBoardUrl": "assets/images/chessboard.png",
          "title": "Opening Repertoire for All Levels",
          "headerTitle": "Opening Repertoire:\nMax Lange Attack",
          "price": 400000, "rating": 4.2, "reviewCount": 30, "category": "all",
          "youtube_url": "https://www.youtube.com/watch?v=W1gWHIpQNVU",
          "description": "Lorem ipsum dolor, sit amet consectetur adipisicing elit. Saepe excepturi id labore, aliquid ratione veritatis quam nam, commodi voluptates dignissimos optio quod maiores itaque. Excepturi doloremque non totam. Aliquid, nesciunt.",
          "instructorName": "Sven Magnus Øen Carlsen",
          "instructorAvatar": "assets/images/sven.png",
          "instructorSubtitle": "LOA 3000",
          "lessonCount": 30, "totalDuration": "15h 20m",
          "lessons": [
            {"title": "Introduction to Max Lange", "duration": "1h 05m", "thumbnail": "assets/images/lesson1.png", "isLocked": false},
            {"title": "Key Tactical Ideas", "duration": "1h 45m", "thumbnail": "assets/images/lesson2.png", "isLocked": false},
            {"title": "Responding to Deviations", "duration": "2h 15m", "thumbnail": "assets/images/lesson1.png", "isLocked": true},
            {"title": "Model Games Analysis", "duration": "2h 00m", "thumbnail": "assets/images/lesson2.png", "isLocked": true},
          ]
        },
      ];
    } catch (e) { rethrow; }
  }

  Future<void> _fetchArticleData() async { try { await Future.delayed(const Duration(milliseconds: 300)); final random = Random(); _allArticles = [ {"id": "a1", "imageUrl": "assets/images/article1.png", "title": "Learn Chess with a Mind of Its Own: The Sentient Chess Tutor", "summary": "Master the fundamentals of chess through interactive lessons, guided practice, and personalized AI feedback.", "date": "Mar 25, 2025", "source": "Chess.com Blog", "category": "Education", "author": "Sentient Writer",}, {"id": "a2", "imageUrl": "assets/images/article2.png", "title": "Top 5 Openings for Beginners", "summary": "Discover the most effective and easy-to-learn chess openings to start your games.", "date": "Maret 10, 2025", "source": "Lichess Org", "category": "Openings", "author": "Lichess Team",}, {"id": "a3", "imageUrl": "assets/images/article3.png", "title": "Understanding Middlegame Pawn Structures", "summary": "A deep dive into how pawn structures can dictate your middlegame strategy and plans.", "date": "Maret 05, 2025", "source": "ChessBase News", "category": "Strategy", "author": "Sam Copeland",}, {"id": "a4", "imageUrl": "assets/images/article4.png", "title": "The Art of a Kingside Attack", "summary": "Learn key patterns and ideas for launching a successful attack on your opponent's king.", "date": "Februari 28, 2025", "source": "The Week in Chess", "category": "Tactics", "author": "Colin Stapczynski",}, {"id": "a5", "imageUrl": "assets/images/article5.png", "title": "How to Analyze Your Chess Games", "summary": "Improve your chess by effectively analyzing your past games, identifying mistakes and good moves.", "date": "Februari 20, 2025", "source": "Chessable", "category": "Improvement", "author": "Pedro Pinhata",}, {"id": "a6", "imageUrl": "assets/images/article6.png", "title": "Introduction to Chess Variants", "summary": "Explore fun and exciting chess variants like Crazyhouse, Bughouse, and Atomic chess.", "date": "Februari 15, 2025", "source": "Chess Variants Org", "category": "Variants", "author": "Various",}, ]; if (mounted) { setState(() { _allArticles = List.from(_allArticles)..shuffle(random); _allArticles = _allArticles.take(6).toList(); }); } } catch (e) { rethrow; } }

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
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : (_errorMsg != null)
              ? Center(child: Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center))
              : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(profileData: _homeHeaderData),
                const EventSection(),
                CoursesSection(allCourses: _allCourses, onSeeAll: () => widget.onNavigateToTab(1)),
                ShopSection(allProducts: allMockProducts, onSeeAll: () => widget.onNavigateToTab(2)),
                const SizedBox(height: 24.0),
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
  ImageProvider? _avatarImage;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _syncUser();
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileData != widget.profileData) {
      _syncUser();
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (mounted) {
      setState(() {
        if (hour >= 5 && hour < 12) _greeting = "Good Morning";
        else if (hour >= 12 && hour < 18) _greeting = "Good Afternoon";
        else _greeting = "Good Evening";
      });
    }
  }

  Future<void> _syncUser() async {
    final data = widget.profileData;
    String newUsername = 'User';
    ImageProvider? newAvatarImage;
    if (data != null) newUsername = data['username'] ?? 'User';

    final prefs = await SharedPreferences.getInstance();
    final localPath = prefs.getString('avatar_path');

    if (localPath != null && await File(localPath).exists()) {
      newAvatarImage = FileImage(File(localPath));
    }
    else if (data != null && data['avatar'] != null && data['avatar'].toString().isNotEmpty) {
      final avatarUrl = data['avatar'].toString();
      if (avatarUrl.startsWith('http')) newAvatarImage = NetworkImage(avatarUrl);
    }

    if (mounted) setState(() { _username = newUsername; _avatarImage = newAvatarImage; });
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(left: 20.0, right: 20.0, top: topPadding + 16.0, bottom: 24.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kHeaderGradientStart,
            kHeaderGradientMid,
            kHeaderGradientEnd,
          ],
          stops: [0.0, 0.66, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 28, backgroundColor: kLightBlue.withOpacity(0.5), backgroundImage: _avatarImage, child: _avatarImage == null ? const Icon(Icons.person, size: 32, color: kDarkBlue) : null),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_greeting, style: TextStyle(color: kVeryLightBlue.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('$_username!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: () => print("Notification button pressed"),
            customBorder: const CircleBorder(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(padding: const EdgeInsets.all(10.0), decoration: BoxDecoration(color: kVeryLightBlue.withOpacity(0.40), shape: BoxShape.circle), child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24)),
                Positioned(top: 6, right: 8, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: kPrimaryBlue, width: 1.5))))),
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
    {"imageUrl": "assets/images/hikaru.png", "title": "Studi With Hikaru", "subtitle": "Only \$4", "buttonText": "Get Now"},
    {"imageUrl": "assets/images/magnus.png", "title": "Masterclass with Magnus", "subtitle": "Limited Seats!", "buttonText": "Join Now"},
    {"imageUrl": "assets/images/gotham.png", "title": "GothamChess Bootcamp", "subtitle": "Become a Chess Bruh", "buttonText": "Buy"},
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
    if (_eventItems.length > 1) _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
    if (_eventItems.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                if (mounted) setState(() => _currentPage = page);
              },
              itemBuilder: (context, index) {
                final int actualIndex = index % _eventItems.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildEventCard(event: _eventItems[actualIndex]),
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
      decoration: BoxDecoration(color: kPrimaryBlue, borderRadius: BorderRadius.circular(20.0)),
      child: Row(
        children: [
          Expanded(flex: 4, child: ClipRRect(borderRadius: BorderRadius.circular(12.0), child: Image.asset(event['imageUrl']!, fit: BoxFit.cover, height: double.infinity, errorBuilder: (c, e, s) => Container(height: double.infinity, color: kLightBlue.withOpacity(0.3), child: const Center(child: Icon(Icons.photo_size_select_actual_outlined, color: kVeryLightBlue, size: 30)))))),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(event['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(event['subtitle']!, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: kVeryLightBlue, foregroundColor: kPrimaryBlue, tapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
    bool isActive = (_currentPage % _eventItems.length) == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(color: isActive ? kPrimaryBlue : kLightBlue, borderRadius: BorderRadius.circular(4)),
    );
  }
}

class CoursesSection extends StatefulWidget {
  final List<Map<String, dynamic>> allCourses;
  final VoidCallback onSeeAll;
  const CoursesSection({super.key, required this.allCourses, required this.onSeeAll});
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
      if (widget.allCourses.isEmpty) { _filteredCourses = []; return; }
      List<Map<String, dynamic>> tempCourses;
      if (_selectedFilter == "All Course") tempCourses = List.from(widget.allCourses);
      else if (_selectedFilter == "Populer") tempCourses = widget.allCourses.where((c) => (c['rating'] != null && (c['rating'] as num) >= 4.5) || (c['category'] == 'popular')).toList();
      else if (_selectedFilter == "Free") tempCourses = widget.allCourses.where((c) => (c['price'] as num? ?? 0) == 0).toList();
      else tempCourses = List.from(widget.allCourses);
      _filteredCourses = tempCourses;
    });
  }

  @override
  void didUpdateWidget(covariant CoursesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allCourses != widget.allCourses) _applyFilter();
  }

  Widget _buildFilterButton(String title) {
    bool isActive = _selectedFilter == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () => setState(() { _selectedFilter = title; _applyFilter(); }),
        style: ElevatedButton.styleFrom(backgroundColor: isActive ? kPrimaryBlue : kVeryLightBlue, foregroundColor: isActive ? kVeryLightBlue : kPrimaryBlue, elevation: isActive ? 2 : 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: isActive ? BorderSide.none : const BorderSide(color: kPrimaryBlue, width: 1.5)), textStyle: const TextStyle(fontWeight: FontWeight.w500)),
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
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Courses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue)),
              TextButton(onPressed: widget.onSeeAll, child: Text("See all", style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              _buildFilterButton("All Course"),
              _buildFilterButton("Populer"),
              _buildFilterButton("Free"),
            ])),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _filteredCourses.isEmpty
                ? Center(child: Text("No courses found for '$_selectedFilter'", style: TextStyle(color: kDarkBlue.withOpacity(0.7))))
                : ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16.0), itemCount: _filteredCourses.length, itemBuilder: (context, index) {
              return CourseCard(course: _filteredCourses[index]);
            }),
          ),
        ],
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final price = course['price'] as num? ?? 0;
    final String? imageUrl = course['imageUrl'] as String?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(course: course),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [BoxShadow(color: kLightBlue.withOpacity(0.5), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15.0), topRight: Radius.circular(15.0)),
              child: Image.asset(
                imageUrl ?? 'assets/images/course1.png',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(height: 120, color: kLightBlue.withOpacity(0.3), child: const Center(child: Icon(Icons.photo, color: kDarkBlue, size: 40))),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(course['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDarkBlue), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text(price == 0 ? "Free" : "Rp. ${NumberFormat.decimalPattern('id_ID').format(price)}", style: const TextStyle(fontSize: 12, color: kPrimaryBlue, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text("${course['rating']} (${course['reviewCount']})", style: TextStyle(fontSize: 12, color: kDarkBlue.withOpacity(0.7))),
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

class ShopSection extends StatefulWidget {
  final List<Map<String, dynamic>> allProducts;
  final VoidCallback onSeeAll;
  const ShopSection({super.key, required this.allProducts, required this.onSeeAll});
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
      if (widget.allProducts.isEmpty) { _filteredProducts = []; return; }
      List<Map<String, dynamic>> tempProducts;
      if (_selectedFilter == "All Product") tempProducts = List.from(widget.allProducts);
      else if (_selectedFilter == "Chess") tempProducts = widget.allProducts.where((p) => p['category'] == 'Chess').toList();
      else if (_selectedFilter == "Items") tempProducts = widget.allProducts.where((p) => p['category'] == 'Items').toList();
      else tempProducts = List.from(widget.allProducts);
      _filteredProducts = tempProducts;
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
        onPressed: () => setState(() { _selectedFilter = title; _applyFilter(); }),
        style: ElevatedButton.styleFrom(backgroundColor: isActive ? kPrimaryBlue : kVeryLightBlue, foregroundColor: isActive ? kVeryLightBlue : kPrimaryBlue, elevation: isActive ? 2 : 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: isActive ? BorderSide.none : const BorderSide(color: kPrimaryBlue, width: 1.5)), textStyle: const TextStyle(fontWeight: FontWeight.w600)),
        child: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedProducts = _filteredProducts.take(4).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Shop", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue)),
              TextButton(onPressed: widget.onSeeAll, child: Text("See all", style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              _buildFilterButton("All Product"),
              _buildFilterButton("Chess"),
              _buildFilterButton("Items"),
            ])),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: displayedProducts.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text(_selectedFilter == "All Product" ? "No products found." : "No products found in category '$_selectedFilter'.", style: TextStyle(color: kDarkBlue.withOpacity(0.7)))))
                : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.72),
              itemCount: displayedProducts.length,
              itemBuilder: (context, index) => ProductCard(product: displayedProducts[index]),
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
      final List<Map<String, dynamic>> shuffled = List.from(widget.allArticles)..shuffle(_random);
      setState(() => _displayedArticles = shuffled.take(6).toList());
    } else {
      setState(() => _displayedArticles = []);
    }
  }

  @override
  void didUpdateWidget(covariant ArticleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allArticles != widget.allArticles) _loadRandomArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text("Article", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue))),
          _displayedArticles.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text("No articles to display.", style: TextStyle(color: kDarkBlue.withOpacity(0.7)))))
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.65),
            itemCount: _displayedArticles.length,
            itemBuilder: (context, index) => ArticleCard(article: _displayedArticles[index]),
          ),
          Center(child: TextButton(onPressed: () {}, child: Text("See all articles", style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 16),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ArticleDetailScreen(article: article))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.0), boxShadow: [BoxShadow(color: kLightBlue.withOpacity(0.6), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(15.0), topRight: Radius.circular(15.0)),
                child: Image.asset(article['imageUrl']!, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: kLightBlue.withOpacity(0.2), child: Center(child: Icon(Icons.article_outlined, color: kDarkBlue.withOpacity(0.4), size: 40)))),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(article['title'] ?? 'No Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kDarkBlue), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(article['summary'] ?? 'No summary available.', style: TextStyle(fontSize: 11, color: kDarkBlue.withOpacity(0.7)), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ]),
                    Align(alignment: Alignment.centerRight, child: Text(article['date'] ?? 'No Date', style: TextStyle(fontSize: 10, color: kDarkBlue.withOpacity(0.6), fontStyle: FontStyle.italic))),
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