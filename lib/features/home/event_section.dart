import 'package:flutter/material.dart';
import 'dart:async';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);
const Color kGradientStartBlue = Color(0xFF000A26);
const Color kGradientEndBlue = Color(0xFF0A3D91);


// EventSection Widget (Tetap sama)
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
      if (!mounted || !_pageController.hasClients) return;
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
                if (mounted) {
                  setState(() {
                    _currentPage = page;
                  });
                }
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
                  print("Error loading event image: ${event['imageUrl']}");
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
                  onPressed: () {
                    /* TODO: Implement event action */
                  },
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

