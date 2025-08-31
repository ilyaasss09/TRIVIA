import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/database_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = false;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('LeaderboardScreen: Starting to load leaderboard');
      
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      await gameProvider.loadLeaderboard();
      
      print('LeaderboardScreen: Leaderboard loaded successfully');
      print('LeaderboardScreen: Found ${gameProvider.leaderboard.length} scores');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Liderlik tablosu güncellendi: ${gameProvider.leaderboard.length} skor bulundu'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('LeaderboardScreen: Error loading leaderboard: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Liderlik tablosu yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetDatabase() async {
    setState(() {
      _isResetting = true;
    });

    try {
      print('LeaderboardScreen: Starting database reset...');
      
      final databaseService = DatabaseService();
      await databaseService.resetDatabase();
      
      print('LeaderboardScreen: Database reset successful');
      
      // Leaderboard'u yeniden yükle
      await _loadLeaderboard();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veritabanı sıfırlandı ve test verileri eklendi!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('LeaderboardScreen: Error resetting database: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veritabanı sıfırlanırken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Liderlik Tablosu"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLeaderboard,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _isResetting ? null : _resetDatabase,
            tooltip: 'Veritabanını Sıfırla',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                final scores = gameProvider.leaderboard;

                if (scores.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Henüz kayıtlı skor yok",
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "İlk skorunuzu yapmak için oyun oynayın!",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _resetDatabase,
                          icon: const Icon(Icons.add),
                          label: const Text('Test Verileri Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Header with score count
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.green.withOpacity(0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Toplam ${scores.length} skor',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'En Yüksek: ${scores.isNotEmpty ? scores.first.score : 0} puan',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Scores list
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: scores.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final score = scores[index];
                          final isTop3 = index < 3;
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isTop3 
                                  ? (index == 0 ? Colors.amber : index == 1 ? Colors.grey : Colors.brown)
                                  : Colors.blue,
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: isTop3 ? Colors.white : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              "${score.username} - ${score.score} puan",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                                color: isTop3 ? Colors.black87 : Colors.black54,
                              ),
                            ),
                            subtitle: Text(
                              "${score.category} • ${score.difficulty}",
                              style: TextStyle(
                                color: isTop3 ? Colors.black54 : Colors.black38,
                              ),
                            ),
                            trailing: Text(
                              _formatTimestamp(score.timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }
}
