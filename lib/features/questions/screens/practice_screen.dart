import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/question_generator.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _generator = QuestionGenerator();
  final _answerController = TextEditingController();
  final _supabase = Supabase.instance.client;

  late Question _currentQuestion;
  bool _showFeedback = false;
  bool? _wasCorrect;
  int _sessionScore = 0;
  int _questionCount = 0;
  int _totalXP = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion = _generator.generateRandom();
      _showFeedback = false;
      _wasCorrect = null;
      _answerController.clear();
    });
  }

  Future<void> _checkAnswer() async {
    final userAnswer = double.tryParse(_answerController.text.trim());

    if (userAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a number')),
      );
      return;
    }

    final correct = QuestionGenerator.isCorrect(userAnswer, _currentQuestion.correctAnswer);

    setState(() {
      _wasCorrect = correct;
      _showFeedback = true;
      _questionCount++;
      if (correct) {
        _sessionScore++;
        _totalXP += 10;
      }
      _isLoading = true;
    });

    // Save to Supabase in background
    await _saveAttempt(userAnswer, correct);

    if (correct) {
      await _addXP(10);
    }

    setState(() { _isLoading = false; });
  }

  Future<void> _saveAttempt(double userAnswer, bool correct) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('question_attempts').insert({
        'user_id': userId,
        'question_type': _currentQuestion.type.name,
        'correct_answer': _currentQuestion.correctAnswer,
        'user_answer': userAnswer,
        'is_correct': correct,
      });
    } catch (e) {
      // Don't crash the app if saving fails
      print('Could not save attempt: $e');
    }
  }

  Future<void> _addXP(int xp) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get current XP
      final profile = await _supabase
          .from('profiles')
          .select('xp, level')
          .eq('id', userId)
          .single();

      final currentXP = profile['xp'] as int;
      final newXP = currentXP + xp;
      final newLevel = (newXP / 200).floor() + 1;

      await _supabase.from('profiles').update({
        'xp': newXP,
        'level': newLevel,
      }).eq('id', userId);
    } catch (e) {
      print('Could not update XP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_questionCount + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_totalXP XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Score bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: $_sessionScore / $_questionCount',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    _questionCount > 0
                      ? '${((_sessionScore / _questionCount) * 100).toStringAsFixed(0)}% accuracy'
                      : 'Let\'s go!',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Question card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6C63FF),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _questionTypeName(_currentQuestion.type),
                        style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _currentQuestion.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Answer input
              if (!_showFeedback) ...[
                Text(
                  'Your answer (${_currentQuestion.unit})',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _answerController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: _currentQuestion.unit,
                    suffixStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF16213E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6C63FF), width: 2),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Check answer',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
              ],

              // Feedback panel
              if (_showFeedback) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _wasCorrect!
                      ? Colors.green.shade900.withOpacity(0.5)
                      : Colors.red.shade900.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _wasCorrect! ? Colors.greenAccent : Colors.redAccent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _wasCorrect! ? Icons.check_circle : Icons.cancel,
                            color: _wasCorrect! ? Colors.greenAccent : Colors.redAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _wasCorrect! ? 'Correct! +10 XP' : 'Incorrect',
                            style: TextStyle(
                              color: _wasCorrect! ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Correct answer: ${_currentQuestion.correctAnswer} ${_currentQuestion.unit}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      const Text(
                        'Worked solution:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentQuestion.workedSolution,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16213E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                      ),
                    ),
                    child: const Text(
                      'Next question →',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

            ],
          ),
        ),
      ),
    );
  }

  String _questionTypeName(QuestionType type) {
    switch (type) {
      case QuestionType.dilution:      return '💊 Drug dilution';
      case QuestionType.mgPerKg:       return '⚖️ mg/kg dosing';
      case QuestionType.ivDrip:        return '💧 IV drip rate';
      case QuestionType.reconstitution: return '🧪 Reconstitution';
      case QuestionType.dosage:        return '📋 Dosage';
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}