import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'package:sentient/core/utils/image_helper.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);
const Color kGradientStartBlue = Color(0xFF000A26);
const Color kGradientEndBlue = Color(0xFF0A3D91);


class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});
  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _greeting = "";

  @override
  void initState() {
    super.initState();
    _updateGreeting();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final userProvider = Provider.of<UserProvider>(context);

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

    return Container(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: topPadding + 16.0,
        bottom: 24.0,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kGradientStartBlue, kGradientEndBlue],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: kLightBlue.withValues(alpha: 0.5),
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? const Icon(Icons.person, size: 32, color: kDarkBlue)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greeting,
                  style: TextStyle(
                    color: kVeryLightBlue.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$username!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (userProvider.userData?['email'] != null)
                  Text(
                    userProvider.userData!['email'],
                    style: TextStyle(
                      fontSize: 13,
                      color: kVeryLightBlue.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

