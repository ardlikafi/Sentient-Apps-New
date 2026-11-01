import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentient/features/chess/models/chess_player_stats.dart';

class ChessStatsService {
  static const String _storageKey = 'sentient_chess_player_stats_v2';

  /// Mengambil data statistik karir catur pengguna
  static Future<ChessPlayerStats> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final stats = ChessPlayerStats.fromMap(map);
        // Pastikan tidak ada sisa dummy bot percobaan
        final hasDummy = stats.recentMatches.any(
          (m) => m.opponent.contains('Ahmad Rizky') || m.opponent.contains('Sentient Bot (Med)'),
        );
        if (!hasDummy) {
          return stats;
        }
      }
    } catch (e) {
      // ignore
    }

    // Default starter stats jika belum pernah ada (murni 0)
    final initial = ChessPlayerStats.starterDefault();
    await saveStats(initial);
    return initial;
  }

  /// Reset seluruh statistik kembali ke 0 (misalnya setelah masa pengujian / testing)
  static Future<void> resetStats() async {
    final initial = ChessPlayerStats.starterDefault();
    await saveStats(initial);
  }

  /// Menyimpan statistik lokal dan cloud
  static Future<void> saveStats(ChessPlayerStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(stats.toMap());
      await prefs.setString(_storageKey, encoded);

      // Sinkronkan ke Firestore jika user login
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

        // Update fields di dokumen root user agar mudah di-query untuk leaderboard
        userDoc.set({
          'chess_online_wins': stats.onlineWins,
          'chess_online_games': stats.onlineGames,
          'chess_online_losses': stats.onlineLosses,
          'chess_online_draws': stats.onlineDraws,
          'chess_online_win_rate': stats.onlineWinRate,
          'chess_offline_wins': stats.offlineWins,
          'chess_offline_games': stats.offlineGames,
          'chess_offline_losses': stats.offlineLosses,
          'chess_offline_draws': stats.offlineDraws,
          'chess_offline_win_rate': stats.offlineWinRate,
          'chess_wins': stats.wins,
          'chess_total_games': stats.totalGames,
          'chess_win_rate': stats.winRate,
          'chess_accuracy': stats.averageAccuracy,
          'chess_streak': stats.currentStreak,
          'chess_title': stats.playerTitle,
          'chess_last_played': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).catchError((_) {});

        userDoc
            .collection('chess_meta')
            .doc('career_stats')
            .set(stats.toMap(), SetOptions(merge: true))
            .catchError((_) {});
      }
    } catch (e) {
      // ignore
    }
  }

  /// Mencatat hasil pertandingan catur yang baru saja selesai
  static Future<void> recordMatchResult({
    required String opponent,
    required String result, // 'win', 'loss', 'draw'
    required int movesCount,
    required double accuracy,
    required String mode,
    int blunders = 0,
    int goodMoves = 0,
    int brilliantMoves = 0,
    int normalMoves = 0,
  }) async {
    try {
      final current = await getStats();

      final isOnline = mode.toLowerCase().contains('online');

      final newTotalGames = current.totalGames + 1;
      final newWins = current.wins + (result == 'win' ? 1 : 0);
      final newLosses = current.losses + (result == 'loss' ? 1 : 0);
      final newDraws = current.draws + (result == 'draw' ? 1 : 0);

      // Pisahkan statistik match Online vs Latihan (Bot / Teman Lokal)
      final newOnlineGames = current.onlineGames + (isOnline ? 1 : 0);
      final newOnlineWins = current.onlineWins + (isOnline && result == 'win' ? 1 : 0);
      final newOnlineLosses = current.onlineLosses + (isOnline && result == 'loss' ? 1 : 0);
      final newOnlineDraws = current.onlineDraws + (isOnline && result == 'draw' ? 1 : 0);

      final newOfflineGames = current.offlineGames + (!isOnline ? 1 : 0);
      final newOfflineWins = current.offlineWins + (!isOnline && result == 'win' ? 1 : 0);
      final newOfflineLosses = current.offlineLosses + (!isOnline && result == 'loss' ? 1 : 0);
      final newOfflineDraws = current.offlineDraws + (!isOnline && result == 'draw' ? 1 : 0);

      final newStreak = result == 'win' ? (current.currentStreak + 1) : 0;
      final newBestStreak = newStreak > current.bestStreak ? newStreak : current.bestStreak;

      // Hitung running average akurasi
      final totalAccSoFar = (current.averageAccuracy * current.totalGames) + accuracy;
      final newAvgAccuracy = double.parse((totalAccSoFar / newTotalGames).toStringAsFixed(1));

      int newFastestMate = current.fastestMateMoves;
      if (result == 'win' && movesCount > 0) {
        if (newFastestMate == 0 || movesCount < newFastestMate) {
          newFastestMate = movesCount;
        }
      }

      final now = DateTime.now();
      final dateStr = '${now.day}/${now.month}/${now.year}';

      final newRecord = ChessMatchRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        opponent: opponent,
        result: result,
        movesCount: movesCount,
        accuracy: accuracy,
        date: dateStr,
        mode: mode,
      );

      final updatedMatches = [newRecord, ...current.recentMatches];
      if (updatedMatches.length > 10) {
        updatedMatches.removeRange(10, updatedMatches.length);
      }

      final updated = ChessPlayerStats(
        totalGames: newTotalGames,
        wins: newWins,
        losses: newLosses,
        draws: newDraws,
        onlineGames: newOnlineGames,
        onlineWins: newOnlineWins,
        onlineLosses: newOnlineLosses,
        onlineDraws: newOnlineDraws,
        offlineGames: newOfflineGames,
        offlineWins: newOfflineWins,
        offlineLosses: newOfflineLosses,
        offlineDraws: newOfflineDraws,
        currentStreak: newStreak,
        bestStreak: newBestStreak,
        averageAccuracy: newAvgAccuracy,
        brilliantMoves: current.brilliantMoves + brilliantMoves,
        goodMoves: current.goodMoves + goodMoves,
        normalMoves: current.normalMoves + normalMoves,
        blunders: current.blunders + blunders,
        fastestMateMoves: newFastestMate,
        recentMatches: updatedMatches,
      );

      await saveStats(updated);
    } catch (e) {
      // ignore
    }
  }
}
