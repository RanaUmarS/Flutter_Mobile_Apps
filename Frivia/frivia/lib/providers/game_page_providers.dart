import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:html_unescape/html_unescape.dart';


class GamePageProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final int _maxQuestions = 10;
  final String difficultyLevel;
  List? questions;
  int _currentQestionCount = 0;
  int _correctAnswersCount = 0;
  int get currentQuestionCount => _currentQestionCount;

  BuildContext context;

  GamePageProvider({required this.context, required this.difficultyLevel}) {
    _dio.options.baseUrl = "https://opentdb.com/api.php";
    _getQuestionsFromAPI();
  }

  Future<void> _getQuestionsFromAPI() async {
    var _response = await _dio.get(
      '',
      queryParameters: {'amount': 10, 'type': 'boolean', 'difficulty': difficultyLevel},
    );
    var _data = jsonDecode(_response.toString());
    questions = _data["results"];
    notifyListeners();
  }
  String getCurrentQuestionText() {
    final unescape = HtmlUnescape();
    return unescape.convert(questions![_currentQestionCount]["question"]);
  }

  // String getCurrentQuestionText() {
  //   return questions![_currentQestionCount]["question"];
  // }

  void answerQuestion(String _answer) async {
    bool isCorrect =
        questions![_currentQestionCount]["correct_answer"] == _answer;
    _correctAnswersCount += isCorrect? 1 : 0 ;
    _currentQestionCount++;
    showDialog(
      context: context,
      builder: (BuildContext _context) {
        return AlertDialog(
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          title: Icon(
            isCorrect ? Icons.check_circle : Icons.cancel_sharp,
            color: Colors.white,
          ),
        );
      },
    );
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);
    if (_currentQestionCount == _maxQuestions) {
      endGame();
    } else {
      notifyListeners();
    }
  }

  Future<void> endGame() async {
    showDialog(
      context: context,
      builder: (BuildContext _context) {
        return AlertDialog(
          backgroundColor: Colors.blue,
          title: Text(
            "End Game!",
            style: TextStyle(fontSize: 25, color: Colors.white),
          ),
          content: Text('Score $_correctAnswersCount/$_maxQuestions'),
        );
      },
    );
    await Future.delayed(const Duration(seconds: 5));
    Navigator.pop(context);
    Navigator.pop(context);
  }
}
