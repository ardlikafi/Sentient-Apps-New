import 'package:flutter/foundation.dart';
import 'package:sentient/firebase_service.dart';

class LikedProductsProvider with ChangeNotifier {
  List<String> _likedProductIds = [];
  bool _isLoading = false;

  List<String> get likedProductIds => _likedProductIds;
  bool get isLoading => _isLoading;

  LikedProductsProvider() {
    syncLikesWithFirebase();
  }

  Future<void> syncLikesWithFirebase() async {
    _isLoading = true;
    notifyListeners();

    final user = await FirebaseService.getCurrentUser();

    if (user != null && user['liked_products'] != null) {
      _likedProductIds = List<String>.from(user['liked_products']);
    } else {
      _likedProductIds = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  bool isLiked(String productId) {
    return _likedProductIds.contains(productId);
  }

  void toggleLike(String productId) async {
    if (FirebaseService.getCurrentUserId() == null) {
      print("Cannot like product. No user is logged in.");
      return;
    }

    final bool currentlyLiked = isLiked(productId);
    if (currentlyLiked) {
      _likedProductIds.remove(productId);
    } else {
      _likedProductIds.add(productId);
    }
    notifyListeners();

    try {
      if (currentlyLiked) {
        await FirebaseService.unlikeProduct(productId);
      } else {
        await FirebaseService.likeProduct(productId);
      }
    } catch (e) {
      print("Error toggling like: $e");
      if (currentlyLiked) {
        _likedProductIds.add(productId);
      } else {
        _likedProductIds.remove(productId);
      }
      notifyListeners();
    }
  }
}