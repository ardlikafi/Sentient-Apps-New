import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'course_screen.dart'; // To access YouTubeDialog

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

const Color kAppBarGradientStart = Color(0xFF000A26);
const Color kAppBarGradientMid = Color(0xFF001759);
const Color kAppBarGradientEnd = Color(0xFF00207B);



class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final String? videoId;

  const CourseDetailScreen({super.key, required this.course, this.videoId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final double imageHeight = 280.0;
  final double contentOverlap = 30.0;

  bool _hasBought = false;

  void _simulatePurchase() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Processing Payment...'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Simulating transaction...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Tutup dialog loading
      setState(() {
        _hasBought = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase Successful! You can now watch the course.'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _playVideo() {
    if (widget.videoId != null) {
      showDialog(
        context: context,
        builder: (context) => YouTubeDialog(videoId: widget.videoId!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video is not available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.course['price'] as num? ?? 0;
    final isFree = price == 0;
    final canPlay = isFree || _hasBought;

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
          "Course Detail",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: kPrimaryBlue.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 20),
                onPressed: () {},
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
          _buildHeaderImage(context),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: imageHeight - contentOverlap),
                Container(
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
                    child: _buildCourseContent(canPlay, price),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(BuildContext context) {
    final String imageUrl = widget.course['imageUrl'] ?? 'assets/images/course1.png';

    return SizedBox(
      height: imageHeight,
      width: double.infinity,
      child: Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: kDarkBlue),
      ),
    );
  }

  Widget _buildCourseContent(bool canPlay, num price) {
    final String title = widget.course['title'] ?? 'No Title';
    final String instructorName = widget.course['instructorName'] ?? 'Unknown Instructor';
    final String instructorAvatar = widget.course['instructorAvatar'] ?? 'assets/images/sven.png';
    final String instructorSubtitle = widget.course['instructorSubtitle'] ?? 'Pro Player';
    final int lessonCount = widget.course['lessonCount'] ?? 0;
    final String totalDuration = widget.course['totalDuration'] ?? '0h 0m';
    final String description = widget.course['description'] ?? 'No description available.';
    final List<Map<String, dynamic>> lessons = List<Map<String, dynamic>>.from(widget.course['lessons'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kDarkBlue)),
            ),
            if (price > 0 && !canPlay)
              Text("Rp. ${NumberFormat.decimalPattern('id_ID').format(price)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
            if (price == 0)
              const Text("Free", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(instructorAvatar),
              onBackgroundImageError: (e, s) => const Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(instructorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDarkBlue)),
                Text(instructorSubtitle, style: TextStyle(fontSize: 14, color: kDarkBlue.withOpacity(0.7))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildInfoChip(Icons.library_books_outlined, '$lessonCount Lessons'),
            const SizedBox(width: 12),
            _buildInfoChip(Icons.timer_outlined, totalDuration),
          ],
        ),
        const SizedBox(height: 24),
        Text(description, style: TextStyle(fontSize: 15, color: kDarkBlue.withOpacity(0.8), height: 1.5)),
        const SizedBox(height: 24),
        
        // Buy / Play Full Course Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: canPlay ? _playVideo : _simulatePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
            ),
            child: Text(
              canPlay ? "Play Full Course" : "Buy Course",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Lessons", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue)),
            Text("(${lessons.length} videos)", style: TextStyle(fontSize: 14, color: kDarkBlue.withOpacity(0.7))),
          ],
        ),
        const SizedBox(height: 16),
        if (lessons.isEmpty) 
          _buildLessonItem(
            title: 'Full Course Recording',
            duration: totalDuration,
            thumbnail: widget.course['imageUrl'] ?? 'assets/images/lesson1.png',
            isLocked: !canPlay,
            onTap: () => canPlay ? _playVideo() : _simulatePurchase(),
          ),
        if (lessons.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lessons.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return _buildLessonItem(
                title: lesson['title'] ?? 'Lesson ${index + 1}',
                duration: lesson['duration'] ?? 'N/A',
                thumbnail: lesson['thumbnail'] ?? 'assets/images/lesson1.png',
                isLocked: !canPlay && (lesson['isLocked'] ?? true),
                onTap: () {
                  if (canPlay || !(lesson['isLocked'] ?? true)) {
                    _playVideo();
                  } else {
                    _simulatePurchase();
                  }
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryBlue, size: 20),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: kDarkBlue.withOpacity(0.8), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildLessonItem({
    required String title,
    required String duration,
    required String thumbnail,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kLightBlue.withOpacity(0.4),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                thumbnail,
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(width: 80, height: 60, color: kLightBlue, child: const Icon(Icons.video_camera_back_outlined)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kDarkBlue)),
                  const SizedBox(height: 4),
                  Text(duration, style: TextStyle(fontSize: 13, color: kDarkBlue.withOpacity(0.7))),
                ],
              ),
            ),
            isLocked
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kVeryLightBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimaryBlue),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: kPrimaryBlue, size: 18),
                  SizedBox(width: 6),
                  Text("Buy", style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            )
                : ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
              label: const Text("Play"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}