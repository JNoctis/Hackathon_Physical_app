import 'package:flutter/material.dart';

class QuestionPage extends StatefulWidget {
  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  int currentQuestionIndex = 0;
  String? selectedOption;
  int score = 0;

  final List<Map<String, dynamic>> questions = [
    {
      'question': "What is the capital of France?",
      'options': ["Berlin", "Madrid", "Paris", "Rome"],
      'answer': "Paris"
    },
    {
      'question': "Which planet is known as the Red Planet?",
      'options': ["Earth", "Mars", "Venus", "Jupiter"],
      'answer': "Mars"
    },
    {
      'question': "Which language is used for Flutter?",
      'options': ["Java", "Kotlin", "Swift", "Dart"],
      'answer': "Dart"
    }
  ];

  void handleAnswer(String selected) {
    final currentQuestion = questions[currentQuestionIndex];
    final correctAnswer = currentQuestion['answer'];

    if (selected == correctAnswer) {
      score++;
    }

    setState(() {
      selectedOption = null;
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      } else {
        // 所有題目都完成
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Quiz Complete!"),
            content: Text("Your score: $score / ${questions.length}"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    currentQuestionIndex = 0;
                    score = 0;
                  });
                },
                child: Text("Restart"),
              )
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestionIndex]['question'];
    final options = questions[currentQuestionIndex]['options'] as List<String>;

    return Scaffold(
      appBar: AppBar(title: Text("Quiz App")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          const questionHeight = 120.0;
          final remainingHeight = totalHeight - questionHeight;
          final squareHeight = remainingHeight / 2;
          final squareWidth = constraints.maxWidth / 2;

          return Column(
            children: [
              // 問題
              SizedBox(
                height: questionHeight,
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
              // 選項區
              SizedBox(
                height: remainingHeight,
                child: Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  children: options.map((option) {
                    return GestureDetector(
                      onTap: () {
                        handleAnswer(option);
                      },
                      child: Container(
                        width: squareWidth,
                        height: squareHeight,
                        color: Colors.grey[300],
                        child: Center(
                          child: Text(
                            option,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
