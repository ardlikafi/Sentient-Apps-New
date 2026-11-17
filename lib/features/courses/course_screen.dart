import 'package:intl/intl.dart';
// File: lib/course_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:sentient/core/services/firebase_service.dart';
import 'package:sentient/core/utils/image_helper.dart';
import 'package:sentient/core/widgets/shimmer_loading.dart';
import 'package:sentient/features/courses/course_shimmer.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:sentient/features/courses/course_detail_screen.dart';
import 'package:sentient/core/services/simulated_order_service.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/user_provider.dart';

// Definisikan konstanta warna
const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

// Konstanta warna tidak digunakan lagi karena langsung memakai warna dari profile

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  String _motivationalQuote = "";

  final List<String> _quotes = [
    "Find a Best Course For You",
    "Unlock Your Chess Potential",
    "Master the Game, One Move at a Time",
    "Elevate Your Strategy Skills",
    "Your Journey to Chess Mastery Starts Here",
  ];

  final Random _random = Random();

  // Data statistik dinamis dari database
  int _savedCourses = 0;
  int _finishedCourses = 0;
  int _inProgressCourses = 0;

  List<String> _savedCourseIds = [];
  List<String> _finishedCourseIds = [];
  List<String> _inProgressCourseIds = [];

  // Filter statistik aktif: null (semua), 'Save', 'Finished', atau 'In Progress'
  String? _activeStatFilter;

  List<Map<String, dynamic>> _allCourses = [];
  bool _isLoadingCourses = true;
  StreamSubscription? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _changeQuote();
    _fetchCourses();
    _fetchUserStats();
    _orderSubscription = SimulatedOrderService.orderStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _fetchUserStats() async {
    final stats = await FirebaseService.getUserCourseStats();
    if (mounted) {
      setState(() {
        _savedCourseIds = List<String>.from(stats['saved_ids'] ?? []);
        _inProgressCourseIds =
            List<String>.from(stats['in_progress_ids'] ?? []);
        _finishedCourseIds = List<String>.from(stats['finished_ids'] ?? []);

        _savedCourses = _savedCourseIds.length;
        _inProgressCourses = _inProgressCourseIds.length;
        _finishedCourses = _finishedCourseIds.length;
      });
    }
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await FirebaseService.getAllCourses();
      if (mounted) {
        setState(() {
          _allCourses = courses;
          _isLoadingCourses = false;
        });
      }
      await _fetchUserStats();
    } catch (e) {
      debugPrint('Error fetching courses in CourseScreen: $e');
      if (mounted) {
        setState(() => _isLoadingCourses = false);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredCoursesByStat() {
    if (_activeStatFilter == null) return _allCourses;

    if (_activeStatFilter == "Save") {
      return _allCourses.where((c) {
        final id = c['id']?.toString();
        return id != null && _savedCourseIds.contains(id);
      }).toList();
    } else if (_activeStatFilter == "Finished") {
      return _allCourses.where((c) {
        final id = c['id']?.toString();
        return id != null && _finishedCourseIds.contains(id);
      }).toList();
    } else if (_activeStatFilter == "In Progress") {
      return _allCourses.where((c) {
        final id = c['id']?.toString();
        return id != null && _inProgressCourseIds.contains(id);
      }).toList();
    }
    return _allCourses;
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _changeQuote() {
    setState(() {
      _motivationalQuote = _quotes[_random.nextInt(_quotes.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVeryLightBlue,
      body: RefreshIndicator(
        onRefresh: _fetchCourses,
        color: kPrimaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildCourseHeader(context),
              _buildCourseStatsSection(context),
              RecommendationSection(
                courses: _allCourses,
                isLoading: _isLoadingCourses,
                onStatsChanged: _fetchUserStats,
              ),
              CourseFilterAndListSection(
                courses: _getFilteredCoursesByStat(),
                isLoading: _isLoadingCourses,
                savedCourseIds: _savedCourseIds,
                onStatsChanged: _fetchUserStats,
              ),
              const Padding(padding: EdgeInsets.all(16.0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseHeader(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: topPadding + 20,
          bottom: 40,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000A26), Color(0xFF001759), Color(0xFF00207B)],
            stops: [0.0, 0.66, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLoading(width: 120, height: 28),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ShimmerLoading(width: 100, height: 100, borderRadius: 50),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: const ShimmerLoading(width: 200, height: 20),
            ),
          ],
        ),
      );
    }

    String username = 'User';
    ImageProvider? avatarImage;

    if (userProvider.userData != null) {
      String fullUsername = userProvider.userData!['username'] ?? 'User';
      List<String> nameParts = fullUsername.split(' ');
      username = nameParts.first.isNotEmpty ? nameParts.first : 'User';

      final firebaseAvatar = userProvider.userData!['avatar'];
      if (firebaseAvatar != null && firebaseAvatar.toString().isNotEmpty) {
        avatarImage = ImageHelper.getImageProvider(firebaseAvatar.toString());
      }
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: topPadding + 20,
            bottom: 40,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF000A26), Color(0xFF001759), Color(0xFF00207B)],
              stops: [0.0, 0.66, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Hi, $username',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: kVeryLightBlue,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child:
                          avatarImage != null
                              ? CircleAvatar(
                                radius: 50,
                                backgroundColor: kVeryLightBlue.withOpacity(
                                  0.2,
                                ),
                                backgroundImage: avatarImage,
                              )
                              : CircleAvatar(
                                radius: 50,
                                backgroundColor: kVeryLightBlue.withOpacity(
                                  0.2,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: kDarkBlue,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  _motivationalQuote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kVeryLightBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(35),
              bottomRight: Radius.circular(35),
            ),
            child: Opacity(
              opacity: 1,
              child: Image.asset(
                "assets/images/bg_titik.png",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildStatItem(
            context,
            iconPath: "assets/icons/ic_save.png",
            count: _savedCourses,
            label: "Save",
            isSelected: _activeStatFilter == "Save",
            onTap: () {
              setState(() {
                _activeStatFilter =
                    (_activeStatFilter == "Save") ? null : "Save";
              });
            },
          ),
          _buildStatItem(
            context,
            iconPath: "assets/icons/ic_finished.png",
            count: _finishedCourses,
            label: "Finished",
            isSelected: _activeStatFilter == "Finished",
            onTap: () {
              setState(() {
                _activeStatFilter =
                    (_activeStatFilter == "Finished") ? null : "Finished";
              });
            },
          ),
          _buildStatItem(
            context,
            iconPath: "assets/icons/ic_progress.png",
            count: _inProgressCourses,
            label: "In Progress",
            isSelected: _activeStatFilter == "In Progress",
            onTap: () {
              setState(() {
                _activeStatFilter =
                    (_activeStatFilter == "In Progress") ? null : "In Progress";
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String iconPath,
    required int count,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? kPrimaryBlue.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected ? Border.all(color: kPrimaryBlue, width: 1.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  isSelected ? kPrimaryBlue : kLightBlue.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.asset(
                  iconPath,
                  color: isSelected ? Colors.white : null,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.bookmark_border,
                      color: isSelected ? Colors.white : kPrimaryBlue,
                      size: 28,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? kPrimaryBlue : kDarkBlue,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? kPrimaryBlue : kDarkBlue.withOpacity(0.7),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecommendationSection extends StatefulWidget {
  final List<Map<String, dynamic>> courses;
  final bool isLoading;
  final VoidCallback? onStatsChanged;

  const RecommendationSection({
    super.key,
    required this.courses,
    this.isLoading = false,
    this.onStatsChanged,
  });

  @override
  State<RecommendationSection> createState() => _RecommendationSectionState();
}

class _RecommendationSectionState extends State<RecommendationSection> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final list = _getRecommendations();
      if (list.length <= 1) return;
      int nextPage = (_currentPage + 1) % list.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  List<Map<String, dynamic>> _getRecommendations() {
    if (widget.courses.isEmpty) return [];
    // Prioritaskan course yang isPopular atau top rating
    final popular = widget.courses.where((c) => c['isPopular'] == true).toList();
    if (popular.isNotEmpty) return popular;
    return widget.courses.take(3).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _getRecommendations();

    if (widget.isLoading && list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          height: 155,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: kPrimaryBlue),
          ),
        ),
      );
    }

    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Recommendation",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 155,
            child: PageView.builder(
              controller: _pageController,
              itemCount: list.length,
              onPageChanged: (int page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) {
                final course = list[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildRecommendationCard(course: course),
                );
              },
            ),
          ),
          if (list.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                list.length,
                (index) => _buildDot(index: index, total: list.length),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({
    required Map<String, dynamic> course,
  }) {
    final title = course['title']?.toString() ?? 'Featured Course';
    final price = course['price'] as num? ?? 0;
    final category = course['category']?.toString() ?? 'All Levels';
    final youtubeUrl = course['youtube_url']?.toString();
    final videoId = youtubeUrl != null ? extractYoutubeId(youtubeUrl) : null;
    final imageUrl = course['imageUrl']?.toString();
    final thumbnailUrl = videoId != null ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg' : null;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isPremiumAccount = userProvider.isPremium || SimulatedOrderService.isPremium;
    final bool isFree = price == 0;
    final bool canPlay = isFree || isPremiumAccount;
    // Ringkas label agar tidak overflow di device kecil
    final String statusLabel = isFree
        ? "Free"
        : (isPremiumAccount ? "Unlocked" : "Premium");

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              course: course,
              videoId: videoId,
            ),
          ),
        );
        if (mounted) {
          setState(() {});
          widget.onStatsChanged?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: kPrimaryBlue,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail dengan lebar tetap responsif 120-130 agar layout teks punya ruang maksimal
            SizedBox(
              width: 125,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnailUrl != null)
                      Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _buildAssetOrFallback(imageUrl),
                      )
                    else
                      _buildAssetOrFallback(imageUrl),
                    if (canPlay)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFree
                                  ? const Color(0xFF10B981)
                                  : (isPremiumAccount ? const Color(0xFF10B981) : Colors.amber),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isFree) ...[
                                  Icon(
                                    isPremiumAccount
                                        ? Icons.check_circle_rounded
                                        : Icons.workspace_premium,
                                    size: 11,
                                    color: isPremiumAccount ? Colors.white : kDarkBlue,
                                  ),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isFree
                                        ? Colors.white
                                        : (isPremiumAccount ? Colors.white : kDarkBlue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseDetailScreen(
                            course: course,
                            videoId: videoId,
                          ),
                        ),
                      );
                      if (mounted) {
          setState(() {});
          widget.onStatsChanged?.call();
        }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kVeryLightBlue,
                      foregroundColor: kPrimaryBlue,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    child: Text(canPlay ? "Play" : "View Course"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildAssetOrFallback(String? assetPath) {
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: kDarkBlue),
      );
    }
    return Container(color: kDarkBlue);
  }

  Widget _buildDot({required int index, required int total}) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? kPrimaryBlue : kLightBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

class CourseFilterAndListSection extends StatefulWidget {
  final List<Map<String, dynamic>> courses;
  final bool isLoading;
  final List<String> savedCourseIds;
  final VoidCallback? onStatsChanged;

  const CourseFilterAndListSection({
    super.key,
    required this.courses,
    this.isLoading = false,
    this.savedCourseIds = const [],
    this.onStatsChanged,
  });

  @override
  State<CourseFilterAndListSection> createState() =>
      _CourseFilterAndListSectionState();
}

class _CourseFilterAndListSectionState
    extends State<CourseFilterAndListSection> {
  String _selectedTypeFilter = "All Course";
  String _selectedLevelFilter = "All";
  List<Map<String, dynamic>> _filteredCourses = [];

  final GlobalKey _filterButtonKey = GlobalKey();
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  StreamSubscription? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _applyFilters();
    _orderSubscription = SimulatedOrderService.orderStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant CourseFilterAndListSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courses != widget.courses ||
        oldWidget.savedCourseIds != widget.savedCourseIds) {
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _removeDropdownOverlay();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      List<Map<String, dynamic>> temp = List.from(widget.courses);

      // 1. Type Filter: All Course / Popular / Premium / Free
      if (_selectedTypeFilter == "Popular") {
        temp = temp.where((c) =>
          (c['isPopular'] == true) ||
          ((c['rating'] as num? ?? 0) >= 4.5) ||
          (c['category']?.toString().toLowerCase() == 'popular')
        ).toList();
      } else if (_selectedTypeFilter == "Premium") {
        temp = temp.where((c) => (c['price'] as num? ?? 0) > 0).toList();
      } else if (_selectedTypeFilter == "Free") {
        temp = temp.where((c) => (c['price'] as num? ?? 0) == 0).toList();
      }

      // 2. Level Filter: All / Beginner / Intermediate / Expert
      if (_selectedLevelFilter != "All") {
        final target = _selectedLevelFilter.trim().toLowerCase();
        temp = temp.where((c) {
          final cat = (c['category'] ?? c['level'] ?? '').toString().trim().toLowerCase();
          return cat == target;
        }).toList();
      }

      _filteredCourses = temp;
    });
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _removeDropdownOverlay();
    } else {
      _showDropdownOverlay();
    }
    setState(() => _isDropdownOpen = !_isDropdownOpen);
  }

  void _removeDropdownOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDropdownOverlay() {
    final RenderBox renderBox =
        _filterButtonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 5,
            width: 150,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kLightBlue),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      <String>['All Course', 'Popular', 'Premium', 'Free']
                          .map(
                            (value) => ListTile(
                              title: Text(
                                value,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      _selectedTypeFilter == value
                                          ? kPrimaryBlue
                                          : kDarkBlue,
                                ),
                              ),
                              dense: true,
                              onTap: () {
                                setState(() {
                                  _selectedTypeFilter = value;
                                  _applyFilters();
                                });
                                _toggleDropdown();
                              },
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildLevelFilterButton(String title) {
    bool isActive = _selectedLevelFilter.toLowerCase() == title.toLowerCase();
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedLevelFilter = title;
          _applyFilters();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? kPrimaryBlue : kVeryLightBlue,
        foregroundColor: isActive ? Colors.white : kPrimaryBlue,
        elevation: isActive ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side:
              isActive
                  ? BorderSide.none
                  : const BorderSide(color: kPrimaryBlue, width: 1.5),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      child: Text(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                key: _filterButtonKey,
                onTap: _toggleDropdown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kVeryLightBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryBlue, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        color: kPrimaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedTypeFilter,
                        style: const TextStyle(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_selectedTypeFilter != "All Course") ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: kDarkBlue.withOpacity(0.6)),
                const SizedBox(width: 6),
                Text(
                  "Type filter active: $_selectedTypeFilter",
                  style: TextStyle(
                    fontSize: 12,
                    color: kDarkBlue.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTypeFilter = "All Course";
                      _applyFilters();
                    });
                  },
                  child: const Text(
                    "Clear",
                    style: TextStyle(
                      fontSize: 12,
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildLevelFilterButton("All"),
                const SizedBox(width: 8),
                _buildLevelFilterButton("Beginner"),
                const SizedBox(width: 8),
                _buildLevelFilterButton("Intermediate"),
                const SizedBox(width: 8),
                _buildLevelFilterButton("Expert"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (widget.isLoading && _filteredCourses.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: CourseListShimmer(),
            )
          else if (_filteredCourses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: kPrimaryBlue.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedLevelFilter == "All"
                          ? "No courses found"
                          : "No courses found for '$_selectedLevelFilter'",
                      style: TextStyle(
                        fontSize: 15,
                        color: kDarkBlue.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedTypeFilter = "All Course";
                          _selectedLevelFilter = "All";
                          _applyFilters();
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16, color: kPrimaryBlue),
                      label: const Text(
                        "Show All Courses",
                        style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.64,
              ),
              itemCount: _filteredCourses.length,
              itemBuilder: (context, index) {
                final course = _filteredCourses[index];
                return CourseCard(
                  course: course,
                  isSaved: widget.savedCourseIds
                      .contains(course['id']?.toString()),
                  onStatsChanged: widget.onStatsChanged,
                );
              },
            ),
        ],
      ),
    );
  }
}

class CourseCard extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isSaved;
  final VoidCallback? onStatsChanged;

  const CourseCard({
    super.key,
    required this.course,
    this.isSaved = false,
    this.onStatsChanged,
  });

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

  String _getYoutubeThumbnail(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.course['price'] as num? ?? 0;
    final String? assetImage = widget.course['imageUrl'] as String?;
    final String category = widget.course['category']?.toString() ?? 'General';
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isPremium = userProvider.isPremium || SimulatedOrderService.isPremium;

    return GestureDetector(
      onTap: () async {
        final canPlay = price == 0 || isPremium;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              course: widget.course,
              videoId: _videoId,
              ),
          ),
        );
        if (mounted) {
          setState(() {});
          widget.onStatsChanged?.call();
        }
      },
      child: Container(
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
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child:
                        _videoId != null
                            ? Image.network(
                              _getYoutubeThumbnail(_videoId!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAssetImage(assetImage);
                              },
                            )
                            : _buildAssetImage(assetImage),
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
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
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
                  if (price > 0 && isPremium)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
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
                            Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'UNLOCKED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  // Tombol Bookmark Kursus
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () async {
                        final courseId = widget.course['id']?.toString() ?? '';
                        if (courseId.isEmpty) return;
                        final nowSaved =
                            await FirebaseService.toggleSaveCourse(courseId);
                        widget.onStatsChanged?.call();
                        if (context.mounted) {
                          try {
                            Provider.of<UserProvider>(context, listen: false)
                                .refreshUser();
                          } catch (_) {}
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                nowSaved
                                    ? 'Kursus berhasil disimpan!'
                                    : 'Kursus dihapus dari bookmark.',
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                              duration: const Duration(seconds: 1),
                              backgroundColor:
                                  nowSaved ? kPrimaryBlue : Colors.grey[800],
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: Colors.amberAccent,
                          size: 20,
                        ),
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
                      widget.course['title'] ?? 'Course',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDarkBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kPrimaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
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
                                ? const Color(0xFF10B981).withOpacity(0.12)
                                : (isPremium
                                    ? const Color(0xFF10B981).withOpacity(0.12)
                                    : Colors.amber.withOpacity(0.2)),
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
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${widget.course['rating']} (${widget.course['reviewCount']})",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: kDarkBlue.withOpacity(0.7),
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

  Widget _buildAssetImage(String? assetPath) {
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        height: 110,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 110,
            color: kLightBlue.withOpacity(0.3),
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: kDarkBlue,
                size: 30,
              ),
            ),
          );
        },
      );
    }
    return Container(height: 110, color: kLightBlue);
  }
}

String? extractYoutubeId(String url) {
  final RegExp regExp = RegExp(
    r'(?:v=|\/)([0-9A-Za-z_-]{11}).*',
    caseSensitive: false,
    multiLine: false,
  );
  final match = regExp.firstMatch(url);
  return match?.group(1);
}

// Widget Dialog Terpisah untuk Menangani Siklus Hidup Video Player
class YouTubeDialog extends StatefulWidget {
  final String videoId;
  const YouTubeDialog({super.key, required this.videoId});

  @override
  State<YouTubeDialog> createState() => _YouTubeDialogState();
}

class _YouTubeDialogState extends State<YouTubeDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller HANYA ketika dialog dibuka
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        playsInline: true,
        origin: 'https://www.youtube-nocookie.com',
      ),
    );
  }

  @override
  void dispose() {
    // Sangat Penting: Hapus controller saat dialog ditutup
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                ),
              ),
            ),
          ),
          // Tombol Close di luar frame
          Positioned(
            top: -40,
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.black, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
