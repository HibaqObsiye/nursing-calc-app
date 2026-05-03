import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  int _totalQuestions = 0;
  int _correctAnswers = 0;
  int _examsAttempted = 0;
  int _examsPassed = 0;
  Map<String, int> _questionsByType = {};
  Map<String, int> _correctByType = {};
  List<Map<String, dynamic>> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Load all question attempts
      final attempts = await _supabase
          .from('question_attempts')
          .select()
          .eq('user_id', userId);

      // Load all exam sessions
      final sessions = await _supabase
          .from('sessions')
          .select()
          .eq('user_id', userId)
          .eq('mode', 'exam')
          .order('completed_at', ascending: false)
          .limit(5);

      // Process attempts — like array.reduce() in JS
      int correct = 0;
      Map<String, int> byType = {};
      Map<String, int> correctByType = {};

      for (final attempt in attempts) {
        final type = attempt['question_type'] as String;
        final isCorrect = attempt['is_correct'] as bool;

        byType[type] = (byType[type] ?? 0) + 1;
        if (isCorrect) {
          correct++;
          correctByType[type] = (correctByType[type] ?? 0) + 1;
        }
      }

      int passed = 0;
      for (final session in sessions) {
        if (session['passed'] == true) passed++;
      }

      setState(() {
        _totalQuestions = attempts.length;
        _correctAnswers = correct;
        _examsAttempted = sessions.length;
        _examsPassed = passed;
        _questionsByType = byType;
        _correctByType = correctByType;
        _recentSessions = List<Map<String, dynamic>>.from(sessions);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() { _isLoading = false; });
    }
  }

  String get _accuracyDisplay {
    if (_totalQuestions == 0) return '0%';
    return '${((_correctAnswers / _totalQuestions) * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'My statistics',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Overall stats grid
                  Row(
                    children: [
                      _bigStatCard(
                        _totalQuestions.toString(),
                        'Total questions',
                        Icons.quiz_outlined,
                      ),
                      const SizedBox(width: 12),
                      _bigStatCard(
                        _accuracyDisplay,
                        'Overall accuracy',
                        Icons.track_changes,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _bigStatCard(
                        _examsAttempted.toString(),
                        'Exams attempted',
                        Icons.timer_outlined,
                      ),
                      const SizedBox(width: 12),
                      _bigStatCard(
                        _examsPassed.toString(),
                        'Exams passed',
                        Icons.check_circle_outline,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Accuracy by topic
                  const Text(
                    'Accuracy by topic',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _topicAccuracyBar('dilution', '💊 Drug dilution'),
                  _topicAccuracyBar('mgPerKg', '⚖️ mg/kg dosing'),
                  _topicAccuracyBar('ivDrip', '💧 IV drip rates'),
                  _topicAccuracyBar('reconstitution', '🧪 Reconstitution'),
                  _topicAccuracyBar('dosage', '📋 Dosage'),

                  const SizedBox(height: 28),

                  // Recent exams
                  const Text(
                    'Recent exams',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_recentSessions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No exams yet — take your first exam!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._recentSessions.map((session) {
                      final passed = session['passed'] as bool? ?? false;
                      final score = session['score'] as int? ?? 0;
                      final total = session['total_questions'] as int? ?? 0;
                      final correct = session['correct_answers'] as int? ?? 0;
                      final date = session['completed_at'] != null
                          ? DateTime.parse(session['completed_at'])
                          : DateTime.now();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: passed
                              ? Colors.greenAccent.withOpacity(0.3)
                              : Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: passed
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                passed ? Icons.check : Icons.close,
                                color: passed
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    passed ? 'Passed ✓' : 'Failed',
                                    style: TextStyle(
                                      color: passed
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '$correct/$total correct · $score%',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _bigStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topicAccuracyBar(String typeKey, String label) {
    final total = _questionsByType[typeKey] ?? 0;
    final correct = _correctByType[typeKey] ?? 0;
    final accuracy = total == 0 ? 0.0 : correct / total;
    final percentage = (accuracy * 100).toStringAsFixed(0);

    Color barColor;
    if (accuracy >= 0.8) {
      barColor = Colors.greenAccent;
    } else if (accuracy >= 0.5) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              Text(
                total == 0 ? 'No attempts' : '$percentage% ($correct/$total)',
                style: TextStyle(
                  color: total == 0 ? Colors.grey : barColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: accuracy,
              backgroundColor: const Color(0xFF16213E),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}