import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:sentient/course_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import 'dart:io';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

const Color kHeaderGradientStart = Color(0xFF000A26);
const Color kHeaderGradientMid = Color(0xFF001759);
const Color kHeaderGradientEnd = Color(0xFF00207B);

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  String _username = "User";
  String _motivationalQuote = "";
  ImageProvider? _avatarImage;
  bool _isLoading = true;
  String? _errorMsg;

  final List<String> _quotes = [
    "Find a Best Course For You",
    "Unlock Your Chess Potential",
    "Master the Game, One Move at a Time",
    "Elevate Your Strategy Skills",
    "Your Journey to Chess Mastery Starts Here",
  ];

  final Random _random = Random();
  final int _savedCourses = 8;
  final int _finishedCourses = 19;
  final int _inProgressCourses = 4;

  @override
  void initState() {
    super.initState();
    _changeQuote();
    _loadProfileAndAvatar();
  }

  Future<void> _loadProfileAndAvatar() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      if (!FirebaseService.isAuthenticated()) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('avatar_path');
      ImageProvider? newAvatar;
      if (path != null && path.isNotEmpty) {
        newAvatar = FileImage(File(path));
      }

      final result = await FirebaseService.getCurrentUser();
      if (mounted) {
        if (result != null) {
          if (newAvatar == null) {
            final backendAvatar = result['avatar'];
            if (backendAvatar != null && backendAvatar.toString().isNotEmpty) {
              newAvatar = NetworkImage(backendAvatar.toString());
            }
          }
          setState(() {
            _username = result['username'] ?? 'User';
            _avatarImage = newAvatar;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeQuote() {
    setState(() => _motivationalQuote = _quotes[_random.nextInt(_quotes.length)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVeryLightBlue,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildCourseHeader(),
            _buildCourseStatsSection(),
            const RecommendationSection(),
            const CourseFilterAndListSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader() {
    final double topPadding = MediaQuery.of(context).padding.top;

    const gradient = LinearGradient(
        colors: [kHeaderGradientStart, kHeaderGradientMid, kHeaderGradientEnd],
        stops: [0.0, 0.66, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter);

    Widget headerContent;
    if (_isLoading) {
      headerContent = const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kVeryLightBlue)));
    } else if (_errorMsg != null) {
      headerContent = Center(child: Text(_errorMsg!, style: const TextStyle(color: kVeryLightBlue, fontSize: 14), textAlign: TextAlign.center));
    } else {
      headerContent = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Hi, $_username', style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w600, color: kVeryLightBlue)),
          const SizedBox(height: 25),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: kVeryLightBlue.withOpacity(0.2),
              backgroundImage: _avatarImage,
              child: _avatarImage == null ? const Icon(Icons.person, size: 48, color: kDarkBlue) : null,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              _motivationalQuote,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: kVeryLightBlue),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding + 20, bottom: 40, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
      ),
      child: headerContent,
    );
  }

  Widget _buildCourseStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildStatItem(iconPath: "assets/icons/ic_save.png", count: _savedCourses, label: "Save"),
          _buildStatItem(iconPath: "assets/icons/ic_finished.png", count: _finishedCourses, label: "Finished"),
          _buildStatItem(iconPath: "assets/icons/ic_progress.png", count: _inProgressCourses, label: "In Progress"),
        ],
      ),
    );
  }

  Widget _buildStatItem({ required String iconPath, required int count, required String label }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircleAvatar(
          radius: 30,
          backgroundColor: kLightBlue.withOpacity(0.4),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(iconPath, errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.bookmark_border, color: kPrimaryBlue, size: 28);
            }),
          ),
        ),
        const SizedBox(height: 8),
        Text(count.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue, fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: kDarkBlue.withOpacity(0.7), fontFamily: 'Poppins')),
      ],
    );
  }
}

class RecommendationSection extends StatefulWidget {
  const RecommendationSection({super.key});
  @override
  State<RecommendationSection> createState() => _RecommendationSectionState();
}

class _RecommendationSectionState extends State<RecommendationSection> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, String>> _recommendationList = [
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
    if (_recommendationList.length > 1) _startAutoScroll();
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
    if (_recommendationList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Recommendation", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) {
                final int actualIndex = index % _recommendationList.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildRecommendationCard(recommendation: _recommendationList[actualIndex]),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _recommendationList.length,
                  (index) => _buildDot(index: index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({required Map<String, String> recommendation}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(color: kPrimaryBlue, borderRadius: BorderRadius.circular(20.0)),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(recommendation['imageUrl']!, fit: BoxFit.cover, height: double.infinity,
                errorBuilder: (c, e, s) => Container(height: double.infinity, color: kLightBlue.withOpacity(0.3), child: const Center(child: Icon(Icons.photo_size_select_actual_outlined, color: kVeryLightBlue, size: 30))),
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
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(recommendation['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(recommendation['subtitle']!, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kVeryLightBlue, foregroundColor: kPrimaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  child: Text(recommendation['buttonText']!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required int index}) {
    bool isActive = (_currentPage % _recommendationList.length) == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(color: isActive ? kPrimaryBlue : kLightBlue, borderRadius: BorderRadius.circular(4)),
    );
  }
}

class CourseFilterAndListSection extends StatefulWidget {
  const CourseFilterAndListSection({super.key});
  @override
  State<CourseFilterAndListSection> createState() => _CourseFilterAndListSectionState();
}

class _CourseFilterAndListSectionState extends State<CourseFilterAndListSection> {
  final List<Map<String, dynamic>> _allCourses = [
    {
      "id": "c1",
      "level": "Beginner",
      "isPopular": true,
      "imageUrl": "assets/images/course1.png",
      "headerImageUrl": "assets/images/gotham.png",
      "chessBoardUrl": "assets/images/chessboard.png",
      "title": "Mastering Chess Fundamentals",
      "headerTitle": "Mastering Chess\nFundamentals",
      "price": 100000, "rating": 4.5, "reviewCount": 50,
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
      "level": "Intermediate",
      "isPopular": true,
      "imageUrl": "assets/images/course2.png",
      "headerImageUrl": "assets/images/kostya.png",
      "chessBoardUrl": "assets/images/chessboard.png",
      "title": "Tactical Patterns & Strategy",
      "headerTitle": "Advanced Tactical\nPatterns",
      "price": 0, "rating": 4.8, "reviewCount": 75,
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
      "level": "Expert",
      "imageUrl": "assets/images/course3.png",
      "headerImageUrl": "assets/images/magnus.png",
      "chessBoardUrl": "assets/images/chessboard.png",
      "title": "Opening Repertoire for All Levels",
      "headerTitle": "Opening Repertoire:\nMax Lange Attack",
      "price": 400000, "rating": 4.2, "reviewCount": 30,
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

  String _selectedTypeFilter = "All Course";
  String _selectedLevelFilter = "Beginner";
  List<Map<String, dynamic>> _filteredCourses = [];

  final GlobalKey _filterButtonKey = GlobalKey();
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  @override
  void dispose() {
    _removeDropdownOverlay();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      List<Map<String, dynamic>> tempCourses = List.from(_allCourses);
      if (_selectedTypeFilter == "Popular") tempCourses = tempCourses.where((c) => c['isPopular'] == true).toList();
      else if (_selectedTypeFilter == "Paid") tempCourses = tempCourses.where((c) => c['price'] > 0).toList();
      else if (_selectedTypeFilter == "Free") tempCourses = tempCourses.where((c) => c['price'] == 0).toList();

      tempCourses = tempCourses.where((c) => c['level'] == _selectedLevelFilter).toList();
      _filteredCourses = tempCourses;
    });
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) _removeDropdownOverlay();
    else _showDropdownOverlay();
    setState(() => _isDropdownOpen = !_isDropdownOpen);
  }

  void _removeDropdownOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDropdownOverlay() {
    final RenderBox renderBox = _filterButtonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx, top: offset.dy + size.height + 5, width: 150,
        child: Material(
          elevation: 4.0, borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kLightBlue)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <String>['All Course', 'Popular', 'Paid', 'Free'].map((value) => ListTile(
                title: Text(value, style: TextStyle(fontSize: 14, color: _selectedTypeFilter == value ? kPrimaryBlue : kDarkBlue)),
                dense: true,
                onTap: () {
                  setState(() { _selectedTypeFilter = value; _applyFilters(); });
                  _toggleDropdown();
                },
              )).toList(),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildLevelFilterButton(String title) {
    bool isActive = _selectedLevelFilter == title;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => setState(() { _selectedLevelFilter = title; _applyFilters(); }),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? kPrimaryBlue : kVeryLightBlue, foregroundColor: isActive ? kVeryLightBlue : kPrimaryBlue,
            elevation: isActive ? 2 : 0, padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isActive ? BorderSide.none : const BorderSide(color: kPrimaryBlue, width: 1.5)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          child: Text(title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                key: _filterButtonKey,
                onTap: _toggleDropdown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: kVeryLightBlue, borderRadius: BorderRadius.circular(12), border: Border.all(color: kPrimaryBlue, width: 1.5)),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, color: kPrimaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(_selectedTypeFilter, style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [_buildLevelFilterButton("Beginner"), _buildLevelFilterButton("Intermediate"), _buildLevelFilterButton("Expert")]),
          const SizedBox(height: 20),
          _filteredCourses.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text("No courses found for this level.", style: TextStyle(color: kDarkBlue.withOpacity(0.7))),
          )
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.72),
            itemCount: _filteredCourses.length,
            itemBuilder: (context, index) {
              return CourseCard(course: _filteredCourses[index]);
            },
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [BoxShadow(color: kLightBlue.withOpacity(0.5), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
        ),
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
                  children: [
                    Text(course['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDarkBlue), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(price == 0 ? "Free" : "Rp. ${NumberFormat.decimalPattern('id_ID').format(price)}", style: const TextStyle(fontSize: 12, color: kPrimaryBlue, fontWeight: FontWeight.bold)),
                    const Spacer(),
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