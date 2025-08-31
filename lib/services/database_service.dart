import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/score.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'trivia_scores.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      print('DatabaseService: Initializing database...');
      
      // Masaüstü için sqflite_common_ffi başlatılır
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        print('DatabaseService: Platform detected: ${Platform.operatingSystem}');
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print('DatabaseService: sqflite_common_ffi initialized');
      }

      String databasePath;
      if (Platform.isWindows) {
        // Windows için özel yol - kullanıcının belgeler klasörü
        final documentsPath = await _getWindowsDocumentsPath();
        databasePath = join(documentsPath, _databaseName);
        print('DatabaseService: Windows database path: $databasePath');
      } else {
        databasePath = join(await getDatabasesPath(), _databaseName);
        print('DatabaseService: Standard database path: $databasePath');
      }

      print('DatabaseService: Opening database at: $databasePath');
      
      final db = await openDatabase(
        databasePath,
        version: 1,
        onCreate: _createDatabase,
        onOpen: (db) {
          print('DatabaseService: Database opened successfully');
        },
      );
      
      print('DatabaseService: Database initialization complete');
      return db;
      
    } catch (e, stackTrace) {
      print('DatabaseService: ERROR initializing database: $e');
      print('DatabaseService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<String> _getWindowsDocumentsPath() async {
    try {
      // Windows için belgeler klasörünü al
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final documentsPath = join(userProfile, 'Documents', 'TriviaApp');
        // Klasörü oluştur
        final dir = Directory(documentsPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          print('DatabaseService: Created documents directory: $documentsPath');
        }
        return documentsPath;
      }
      throw Exception('USERPROFILE environment variable not found');
    } catch (e) {
      print('DatabaseService: Error getting Windows documents path: $e');
      // Fallback to current directory
      return Directory.current.path;
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    try {
      print('DatabaseService: Creating database tables...');
      
      await db.execute('''
        CREATE TABLE scores(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          score INTEGER NOT NULL,
          category TEXT NOT NULL,
          difficulty TEXT NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
      
      print('DatabaseService: Database tables created successfully');
      
      // Test verisi ekle
      await _insertTestData(db);
      
    } catch (e) {
      print('DatabaseService: ERROR creating database: $e');
      rethrow;
    }
  }

  Future<void> _insertTestData(Database db) async {
    try {
      // Test verisi ekle
      final testScores = [
        {
          'username': 'TestUser1',
          'score': 100,
          'category': 'Science',
          'difficulty': 'Easy',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        {
          'username': 'TestUser2',
          'score': 150,
          'category': 'History',
          'difficulty': 'Medium',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ];

      for (final testScore in testScores) {
        await db.insert('scores', testScore);
      }
      
      print('DatabaseService: Test data inserted successfully');
      
    } catch (e) {
      print('DatabaseService: Error inserting test data: $e');
    }
  }

  Future<void> saveScore(Score score) async {
    try {
      print('DatabaseService: ===== SAVE SCORE START =====');
      print('DatabaseService: Attempting to save score: $score');
      
      // Skor bilgilerini doğrula
      if (score.username.isEmpty) {
        throw Exception('Username cannot be empty');
      }
      if (score.score < 0) {
        throw Exception('Score cannot be negative');
      }
      if (score.category.isEmpty) {
        throw Exception('Category cannot be empty');
      }
      if (score.difficulty.isEmpty) {
        throw Exception('Difficulty cannot be empty');
      }
      
      final db = await database;
      print('DatabaseService: Database connection successful');
      
      // Önce mevcut skorları kontrol et
      final existingScores = await db.query(
        'scores',
        where: 'username = ? AND category = ? AND difficulty = ?',
        whereArgs: [score.username, score.category, score.difficulty],
      );

      print('DatabaseService: Found ${existingScores.length} existing scores for this user/category/difficulty');

      if (existingScores.isNotEmpty) {
        final existingScore = existingScores.first;
        print('DatabaseService: Found existing score: ${existingScore['score']} for ${score.username}');
        
        if (score.score > (existingScore['score'] as int)) {
          print('DatabaseService: New score is higher, updating existing record');
          final result = await db.update(
            'scores',
            {
              'score': score.score,
              'timestamp': score.timestamp,
            },
            where: 'id = ?',
            whereArgs: [existingScore['id']],
          );
          print('DatabaseService: Updated existing score to ${score.score}, rows affected: $result');
        } else {
          print('DatabaseService: New score ${score.score} is not higher than existing score ${existingScore['score']}');
        }
      } else {
        print('DatabaseService: No existing score found, inserting new record');
        final result = await db.insert('scores', {
          'username': score.username,
          'score': score.score,
          'category': score.category,
          'difficulty': score.difficulty,
          'timestamp': score.timestamp,
        });
        print('DatabaseService: Inserted new score with ID: $result');
        print('DatabaseService: Inserted new score: ${score.username} - ${score.score} points');
      }
      
      // Verify the save operation
      print('DatabaseService: Verifying save operation...');
      final savedScores = await db.query(
        'scores',
        where: 'username = ? AND category = ? AND difficulty = ?',
        whereArgs: [score.username, score.category, score.difficulty],
      );
      
      if (savedScores.isNotEmpty) {
        print('DatabaseService: Verification successful - Score saved: ${savedScores.first['score']}');
        final totalScores = await db.query('scores');
        print('DatabaseService: Total scores in database: ${totalScores.length}');
        
        // Debug: Show all scores
        print('DatabaseService: All scores in database:');
        for (final scoreData in totalScores) {
          print('  ID: ${scoreData['id']}, User: ${scoreData['username']}, Score: ${scoreData['score']}, Category: ${scoreData['category']}, Difficulty: ${scoreData['difficulty']}');
        }
      } else {
        print('DatabaseService: WARNING - Score verification failed!');
        throw Exception('Score verification failed - score was not saved properly');
      }
      
      print('DatabaseService: ===== SAVE SCORE END =====');
      
    } catch (e, stackTrace) {
      print('DatabaseService: ERROR saving score: $e');
      print('DatabaseService: Stack trace: $stackTrace');
      
      // Retry once if it's a database connection issue
      if (e.toString().contains('database') || e.toString().contains('connection')) {
        print('DatabaseService: Attempting retry...');
        try {
          await Future.delayed(const Duration(seconds: 1));
          _database = null; // Reset database connection
          await saveScore(score); // Retry
          return;
        } catch (retryError) {
          print('DatabaseService: Retry failed: $retryError');
        }
      }
      
      rethrow;
    }
  }

  Future<List<Score>> getAllScores() async {
    try {
      final db = await database;
      print('DatabaseService: Loading all scores from database');
      
      final List<Map<String, dynamic>> maps = await db.query(
        'scores',
        orderBy: 'score DESC, timestamp DESC',
      );

      print('DatabaseService: Found ${maps.length} scores in database');
      
      final scores = List.generate(maps.length, (i) {
        final map = maps[i];
        final score = Score.fromMap(map);
        print('DatabaseService: Loaded score: $score');
        return score;
      });
      
      // Debug: Print first few scores
      if (scores.isNotEmpty) {
        print('DatabaseService: Top scores:');
        for (int i = 0; i < (scores.length > 3 ? 3 : scores.length); i++) {
          print('  ${i + 1}. ${scores[i].username}: ${scores[i].score} points (${scores[i].category} - ${scores[i].difficulty})');
        }
      } else {
        print('DatabaseService: No scores found in database');
      }
      
      return scores;
    } catch (e) {
      print('DatabaseService: Error loading scores: $e');
      return [];
    }
  }

  Future<void> clearAllScores() async {
    try {
      final db = await database;
      final result = await db.delete('scores');
      print('DatabaseService: Cleared all scores, rows affected: $result');
    } catch (e) {
      print('DatabaseService: Error clearing scores: $e');
      rethrow;
    }
  }

  Future<void> deleteScore(int id) async {
    try {
      final db = await database;
      final result = await db.delete(
        'scores',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseService: Deleted score with ID $id, rows affected: $result');
    } catch (e) {
      print('DatabaseService: Error deleting score: $e');
      rethrow;
    }
  }

  Future<void> resetDatabase() async {
    try {
      print('DatabaseService: Resetting database...');
      await clearAllScores();
      await _insertTestData(await database);
      print('DatabaseService: Database reset complete');
    } catch (e) {
      print('DatabaseService: Error resetting database: $e');
      rethrow;
    }
  }
}