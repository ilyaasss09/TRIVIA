import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = context.read<GameProvider>();
      if (gameProvider.questions.isEmpty) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            return Text(
              '${gameProvider.selectedCategory} - ${gameProvider.selectedDifficulty}',
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showExitDialog(),
        ),
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          if (gameProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading questions...'),
                ],
              ),
            );
          }

          if (gameProvider.questions.isEmpty) {
            return const Center(
              child: Text('No questions available'),
            );
          }

          if (gameProvider.currentQuestionIndex >= gameProvider.questions.length &&
              !gameProvider.isGameActive) {
            //Oyun bitti → ResultScreen'e gönder
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreen(
                    score: gameProvider.score,
                    category: gameProvider.selectedCategory,
                    difficulty: gameProvider.selectedDifficulty,
                  ),
                ),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          final currentQuestion =
          gameProvider.questions[gameProvider.currentQuestionIndex];

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5F5F5), Color(0xFFE3F2FD)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    //Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Progress bar
                          Row(
                            children: [
                              Text(
                                'Question ${gameProvider.currentQuestionIndex + 1} of ${gameProvider.questions.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Score: ${gameProvider.score}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (gameProvider.currentQuestionIndex + 1) /
                                gameProvider.questions.length,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Timer
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Color(0xFFFF9800)),
                              const SizedBox(width: 8),
                              Text(
                                'Time: ${gameProvider.timeLeft}s',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: gameProvider.timeLeft <= 3
                                      ? Colors.red
                                      : const Color(0xFFFF9800),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: gameProvider.timeLeft <= 3
                                      ? Colors.red
                                      : const Color(0xFFFF9800),
                                ),
                                child: Center(
                                  child: Text(
                                    '${gameProvider.timeLeft}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Question card
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentQuestion.question,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: currentQuestion.options.length,
                                  itemBuilder: (context, index) {
                                    final isSelected =
                                        gameProvider.selectedAnswer == index;
                                    final isCorrect =
                                        index == currentQuestion.correctAnswer;

                                    Color backgroundColor = Colors.white;
                                    Color textColor =
                                    const Color(0xFF2196F3);

                                    if (gameProvider.isAnswered) {
                                      if (isCorrect) {
                                        backgroundColor = Colors.green;
                                        textColor = Colors.white;
                                      } else if (isSelected && !isCorrect) {
                                        backgroundColor = Colors.red;
                                        textColor = Colors.white;
                                      }
                                    }

                                    return Padding(
                                      padding:
                                      const EdgeInsets.only(bottom: 12),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: gameProvider.isGameActive
                                              ? () => gameProvider
                                              .answerQuestion(index)
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: backgroundColor,
                                            foregroundColor: textColor,
                                            elevation: 4,
                                            padding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: (backgroundColor ==
                                                      Colors.green ||
                                                      backgroundColor ==
                                                          Colors.red)
                                                      ? Colors.white
                                                      : const Color(
                                                      0xFF2196F3),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      16),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    String.fromCharCode(
                                                        65 + index),
                                                    style: TextStyle(
                                                      color: (backgroundColor ==
                                                          Colors.green ||
                                                          backgroundColor ==
                                                              Colors.red)
                                                          ? backgroundColor
                                                          : Colors.white,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  currentQuestion.options[
                                                  index],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                              if (gameProvider.isAnswered &&
                                                  isCorrect)
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              if (gameProvider.isAnswered &&
                                                  isSelected &&
                                                  !isCorrect)
                                                const Icon(
                                                  Icons.cancel,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Game'),
          content: const Text(
              'Are you sure you want to exit? Your progress will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<GameProvider>().resetGame();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}
