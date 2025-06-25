import 'package:flutter/material.dart';

class DecisionTreePage extends StatefulWidget {
  const DecisionTreePage({super.key});

  @override
  _DecisionTreePageState createState() => _DecisionTreePageState();
}

class _DecisionTreePageState extends State<DecisionTreePage> {
  String? currentQuestionId = 'g1';
  Map<String, String> answers = {};
  List<String> questionHistory = ['g1'];
  int currentQuestionIndex = 0;

  final Map<String, Map<String, dynamic>> questionsData = {
    'g1': {
      'question': 'Why do you run?',
      'options': ['Faster speed', 'Longer distance', 'Healthier shape'],
    },
    'g2': {
      'question': 'Do you have a long term goal?',
      'options': ['Yes', 'No'],
    },
    'h1': {
      'question': 'How long has it been since you last ran?',
      'options': ['Within a week', 'Within a month', 'More than a month'],
    },
    'h2': {
      'question': 'How far did you run last time?',
      'options': ['Less than 3km', '3~10km', 'More than 10km'],
    },
    'h3': {
      'question': 'How fast did you run last time? (min/km)',
      'options': ['Less than 5', '5~7', 'More than 7', 'No idea'],
    },
    'h4': {
      'question': 'What is your current weight?',
      'options': ['kg'],
    },
    'm1': {
      'question': 'Have you started and quit running?',
      'options': ['Yes', 'No'],
    },
    'm2': {
      'question': 'Do you believe in the idea: "Don\'t think. Just run as AI tells you"?',
      'options': ['Yes', 'No'],
    },
  };

  final Map<String, String> questionFlow = {
    'g1': 'g2',
    'g2': 'h1',
    'h1': 'h2',
    'h2': 'm1',
    'h3': 'm1',
    'h4': 'm1',
    'm1': 'm2'
  };

  final Set<String> inputRequiredOptions = {
    'g2-Yes',
    'h4-kg'
  };

  String? pendingInputTrigger;
  final Map<String, TextEditingController> inputControllers = {};

  String? getNextQuestionId(String currentId) {
    if (currentId == 'h2') {
      if (answers['g1'] == 'Faster speed') return 'h3';
      if (answers['g1'] == 'Healthier shape') return 'h4';
    }
    return questionFlow[currentId];
  }

  List<Map<String, String>> getInputFields(String key) {
    if (key == 'g2-Yes') {
      final g1 = answers['g1']?.toLowerCase();
      if (g1 == 'faster speed') {
        return [
          {'key': 'distance', 'hint': 'Enter distance (km)'},
          {'key': 'speed', 'hint': 'Enter speed (min/km)'},
        ];
      } else if (g1 == 'longer distance') {
        return [
          {'key': 'goal', 'hint': 'Enter goal distance (km)'},
        ];
      } else if (g1 == 'healthier shape') {
        return [
          {'key': 'weight', 'hint': 'Enter dream weight (kg)'},
        ];
      }
    } else if (key == 'h4-kg') {
      return [
        {'key': 'weight', 'hint': 'Enter your current weight (kg)'},
      ];
    }
    return [];
  }

  void selectOption(String option) {
    if (currentQuestionId == null) return;

    final key = '$currentQuestionId-$option';

    if (inputRequiredOptions.contains(key)) {
      final fields = getInputFields(key);
      for (var field in fields) {
        final subKey = '$key-${field['key']}';
        inputControllers.putIfAbsent(subKey, () => TextEditingController());
      }
      setState(() {
        pendingInputTrigger = key;
        answers[currentQuestionId!] = option;
      });
      return;
    }

    final nextId = getNextQuestionId(currentQuestionId!);

    setState(() {
      answers[currentQuestionId!] = option;
      pendingInputTrigger = null;

      if (nextId != null) {
        if (currentQuestionIndex + 1 < questionHistory.length) {
          questionHistory = questionHistory.sublist(0, currentQuestionIndex + 1);
        }
        questionHistory.add(nextId);
        currentQuestionIndex++;
        currentQuestionId = nextId;
      } else {
        currentQuestionId = null;
      }
    });
  }

  void submitInput(String key) {
    if (currentQuestionId == null || pendingInputTrigger == null) return;

    final fieldList = getInputFields(key);
    final Map<String, String> inputData = {};

    for (var field in fieldList) {
      final subKey = '$key-${field['key']}';
      final text = inputControllers[subKey]?.text.trim() ?? '';
      if (text.isEmpty) return;
      inputData[field['key']!] = text;
    }

    final answerText = inputData.entries.map((e) => '${e.key}=${e.value}').join(', ');
    final nextId = getNextQuestionId(currentQuestionId!);

    setState(() {
      answers[currentQuestionId!] = '${answers[currentQuestionId!]} (Additional: $answerText)';
      if (nextId != null) {
        if (currentQuestionIndex + 1 < questionHistory.length) {
          questionHistory = questionHistory.sublist(0, currentQuestionIndex + 1);
        }
        questionHistory.add(nextId);
        currentQuestionIndex++;
        currentQuestionId = nextId;
      } else {
        currentQuestionId = null;
      }
    });
  }

  void goToPrevious() {
    if (currentQuestionIndex > 0) {
      final prevId = questionHistory[currentQuestionIndex - 1];
      setState(() {
        currentQuestionIndex--;
        currentQuestionId = prevId;
        final prevAnswer = answers[prevId];
        final key = '$prevId-$prevAnswer';
        pendingInputTrigger = inputRequiredOptions.contains(key) ? key : null;
      });
    }
  }

  void goToNext() {
    if (currentQuestionIndex < questionHistory.length - 1) {
      final nextId = questionHistory[currentQuestionIndex + 1];
      setState(() {
        currentQuestionIndex++;
        currentQuestionId = nextId;
        final nextAnswer = answers[nextId];
        final key = '$nextId-$nextAnswer';
        pendingInputTrigger = inputRequiredOptions.contains(key) ? key : null;
      });
    }
  }

  void restart() {
    setState(() {
      currentQuestionId = 'g1';
      answers.clear();
      pendingInputTrigger = null;
      inputControllers.clear();
      questionHistory = ['g1'];
      currentQuestionIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentQuestionId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Questionnaire Completed')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have completed all the questions!', style: TextStyle(fontSize: 24)),
              SizedBox(height: 16),
              ElevatedButton(onPressed: restart, child: Text('Restart')),
            ],
          ),
        ),
      );
    }

    final questionData = questionsData[currentQuestionId]!;
    final question = questionData['question'] as String;
    final options = questionData['options'] as List<String>;

    return Scaffold(
      appBar: AppBar(title: Text('Conditional Questionnaire')),
      body: Column(
        children: [
          SizedBox(
            height: 120,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  question,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: options.map((option) {
                final key = '$currentQuestionId-$option';
                final isInputRequired = inputRequiredOptions.contains(key);

                return Container(
                  width: 160,
                  height: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.grey[300],
                  child: InkWell(
                    onTap: () => selectOption(option),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(option, style: TextStyle(fontSize: 18)),
                          if (isInputRequired && pendingInputTrigger == key)
                            ...getInputFields(key).map((field) {
                              final subKey = '$key-${field['key']}';
                              final controller = inputControllers.putIfAbsent(
                                  subKey, () => TextEditingController());
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: field['hint'],
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) => submitInput(key),
                                ),
                              );
                            })
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: currentQuestionIndex > 0 ? goToPrevious : null,
                  child: Text('Previous'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: currentQuestionIndex < questionHistory.length - 1 ? goToNext : null,
                  child: Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}