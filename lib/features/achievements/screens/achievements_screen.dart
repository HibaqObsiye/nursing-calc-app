import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  int _totalQuestions = 0;
  int _correctAnswers = 0;
  int _examsPassed = 0;
  int _currentStreak = 0;

  // All possible achievements
  final List<Map<String, dynamic>> _allAchievements = [
    {
      'id': 'first_correct',
      'icon': '🎯',
      'name': 'First steps',
      'description': 'Answer your first question correctly',
      'xpReward': 50,
      'condition': 'correct_1',
    },
    {
      'id': 'correct_10',
      'icon': '⭐',
      'name': 'Getting started',
      'description': 'Answer 10 questions correctly',
      'xpReward': 75,
      'condition': 'correct_10',
    },
    {
      'id': 'correct_50',
      'icon': '🏆',
      'name': 'On a roll',
      'description': 'Answer 50 questions correctly',
      'xpReward': 150,
      'condition': 'correct_50',
    },
    {
      'id': 'correct_100',
      'icon': '💎',
      'name': 'Century',
      'description': 'Answer 100 questions correctly',
      'xpReward': 300,
      'condition': 'correct_100',
    },
    {
      'id': 'perfect_exam',
      'icon': '🥇',
      'name': 'Perfect score',
      'description': 'Pass an exam with 100%',
      'xpReward': 200,
      'condition': 'exam_passed_1',
    },
    {
      'id': 'exam_3',
      'icon': '📚',
      'name': 'Exam veteran',
      'description': 'Pass 3 exams',
      'xpReward': 300,
      'condition': 'exam_passed_3',
    },
    {
      'id': 'streak_3',
      'icon': '🔥',
      'name': 'On fire',
      'description': 'Maintain a 3 day streak',
      'xpReward': 75,
      'condition': 'streak_3',
    },
    {
      'id': 'streak_7',
      'icon': '⚡',
      'name': 'Week warrior',
      'description': 'Maintain a 7 day streak',
      'xpReward': 150,
      'condition': 'streak_7',
    },
    {
      'id': 'streak_30',
      'icon': '💪',
      'name': 'Iron nurse',
      'description': 'Maintain a 30 day streak',
      'xpReward': 500,
      'condition': 'streak_30',
    },
    {
      'id': 'accuracy_80',
      'icon': '🧠',
      'name': 'Sharp mind',
      'description': 'Reach 80% overall accuracy',
      'xpReward': 200,
      'condition': 'accuracy_80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final attempts = await _supabase
          .from('question_attempts')
          .select()
          .eq('user_id', userId);

      final sessions = await _supabase
          .from('sessions')
          .select()
          .eq('user_id', userId)
          .eq('mode', 'exam');

      final profile = await _supabase
          .from('profiles')
          .select('current_streak')
          .eq('id', userId)
          .single();

      int correct = 0;
      for (final a in attempts) {
        if (a['is_correct'] == true) correct++;
      }

      int passed = 0;
      for (final s in sessions) {
        if (s['passed'] == true) passed++;
      }

      setState(() {
        _totalQuestions = attempts.length;
        _correctAnswers = correct;
        _examsPassed = passed;
        _currentStreak = profile['current_streak'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading achievements: $e');
      setState(() { _isLoading = false; });
    }
  }

  // Check if an achievement is unlocked based on current stats
  bool _isUnlocked(String condition) {
    final accuracy = _totalQuestions == 0
        ? 0.0
        : _correctAnswers / _totalQuestions;

    switch (condition) {
      case 'correct_1':   return _correctAnswers >= 1;
      case 'correct_10':  return _correctAnswers >= 10;
      case 'correct_50':  return _correctAnswers >= 50;
      case 'correct_100': return _correctAnswers >= 100;
      case 'exam_passed_1': return _examsPassed >= 1;
      case 'exam_passed_3': return _examsPassed >= 3;
      case 'streak_3':  return _currentStreak >= 3;
      case 'streak_7':  return _currentStreak >= 7;
      case 'streak_30': return _currentStreak >= 30;
      case 'accuracy_80': return accuracy >= 0.8 && _totalQuestions >= 10;
      default: return false;
    }
  }

  // How far along is the user for each achievement
  String _progressText(String condition) {
    final accuracy = _totalQuestions == 0
        ? 0.0
        : _correctAnswers / _totalQuestions;

    switch (condition) {
      case 'correct_1':   return '$_correctAnswers / 1';
      case 'correct_10':  return '$_correctAnswers / 10';
      case 'correct_50':  return '$_correctAnswers / 50';
      case 'correct_100': return '$_correctAnswers / 100';
      case 'exam_passed_1': return '$_examsPassed / 1 exams';
      case 'exam_passed_3': return '$_examsPassed / 3 exams';
      case 'streak_3':  return '$_currentStreak / 3 days';
      case 'streak_7':  return '$_currentStreak / 7 days';
      case 'streak_30': return '$_currentStreak / 30 days';
      case 'accuracy_80':
        return '${(accuracy * 100).toStringAsFixed(0)}% / 80%';
      default: return '';
    }
  }

  int get _unlockedCount =>
      _allAchievements
        .where((a) => _isUnlocked(a['condition']))
        .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Achievements',
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

                  // Summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6C63FF), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Text('🏅', style: TextStyle(fontSize: 40)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_unlockedCount / ${_allAchievements.length} unlocked',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_allAchievements.length - _unlockedCount} more to go!',
                              style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Unlocked section
                  const Text(
                    'Unlocked',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._allAchievements
                    .where((a) => _isUnlocked(a['condition']))
                    .map((a) => _achievementCard(a, true)),

                  if (_unlockedCount == 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No achievements yet — start practising!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Locked section
                  const Text(
                    'Locked',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._allAchievements
                    .where((a) => !_isUnlocked(a['condition']))
                    .map((a) => _achievementCard(a, false)),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _achievementCard(Map<String, dynamic> achievement, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
            ? const Color(0xFF6C63FF).withOpacity(0.5)
            : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [

          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: unlocked
                ? const Color(0xFF6C63FF).withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                unlocked ? achievement['icon'] : '🔒',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['name'],
                  style: TextStyle(
                    color: unlocked ? Colors.white : Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  achievement['description'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _progressText(achievement['condition']),
                  style: TextStyle(
                    color: unlocked
                      ? const Color(0xFF6C63FF)
                      : Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // XP reward
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: unlocked
                ? const Color(0xFF6C63FF).withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${achievement['xpReward']} XP',
              style: TextStyle(
                color: unlocked ? const Color(0xFF6C63FF) : Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}