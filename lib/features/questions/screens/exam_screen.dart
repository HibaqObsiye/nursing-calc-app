import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/question_generator.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final _generator = QuestionGenerator();
  final _answerController = TextEditingController();
  final _supabase = Supabase.instance.client;

  late List<Question> _questions;
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _examFinished = false;
  bool _passed = false;

  // Timer
  int _secondsRemaining = 600; // 10 minutes
  late final Stream<int> _timerStream;

  final List<Map<String, dynamic>> _answers = [];

  @override
  void initState() {
    super.initState();
    // Generate 10 random questions
    _questions = List.generate(10, (_) => _generator.generateRandom());

    // Timer stream — ticks every second like setInterval in JS
    _timerStream = Stream.periodic(
      const Duration(seconds: 1),
      (tick) => 600 - tick - 1,
    ).take(600);

    _timerStream.listen((seconds) {
      if (!mounted) return;
      setState(() { _secondsRemaining = seconds; });
      if (seconds <= 0) _finishExam();
    });
  }

  String get _timerDisplay {
    final mins = (_secondsRemaining / 60).floor();
    final secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsRemaining > 300) return Colors.greenAccent;
    if (_secondsRemaining > 120) return Colors.orange;
    return Colors.redAccent;
  }

  void _submitAnswer() {
    final userAnswer = double.tryParse(_answerController.text.trim());

    if (userAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a number')),
      );
      return;
    }

    final question = _questions[_currentIndex];
    final correct = QuestionGenerator.isCorrect(userAnswer, question.correctAnswer);

    // Record the answer
    _answers.add({
      'question': question,
      'userAnswer': userAnswer,
      'correct': correct,
    });

    if (correct) _correctCount++;
    _answerController.clear();

    if (_currentIndex < _questions.length - 1) {
      setState(() { _currentIndex++; });
    } else {
      _finishExam();
    }
  }

  Future<void> _finishExam() async {
    if (_examFinished) return;

    final passed = _correctCount == _questions.length;

    setState(() {
      _examFinished = true;
      _passed = passed;
    });

    // Save exam result to Supabase
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('sessions').insert({
        'user_id': userId,
        'mode': 'exam',
        'score': ((_correctCount / _questions.length) * 100).round(),
        'total_questions': _questions.length,
        'correct_answers': _correctCount,
        'passed': passed,
      });

      // Award XP for passing
      if (passed) {
        final profile = await _supabase
            .from('profiles')
            .select('xp, level')
            .eq('id', userId)
            .single();

        final newXP = (profile['xp'] as int) + 100;
        final newLevel = (newXP / 200).floor() + 1;

        await _supabase.from('profiles').update({
          'xp': newXP,
          'level': newLevel,
        }).eq('id', userId);
      }
    } catch (e) {
      print('Could not save exam: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_examFinished) return _buildResultScreen();
    return _buildExamScreen();
  }

  Widget _buildExamScreen() {
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Question counter
            Text(
              '${_currentIndex + 1} / ${_questions.length}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: _timerColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _timerDisplay,
                    style: TextStyle(
                      color: _timerColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF16213E),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6C63FF)),
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 8),

              // Exam mode warning
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠️ Exam mode — you must score 100% to pass',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Question card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6C63FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _questionTypeName(question.type),
                        style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      question.text,
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
              Text(
                'Your answer (${question.unit})',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _answerController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  suffixText: question.unit,
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
                onSubmitted: (_) => _submitAnswer(),
              ),

              const Spacer(),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1
                      ? 'Submit & next →'
                      : 'Submit & finish',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Pass / fail icon
              Text(
                _passed ? '🎉' : '😔',
                style: const TextStyle(fontSize: 72),
              ),
              const SizedBox(height: 16),

              Text(
                _passed ? 'You passed!' : 'Not quite',
                style: TextStyle(
                  color: _passed ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                _passed
                  ? 'Perfect score! +100 XP earned'
                  : 'You need 100% to pass. Keep practising!',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Score card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _resultStat('$_correctCount / ${_questions.length}', 'Score'),
                        _resultStat(
                          '${((_correctCount / _questions.length) * 100).toStringAsFixed(0)}%',
                          'Accuracy'),
                        _resultStat(
                          _passed ? '+100' : '+0',
                          'XP earned'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Question review
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Question review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              ..._answers.asMap().entries.map((entry) {
                final i = entry.key;
                final answer = entry.value;
                final correct = answer['correct'] as bool;
                final question = answer['question'] as Question;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: correct
                        ? Colors.greenAccent.withOpacity(0.4)
                        : Colors.redAccent.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        correct ? Icons.check_circle : Icons.cancel,
                        color: correct ? Colors.greenAccent : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q${i + 1}: ${_questionTypeName(question.type)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!correct) ...[
                              Text(
                                'Your answer: ${answer['userAnswer']} ${question.unit}',
                                style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 12),
                              ),
                              Text(
                                'Correct: ${question.correctAnswer} ${question.unit}',
                                style: const TextStyle(
                                  color: Colors.greenAccent, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Try again button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExamScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Try again',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Back to dashboard
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context, '/dashboard'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _resultStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF6C63FF),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  String _questionTypeName(QuestionType type) {
    switch (type) {
      case QuestionType.dilution:       return '💊 Drug dilution';
      case QuestionType.mgPerKg:        return '⚖️ mg/kg dosing';
      case QuestionType.ivDrip:         return '💧 IV drip rate';
      case QuestionType.reconstitution: return '🧪 Reconstitution';
      case QuestionType.dosage:         return '📋 Dosage';
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}