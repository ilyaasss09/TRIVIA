import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../models/score.dart';
import '../services/database_service.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final String category;
  final String difficulty;

  const ResultScreen({
    super.key, 
    required this.score, 
    required this.category, 
    required this.difficulty
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  bool _scoreSaved = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scoreSaved = false; // Her yeni ekran açılışında flag'i sıfırla
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
    
    // Skoru hemen kaydet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveScoreToDatabase();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Eğer ekran tekrar açılırsa flag'i sıfırla
    _scoreSaved = false;
  }

  Future<void> _saveScoreToDatabase() async {
    // Eğer skor zaten kaydedildiyse, tekrar kaydetme
    if (_scoreSaved) {
      print('ResultScreen: Score already saved, skipping...');
      return;
    }
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final username = userProvider.username.isNotEmpty ? userProvider.username : "Guest";
      
      print('ResultScreen: Starting to save score for $username');
      print('ResultScreen: Score: ${widget.score}, Category: ${widget.category}, Difficulty: ${widget.difficulty}');
      
      // İlk deneme: Game provider üzerinden skoru kaydet
      try {
        await gameProvider.saveScore(username);
        print('ResultScreen: Score saved through game provider successfully');
      } catch (e) {
        print('ResultScreen: Game provider save failed: $e');
        
        // İkinci deneme: Doğrudan database service'e kaydet
        try {
          print('ResultScreen: Attempting direct database save...');
          final score = Score(
            username: username,
            score: widget.score,
            category: widget.category,
            difficulty: widget.difficulty,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          
          final databaseService = DatabaseService();
          await databaseService.saveScore(score);
          print('ResultScreen: Direct database save successful');
          
          // Leaderboard'u güncelle
          await gameProvider.loadLeaderboard();
          
        } catch (directError) {
          print('ResultScreen: Direct database save also failed: $directError');
          rethrow;
        }
      }
      
      // Skor kaydedildi bildirimi kaldırıldı
      
      setState(() {
        _scoreSaved = true;
      });
      
      // Skor kaydedildikten sonra oyunu reset et
      Future.delayed(const Duration(seconds: 1), () {
        gameProvider.resetGame();
        // Kategori ve zorluk bilgilerini temizle
        gameProvider.clearCategoryAndDifficulty();
        print('ResultScreen: Game reset and category/difficulty cleared after score save');
      });
      
    } catch (e) {
      print('ResultScreen: All score save methods failed: $e');
      
      // Kullanıcıya hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Skor kaydedilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Hata durumunda da oyunu reset et
      Future.delayed(const Duration(seconds: 1), () {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        gameProvider.resetGame();
        // Kategori ve zorluk bilgilerini temizle
        gameProvider.clearCategoryAndDifficulty();
        print('ResultScreen: Game reset and category/difficulty cleared after score save error');
      });
    }
  }

  String _getPerformanceMessage() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final correctAnswers = gameProvider.correctAnswers;
    final totalQuestions = gameProvider.totalQuestions;
    final percentage = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;
    
    if (percentage >= 90) return "Mükemmel! Harika bir performans! 🎉";
    if (percentage >= 80) return "Çok iyi! Güzel bir skor! 👏";
    if (percentage >= 70) return "İyi! Daha da geliştirebilirsin! 👍";
    if (percentage >= 60) return "Orta! Biraz daha çalışman gerek! 💪";
    if (percentage >= 50) return "Geçer! Daha iyisini yapabilirsin! 💪";
    return "Daha iyisini yapabilirsin! Çalışmaya devam et! 💪";
  }

  Color _getScoreColor() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final correctAnswers = gameProvider.correctAnswers;
    final totalQuestions = gameProvider.totalQuestions;
    final percentage = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;
    
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final correctAnswers = gameProvider.correctAnswers;
    final totalQuestions = gameProvider.totalQuestions;
    final percentage = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getScoreColor().withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: _getScoreColor(),
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Oyun Sonucu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getScoreColor(),
                              _getScoreColor().withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Score Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  percentage >= 80 ? Icons.emoji_events : 
                                  percentage >= 60 ? Icons.star : Icons.psychology,
                                  size: 80,
                                  color: _getScoreColor(),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '${widget.score} Puan',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _getPerformanceMessage(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Statistics Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Detaylı İstatistikler',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildStatRow('Kategori', widget.category, Icons.category),
                                _buildStatRow('Zorluk', widget.difficulty, Icons.trending_up),
                                _buildStatRow('Doğru Cevap', '$correctAnswers / $totalQuestions', Icons.check_circle),
                                _buildStatRow('Başarı Oranı', '%${percentage.toStringAsFixed(1)}', Icons.analytics),
                                _buildStatRow('Zaman', '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}', Icons.access_time),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Action Buttons
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getScoreColor(),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 5,
                                  ),
                                  onPressed: () {
                                    gameProvider.resetGame();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Ana Menüye Dön',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: _getScoreColor(),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(color: _getScoreColor(), width: 2),
                                    ),
                                    elevation: 3,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LeaderboardScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Liderlik Tablosu',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: _getScoreColor(), size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
