import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class DifficultyScreen extends StatefulWidget {
  final String selectedCategory;

  const DifficultyScreen({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  String _selectedDifficulty = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedCategory} - Difficulty'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                      Icon(
                        _getCategoryIcon(widget.selectedCategory),
                        size: 40,
                        color: const Color(0xFF2196F3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.selectedCategory,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose difficulty level',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Difficulty Levels',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                                 // Difficulty options
                 Expanded(
                   child: SingleChildScrollView(
                     child: Column(
                       children: GameProvider.difficulties.map((difficulty) {
                      final isSelected = _selectedDifficulty == difficulty;
                      final color = _getDifficultyColor(difficulty);
                      final points = _getPointsForDifficulty(difficulty);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: isSelected ? 8 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isSelected 
                                ? BorderSide(color: color, width: 3)
                                : BorderSide.none,
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDifficulty = difficulty;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: isSelected
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [color, color.withOpacity(0.8)],
                                      )
                                    : null,
                                color: isSelected ? null : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getDifficultyIcon(difficulty),
                                    size: 32,
                                    color: isSelected ? Colors.white : color,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          difficulty,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$points points per correct answer',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected ? Colors.white70 : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                                             );
                     }).toList(),
                   ),
                 ),
               ),
                
                                       // Start game button
                       if (_selectedDifficulty.isNotEmpty) ...[
                         const SizedBox(height: 16),
                         SizedBox(
                           width: double.infinity,
                           height: 56,
                           child: ElevatedButton(
                             onPressed: _isLoading ? null : () async {
                               setState(() {
                                 _isLoading = true;
                               });
                               
                               await context.read<GameProvider>().loadQuestions(
                                 widget.selectedCategory,
                                 _selectedDifficulty,
                               );
                               
                               if (mounted) {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => const GameScreen(),
                                   ),
                                 );
                               }
                             },
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFF2196F3),
                               foregroundColor: Colors.white,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(16),
                               ),
                             ),
                             child: _isLoading
                                 ? const SizedBox(
                                     width: 20,
                                     height: 20,
                                     child: CircularProgressIndicator(
                                       strokeWidth: 2,
                                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                     ),
                                   )
                                 : const Text(
                                     'Start Game',
                                     style: TextStyle(
                                       fontSize: 18,
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                           ),
                         ),
                       ],
                       
                       // Back button
                       const SizedBox(height: 12),
                       SizedBox(
                         width: double.infinity,
                         height: 50,
                         child: OutlinedButton(
                           onPressed: () {
                             Navigator.pop(context);
                           },
                           style: OutlinedButton.styleFrom(
                             foregroundColor: const Color(0xFF2196F3),
                             side: const BorderSide(color: Color(0xFF2196F3)),
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(16),
                             ),
                           ),
                           child: const Text(
                             'Back',
                             style: TextStyle(
                               fontSize: 16,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ),
                       ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'history':
        return Icons.history;
      case 'geography':
        return Icons.public;
      case 'sports':
        return Icons.sports_soccer;
      case 'science':
        return Icons.science;
      case 'art':
        return Icons.palette;
      case 'literature':
        return Icons.book;
      case 'technology':
        return Icons.computer;
      case 'general knowledge':
        return Icons.psychology;
      default:
        return Icons.quiz;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'medium':
        return Icons.sentiment_neutral;
      case 'hard':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.green;
    }
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
} 