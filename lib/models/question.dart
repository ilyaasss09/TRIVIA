class Question {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String category;
  final String difficulty;
  final int points;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
    required this.difficulty,
    required this.points,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final correct = Uri.decodeComponent(json['correct_answer'] as String? ?? '');
    final incorrect = (json['incorrect_answers'] as List<dynamic>? ?? [])
        .map((e) => Uri.decodeComponent(e as String))
        .toList();
    final allOptions = List<String>.from(incorrect)..add(correct);
    allOptions.shuffle();
    final correctIndex = allOptions.indexOf(correct);

    return Question(
      question: Uri.decodeComponent(json['question'] ?? ''),
      options: allOptions,
      correctAnswer: correctIndex,
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'easy',
      points: _getPointsForDifficulty(json['difficulty'] ?? 'easy'),
    );
  }

  static int _getPointsForDifficulty(String difficulty) {
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
}