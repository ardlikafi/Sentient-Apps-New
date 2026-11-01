import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedDatabase() async {
    print("Checking database status for seeding...");
    
    // Seed Courses
    final coursesSnapshot = await _firestore.collection('courses').limit(1).get();
    if (coursesSnapshot.docs.isEmpty) {
      print("Seeding Courses...");
      final courses = [
        {
          "id": "c1",
          "imageUrl": "assets/images/course1.png",
          "title": "Mastering Chess Fundamentals",
          "price": 100000,
          "rating": 4.5,
          "reviewCount": 50,
          "category": "Beginner", // Merged category for filtering
          "isPopular": true,
          "youtube_url": "https://www.youtube.com/watch?v=OCSbzArwB10",
          "description": "Learn the complete basics of chess with this comprehensive guide. Perfect for beginners who want to start their chess journey.",
        },
        {
          "id": "c2",
          "imageUrl": "assets/images/course2.png",
          "title": "Tactical Patterns & Strategy",
          "price": 270000,
          "rating": 4.8,
          "reviewCount": 75,
          "category": "Intermediate",
          "isPopular": true,
          "youtube_url": "https://www.youtube.com/watch?v=NAIQyoPcjNM",
          "description": "Master essential tactical patterns and strategic concepts to improve your game.",
        },
        {
          "id": "c3",
          "imageUrl": "assets/images/course3.png",
          "title": "Advanced Opening Repertoire",
          "price": 400000,
          "rating": 4.2,
          "reviewCount": 30,
          "category": "Expert",
          "isPopular": false,
          "youtube_url": "https://www.youtube.com/watch?v=W1gWHIpQNVU",
          "description": "Build a comprehensive master-level opening repertoire with deep strategic theory and competitive opening preparation.",
        },
        {
          "id": "c4",
          "imageUrl": "assets/images/course1.png",
          "title": "Free Basic Chess Rules",
          "price": 0,
          "rating": 4.0,
          "reviewCount": 120,
          "category": "Beginner",
          "isPopular": false,
          "youtube_url": "https://www.youtube.com/watch?v=Reza8udb47Y",
          "description": "Start your chess journey with this free course covering all the basic rules and concepts.",
        },
        {
          "id": "c5",
          "imageUrl": "assets/images/course2.png",
          "title": "Advanced Endgame Techniques",
          "price": 350000,
          "rating": 4.9,
          "reviewCount": 90,
          "category": "Expert",
          "isPopular": true,
          "youtube_url": "https://www.youtube.com/watch?v=MA8Scue28Ks",
          "description": "Master the art of endgame play with advanced techniques and strategies.",
        },
        {
          "id": "c6",
          "imageUrl": "assets/images/course4.png",
          "title": "Chess Tutorial by Sentient Society",
          "price": 0,
          "rating": 4.9,
          "reviewCount": 90,
          "category": "Intermediate",
          "isPopular": true,
          "youtube_url": "https://www.youtube.com/watch?v=dUZIJ-Z61eo",
          "description": "Master the art of endgame play with advanced techniques and strategies.",
        },
      ];
      for (var course in courses) {
        await _firestore.collection('courses').doc(course['id'] as String).set(course);
      }
      print("Courses seeded.");
    }

    // Seed Products
    final productsSnapshot = await _firestore.collection('products').limit(1).get();
    if (productsSnapshot.docs.isEmpty) {
      print("Seeding Products...");
      final products = [
        {
          "id": "p1",
          "imageUrl": "assets/images/product1.png",
          "name": "Beautiful Metal Chess Set",
          "subtitle": "Chess Board",
          "price": 99999,
          "category": "Chess",
          "description": "Experience a modern and premium feel with this metal chess set. Crafted with high precision, each piece has substantial weight and sharp details. Perfect for competitive play or as an elegant display in your workspace.",
        },
        {
          "id": "p2",
          "imageUrl": "assets/images/product2.png",
          "name": "Beautiful Handcrafted Wooden Chess Set",
          "subtitle": "Chess Board",
          "price": 149999,
          "category": "Chess",
          "description": "Return to classic roots with this handcrafted wooden chess set. Each piece is meticulously carved from Sheesham and Boxwood, providing a warm and authentic feel. A sturdy chess board completes this timeless set.",
        },
        {
          "id": "p3",
          "imageUrl": "assets/images/product3.png",
          "name": "Elegant Glass Chess Set",
          "subtitle": "Chess Board",
          "price": 199999,
          "category": "Chess",
          "description": "More than just a game, this glass chess set is a piece of art. Its transparent, minimalist design creates a stunning look on any table. Clear and frosted pieces provide a beautiful visual contrast.",
        },
        {
          "id": "p4",
          "imageUrl": "assets/images/product4.png",
          "name": "Luxurious Marble Chess Set",
          "subtitle": "Chess Board",
          "price": 129999,
          "category": "Chess",
          "description": "Elevate your playing experience with the luxury of a marble chess set. Each piece is polished from genuine marble stone, providing unmatched weight and texture. Natural stone patterns make every set unique.",
        },
        {
          "id": "p5",
          "imageUrl": "assets/images/product5.png",
          "name": "Chess Clock Digital Timer",
          "subtitle": "Chess Items",
          "price": 250000,
          "category": "Items",
          "description": "A reliable digital chess clock for serious players. Equipped with bonus and delay modes, meeting FIDE tournament standards. Easy to operate with a clear large display and responsive buttons for rapid play.",
        },
        {
          "id": "p6",
          "imageUrl": "assets/images/product6.png",
          "name": "Roll-Up Chess Board",
          "subtitle": "Chess Items",
          "price": 150000,
          "category": "Items",
          "description": "Take your chess game anywhere with this roll-up chess board. Made of durable, easy-to-clean high-quality vinyl or silicone. Lightweight and portable, ideal for chess clubs, tournaments, or casual play in the park.",
        },
      ];
      for (var product in products) {
        await _firestore.collection('products').doc(product['id'] as String).set(product);
      }
      print("Products seeded.");
    }

    // Seed Articles
    final articlesSnapshot = await _firestore.collection('articles').limit(1).get();
    if (articlesSnapshot.docs.isEmpty) {
      print("Seeding Articles...");
      final articles = [
        {
          "id": "a1",
          "imageUrl": "assets/images/article1.png",
          "title": "Learn Chess with a Mind of Its Own: The Sentient Chess Tutor",
          "summary": "Master the fundamentals of chess through interactive lessons, guided practice, and personalized AI feedback.",
          "date": "Mar 25, 2025",
          "source": "Chess.com Blog",
          "category": "Education",
          "author": "Sentient Writer",
        },
        {
          "id": "a2",
          "imageUrl": "assets/images/article2.png",
          "title": "Top 5 Openings for Beginners",
          "summary": "Discover the most effective and easy-to-learn chess openings to start your games.",
          "date": "Mar 10, 2025",
          "source": "Lichess Org",
          "category": "Openings",
          "author": "Lichess Team",
        },
        {
          "id": "a3",
          "imageUrl": "assets/images/article3.png",
          "title": "Understanding Middlegame Pawn Structures",
          "summary": "A deep dive into how pawn structures can dictate your middlegame strategy and plans.",
          "date": "Mar 05, 2025",
          "source": "ChessBase News",
          "category": "Strategy",
          "author": "Sam Copeland",
        },
        {
          "id": "a4",
          "imageUrl": "assets/images/article4.png",
          "title": "The Art of a Kingside Attack",
          "summary": "Learn key patterns and ideas for launching a successful attack on your opponent's king.",
          "date": "Feb 28, 2025",
          "source": "The Week in Chess",
          "category": "Tactics",
          "author": "Colin Stapczynski",
        },
        {
          "id": "a5",
          "imageUrl": "assets/images/article5.png",
          "title": "How to Analyze Your Chess Games",
          "summary": "Improve your chess by effectively analyzing your past games, identifying mistakes and good moves.",
          "date": "Feb 20, 2025",
          "source": "Chessable",
          "category": "Improvement",
          "author": "Pedro Pinhata",
        },
        {
          "id": "a6",
          "imageUrl": "assets/images/article6.png",
          "title": "Introduction to Chess Variants",
          "summary": "Explore fun and exciting chess variants like Crazyhouse, Bughouse, and Atomic chess.",
          "date": "Feb 15, 2025",
          "source": "Chess Variants Org",
          "category": "Variants",
          "author": "Various",
        },
      ];
      for (var article in articles) {
        await _firestore.collection('articles').doc(article['id'] as String).set(article);
      }
      print("Articles seeded.");
    }
  }
}
