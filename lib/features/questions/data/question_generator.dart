import 'dart:math';

enum QuestionType { dilution, mgPerKg, ivDrip, reconstitution, dosage }

class Question {
  final QuestionType type;
  final String text;
  final double correctAnswer;
  final String unit;
  final String workedSolution;

  const Question({
    required this.type,
    required this.text,
    required this.correctAnswer,
    required this.unit,
    required this.workedSolution,
  });
}

class QuestionGenerator {
  final Random _random = Random();

  int _randInt(int min, int max) => min + _random.nextInt(max - min + 1);

  T _pick<T>(List<T> list) => list[_random.nextInt(list.length)];

  double _roundTo(double value, int decimals) {
    final factor = pow(10, decimals).toDouble();
    return (value * factor).round() / factor;
  }

  // Check if answer is close enough — allows small rounding differences
  static bool isCorrect(double userAnswer, double correctAnswer) {
    final difference = (userAnswer - correctAnswer).abs();
    return difference <= 0.1;
  }

  Question generate(QuestionType type) {
    switch (type) {
      case QuestionType.dilution:
        return _generateDilution();
      case QuestionType.mgPerKg:
        return _generateMgPerKg();
      case QuestionType.ivDrip:
        return _generateIvDrip();
      case QuestionType.reconstitution:
        return _generateReconstitution();
      case QuestionType.dosage:
        return _generateDosage();
    }
  }

  Question generateRandom() {
    final types = QuestionType.values;
    return generate(_pick(types));
  }

  Question _generateDilution() {
    final drugs = ['amoxicillin', 'morphine', 'vancomycin', 'metronidazole', 'gentamicin'];
    final drug = _pick(drugs);
    final stockMg = _pick([250, 500, 1000]);
    final stockMl = _pick([2, 5, 10]);
    final requiredMg = _pick([125, 250, 500]).clamp(1, stockMg).toInt();
    final answer = _roundTo((requiredMg / stockMg) * stockMl, 2);

    return Question(
      type: QuestionType.dilution,
      text: 'You have ${stockMg}mg of $drug in ${stockMl}ml.\n\n'
            'The patient requires ${requiredMg}mg.\n\n'
            'How many ml should be administered?',
      correctAnswer: answer,
      unit: 'ml',
      workedSolution:
          'Formula: (Required dose ÷ Stock dose) × Stock volume\n'
          '= ($requiredMg ÷ $stockMg) × $stockMl\n'
          '= $answer ml',
    );
  }

  Question _generateMgPerKg() {
    final drugs = ['paracetamol', 'ibuprofen', 'amoxicillin', 'gentamicin'];
    final drug = _pick(drugs);
    final weight = _randInt(20, 90).toDouble();
    final dosePerKg = _pick([5, 10, 15, 20]).toDouble();
    final answer = _roundTo(weight * dosePerKg, 1);

    return Question(
      type: QuestionType.mgPerKg,
      text: 'The prescribed dose of $drug is ${dosePerKg.toInt()} mg/kg.\n\n'
            'The patient weighs ${weight.toInt()} kg.\n\n'
            'What is the total dose in mg?',
      correctAnswer: answer,
      unit: 'mg',
      workedSolution:
          'Formula: Weight × Dose per kg\n'
          '= ${weight.toInt()} × ${dosePerKg.toInt()}\n'
          '= $answer mg',
    );
  }

  Question _generateIvDrip() {
    final volume = _pick([250, 500, 1000]);
    final hours = _pick([4, 6, 8, 12]);
    final dropFactor = _pick([10, 15, 20]);
    final answer = _roundTo((volume * dropFactor) / (hours * 60), 0);

    return Question(
      type: QuestionType.ivDrip,
      text: 'An IV of ${volume}ml must run over $hours hours.\n\n'
            'The giving set has a drop factor of $dropFactor drops/ml.\n\n'
            'Calculate the drip rate in drops per minute.',
      correctAnswer: answer,
      unit: 'drops/min',
      workedSolution:
          'Formula: (Volume × Drop factor) ÷ (Hours × 60)\n'
          '= ($volume × $dropFactor) ÷ ($hours × 60)\n'
          '= ${volume * dropFactor} ÷ ${hours * 60}\n'
          '= $answer drops/min',
    );
  }

  Question _generateReconstitution() {
    final drugs = ['penicillin', 'ceftriaxone', 'vancomycin'];
    final drug = _pick(drugs);
    final powderMg = _pick([250, 500, 1000]);
    final diluentMl = _pick([5, 10]);
    final requiredMg = _pick([125, 250]).clamp(1, powderMg).toInt();
    final concentration = powderMg / diluentMl;
    final answer = _roundTo(requiredMg / concentration, 2);

    return Question(
      type: QuestionType.reconstitution,
      text: 'A vial contains ${powderMg}mg of $drug powder.\n\n'
            'You add ${diluentMl}ml of water to reconstitute it.\n\n'
            'How many ml do you draw up to give ${requiredMg}mg?',
      correctAnswer: answer,
      unit: 'ml',
      workedSolution:
          'Step 1: Find concentration after mixing\n'
          '= $powderMg mg ÷ $diluentMl ml = $concentration mg/ml\n\n'
          'Step 2: Volume needed\n'
          '= $requiredMg ÷ $concentration\n'
          '= $answer ml',
    );
  }

  Question _generateDosage() {
    final drugs = ['paracetamol', 'ibuprofen', 'codeine'];
    final drug = _pick(drugs);
    final tabletStrength = _pick([250, 500]);
    final requiredDose = _pick([500, 750, 1000]).clamp(tabletStrength, 1000).toInt();
    final answer = _roundTo(requiredDose / tabletStrength, 1);

    return Question(
      type: QuestionType.dosage,
      text: '$drug tablets are available as ${tabletStrength}mg each.\n\n'
            'The patient needs ${requiredDose}mg.\n\n'
            'How many tablets should be given?',
      correctAnswer: answer,
      unit: 'tablets',
      workedSolution:
          'Formula: Required dose ÷ Tablet strength\n'
          '= $requiredDose ÷ $tabletStrength\n'
          '= $answer tablets',
    );
  }
}