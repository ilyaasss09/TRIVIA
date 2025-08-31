class Score {
  final int? id;
  final String username;
  final int score;
  final String category;
  final String difficulty;
  final int timestamp;

  Score({
    this.id,
    required this.username,
    required this.score,
    required this.category,
    required this.difficulty,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'score': score,
      'category': category,
      'difficulty': difficulty,
      'timestamp': timestamp,
    };
  }

  factory Score.fromMap(Map<String, dynamic> map) {
    return Score(
      id: map['id'] as int?,
      username: map['username'] as String,
      score: map['score'] as int,
      category: map['category'] as String,
      difficulty: map['difficulty'] as String,
      timestamp: map['timestamp'] as int,
    );
  }

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);
  
  @override
  String toString() {
    return 'Score(id: $id, username: $username, score: $score, category: $category, difficulty: $difficulty, timestamp: $timestamp)';
  }
} 