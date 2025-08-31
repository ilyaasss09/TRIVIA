import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/question.dart';
import '../models/score.dart';
import '../services/database_service.dart';

class GameProvider with ChangeNotifier {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = false;
  String _selectedCategory = '';
  String _selectedDifficulty = '';
  List<Score> _leaderboard = [];
  Timer? _timer;
  int _timeLeft = 10;
  bool _isGameActive = false;
  int? _selectedAnswer;
  bool _isAnswered = false;
  
  // Track answers for each question
  List<int?> _questionAnswers = [];

  // Getterlar
  List<Question> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get selectedDifficulty => _selectedDifficulty;
  List<Score> get leaderboard => _leaderboard;
  int get timeLeft => _timeLeft;
  bool get isGameActive => _isGameActive;
  int? get selectedAnswer => _selectedAnswer;
  bool get isAnswered => _isAnswered;

  // Yeni eklenen getterlar:
  int get totalQuestions => _questions.length;

  // Doğru cevap sayısını hesaplayan getter
  int get correctAnswers {
    int correctCount = 0;
    for (int i = 0; i < _questionAnswers.length; i++) {
      if (i < _questions.length && _questionAnswers[i] != null) {
        if (_questions[i].correctAnswer == _questionAnswers[i]) {
          correctCount++;
        }
      }
    }
    return correctCount;
  }

  // Kategori ve zorluk seçenekleri
  static const List<String> categories = [
    'History', 'Geography', 'Sports', 'Science', 'Art', 'Literature', 'Technology', 'General Knowledge'
  ];
  static const List<String> difficulties = ['Easy', 'Medium', 'Hard'];

  Future<void> loadQuestions(String category, String difficulty) async {
    _isLoading = true;
    _selectedCategory = category;
    _selectedDifficulty = difficulty;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://opentdb.com/api.php?amount=10&category=${_getCategoryId(category)}&difficulty=${_getDifficultyString(difficulty)}&type=multiple&encode=url3986'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['response_code'] == 0) {
          _questions = (data['results'] as List).map<Question>((questionData) {
            final correctAnswer = Uri.decodeComponent(questionData['correct_answer']);
            final incorrectAnswers = (questionData['incorrect_answers'] as List)
                .map((o) => Uri.decodeComponent(o as String))
                .toList();
            final options = List<String>.from(incorrectAnswers)..add(correctAnswer);
            options.shuffle();
            return Question(
              question: Uri.decodeComponent(questionData['question']),
              options: options,
              correctAnswer: options.indexOf(correctAnswer),
              category: category,
              difficulty: difficulty,
              points: _getPointsForDifficulty(difficulty),
            );
          }).toList();
        } else {
          _questions = _getSampleQuestions(category, difficulty);
        }
      } else {
        _questions = _getSampleQuestions(category, difficulty);
      }
    } catch (e) {
      _questions = _getSampleQuestions(category, difficulty);
    }

    _isLoading = false;
    _currentQuestionIndex = 0;
    _score = 0;
    _timeLeft = 10;
    _isGameActive = true;
    _selectedAnswer = null;
    _isAnswered = false;
    _questionAnswers = List.filled(_questions.length, null);
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        answerQuestion(-1);
      }
    });
  }

  void answerQuestion(int selectedAnswer) {
    if (!_isGameActive || _questions.isEmpty || _currentQuestionIndex >= _questions.length) return;

    _timer?.cancel();
    _isGameActive = false;
    _selectedAnswer = selectedAnswer;
    _isAnswered = true;
    
    // Save the answer for this question
    if (_currentQuestionIndex < _questions.length) {
      _questionAnswers[_currentQuestionIndex] = selectedAnswer;
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    bool isCorrect = selectedAnswer == currentQuestion.correctAnswer;

    if (isCorrect) {
      _score += currentQuestion.points;
    }

    notifyListeners();

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _timeLeft = 10;
        _isGameActive = true;
        _selectedAnswer = null;
        _isAnswered = false;
        _startTimer();
        notifyListeners();
      } else {
        // Oyun bitti - skor kaydedilmeli
        _isGameActive = false;
        _selectedAnswer = null;
        _isAnswered = false;
        _timer?.cancel();
        _currentQuestionIndex = _questions.length;
        
        print('GameProvider: Game finished! Final score: $_score');
        print('GameProvider: Category: $_selectedCategory, Difficulty: $_selectedDifficulty');
        
        notifyListeners();
      }
    });
  }

  Future<void> saveScore(String username) async {
    try {
      print('GameProvider: ===== SAVE SCORE START =====');
      print('GameProvider: Starting to save score for $username');
      print('GameProvider: Score: $_score, Category: $_selectedCategory, Difficulty: $_selectedDifficulty');
      
      // Kategori ve zorluk bilgilerini kontrol et
      if (_selectedCategory.isEmpty || _selectedDifficulty.isEmpty) {
        print('GameProvider: ERROR - Category or difficulty is empty!');
        print('GameProvider: Category: "$_selectedCategory", Difficulty: "$_selectedDifficulty"');
        
        // Eğer kategori/zorluk bilgisi yoksa, son oyundan al
        if (_questions.isNotEmpty) {
          final lastQuestion = _questions.last;
          _selectedCategory = lastQuestion.category;
          _selectedDifficulty = lastQuestion.difficulty;
          print('GameProvider: Recovered category and difficulty from last question: $_selectedCategory, $_selectedDifficulty');
        } else {
          throw Exception('Category or difficulty information is missing and cannot be recovered');
        }
      }
      
      final score = Score(
        username: username,
        score: _score,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      print('GameProvider: Created score object: $score');

      final databaseService = DatabaseService();
      await databaseService.saveScore(score);
      
      print('GameProvider: Score saved to database successfully');
      
      // Leaderboard'u hemen güncelle
      await loadLeaderboard();
      
      print('GameProvider: Leaderboard updated after saving score');
      print('GameProvider: Current leaderboard has ${_leaderboard.length} scores');
      print('GameProvider: ===== SAVE SCORE END =====');
      
    } catch (e) {
      print('GameProvider: SaveScore error: $e');
      
      // Fallback: Doğrudan database service'e kaydet
      try {
        print('GameProvider: Attempting fallback save method...');
        final fallbackScore = Score(
          username: username,
          score: _score,
          category: _selectedCategory.isNotEmpty ? _selectedCategory : 'Unknown',
          difficulty: _selectedDifficulty.isNotEmpty ? _selectedDifficulty : 'Unknown',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        
        final databaseService = DatabaseService();
        await databaseService.saveScore(fallbackScore);
        print('GameProvider: Fallback save successful');
        
        // Leaderboard'u güncelle
        await loadLeaderboard();
        
      } catch (fallbackError) {
        print('GameProvider: Fallback save also failed: $fallbackError');
        rethrow;
      }
    }
  }

  Future<void> saveScoreToLeaderboard(int score) async {
    try {
      print('GameProvider: Starting to save score to leaderboard: $score');
      print('GameProvider: Category: $_selectedCategory, Difficulty: $_selectedDifficulty');
      
      if (_selectedCategory.isEmpty || _selectedDifficulty.isEmpty) {
        print('GameProvider: ERROR - Category or difficulty is empty!');
        throw Exception('Category or difficulty information is missing');
      }
      
      final scoreEntry = Score(
        username: 'Guest',
        score: score,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      print('GameProvider: Created score entry: $scoreEntry');

      final databaseService = DatabaseService();
      await databaseService.saveScore(scoreEntry);
      
      print('GameProvider: Score saved to leaderboard successfully');
      
      // Leaderboard'u hemen güncelle
      await loadLeaderboard();
      
      print('GameProvider: Leaderboard updated after saving to leaderboard');
      print('GameProvider: Current leaderboard has ${_leaderboard.length} scores');
      
    } catch (e) {
      print('GameProvider: SaveScoreToLeaderboard error: $e');
      rethrow;
    }
  }

  Future<void> loadLeaderboard() async {
    try {
      print('GameProvider: Loading leaderboard from database...');
      final databaseService = DatabaseService();
      _leaderboard = await databaseService.getAllScores();
      
      print('GameProvider: Leaderboard loaded successfully');
      print('GameProvider: Found ${_leaderboard.length} scores');
      
      // Debug: Print first few scores
      if (_leaderboard.isNotEmpty) {
        print('GameProvider: Top scores in leaderboard:');
        for (int i = 0; i < (_leaderboard.length > 3 ? 3 : _leaderboard.length); i++) {
          print('  ${i + 1}. ${_leaderboard[i].username}: ${_leaderboard[i].score} points (${_leaderboard[i].category} - ${_leaderboard[i].difficulty})');
        }
      } else {
        print('GameProvider: No scores found in leaderboard');
      }
      
      notifyListeners();
    } catch (e) {
      print('GameProvider: LoadLeaderboard error: $e');
      _leaderboard = [];
      notifyListeners();
    }
  }

  void resetGame() {
    print('GameProvider: Resetting game...');
    print('GameProvider: Previous score: $_score, Category: $_selectedCategory, Difficulty: $_selectedDifficulty');
    
    _questions = [];
    _currentQuestionIndex = 0;
    _score = 0;
    _timeLeft = 10;
    _isGameActive = false;
    _selectedAnswer = null;
    _isAnswered = false;
    _questionAnswers = [];
    _timer?.cancel();
    notifyListeners();
    
    print('GameProvider: Game reset complete');
  }

  // Kategori ve zorluk bilgilerini temizlemek için ayrı metod
  void clearCategoryAndDifficulty() {
    print('GameProvider: Clearing category and difficulty information');
    _selectedCategory = '';
    _selectedDifficulty = '';
    notifyListeners();
  }

  int _getPointsForDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 10;
      case 'medium':
        return 20;
      case 'hard':
        return 30;
      default:
        return 10;
    }
  }

  String _getDifficultyString(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'easy';
      case 'medium':
        return 'medium';
      case 'hard':
        return 'hard';
      default:
        return 'easy';
    }
  }

  int _getCategoryId(String category) {
    switch (category.toLowerCase()) {
      case 'history':
        return 23;
      case 'geography':
        return 22;
      case 'sports':
        return 21;
      case 'science':
        return 17;
      case 'art':
        return 25;
      case 'literature':
        return 10;
      case 'technology':
        return 18;
      case 'general knowledge':
        return 9;
      default:
        return 9;
    }
  }

  List<Question> _getSampleQuestions(String category, String difficulty) {
    return [
      Question(
        question: 'What is the capital of France?',
        options: ['London', 'Berlin', 'Paris', 'Madrid'],
        correctAnswer: 2,
        category: category,
        difficulty: difficulty,
        points: _getPointsForDifficulty(difficulty),
      ),
      Question(
        question: 'Which planet is known as the Red Planet?',
        options: ['Earth', 'Mars', 'Jupiter', 'Venus'],
        correctAnswer: 1,
        category: category,
        difficulty: difficulty,
        points: _getPointsForDifficulty(difficulty),
      ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
